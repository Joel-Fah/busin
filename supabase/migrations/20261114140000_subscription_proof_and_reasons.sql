-- Subscriptions need a proof, and reasons must be sensible (owner fixes list).
--   * A subscription cannot be requested without a proof that really exists in storage, nor approved without one, nor for
--     a semester that has ended.
--   * Reasons (reject, revoke, restore, cancelling a trip, declining a join request) are trimmed, have their runs of
--     spaces collapsed, and must be 10 to 500 characters (300 for a trip or a join request). Restoring a subscription now
--     needs a reason like the others. Each refusal says why in one short word the apps can read (`reason_too_short`).

-- The cleaned reason, or null when none was given and none is needed. 22023 with a short code when it will not do.
create function private.clean_reason(p_reason text, p_required boolean, p_max int default 500)
returns text
language plpgsql immutable
set search_path = ''
as $$
declare
  v text := nullif(btrim(regexp_replace(coalesce(p_reason, ''), '\s+', ' ', 'g')), '');
begin
  if v is null then
    if p_required then
      raise exception 'reason_required' using errcode = '22023';
    end if;
    return null;
  end if;
  if char_length(v) < 10 then
    raise exception 'reason_too_short' using errcode = '22023';
  end if;
  if char_length(v) > p_max then
    raise exception 'reason_too_long' using errcode = '22023';
  end if;
  return v;
end;
$$;
revoke execute on function private.clean_reason(text, boolean, int) from public;

-- ---------------------------------------------------------------- a request needs a proof that exists
create function private.check_subscription_request() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Runs as the student: they can read their own proof and their school's semesters. Only people using the API are held
  -- to it (the writing role is `authenticated`); seeds and fixtures load history on purpose.
  if current_user <> 'authenticated' then
    return new;
  end if;
  if new.proof_path is null or btrim(new.proof_path) = '' then
    raise exception 'proof_required' using errcode = '22023';
  end if;
  if not exists (select 1 from storage.objects o where o.bucket_id = 'proofs' and o.name = new.proof_path) then
    raise exception 'proof_missing' using errcode = '22023';
  end if;
  if exists (select 1 from public.semesters m where m.id = new.semester_id and m.end_date < private.school_today(new.school_id)) then
    raise exception 'semester_ended' using errcode = '55000';
  end if;
  return new;
