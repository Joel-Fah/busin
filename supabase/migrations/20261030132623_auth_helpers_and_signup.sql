-- Access helpers, the sign-up domain check and the access token hook.
--
-- RLS reads the caller's school and role live from public.profiles instead of
-- trusting JWT claims, so a suspension or demotion applies immediately rather
-- than when the token next refreshes. The hook still adds the same values to
-- the token so clients can route screens without an extra request.

-- The caller's school, or null when the caller is not signed in or not verified.
create function private.my_school_id() returns uuid
language sql stable security definer
set search_path = ''
as $$
  select p.school_id
  from public.profiles p
  where p.id = (select auth.uid()) and p.status = 'verified'
$$;

-- The caller's role, or null when the caller is not signed in or not verified.
create function private.my_role() returns public.user_role
language sql stable security definer
set search_path = ''
as $$
  select p.role
  from public.profiles p
  where p.id = (select auth.uid()) and p.status = 'verified'
$$;

create function private.is_admin() returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce(private.my_role() = 'admin', false)
$$;

create function private.is_staff() returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce(private.my_role() in ('staff', 'admin'), false)
$$;

grant execute on function
  private.my_school_id(), private.my_role(), private.is_admin(), private.is_staff()
  to authenticated;

-- Sign-up: Google only, email domain must belong to an active school, and the
-- new account is always a verified student. Roles are never chosen by the client.
create function private.handle_new_user() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_domain text;
  v_school uuid;
  v_name text;
begin
  if coalesce(new.raw_app_meta_data ->> 'provider', '') <> 'google' then
    raise exception 'Only Google sign-in is allowed' using errcode = '42501';
  end if;
  if new.email is null or position('@' in new.email) = 0 then
    raise exception 'A valid email is required' using errcode = '42501';
  end if;

  v_domain := lower(split_part(new.email, '@', 2));
  select d.school_id into v_school
  from public.school_domains d
  join public.schools s on s.id = d.school_id
  where d.domain = v_domain and s.status = 'active';

  if v_school is null then
    raise exception 'This email domain is not enabled for BusIn' using errcode = '42501';
  end if;

  v_name := left(coalesce(
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    nullif(new.raw_user_meta_data ->> 'name', ''),
    split_part(new.email, '@', 1)
  ), 120);

  insert into public.profiles (id, school_id, email, full_name, avatar_url)
  values (
    new.id,
    v_school,
    lower(new.email),
    v_name,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'avatar_url', ''),
      nullif(new.raw_user_meta_data ->> 'picture', '')
    )
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- Access token hook: copies school, role and status into app_metadata of the token.
create function public.custom_access_token_hook(event jsonb) returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_claims jsonb := event -> 'claims';
  v_profile record;
begin
  select p.school_id, p.role, p.status into v_profile
  from public.profiles p
  where p.id = (event ->> 'user_id')::uuid;

  if found then
    v_claims := jsonb_set(
      v_claims,
      '{app_metadata}',
      coalesce(v_claims -> 'app_metadata', '{}'::jsonb) || jsonb_build_object(
        'school_id', v_profile.school_id,
        'role', v_profile.role,
        'status', v_profile.status
      )
    );
  end if;

  return jsonb_set(event, '{claims}', v_claims);
end;
$$;

revoke execute on function public.custom_access_token_hook(jsonb)
  from public, anon, authenticated;
grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
