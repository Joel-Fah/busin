-- Adding staff by email (ADR 0015). An admin names an email and a role (staff or admin). Signing up with that email
-- joins the admin's school directly, verified, with that role, whatever the email domain. An account that already
-- exists gets the role at once when it belongs to the school, or has no school yet. The email Google returns is the
-- proof: the invite only ever matches the exact address.

create table public.staff_invites (
  email text primary key check (email = lower(email) and email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(email) <= 254),
  school_id uuid not null references public.schools (id) on delete cascade,
  role public.user_role not null check (role in ('staff', 'admin')),
  invited_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days'
);
create index staff_invites_school_idx on public.staff_invites (school_id, created_at desc);

alter table public.staff_invites enable row level security;
alter table public.staff_invites force row level security;
revoke all on public.staff_invites from public, anon, authenticated;
grant select (email, role, created_at, expires_at) on public.staff_invites to authenticated;
create policy staff_invites_admin_read on public.staff_invites for select to authenticated
  using (school_id = private.my_school_id() and private.is_admin());

-- Sign-up, as in ADR 0012, with one addition first: an open invite for the exact email joins its school, verified, with
-- the invited role, and is used up.
create or replace function private.handle_new_user() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_domain text;
  v_school uuid;
  v_name text;
  v_status public.account_status := 'verified';
  v_role public.user_role := 'student';
  v_invite public.staff_invites;
begin
  if coalesce(new.raw_app_meta_data ->> 'provider', '') <> 'google' then
    raise exception 'Only Google sign-in is allowed' using errcode = '42501';
  end if;
  if new.email is null or position('@' in new.email) = 0 then
    raise exception 'A valid email is required' using errcode = '42501';
  end if;

  select i.* into v_invite
  from public.staff_invites i
  join public.schools s on s.id = i.school_id and s.status = 'active'
  where i.email = lower(new.email) and i.expires_at > now();

  if v_invite.email is not null then
    v_school := v_invite.school_id;
    v_role := v_invite.role;
  else
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
  end if;

  v_name := left(coalesce(
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    nullif(new.raw_user_meta_data ->> 'name', ''),
    split_part(new.email, '@', 1)
  ), 120);

  insert into public.profiles (id, school_id, email, full_name, avatar_url, status, role)
  values (
    new.id,
    v_school,
    lower(new.email),
    v_name,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'avatar_url', ''),
      nullif(new.raw_user_meta_data ->> 'picture', '')
    ),
    v_status,
    v_role
  );

  if v_invite.email is not null then
    delete from public.staff_invites where email = v_invite.email;
    perform private.write_audit(v_school, new.id, 'invite.accepted', 'profile', new.id, jsonb_build_object('role', v_role));
  end if;
  return new;
end;
$$;

-- Invites someone by email as staff or admin of the caller's school. Returns 'applied' when the account already exists
-- and got the role now, 'invited' when the invite waits for the first sign-in (renewed for 30 days if one existed).
-- Errors: 22023 invalid_email or invalid_role; 42501 for the caller's own account; 55000 other_school when the
-- account or an open invite belongs to another school.
create function public.admin_invite_staff(p_email text, p_role public.user_role)
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
    update public.profiles
    set school_id = v_school, role = p_role, status = case when status = 'suspended' then status else 'verified' end,
        join_requested_at = null, join_declined_at = null, join_declined_school = null, join_decline_note = null
    where id = v_profile.id;
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

-- Withdraws an open invite of the caller's school. Nothing happens for an email the school did not invite.
create function public.admin_cancel_invite(p_email text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  delete from public.staff_invites where email = lower(trim(coalesce(p_email, ''))) and school_id = v_school;
  if found then
    perform private.write_audit(v_school, (select auth.uid()), 'invite.cancelled', 'school', v_school, '{}'::jsonb);
  end if;
end;
$$;

revoke execute on function public.admin_invite_staff(text, public.user_role), public.admin_cancel_invite(text) from public, anon;
grant execute on function public.admin_invite_staff(text, public.user_role), public.admin_cancel_invite(text) to authenticated;