end;
$$;
revoke execute on function private.check_subscription_request() from public;
grant execute on function private.check_subscription_request() to authenticated;
-- After the row-level security check, so the more basic refusals (someone else's request, another school) come first.
create constraint trigger subscriptions_check_request after insert on public.subscriptions
  for each row execute function private.check_subscription_request();

-- ---------------------------------------------------------------- reviewing
create or replace function public.admin_review_subscription(
  p_subscription_id uuid,
  p_decision text,
  p_note text default null
) returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_sub public.subscriptions;
  v_note text;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if p_decision is null or p_decision not in ('approved', 'rejected') then
    raise exception 'Decision must be approved or rejected' using errcode = '22023';
  end if;
  v_note := private.clean_reason(p_note, p_decision = 'rejected');

  select * into v_sub
  from public.subscriptions
  where id = p_subscription_id and school_id = v_school
  for update;
  if not found then
    raise exception 'Subscription not found' using errcode = 'P0002';
  end if;
  if v_sub.status <> 'pending' then
    raise exception 'Only pending subscriptions can be reviewed' using errcode = '55000';
  end if;
  if p_decision = 'approved' then
    if v_sub.proof_path is null then
      raise exception 'proof_required' using errcode = '22023';
    end if;
    if exists (select 1 from public.semesters m where m.id = v_sub.semester_id and m.end_date < private.school_today(v_school)) then
      raise exception 'semester_ended' using errcode = '55000';
    end if;
  end if;

  update public.subscriptions
  set status = p_decision::public.subscription_status,
      review_note = v_note,
      reviewed_by = v_actor,
      reviewed_at = now()
  where id = p_subscription_id;

  perform private.write_audit(
    v_school, v_actor, 'subscription.' || p_decision, 'subscription', p_subscription_id,
    jsonb_build_object('student_id', v_sub.student_id)
  );
end;
$$;

create or replace function public.admin_revoke_subscription(p_subscription_id uuid, p_note text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_sub public.subscriptions;
  v_note text;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  v_note := private.clean_reason(p_note, true);

  select * into v_sub
  from public.subscriptions
  where id = p_subscription_id and school_id = v_school
  for update;
  if not found then
    raise exception 'Subscription not found' using errcode = 'P0002';
  end if;
  if v_sub.status <> 'approved' then
    raise exception 'Only approved subscriptions can be revoked' using errcode = '55000';
  end if;

  update public.subscriptions
  set status = 'revoked',
      review_note = v_note,
      reviewed_by = v_actor,
      reviewed_at = now()
  where id = p_subscription_id;

  perform private.write_audit(
    v_school, v_actor, 'subscription.revoked', 'subscription', p_subscription_id,
    jsonb_build_object('student_id', v_sub.student_id, 'approved_by', v_sub.reviewed_by)
  );
end;
$$;

create or replace function public.admin_reinstate_subscription(p_subscription_id uuid, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_sub public.subscriptions;
  v_note text;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  v_note := private.clean_reason(p_note, true);

  select * into v_sub
  from public.subscriptions
  where id = p_subscription_id and school_id = v_school
  for update;
  if not found then
    raise exception 'Subscription not found' using errcode = 'P0002';
  end if;
  if v_sub.status <> 'revoked' then
    raise exception 'Only revoked subscriptions can be reinstated' using errcode = '55000';
  end if;
  -- One live subscription per student and semester: a newer request has to be dealt with first.
  if exists (
    select 1 from public.subscriptions s
    where s.student_id = v_sub.student_id and s.semester_id = v_sub.semester_id
      and s.id <> v_sub.id and s.status in ('pending', 'approved')
  ) then
    raise exception 'The student already has a live subscription for this semester' using errcode = '55000';
  end if;
  if exists (select 1 from public.semesters m where m.id = v_sub.semester_id and m.end_date < private.school_today(v_school)) then
    raise exception 'semester_ended' using errcode = '55000';
  end if;

  update public.subscriptions
  set status = 'approved',
      review_note = v_note,
      reviewed_by = v_actor,
      reviewed_at = now()
  where id = p_subscription_id;

  perform private.write_audit(
    v_school, v_actor, 'subscription.reinstated', 'subscription', p_subscription_id,
    jsonb_build_object('student_id', v_sub.student_id)
  );
end;
$$;

-- ---------------------------------------------------------------- the other reasons
create or replace function public.admin_cancel_trip(p_trip_id uuid, p_reason text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_trip public.trips;
  v_reason text;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  v_reason := private.clean_reason(p_reason, false, 300);

  select * into v_trip
  from public.trips
  where id = p_trip_id and school_id = v_school
  for update;
  if not found then
    raise exception 'Trip not found' using errcode = 'P0002';
  end if;
  if v_trip.status <> 'scheduled' then
    raise exception 'Only a trip that has not started can be cancelled' using errcode = '55000';
  end if;

  update public.trips set status = 'cancelled' where id = p_trip_id;

  perform private.write_audit(
    v_school, v_actor, 'trip.cancelled', 'trip', p_trip_id,
    jsonb_build_object('bus_id', v_trip.bus_id, 'scheduled_start', v_trip.scheduled_start, 'reason', v_reason)
  );
end;
$$;

create or replace function public.admin_decline_member(p_user_id uuid, p_reason text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_reason text;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  v_reason := private.clean_reason(p_reason, false, 300);
  update public.profiles
  set school_id = null, join_requested_at = null, join_declined_at = now(), join_declined_school = v_school, join_decline_note = v_reason
  where id = p_user_id and school_id = v_school and role = 'student' and status = 'pending';
  if not found then
    raise exception 'No request to decline' using errcode = 'P0002';
  end if;
  perform private.write_audit(v_school, v_actor, 'member.declined', 'profile', p_user_id, jsonb_build_object('reason', v_reason));
end;
$$;
