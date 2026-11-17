-- Staff access is asked at most 3 times (issue #543, owner's rule; extends ADR 0026).
--
-- The rule:
-- - Every request an account sends with request_staff_access counts, per account (not per school), in
--   profiles.staff_request_count. Users cannot write the column (no column grant): only the functions below change it.
-- - Withdrawing does not count, and neither does changing the school of a request still waiting (the function already
--   lets a waiting request be pointed at another school; that is the same attempt). A refused call does not count.
-- - With 3 requests sent and none waiting, request_staff_access refuses with 55000 requests_used_up. A waiting request
--   can still be withdrawn or changed, and the school can still approve or decline it.
-- - From then on only an administrator lets the account in: approving the request still waiting, or inviting the email
--   (admin_invite_staff). Inviting the email of a student account that has used up its requests now makes it verified
--   staff of the school at once, with the same guards as an approval (not suspended, no live subscription), when it is a
--   school the account could ask. Any other student account is still refused with student_account (unchanged).
-- - An invite applied to an account sets the count back to 0 (the administrator let them in; if they are made a student
--   again later, they can ask again). An approval leaves the count as it is: becoming staff makes it moot, and if an
--   administrator makes them a student again, only the requests left remain until an administrator invites them.
-- - my_staff_request tells the app how many requests are left (requests_left), and admin_staff_requests tells the
--   portal the same, so it can say that declining the last one leaves only an invite.
--
-- Re-runnable: the column is added if missing and every function is replaced (or dropped first when its result
-- changes).

alter table public.profiles
  add column if not exists staff_request_count smallint not null default 0
    check (staff_request_count >= 0);

comment on column public.profiles.staff_request_count is
  'How many staff access requests the account sent (issue #543). Written only by request_staff_access and admin_invite_staff.';

-- The number of staff requests an account may send. One place, read by the functions below.
create or replace function private.staff_request_limit()
returns smallint
language sql immutable
set search_path = ''
as $$ select 3::smallint $$;

-- ---------------------------------------------------------------- the person's own request
drop function if exists public.my_staff_request();
create function public.my_staff_request()
returns table (school_id uuid, school_name text, school_logo_path text, requested_at timestamptz, declined_at timestamptz,
  declined_school_name text, decline_note text, requests_left integer)
language sql stable security definer
set search_path = ''
as $$
  select p.staff_request_school, s.name, s.logo_path, p.staff_requested_at, p.staff_declined_at, d.name, p.staff_decline_note,
         greatest(0, private.staff_request_limit() - p.staff_request_count)::integer
  from public.profiles p
  left join public.schools s on s.id = p.staff_request_school
  left join public.schools d on d.id = p.staff_declined_school
  where p.id = (select auth.uid()) and p.role = 'student';
$$;

-- Ask a school for staff access, change the request, or withdraw it (null). Not more than once every 30 seconds, and
-- at most staff_request_limit() requests per account. Refusals: 42501 not_student (or a suspended account),
-- 42501 not_your_school, 22023 school_unknown, 54000 too_many, 55000 requests_used_up.
create or replace function public.request_staff_access(p_school_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_profile record;
  v_new boolean;
begin
  select id, role, status, school_id, staff_requested_at, staff_request_count into v_profile from public.profiles where id = v_uid for update;
  if not found or v_profile.role <> 'student' or v_profile.status = 'suspended' then
    raise exception 'not_student' using errcode = '42501';
  end if;
  if v_profile.staff_requested_at is not null and v_profile.staff_requested_at > now() - interval '30 seconds' then
    raise exception 'too_many' using errcode = '54000';
  end if;

  if p_school_id is null then
    update public.profiles set staff_requested_at = null, staff_request_school = null where id = v_uid;
    return;
  end if;
  -- A new request counts; pointing the one still waiting at another school does not.
  v_new := v_profile.staff_requested_at is null;
  if v_new and v_profile.staff_request_count >= private.staff_request_limit() then
    raise exception 'requests_used_up' using errcode = '55000';
  end if;
  if not exists (select 1 from public.schools s where s.id = p_school_id and s.status = 'active') then
    raise exception 'school_unknown' using errcode = '22023';
  end if;
  -- Only a school the account may ask (its email's school, its own school, or any for an account without one).
  if p_school_id not in (select private.staff_request_school_ids(v_uid)) then
    raise exception 'not_your_school' using errcode = '42501';
  end if;

  update public.profiles
  set staff_requested_at = now(), staff_request_school = p_school_id, staff_declined_at = null, staff_declined_school = null, staff_decline_note = null,
      staff_request_count = staff_request_count + case when v_new then 1 else 0 end
  where id = v_uid;
  perform private.write_audit(p_school_id, v_uid, 'member.staff_requested', 'profile', v_uid,
    jsonb_build_object('count', v_profile.staff_request_count + case when v_new then 1 else 0 end));
end;
$$;

-- ---------------------------------------------------------------- deciding
-- As before, plus requests_left: 0 means this is the person's last request (declined, only an invite lets them in).
drop function if exists public.admin_staff_requests();
create function public.admin_staff_requests()
returns table (id uuid, full_name text, email text, avatar_url text, requested_at timestamptz, student_here boolean,
  live_subscription boolean, requests_left integer)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  return query
  select p.id, p.full_name, p.email, p.avatar_url, p.staff_requested_at,
         (p.school_id = private.my_school_id() and p.status = 'verified'), private.has_live_subscription(p.id),
         greatest(0, private.staff_request_limit() - p.staff_request_count)::integer
  from public.profiles p
  where p.staff_request_school = private.my_school_id() and p.staff_requested_at is not null and p.role = 'student'
  order by p.staff_requested_at
  limit 200;
end;
$$;

-- ---------------------------------------------------------------- inviting by email (ADR 0015)
-- As in 20261114160000, with two changes for issue #543: a student account that has used up its staff requests, and
-- could ask this school, becomes verified staff of the school (the same guards as approving its request); and an invite
-- applied to an account sets its request count back to 0. Other student accounts are still refused (student_account).
-- Refusals: 42501 not an admin or oneself, 22023 invalid_email or invalid_role, 55000 other_school, student_account,
-- account_not_active, last_admin, live_subscription.
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
      -- Only a student account that asked for staff access until it could not ask any more, and could ask this school.
      -- Made staff (never an administrator directly, as in admin_set_user_role).
      if v_profile.staff_request_count < private.staff_request_limit() then
        raise exception 'student_account' using errcode = '55000';
      end if;
      if v_profile.status = 'suspended' then
        raise exception 'account_not_active' using errcode = '55000';
      end if;
      if p_role <> 'staff' or v_school not in (select private.staff_request_school_ids(v_profile.id)) then
        raise exception 'student_account' using errcode = '55000';
      end if;
      if private.has_live_subscription(v_profile.id) then
        raise exception 'live_subscription' using errcode = '55000';
      end if;
      update public.profiles
      set school_id = v_school, role = 'staff', status = 'verified', staff_request_count = 0,
          staff_requested_at = null, staff_request_school = null, staff_declined_at = null, staff_declined_school = null, staff_decline_note = null,
          join_requested_at = null, join_declined_at = null, join_declined_school = null, join_decline_note = null
      where id = v_profile.id;
      perform private.write_audit(v_school, v_actor, 'invite.applied', 'profile', v_profile.id,
        jsonb_build_object('from', v_profile.role, 'to', 'staff', 'from_status', v_profile.status, 'requests_used_up', true));
      return 'applied';
    end if;

    if v_profile.status <> 'verified' then
      raise exception 'account_not_active' using errcode = '55000';
    end if;
    if v_profile.role = 'admin' and p_role <> 'admin' and not exists (
      select 1 from public.profiles a where a.school_id = v_school and a.role = 'admin' and a.status = 'verified' and a.id <> v_profile.id
    ) then
      raise exception 'last_admin' using errcode = '55000';
    end if;
    update public.profiles set role = p_role, staff_request_count = 0 where id = v_profile.id;
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

revoke execute on function private.staff_request_limit() from public;
revoke execute on function public.my_staff_request(), public.request_staff_access(uuid), public.admin_staff_requests(),
  public.admin_invite_staff(text, public.user_role) from public, anon;
grant execute on function public.my_staff_request(), public.request_staff_access(uuid), public.admin_staff_requests(),
  public.admin_invite_staff(text, public.user_role) to authenticated;
