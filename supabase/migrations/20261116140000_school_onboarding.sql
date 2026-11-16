-- School onboarding from the platform console (ADR 0027, slice 4): create a school with its email domains, invite its
-- first administrator, and switch a school off or on. Everything else (logo, billing, stops, semesters) is then set up by
-- the school's own administrators in their portal, so a new school goes live by configuration only (phase 6).
--
-- Switched off, a school takes no new sign-ups, joins, invites or staff requests, is not listed on the landing page and
-- is not scored; the people already in keep their access (the rules that read schools.status already do this).

-- Creates a school. Refusals (22023 unless said): bad_name, bad_short_name, bad_timezone, bad_country, bad_city,
-- bad_domain, too_many_domains, name_taken (23505), domain_taken (23505, the domain in the hint).
create function public.platform_create_school(
  p_name text,
  p_short_name text default null,
  p_timezone text default null,
  p_country text default null,
  p_city text default null,
  p_domains text[] default '{}'
) returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_name text := btrim(coalesce(p_name, ''));
  v_short text := nullif(btrim(coalesce(p_short_name, '')), '');
  v_country text := nullif(btrim(coalesce(p_country, '')), '');
  v_city text := nullif(btrim(coalesce(p_city, '')), '');
  v_domains text[];
  v_taken text;
  v_id uuid;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  if char_length(v_name) not between 2 and 120 then
    raise exception 'bad_name' using errcode = '22023';
  end if;
  if v_short is not null and char_length(v_short) > 20 then
    raise exception 'bad_short_name' using errcode = '22023';
  end if;
  if p_timezone is null or not exists (select 1 from pg_catalog.pg_timezone_names where name = p_timezone) then
    raise exception 'bad_timezone' using errcode = '22023';
  end if;
  if v_country is not null and char_length(v_country) > 80 then
    raise exception 'bad_country' using errcode = '22023';
  end if;
  if v_city is not null and char_length(v_city) > 80 then
    raise exception 'bad_city' using errcode = '22023';
  end if;

  select coalesce(array_agg(distinct d order by d), '{}') into v_domains
  from (select lower(btrim(x)) as d from unnest(coalesce(p_domains, '{}')) x) t where d <> '';
  if cardinality(v_domains) > 10 then
    raise exception 'too_many_domains' using errcode = '22023';
  end if;
  if exists (select 1 from unnest(v_domains) d where d !~ '^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$' or char_length(d) > 253) then
    raise exception 'bad_domain' using errcode = '22023';
  end if;

  -- Creating the same school twice by accident is the likely mistake.
  if exists (select 1 from public.schools s where lower(s.name) = lower(v_name)) then
    raise exception 'name_taken' using errcode = '23505';
  end if;
  -- One domain belongs to one school (sign-up matches on it).
  select d.domain into v_taken from public.school_domains d where d.domain = any (v_domains) limit 1;
  if v_taken is not null then
    raise exception 'domain_taken' using errcode = '23505', hint = v_taken;
  end if;

  insert into public.schools (name, short_name, timezone, country, city)
  values (v_name, v_short, p_timezone, v_country, v_city)
  returning id into v_id;
  insert into public.school_domains (domain, school_id) select d, v_id from unnest(v_domains) d;
  perform private.write_platform_audit('school.created', v_id, 'school', v_id,
    jsonb_build_object('domains', to_jsonb(v_domains), 'timezone', p_timezone));
  return v_id;
end;
$$;

-- Invites someone as an administrator of a school, as a school admin invites staff (ADR 0015): 'applied' when the
-- account already exists (it becomes a verified admin now), 'invited' when the invite waits for the first sign-in
-- (renewed for 30 days). Refusals: 22023 invalid_email, P0002 no_school (unknown or switched off), 55000 other_school
-- (the account, or an open invite, belongs to another school).
create function public.platform_invite_school_admin(p_school_id uuid, p_email text)
returns text
language plpgsql security definer
set search_path = ''
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_profile public.profiles;
  v_other uuid;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.schools where id = p_school_id and status = 'active') then
    raise exception 'no_school' using errcode = 'P0002';
  end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' or char_length(v_email) > 254 then
    raise exception 'invalid_email' using errcode = '22023';
  end if;

  select * into v_profile from public.profiles where email = v_email for update;
  if found then
    if v_profile.school_id is not null and v_profile.school_id <> p_school_id then
      raise exception 'other_school' using errcode = '55000';
    end if;
    update public.profiles
    set school_id = p_school_id, role = 'admin', status = case when status = 'suspended' then status else 'verified' end,
        join_requested_at = null, join_declined_at = null, join_declined_school = null, join_decline_note = null,
        staff_requested_at = null, staff_request_school = null
    where id = v_profile.id;
    -- The school's own log says the platform did it, without naming who at the platform.
    perform private.write_audit(p_school_id, null, 'invite.applied', 'profile', v_profile.id,
      jsonb_build_object('from', v_profile.role, 'to', 'admin', 'by', 'platform'));
    perform private.write_platform_audit('school.admin_invited', p_school_id, 'profile', v_profile.id, jsonb_build_object('outcome', 'applied'));
    return 'applied';
  end if;

  select school_id into v_other from public.staff_invites where email = v_email and expires_at > now();
  if v_other is not null and v_other <> p_school_id then
    raise exception 'other_school' using errcode = '55000';
  end if;
  insert into public.staff_invites (email, school_id, role, invited_by)
  values (v_email, p_school_id, 'admin', null)
  on conflict (email) do update
    set school_id = excluded.school_id, role = excluded.role, invited_by = null,
        created_at = now(), expires_at = now() + interval '30 days';
  perform private.write_audit(p_school_id, null, 'invite.created', 'school', p_school_id, jsonb_build_object('role', 'admin', 'by', 'platform'));
  perform private.write_platform_audit('school.admin_invited', p_school_id, 'school', p_school_id, jsonb_build_object('outcome', 'invited'));
  return 'invited';
end;
$$;

-- The open administrator invites of a school (the people asked to run it), for its console page.
create function public.platform_school_invites(p_school_id uuid)
returns table (email text, role public.user_role, created_at timestamptz, expires_at timestamptz)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  return query
  select i.email, i.role, i.created_at, i.expires_at from public.staff_invites i
  where i.school_id = p_school_id and i.role = 'admin' and i.expires_at > now()
  order by i.created_at desc
  limit 20;
end;
$$;

-- Switches a school off (no new sign-ups, joins, invites or staff requests; not listed; not scored) or back on.
create function public.platform_set_school_status(p_school_id uuid, p_active boolean)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_status text := case when p_active then 'active' else 'inactive' end;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  if p_active is null then
    raise exception 'bad_status' using errcode = '22023';
  end if;
  update public.schools set status = v_status where id = p_school_id and status <> v_status;
  if not found then
    if not exists (select 1 from public.schools where id = p_school_id) then
      raise exception 'no_school' using errcode = 'P0002';
    end if;
    return;
  end if;
  perform private.write_platform_audit(case when p_active then 'school.switched_on' else 'school.switched_off' end, p_school_id, 'school', p_school_id, '{}'::jsonb);
end;
$$;

revoke execute on function public.platform_create_school(text, text, text, text, text, text[]),
  public.platform_invite_school_admin(uuid, text), public.platform_school_invites(uuid),
  public.platform_set_school_status(uuid, boolean) from public, anon;
grant execute on function public.platform_create_school(text, text, text, text, text, text[]),
  public.platform_invite_school_admin(uuid, text), public.platform_school_invites(uuid),
  public.platform_set_school_status(uuid, boolean) to authenticated;
