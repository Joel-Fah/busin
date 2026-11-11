-- Place search for My area from our own copy of OpenStreetMap (ADR 0013, revised): the named places around each
-- school's stops (neighbourhoods, villages, streets, landmarks) are imported by tools/import-places.mjs and searched
-- here. Nothing leaves our server at search time. The data is (c) OpenStreetMap contributors, under the ODbL; the app
-- credits it where results are shown.
-- Replaces the Mapbox search: claim_place_search goes (the places-search Edge Function is removed).

create extension if not exists pg_trgm with schema extensions;
create extension if not exists unaccent with schema extensions;

-- The form names are compared in: lower case, no accents, hyphens and apostrophes as spaces, single spaces.
create function private.place_key(p_text text) returns text
language sql immutable parallel safe
set search_path = ''
as $$
  select btrim(regexp_replace(lower(extensions.unaccent('extensions.unaccent'::regdictionary, coalesce(p_text, ''))), '[\s''’-]+', ' ', 'g'));
$$;

create table public.places (
  id bigint generated always as identity primary key,
  school_id uuid not null references public.schools (id) on delete cascade,
  osm_id text not null check (char_length(osm_id) <= 40),
  name text not null check (char_length(name) between 1 and 120),
  kind text not null check (kind in ('area', 'village', 'street', 'landmark')),
  location extensions.geography(Point, 4326) not null,
  search_key text not null,
  unique (school_id, osm_id)
);
create index places_school_idx on public.places (school_id);
create index places_search_idx on public.places using gin (search_key extensions.gin_trgm_ops);

alter table public.places enable row level security;
alter table public.places force row level security;
revoke all on public.places from public, anon, authenticated;
-- Read through search_places() only; written by import_places() only.

-- Replaces a school's places with a fresh import. Called by the import script with the service role, never by apps.
create function public.import_places(p_school_id uuid, p_places jsonb)
returns int
language plpgsql security definer
set search_path = ''
as $$
declare
  v_count int;
begin
  if not exists (select 1 from public.schools where id = p_school_id) then
    raise exception 'unknown school' using errcode = 'P0002';
  end if;
  if jsonb_typeof(p_places) <> 'array' or jsonb_array_length(p_places) > 50000 then
    raise exception 'places must be an array of at most 50000' using errcode = '22023';
  end if;
  delete from public.places where school_id = p_school_id;
  insert into public.places (school_id, osm_id, name, kind, location, search_key)
  select p_school_id, left(e->>'osm_id', 40), left(btrim(e->>'name'), 120), e->>'kind',
    extensions.st_setsrid(extensions.st_makepoint((e->>'lng')::double precision, (e->>'lat')::double precision), 4326)::extensions.geography,
    private.place_key(e->>'name')
  from jsonb_array_elements(p_places) e
  where e->>'kind' in ('area', 'village', 'street', 'landmark')
    and coalesce(btrim(e->>'name'), '') <> ''
    and (e->>'lat')::double precision between -85 and 85
    and (e->>'lng')::double precision between -180 and 180
  on conflict (school_id, osm_id) do nothing;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.import_places(uuid, jsonb) from public, anon, authenticated;
grant execute on function public.import_places(uuid, jsonb) to service_role;

-- Places of the caller's school matching the text: names that start with it first, then the closest matches, areas
-- before streets and landmarks, then the nearest to the school's stops. Verified students and admins of the school.
-- Counted against the same quota as before (60 a minute, 600 a day), since a search runs on every few keystrokes.
create function public.search_places(p_query text, p_limit int default 8)
returns table (label text, kind text, lat double precision, lng double precision)
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_key text := private.place_key(p_query);
  v_limit int := least(greatest(coalesce(p_limit, 8), 1), 20);
  v_centre extensions.geography;
begin
  if v_school is null or private.my_role() not in ('student', 'admin') then
    raise exception 'Only a verified member can search places' using errcode = '42501';
  end if;
  if char_length(v_key) < 2 or char_length(v_key) > 80 then
    return;
  end if;
  delete from private.place_search_usage where user_id = v_uid and at < now() - interval '1 day';
  if (select count(*) from private.place_search_usage where user_id = v_uid and at > now() - interval '1 minute') >= 60
     or (select count(*) from private.place_search_usage where user_id = v_uid) >= 600 then
    raise exception 'too_many_searches' using errcode = 'PT429';
  end if;
  insert into private.place_search_usage (user_id) values (v_uid);

  select extensions.st_centroid(extensions.st_collect(s.location::extensions.geometry))::extensions.geography into v_centre
  from public.stops s where s.school_id = v_school;

  -- A place mapped twice (a point and a building) shows once: one row per name and kind, the nearest to the school.
  -- Two places of different kinds may share a name (the Mendong neighbourhood and the Mendong village); both stay.
  return query
  select m.name, m.kind, extensions.st_y(m.location::extensions.geometry), extensions.st_x(m.location::extensions.geometry)
  from (
    select p.name, p.kind, p.location,
      (p.search_key like v_key || '%') as starts,
      extensions.word_similarity(v_key, p.search_key) as likeness,
      case when v_centre is null then 0 else extensions.st_distance(p.location, v_centre) end as distance,
      row_number() over (
        partition by p.search_key, p.kind
        order by case when v_centre is null then 0 else extensions.st_distance(p.location, v_centre) end
      ) as nth
    from public.places p
    where p.school_id = v_school
      and (p.search_key like v_key || '%' or p.search_key like '% ' || v_key || '%' or extensions.word_similarity(v_key, p.search_key) >= 0.5)
  ) m
  where m.nth = 1
  order by m.starts desc, m.likeness desc, case m.kind when 'area' then 0 when 'village' then 1 when 'street' then 2 else 3 end, m.distance
  limit v_limit;
end;
$$;

revoke execute on function public.search_places(text, int) from public, anon;
grant execute on function public.search_places(text, int) to authenticated;

drop function public.claim_place_search();

-- The box the import covers: the school's stops, widened by about 30 km (0.27 degrees). Null when it has no stops.
create function public.place_import_box(p_school_id uuid)
returns table (south double precision, west double precision, north double precision, east double precision)
language sql stable security definer
set search_path = ''
as $$
  select extensions.st_ymin(e) - 0.27, extensions.st_xmin(e) - 0.27, extensions.st_ymax(e) + 0.27, extensions.st_xmax(e) + 0.27
  from (select extensions.st_extent(s.location::extensions.geometry)::extensions.geometry as e from public.stops s where s.school_id = p_school_id) x
  where e is not null;
$$;

revoke execute on function public.place_import_box(uuid) from public, anon, authenticated;
grant execute on function public.place_import_box(uuid) to service_role;
