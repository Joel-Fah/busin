-- A school's profile: its logo and the details a student or a visitor may need, the school's acceptance of the BusIn
-- terms for schools, and whether it agrees to be shown publicly (its name and logo on the BusIn site's wall of schools).
-- `accepts_open_signup` is read by the sign-up flow in a later migration: whether students without the school's email
-- domain may ask to join it (and wait for an admin to verify them).
--
-- The new columns are written only through the functions below (no column grant), which validate every field and write
-- the audit log. Logos live in a public bucket, `school-logos/{school_id}/...`, written only by that school's admins.

alter table public.schools
  add column logo_path text check (logo_path is null or char_length(logo_path) <= 200),
  add column website text check (website is null or (char_length(website) <= 200 and website ~ '^https://[^\s]+$')),
  add column contact_email text check (contact_email is null or (char_length(contact_email) <= 254 and contact_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]{2,}$')),
  add column phone text check (phone is null or (char_length(phone) between 4 and 30 and phone ~ '^[0-9 +()./-]+$')),
  add column address text check (address is null or char_length(address) <= 200),
  add column city text check (city is null or char_length(city) <= 80),
  add column country text check (country is null or char_length(country) <= 80),
  add column about text check (about is null or char_length(about) <= 280),
  add column accepts_open_signup boolean not null default false,
  add column public_listing boolean not null default false,
  add column terms_version text check (terms_version is null or char_length(terms_version) between 1 and 20),
  add column terms_accepted_at timestamptz,
  -- No foreign key to profiles on purpose: a second link between schools and profiles would make the API's
  -- profiles -> schools lookups ambiguous. Who accepted is also in the audit log.
  add column terms_accepted_by uuid,
  -- Shown publicly only once the terms are accepted.
  add constraint schools_listing_needs_terms check (not public_listing or terms_accepted_at is not null);

-- Logos: public files (they are meant to be seen), written only by the school's admins, in the school's folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('school-logos', 'school-logos', true, 1048576, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy school_logos_select on storage.objects for select to authenticated
  using (
    bucket_id = 'school-logos'
    and (storage.foldername(name))[1] = (select private.my_school_id())::text
    and (select private.is_admin())
  );

create policy school_logos_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'school-logos'
    and (storage.foldername(name))[1] = (select private.my_school_id())::text
    and (select private.is_admin())
  );

create policy school_logos_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'school-logos'
    and (storage.foldername(name))[1] = (select private.my_school_id())::text
    and (select private.is_admin())
  );

-- The profile, as one save. Empty text means "not set". The listing switch needs the terms accepted first.
create function public.admin_update_school_profile(
  p_name text,
  p_short_name text,
  p_website text,
  p_contact_email text,
  p_phone text,
  p_address text,
  p_city text,
  p_country text,
  p_about text,
  p_accepts_open_signup boolean,
  p_public_listing boolean
)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_terms timestamptz;
  v_name text := btrim(coalesce(p_name, ''));
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if char_length(v_name) not between 2 and 120 then
    raise exception 'The school name must be 2 to 120 characters' using errcode = '22023';
  end if;

  select terms_accepted_at into v_terms from public.schools where id = v_school for update;
  if coalesce(p_public_listing, false) and v_terms is null then
    raise exception 'Accept the terms before the school is shown publicly' using errcode = '55000';
  end if;

  -- The table's checks validate the format of each field (23514 when one is wrong).
  update public.schools set
    name = v_name,
    short_name = nullif(btrim(coalesce(p_short_name, '')), ''),
    website = nullif(btrim(coalesce(p_website, '')), ''),
    contact_email = lower(nullif(btrim(coalesce(p_contact_email, '')), '')),
    phone = nullif(btrim(coalesce(p_phone, '')), ''),
    address = nullif(btrim(coalesce(p_address, '')), ''),
    city = nullif(btrim(coalesce(p_city, '')), ''),
    country = nullif(btrim(coalesce(p_country, '')), ''),
    about = nullif(btrim(coalesce(p_about, '')), ''),
    accepts_open_signup = coalesce(p_accepts_open_signup, false),
    public_listing = coalesce(p_public_listing, false)
  where id = v_school;

  perform private.write_audit(v_school, v_actor, 'school.profile_saved', 'school', v_school,
    jsonb_build_object('accepts_open_signup', coalesce(p_accepts_open_signup, false), 'public_listing', coalesce(p_public_listing, false)));
end;
$$;

-- The logo: a file the admin uploaded to the school's folder, or null to remove it.
create function public.admin_set_school_logo(p_path text)
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
  if p_path is not null then
    if split_part(p_path, '/', 1) <> v_school::text or p_path like '%..%' or char_length(p_path) > 200 then
      raise exception 'The logo must be in the school''s folder' using errcode = '22023';
    end if;
    if not exists (select 1 from storage.objects where bucket_id = 'school-logos' and name = p_path) then
      raise exception 'Logo file not found' using errcode = 'P0002';
    end if;
  end if;

  update public.schools set logo_path = p_path where id = v_school;
  perform private.write_audit(v_school, v_actor, 'school.logo_changed', 'school', v_school, jsonb_build_object('path', p_path));
end;
$$;

-- The school accepts the terms for schools (a version string, so a later version can be asked for again).
create function public.admin_accept_school_terms(p_version text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_version text := btrim(coalesce(p_version, ''));
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if char_length(v_version) not between 1 and 20 then
    raise exception 'A terms version is required' using errcode = '22023';
  end if;

  update public.schools
  set terms_version = v_version, terms_accepted_at = now(), terms_accepted_by = v_actor
  where id = v_school;
  perform private.write_audit(v_school, v_actor, 'school.terms_accepted', 'school', v_school, jsonb_build_object('version', v_version));
end;
$$;

-- The schools anyone may see: active, terms accepted, and agreed to be listed. Only what is meant to be public.
create function public.public_schools()
returns table (id uuid, name text, short_name text, city text, country text, logo_path text)
language sql stable security definer
set search_path = ''
as $$
  select s.id, s.name, s.short_name, s.city, s.country, s.logo_path
  from public.schools s
  where s.status = 'active' and s.public_listing and s.terms_accepted_at is not null
  order by s.terms_accepted_at
  limit 200;
$$;

revoke execute on function public.admin_update_school_profile(text, text, text, text, text, text, text, text, text, boolean, boolean) from public, anon;
revoke execute on function public.admin_set_school_logo(text) from public, anon;
revoke execute on function public.admin_accept_school_terms(text) from public, anon;
grant execute on function public.admin_update_school_profile(text, text, text, text, text, text, text, text, text, boolean, boolean) to authenticated;
grant execute on function public.admin_set_school_logo(text) to authenticated;
grant execute on function public.admin_accept_school_terms(text) to authenticated;
revoke execute on function public.public_schools() from public;
grant execute on function public.public_schools() to anon, authenticated;
