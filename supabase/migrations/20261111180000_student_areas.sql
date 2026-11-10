-- My area (ADR 0013). A student may say roughly where they live, once, by an approximate phone reading or by picking a
-- searched place. The server snaps the point to a grid of about 500 m before storing it; the exact point is never kept.
-- The student reads, changes and deletes their own row. Administrators see only counts per grid cell, and only cells
-- with at least 5 students. Place search goes through the places-search Edge Function, which counts each student's
-- searches here (claim_place_search).

create table public.student_areas (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  school_id uuid not null references public.schools (id) on delete cascade,
  area extensions.geography(Point, 4326) not null,
  label text not null check (char_length(label) between 1 and 80),
  source text not null check (source in ('device', 'search')),
  updated_at timestamptz not null default now()
);
create index student_areas_school_idx on public.student_areas (school_id);

alter table public.student_areas enable row level security;
alter table public.student_areas force row level security;
revoke all on public.student_areas from public, anon, authenticated;
-- Reads go through my_area(); writes through set_my_area() and clear_my_area(). No direct access at all.

-- The centre of the ~500 m cell a point falls in. Rows of latitude are 0.0045 degrees (about 500 m); the width of a
-- cell in longitude grows with the latitude so cells stay about 500 m wide. The width is fixed per whole degree of
-- latitude, so the columns line up across rows.
create function private.snap_area(p_lat double precision, p_lng double precision)
returns extensions.geography
language sql immutable
set search_path = ''
as $$
  with lat as (select (floor(p_lat / 0.0045) + 0.5) * 0.0045 as c),
  step as (select lat.c, 0.0045 / greatest(cos(radians(round(p_lat))), 0.01) as s from lat)
  select extensions.st_setsrid(extensions.st_makepoint((floor(p_lng / step.s) + 0.5) * step.s, step.c), 4326)::extensions.geography
  from step;
$$;

create function public.set_my_area(p_lat double precision, p_lng double precision, p_label text, p_source text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_label text := btrim(coalesce(p_label, ''));
  v_area extensions.geography;
begin
  if v_school is null or private.my_role() <> 'student' then
    raise exception 'Only a verified student can set an area' using errcode = '42501';
  end if;
  if p_lat is null or p_lng is null or p_lat not between -85 and 85 or p_lng not between -180 and 180 then
    raise exception 'invalid_point' using errcode = '22023';
  end if;
  if char_length(v_label) not between 1 and 80 then
    raise exception 'invalid_label' using errcode = '22023';
  end if;
  if p_source is null or p_source not in ('device', 'search') then
    raise exception 'invalid_source' using errcode = '22023';
  end if;
  v_area := private.snap_area(p_lat, p_lng);
  -- An area must be within reach of the school's bus service (150 km of one of its stops), when it has stops.
  if exists (select 1 from public.stops s where s.school_id = v_school)
     and not exists (select 1 from public.stops s where s.school_id = v_school and extensions.st_dwithin(s.location, v_area, 150000)) then
    raise exception 'too_far' using errcode = '22023';
  end if;
  insert into public.student_areas (user_id, school_id, area, label, source, updated_at)
  values (v_uid, v_school, v_area, v_label, p_source, now())
  on conflict (user_id) do update
    set school_id = excluded.school_id, area = excluded.area, label = excluded.label, source = excluded.source, updated_at = now();
end;
$$;

create function public.my_area()
returns table (label text, lat double precision, lng double precision, source text, updated_at timestamptz)
language sql stable security definer
set search_path = ''
as $$
  select a.label, extensions.st_y(a.area::extensions.geometry), extensions.st_x(a.area::extensions.geometry), a.source, a.updated_at
  from public.student_areas a
  where a.user_id = (select auth.uid()) and a.school_id = private.my_school_id();
$$;

create function public.clear_my_area()
returns void
language sql security definer
set search_path = ''
as $$
  delete from public.student_areas where user_id = (select auth.uid());
$$;

-- For planning stops: how many of the school's students live in each cell, only cells with at least 5 of them.
create function public.admin_area_counts()
returns table (lat double precision, lng double precision, students int)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  return query
  select extensions.st_y(a.area::extensions.geometry), extensions.st_x(a.area::extensions.geometry), count(*)::int
  from public.student_areas a
  join public.profiles p on p.id = a.user_id and p.school_id = a.school_id and p.status = 'verified'
  where a.school_id = private.my_school_id()
  group by a.area::extensions.geometry
  having count(*) >= 5
  order by 3 desc;
end;
$$;

-- Place search quota, kept for a day.
create table private.place_search_usage (
  user_id uuid not null references public.profiles (id) on delete cascade,
  at timestamptz not null default now()
);
create index place_search_usage_user_idx on private.place_search_usage (user_id, at);
alter table private.place_search_usage enable row level security;
alter table private.place_search_usage force row level security;
revoke all on private.place_search_usage from public, anon, authenticated;

-- Called by the places-search function with the student's own token, before each search. Counts the search (20 a
-- minute, 200 a day; over that it answers 429) and returns where to bias the results: the middle and the extent of the
-- school's stops, widened by about 30 km. Null values when the school has no stops yet.
create function public.claim_place_search()
returns table (centre_lng double precision, centre_lat double precision, min_lng double precision, min_lat double precision, max_lng double precision, max_lat double precision)
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
begin
  if v_school is null or private.my_role() <> 'student' then
    raise exception 'Only a verified student can search places' using errcode = '42501';
  end if;
  delete from private.place_search_usage where user_id = v_uid and at < now() - interval '1 day';
  if (select count(*) from private.place_search_usage where user_id = v_uid and at > now() - interval '1 minute') >= 20
     or (select count(*) from private.place_search_usage where user_id = v_uid) >= 200 then
    raise exception 'too_many_searches' using errcode = 'PT429';
  end if;
  insert into private.place_search_usage (user_id) values (v_uid);
  return query
  select extensions.st_x(extensions.st_centroid(e)), extensions.st_y(extensions.st_centroid(e)),
    extensions.st_xmin(e) - 0.27, extensions.st_ymin(e) - 0.27, extensions.st_xmax(e) + 0.27, extensions.st_ymax(e) + 0.27
  from (select extensions.st_extent(s.location::extensions.geometry)::extensions.geometry as e from public.stops s where s.school_id = v_school) x;
end;
$$;

revoke execute on function private.snap_area(double precision, double precision) from public;
revoke execute on function public.set_my_area(double precision, double precision, text, text), public.my_area(), public.clear_my_area(),
  public.admin_area_counts(), public.claim_place_search() from public, anon;
grant execute on function public.set_my_area(double precision, double precision, text, text), public.my_area(), public.clear_my_area(),
  public.admin_area_counts(), public.claim_place_search() to authenticated;
