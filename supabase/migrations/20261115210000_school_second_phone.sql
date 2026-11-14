-- A school can give a second phone number (optional), for example the office and the transport desk. Stored as E.164
-- like the first (ADR 0024); members of the school read it with the rest of the school's row.
alter table public.schools add column phone_secondary text
  constraint schools_phone_secondary_check check (phone_secondary is null or phone_secondary ~ '^\+[1-9][0-9]{6,14}$');

drop function public.admin_update_school_profile(text, text, text, text, text, text, text, text, text, boolean, boolean, text[]);

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
  p_public_listing boolean,
  p_open_signup_domains text[] default '{}',
  p_phone_secondary text default null
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
  v_domains text[];
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if char_length(v_name) not between 2 and 120 then
    raise exception 'The school name must be 2 to 120 characters' using errcode = '22023';
  end if;

  -- Tidy the domains (lowercase, no leading @, no duplicates, in the order given) and check each one.
  select coalesce(array_agg(d order by first_seen), '{}') into v_domains
  from (
    select d, min(ord) as first_seen
    from unnest(coalesce(p_open_signup_domains, '{}')) with ordinality as t(raw, ord),
         lateral (select lower(ltrim(btrim(raw), '@')) as d) x
    where d <> ''
    group by d
  ) cleaned;
  if cardinality(v_domains) > 20 then
    raise exception 'At most 20 domains' using errcode = '22023';
  end if;
  if exists (select 1 from unnest(v_domains) d where not private.is_valid_domain(d)) then
    raise exception 'Invalid domain' using errcode = '22023';
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
    phone_secondary = nullif(btrim(coalesce(p_phone_secondary, '')), ''),
    address = nullif(btrim(coalesce(p_address, '')), ''),
    city = nullif(btrim(coalesce(p_city, '')), ''),
    country = nullif(btrim(coalesce(p_country, '')), ''),
    about = nullif(btrim(coalesce(p_about, '')), ''),
    accepts_open_signup = coalesce(p_accepts_open_signup, false),
    open_signup_domains = v_domains,
    public_listing = coalesce(p_public_listing, false)
  where id = v_school;

  perform private.write_audit(v_school, v_actor, 'school.profile_saved', 'school', v_school,
    jsonb_build_object('accepts_open_signup', coalesce(p_accepts_open_signup, false), 'open_signup_domains', to_jsonb(v_domains),
      'public_listing', coalesce(p_public_listing, false)));
end;
$$;

revoke execute on function public.admin_update_school_profile(text, text, text, text, text, text, text, text, text, boolean, boolean, text[], text) from public, anon;
grant execute on function public.admin_update_school_profile(text, text, text, text, text, text, text, text, text, boolean, boolean, text[], text) to authenticated;
