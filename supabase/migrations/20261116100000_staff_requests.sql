-- Staff access requests and student/staff role changes (ADR 0026, owner's request of 2026-11-15).
--
-- Someone who signs in to the ops app before their school invited them gets a student account (sign-up never gives a
-- staff role). They can now ask a school for staff access from the ops app; that school's administrators approve it
-- (the account becomes verified staff of the school) or decline it with a note. A decline only clears the request: the
-- account stays as it was and the email can still be used as a student's, or ask again. Nothing is blocked.
--
-- Administrators can also switch a verified member between student and staff (the rule of 20261114160000 kept the two
-- apart). An administrator is still never made a student directly. Guards: a person with a live subscription does not
-- become staff; a staff member on a running trip or assigned to coming trips does not become a student (reassign first).
-- Each refusal is a short code the portal and the apps read.

alter table public.profiles
  add column staff_requested_at timestamptz,
  -- No foreign keys on purpose, as for join_declined_school: a second link from profiles to schools would make the
  -- API's profiles -> schools lookups ambiguous.
  add column staff_request_school uuid,
  add column staff_declined_at timestamptz,
  add column staff_declined_school uuid,
  add column staff_decline_note text check (staff_decline_note is null or char_length(staff_decline_note) <= 300),
  add constraint profiles_staff_request_pair check ((staff_requested_at is null) = (staff_request_school is null));

create index profiles_staff_request_idx on public.profiles (staff_request_school, staff_requested_at) where staff_requested_at is not null;

comment on column public.profiles.staff_request_school is 'The school a student account asked for staff access (ADR 0026). Decided by its admins.';

-- Whether a person has a subscription that still counts: waiting or approved, for a period or semester not yet over.
create function private.has_live_subscription(p_user uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.subscriptions s
    join public.semesters m on m.id = s.semester_id
    where s.student_id = p_user and s.status in ('pending', 'approved')
      and coalesce(s.period_end, m.end_date) >= private.school_today(s.school_id)
  );
$$;

-- Whether a person is on a running trip, or on the crew of a trip still to come.
create function private.trip_duty(p_user uuid)
returns text
language sql stable security definer
set search_path = ''
as $$
  select case
    when exists (select 1 from public.trips t where t.status = 'active' and (t.driver_id = p_user or t.assistant_id = p_user)) then 'active_trip'
    when exists (select 1 from public.trips t where t.status = 'scheduled' and t.scheduled_start > now() and (t.driver_id = p_user or t.assistant_id = p_user)) then 'upcoming_trips'
  end;
$$;

-- ---------------------------------------------------------------- asking
-- The school(s) an account may ask for staff access, as for students: the school of the email's domain when it has one
-- (school.edu), else the account's own school when it is a verified student of one, else every active school to choose
-- from. Only a student account that is not suspended asks.
create function private.staff_request_school_ids(p_user uuid)
returns setof uuid
language sql stable security definer
set search_path = ''
as $$
  with me as (
    select p.school_id, p.status, private.email_domain(p.email) as domain
    from public.profiles p where p.id = p_user and p.role = 'student' and p.status <> 'suspended'
  ),
  by_domain as (
    select d.school_id from public.school_domains d join public.schools s on s.id = d.school_id and s.status = 'active'
    join me on d.domain = me.domain
  )
  select school_id from by_domain
  union all
  select me.school_id from me where not exists (select 1 from by_domain) and me.status = 'verified'
  union all
  select s.id from public.schools s, me
  where s.status = 'active' and not exists (select 1 from by_domain) and me.status <> 'verified';
$$;

create function public.list_staff_request_schools()
returns table (id uuid, name text, short_name text, city text, country text, logo_path text)
language sql stable security definer
set search_path = ''
as $$
  select s.id, s.name, s.short_name, s.city, s.country, s.logo_path
  from public.schools s
  where s.id in (select private.staff_request_school_ids((select auth.uid())))
  order by s.name
  limit 200;
$$;

-- The caller's own staff request: the school asked (if any), when, and the last decline with its note.
create function public.my_staff_request()
returns table (school_id uuid, school_name text, school_logo_path text, requested_at timestamptz, declined_at timestamptz, declined_school_name text, decline_note text)
language sql stable security definer
set search_path = ''
as $$
  select p.staff_request_school, s.name, s.logo_path, p.staff_requested_at, p.staff_declined_at, d.name, p.staff_decline_note
  from public.profiles p
  left join public.schools s on s.id = p.staff_request_school
  left join public.schools d on d.id = p.staff_declined_school
  where p.id = (select auth.uid()) and p.role = 'student';
$$;

-- Ask a school for staff access, change the request, or withdraw it (null). Not more than once every 30 seconds.
-- Refusals: 42501 not_student (or a suspended account), 42501 not_your_school, 22023 school_unknown, 54000 too_many.
create function public.request_staff_access(p_school_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_profile record;
begin
  select id, role, status, school_id, staff_requested_at into v_profile from public.profiles where id = v_uid for update;
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
  if not exists (select 1 from public.schools s where s.id = p_school_id and s.status = 'active') then
    raise exception 'school_unknown' using errcode = '22023';
  end if;
  -- Only a school the account may ask (its email's school, its own school, or any for an account without one).
  if p_school_id not in (select private.staff_request_school_ids(v_uid)) then
    raise exception 'not_your_school' using errcode = '42501';
  end if;

  update public.profiles
  set staff_requested_at = now(), staff_request_school = p_school_id, staff_declined_at = null, staff_declined_school = null, staff_decline_note = null
  where id = v_uid;
  perform private.write_audit(p_school_id, v_uid, 'member.staff_requested', 'profile', v_uid, '{}'::jsonb);
end;
$$;

-- ---------------------------------------------------------------- deciding
-- The staff requests waiting at the caller's school, oldest first. The requester may not belong to the school yet, so
-- this function shows them (only to that school's administrators): name, email, picture, and whether they are a
-- student of the school today and have a live subscription (which stops an approval).
create function public.admin_staff_requests()
returns table (id uuid, full_name text, email text, avatar_url text, requested_at timestamptz, student_here boolean, live_subscription boolean)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  return query
  select p.id, p.full_name, p.email, p.avatar_url, p.staff_requested_at,
         (p.school_id = private.my_school_id() and p.status = 'verified'), private.has_live_subscription(p.id)
  from public.profiles p
  where p.staff_request_school = private.my_school_id() and p.staff_requested_at is not null and p.role = 'student'
  order by p.staff_requested_at
  limit 200;
end;
$$;

-- Approve (the account becomes verified staff of the school) or decline (the request is cleared, with an optional note
-- the person sees; the account is otherwise unchanged). Refusals: 42501 not admin, P0002 no_request,
-- 55000 account_not_active (suspended), 55000 live_subscription, 22023 reason_too_long.
create function public.admin_review_staff_request(p_user_id uuid, p_approve boolean, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
  v_target public.profiles;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if v_note is not null and char_length(v_note) > 300 then
    raise exception 'reason_too_long' using errcode = '22023';
  end if;
  select * into v_target from public.profiles
  where id = p_user_id and staff_request_school = v_school and staff_requested_at is not null and role = 'student'
  for update;
  if not found then
    raise exception 'no_request' using errcode = 'P0002';
  end if;

  if p_approve then
    if v_target.status = 'suspended' then
      raise exception 'account_not_active' using errcode = '55000';
    end if;
    if private.has_live_subscription(p_user_id) then
      raise exception 'live_subscription' using errcode = '55000';
    end if;
    update public.profiles
    set school_id = v_school, role = 'staff', status = 'verified',
        staff_requested_at = null, staff_request_school = null, staff_declined_at = null, staff_declined_school = null, staff_decline_note = null,
        join_requested_at = null, join_declined_at = null, join_declined_school = null, join_decline_note = null
    where id = p_user_id;
    perform private.write_audit(v_school, v_actor, 'member.staff_approved', 'profile', p_user_id, jsonb_build_object('from_status', v_target.status));
  else
    update public.profiles
    set staff_requested_at = null, staff_request_school = null, staff_declined_at = now(), staff_declined_school = v_school, staff_decline_note = v_note
    where id = p_user_id;
    perform private.write_audit(v_school, v_actor, 'member.staff_declined', 'profile', p_user_id, jsonb_build_object('reason', v_note));
  end if;
end;
$$;

-- ---------------------------------------------------------------- the role of a person
-- Staff and administrator are interchangeable; student and staff now too (both ways), never student and administrator
-- directly. Refusals as before (account_not_active, last_admin, role_family), plus live_subscription (to staff),
-- active_trip and upcoming_trips (to student).
create or replace function public.admin_set_user_role(p_user_id uuid, p_role public.user_role)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_target public.profiles;
  v_duty text;
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
  if v_target.role = p_role then
    return;
  end if;
  -- A student and an administrator never swap directly (through staff, one step at a time).
  if (v_target.role = 'student' and p_role = 'admin') or (v_target.role = 'admin' and p_role = 'student') then
    raise exception 'role_family' using errcode = '22023';
  end if;
  if v_target.role = 'admin' and not exists (
    select 1 from public.profiles a where a.school_id = v_school and a.role = 'admin' and a.status = 'verified' and a.id <> p_user_id
  ) then
    raise exception 'last_admin' using errcode = '55000';
  end if;
  if v_target.role = 'student' and private.has_live_subscription(p_user_id) then
    raise exception 'live_subscription' using errcode = '55000';
  end if;
  if p_role = 'student' then
    v_duty := private.trip_duty(p_user_id);
    if v_duty is not null then
      raise exception '%', v_duty using errcode = '55000';
    end if;
  end if;

  update public.profiles
  set role = p_role, staff_requested_at = null, staff_request_school = null
  where id = p_user_id;

  perform private.write_audit(
    v_school, v_actor, 'user.role_changed', 'profile', p_user_id,
    jsonb_build_object('from', v_target.role, 'to', p_role)
  );
end;
$$;

revoke execute on function private.has_live_subscription(uuid), private.trip_duty(uuid), private.staff_request_school_ids(uuid) from public;
revoke execute on function public.list_staff_request_schools(), public.my_staff_request(), public.request_staff_access(uuid),
  public.admin_staff_requests(), public.admin_review_staff_request(uuid, boolean, text) from public, anon;
grant execute on function public.list_staff_request_schools(), public.my_staff_request(), public.request_staff_access(uuid),
  public.admin_staff_requests(), public.admin_review_staff_request(uuid, boolean, text) to authenticated;
