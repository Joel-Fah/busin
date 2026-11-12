-- Roles and suspended accounts (owner fixes list).
--   * Staff and administrator are interchangeable; a student is neither: no role change and no invite moves an account
--     between the two (a staff member signs in with a Google account that was never a student's).
--   * A suspended account can do nothing, and nothing can be done to it until it is restored: no role change, no invite,
--     no review of its subscriptions. Restoring is the only way out. Pending accounts keep their join-request flow.
--   * A school always keeps an administrator: the last one cannot be demoted or suspended.
--   * Trip crew must be verified staff of the school, in the database too (the portal already checked).
-- Each refusal is a short code the portal and the apps read.

-- ---------------------------------------------------------------- the role of a person
create or replace function public.admin_set_user_role(p_user_id uuid, p_role public.user_role)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_target public.profiles;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if p_user_id = v_actor then
    raise exception 'You cannot change your own role' using errcode = '42501';
  end if;
  if p_role is null then
    raise exception 'A role is required' using errcode = '22023';
  end if;

  select * into v_target from public.profiles where id = p_user_id and school_id = v_school for update;
  if not found then
    raise exception 'User not found' using errcode = 'P0002';
  end if;
  if v_target.status <> 'verified' then
    raise exception 'account_not_active' using errcode = '55000';
  end if;
  -- Student is one family, staff and administrator the other.
  if (v_target.role = 'student') <> (p_role = 'student') then
    raise exception 'role_family' using errcode = '22023';
  end if;
  if v_target.role = 'admin' and p_role <> 'admin' and not exists (
    select 1 from public.profiles a where a.school_id = v_school and a.role = 'admin' and a.status = 'verified' and a.id <> p_user_id
  ) then
    raise exception 'last_admin' using errcode = '55000';
  end if;

  update public.profiles set role = p_role where id = p_user_id;

  perform private.write_audit(
    v_school, v_actor, 'user.role_changed', 'profile', p_user_id,
    jsonb_build_object('from', v_target.role, 'to', p_role)
  );
end;
$$;

-- ---------------------------------------------------------------- the status of a person
-- Allowed: verified to suspended, suspended to verified (restoring), pending to suspended. A pending account is verified
-- through admin_verify_member, which knows the join request.
create or replace function public.admin_set_user_status(p_user_id uuid, p_status public.account_status)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_target public.profiles;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if p_user_id = v_actor then
    raise exception 'You cannot change your own status' using errcode = '42501';
  end if;
  if p_status is null then
    raise exception 'A status is required' using errcode = '22023';
  end if;

  select * into v_target from public.profiles where id = p_user_id and school_id = v_school for update;
  if not found then
    raise exception 'User not found' using errcode = 'P0002';
  end if;
  if not ((v_target.status = 'verified' and p_status = 'suspended')
       or (v_target.status = 'suspended' and p_status = 'verified')
       or (v_target.status = 'pending' and p_status = 'suspended')) then
    raise exception 'invalid_transition' using errcode = '55000';
  end if;
  if p_status = 'suspended' and v_target.role = 'admin' and v_target.status = 'verified' and not exists (
    select 1 from public.profiles a where a.school_id = v_school and a.role = 'admin' and a.status = 'verified' and a.id <> p_user_id
  ) then
    raise exception 'last_admin' using errcode = '55000';
  end if;

  update public.profiles set status = p_status where id = p_user_id;

  perform private.write_audit(
    v_school, v_actor, 'user.status_changed', 'profile', p_user_id,
    jsonb_build_object('from', v_target.status, 'to', p_status)
  );
end;
$$;

-- ---------------------------------------------------------------- inviting by email (ADR 0015)
-- An account that exists must be staff or an administrator of this school already (or on no school's list): a student's
-- account, a pending one and a suspended one are not converted.
create or replace function public.admin_invite_staff(p_email text, p_role public.user_role)
returns text
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_email text := lower(trim(coalesce(p_email, '')));
  v_profile public.profiles;
  v_other uuid;
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' or char_length(v_email) > 254 then
    raise exception 'invalid_email' using errcode = '22023';
  end if;
  if p_role is null or p_role not in ('staff', 'admin') then
    raise exception 'invalid_role' using errcode = '22023';
  end if;

  select * into v_profile from public.profiles where email = v_email for update;
  if found then
    if v_profile.id = v_actor then
      raise exception 'You cannot change your own role' using errcode = '42501';
    end if;
    -- An account of another school, or one waiting on another school's answer, is not ours to take.
    if v_profile.school_id is not null and v_profile.school_id <> v_school then
      raise exception 'other_school' using errcode = '55000';
    end if;
    if v_profile.role = 'student' then
      raise exception 'student_account' using errcode = '55000';
    end if;
    if v_profile.status <> 'verified' then
      raise exception 'account_not_active' using errcode = '55000';
    end if;
    if v_profile.role = 'admin' and p_role <> 'admin' and not exists (
      select 1 from public.profiles a where a.school_id = v_school and a.role = 'admin' and a.status = 'verified' and a.id <> v_profile.id
    ) then
      raise exception 'last_admin' using errcode = '55000';
    end if;
    update public.profiles set role = p_role where id = v_profile.id;
    perform private.write_audit(v_school, v_actor, 'invite.applied', 'profile', v_profile.id,
      jsonb_build_object('from', v_profile.role, 'to', p_role));
    return 'applied';
  end if;

  select school_id into v_other from public.staff_invites where email = v_email and expires_at > now();
  if v_other is not null and v_other <> v_school then
    raise exception 'other_school' using errcode = '55000';
  end if;
  insert into public.staff_invites (email, school_id, role, invited_by)
  values (v_email, v_school, p_role, v_actor)
  on conflict (email) do update
    set school_id = excluded.school_id, role = excluded.role, invited_by = excluded.invited_by,
        created_at = now(), expires_at = now() + interval '30 days';
  perform private.write_audit(v_school, v_actor, 'invite.created', 'school', v_school, jsonb_build_object('role', p_role));
  return 'invited';
end;
$$;

-- ---------------------------------------------------------------- nothing is done to a suspended student's subscriptions
create function private.student_is_suspended(p_student uuid) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles p where p.id = p_student and p.status = 'suspended')
$$;
revoke execute on function private.student_is_suspended(uuid) from public;

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
  if private.student_is_suspended(v_sub.student_id) then
    raise exception 'account_suspended' using errcode = '55000';
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
  if private.student_is_suspended(v_sub.student_id) then
    raise exception 'account_suspended' using errcode = '55000';
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
  if private.student_is_suspended(v_sub.student_id) then
    raise exception 'account_suspended' using errcode = '55000';
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

-- ---------------------------------------------------------------- a trip's crew must be verified staff of the school
create function private.check_trip_crew() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Runs as the administrator, who can read the school's people. Only people using the API are held to it; seeds and
  -- fixtures, and the staff field trip (which checks its own crew), are not.
  if current_user <> 'authenticated' then
    return new;
  end if;
  if (new.driver_id is not null and (tg_op = 'INSERT' or new.driver_id is distinct from old.driver_id) and not exists (
        select 1 from public.profiles p where p.id = new.driver_id and p.school_id = new.school_id and p.role = 'staff' and p.status = 'verified'))
     or (new.assistant_id is not null and (tg_op = 'INSERT' or new.assistant_id is distinct from old.assistant_id) and not exists (
        select 1 from public.profiles p where p.id = new.assistant_id and p.school_id = new.school_id and p.role = 'staff' and p.status = 'verified')) then
    raise exception 'crew_not_staff' using errcode = '22023';
  end if;
  return new;
end;
$$;
revoke execute on function private.check_trip_crew() from public;
grant execute on function private.check_trip_crew() to authenticated;
create trigger trips_check_crew before insert or update of driver_id, assistant_id on public.trips
  for each row execute function private.check_trip_crew();

-- ---------------------------------------------------------------- the apps learn of a suspension or a new role at once
-- A person reads their own profile row (row-level security), so this reaches only them (and administrators of the school).
alter publication supabase_realtime add table public.profiles;
