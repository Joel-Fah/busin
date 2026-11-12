-- Joining a school (ADR 0012). A school email still joins its school directly, verified. Another email may sign up only
-- if some active school accepts other emails (optionally limited to some domains); the account then starts pending with
-- no school, the student asks to join one, and that school's admins verify or decline the request.
--
-- A pending account reads nothing of any school (private.my_school_id() is null unless verified), so the only things it
-- can see are the schools that accept its email and its own request, both through the functions below.

alter table public.profiles alter column school_id drop not null;

alter table public.profiles
  add column join_requested_at timestamptz,
  add column join_declined_at timestamptz,
  -- No foreign key on purpose: a second link between profiles and schools would make the API's profiles -> schools
  -- lookups ambiguous. It only names the school in the student's "declined" message.
  add column join_declined_school uuid,
  add column join_decline_note text check (join_decline_note is null or char_length(join_decline_note) <= 300),
  add constraint profiles_school_or_pending check (school_id is not null or (role = 'student' and status = 'pending'));

comment on column public.profiles.join_requested_at is 'When a student without a school email asked to join school_id (ADR 0012).';

-- The email domain of an account, as stored (lowercase).
create function private.email_domain(p_email text)
returns text
language sql immutable
set search_path = ''
as $$ select lower(split_part(coalesce(p_email, ''), '@', 2)); $$;

-- Whether a school accepts an email domain that is not one of its own.
create function private.school_accepts_domain(p_school uuid, p_domain text)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.schools s
    where s.id = p_school and s.status = 'active' and s.accepts_open_signup
      and (cardinality(s.open_signup_domains) = 0 or p_domain = any (s.open_signup_domains))
  );
$$;

-- Sign-up: Google only. A school domain joins that school, verified (as before). Any other email may sign up only if
-- some active school accepts it, and then starts pending with no school. Roles are never chosen by the client.
create or replace function private.handle_new_user() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_domain text;
  v_school uuid;
  v_name text;
  v_status public.account_status := 'verified';
begin
  if coalesce(new.raw_app_meta_data ->> 'provider', '') <> 'google' then
    raise exception 'Only Google sign-in is allowed' using errcode = '42501';
  end if;
  if new.email is null or position('@' in new.email) = 0 then
    raise exception 'A valid email is required' using errcode = '42501';
  end if;

  v_domain := private.email_domain(new.email);
  select d.school_id into v_school
  from public.school_domains d
  join public.schools s on s.id = d.school_id
  where d.domain = v_domain and s.status = 'active';

  if v_school is null then
    if not exists (
      select 1 from public.schools s
      where s.status = 'active' and s.accepts_open_signup
        and (cardinality(s.open_signup_domains) = 0 or v_domain = any (s.open_signup_domains))
    ) then
      raise exception 'This email domain is not enabled for BusIn' using errcode = '42501';
    end if;
    v_status := 'pending';
  end if;

  v_name := left(coalesce(
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    nullif(new.raw_user_meta_data ->> 'name', ''),
    split_part(new.email, '@', 1)
  ), 120);

  insert into public.profiles (id, school_id, email, full_name, avatar_url, status)
  values (
    new.id,
    v_school,
    lower(new.email),
    v_name,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'avatar_url', ''),
      nullif(new.raw_user_meta_data ->> 'picture', '')
    ),
    v_status
  );
  return new;
end;
$$;

-- The schools the caller may ask to join: active, accepting other emails, and accepting the caller's domain.
create function public.list_open_schools()
returns table (id uuid, name text, short_name text, city text, country text, logo_path text)
language sql stable security definer
set search_path = ''
as $$
  select s.id, s.name, s.short_name, s.city, s.country, s.logo_path
  from public.schools s
  join public.profiles p on p.id = (select auth.uid())
  where s.status = 'active' and s.accepts_open_signup
    and (cardinality(s.open_signup_domains) = 0 or private.email_domain(p.email) = any (s.open_signup_domains))
  order by s.name
  limit 200;
$$;

-- The caller's own request: the school asked (or the one that declined), when, and the reason given.
create function public.my_join_request()
returns table (school_id uuid, school_name text, school_logo_path text, requested_at timestamptz, declined_at timestamptz, declined_school_name text, decline_note text)
language sql stable security definer
set search_path = ''
as $$
  select p.school_id, s.name, s.logo_path, p.join_requested_at, p.join_declined_at, d.name, p.join_decline_note
  from public.profiles p
  left join public.schools s on s.id = p.school_id
  left join public.schools d on d.id = p.join_declined_school
  where p.id = (select auth.uid()) and p.status = 'pending';
$$;

-- Ask to join a school, change the request, or withdraw it (null). Only a pending student, only a school that accepts
-- the student's email, and not more than once every 30 seconds.
create function public.request_school(p_school_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_profile record;
begin
  select id, role, status, email, school_id, join_requested_at into v_profile
  from public.profiles where id = v_uid for update;
  if not found or v_profile.role <> 'student' or v_profile.status <> 'pending' then
    raise exception 'Only an account waiting for a school can ask to join one' using errcode = '42501';
  end if;
  if v_profile.join_requested_at is not null and v_profile.join_requested_at > now() - interval '30 seconds' then
    raise exception 'Too many requests' using errcode = '54000';
  end if;

  if p_school_id is null then
    update public.profiles set school_id = null, join_requested_at = null where id = v_uid;
    return;
  end if;
  if not private.school_accepts_domain(p_school_id, private.email_domain(v_profile.email)) then
    raise exception 'This school does not accept your email address' using errcode = '42501';
  end if;

  update public.profiles
  set school_id = p_school_id, join_requested_at = now(), join_declined_at = null, join_declined_school = null, join_decline_note = null
  where id = v_uid;
  perform private.write_audit(p_school_id, v_uid, 'member.join_requested', 'profile', v_uid, '{}'::jsonb);
end;
$$;

-- An admin lets a student who asked to join their school in.
create function public.admin_verify_member(p_user_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  update public.profiles set status = 'verified', join_decline_note = null
  where id = p_user_id and school_id = v_school and role = 'student' and status = 'pending';
  if not found then
    raise exception 'No request to verify' using errcode = 'P0002';
  end if;
  perform private.write_audit(v_school, v_actor, 'member.verified', 'profile', p_user_id, '{}'::jsonb);
end;
$$;

-- An admin declines a request, with an optional reason the student sees. The student can then ask another school.
create function public.admin_decline_member(p_user_id uuid, p_reason text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if v_reason is not null and char_length(v_reason) > 300 then
    raise exception 'The reason is 300 characters at most' using errcode = '22023';
  end if;
  update public.profiles
  set school_id = null, join_requested_at = null, join_declined_at = now(), join_declined_school = v_school, join_decline_note = v_reason
  where id = p_user_id and school_id = v_school and role = 'student' and status = 'pending';
  if not found then
    raise exception 'No request to decline' using errcode = 'P0002';
  end if;
  perform private.write_audit(v_school, v_actor, 'member.declined', 'profile', p_user_id, jsonb_build_object('reason', v_reason));
end;
$$;

revoke execute on function public.list_open_schools(), public.my_join_request(), public.request_school(uuid),
  public.admin_verify_member(uuid), public.admin_decline_member(uuid, text) from public, anon;
grant execute on function public.list_open_schools(), public.my_join_request(), public.request_school(uuid),
  public.admin_verify_member(uuid), public.admin_decline_member(uuid, text) to authenticated;
revoke execute on function private.school_accepts_domain(uuid, text) from public;
