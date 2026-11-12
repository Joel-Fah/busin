-- The bus route (ADR 0017): a campus point per school, and a route of stops in order from the first pickup to the
-- campus. One route per school for now (the tables allow more later). The road geometry and each leg's distance and
-- time come from the route-directions Edge Function (Mapbox Directions, server token) and are stored here with a hash of
-- what they were drawn for; a new order or a moved stop or campus makes them out of date.

alter table public.schools
  add column campus_location extensions.geography(Point, 4326),
  add column campus_name text check (campus_name is null or char_length(campus_name) between 1 and 80);

create table public.routes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  name text not null default 'Main route' check (char_length(name) between 1 and 60),
  geometry extensions.geography(LineString, 4326),
  distance_m int check (distance_m is null or distance_m >= 0),
  duration_s int check (duration_s is null or duration_s >= 0),
  legs jsonb,
  computed_at timestamptz,
  drawn_hash text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, school_id)
);
create index routes_school_idx on public.routes (school_id, created_at);

create table public.route_stops (
  route_id uuid not null,
  stop_id uuid not null,
  school_id uuid not null,
  position int not null check (position >= 0),
  primary key (route_id, stop_id),
  unique (route_id, position),
  foreign key (route_id, school_id) references public.routes (id, school_id) on delete cascade,
  foreign key (stop_id, school_id) references public.stops (id, school_id) on delete cascade
);

alter table public.routes enable row level security;
alter table public.routes force row level security;
alter table public.route_stops enable row level security;
alter table public.route_stops force row level security;
revoke all on public.routes, public.route_stops from public, anon, authenticated;
-- Anyone verified at the school may read its route (the student app will show it); only functions write.
grant select (id, school_id, name, distance_m, duration_s, legs, computed_at, drawn_hash, created_at, updated_at) on public.routes to authenticated;
grant select on public.route_stops to authenticated;
create policy routes_read on public.routes for select to authenticated using (school_id = private.my_school_id());
create policy route_stops_read on public.route_stops for select to authenticated using (school_id = private.my_school_id());

-- The school's route (its first one), or null.
create function private.school_route(p_school uuid) returns uuid
language sql stable security definer
set search_path = ''
as $$ select id from public.routes where school_id = p_school order by created_at, id limit 1; $$;
revoke execute on function private.school_route(uuid) from public;

-- What a route was drawn for: its stops in order with their places, and the campus. A different value means redraw.
create function private.route_hash(p_route uuid) returns text
language sql stable security definer
set search_path = ''
as $$
  select md5(coalesce(string_agg(s.id::text || '@' || extensions.st_astext(s.location::extensions.geometry), ',' order by rs.position), '')
    || '>' || coalesce(extensions.st_astext(sc.campus_location::extensions.geometry), ''))
  from public.routes r
  join public.schools sc on sc.id = r.school_id
  left join public.route_stops rs on rs.route_id = r.id
  left join public.stops s on s.id = rs.stop_id
  where r.id = p_route
  group by sc.campus_location;
$$;
revoke execute on function private.route_hash(uuid) from public;

-- The campus: where every route ends. Errors: 22023 invalid_point or invalid_name.
create function public.admin_set_campus(p_lat double precision, p_lng double precision, p_name text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_name text := btrim(coalesce(p_name, ''));
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  if p_lat is null or p_lng is null or p_lat not between -85 and 85 or p_lng not between -180 and 180 then
    raise exception 'invalid_point' using errcode = '22023';
  end if;
  if char_length(v_name) not between 1 and 80 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  update public.schools
  set campus_location = extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography, campus_name = v_name
  where id = v_school;
  perform private.write_audit(v_school, (select auth.uid()), 'route.campus_set', 'school', v_school, '{}'::jsonb);
end;
$$;

-- Checks a list of stops for a route: one or more, no repeats, all active stops of the caller's school.
create function private.check_route_stops(p_school uuid, p_stop_ids uuid[]) returns void
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if p_stop_ids is null or cardinality(p_stop_ids) = 0 then
    raise exception 'empty_route' using errcode = '22023';
  end if;
  if cardinality(p_stop_ids) > 200 then
    raise exception 'too_many_stops' using errcode = '22023';
  end if;
  if (select count(distinct x) from unnest(p_stop_ids) x) <> cardinality(p_stop_ids) then
    raise exception 'repeated_stop' using errcode = '22023';
  end if;
  if (select count(*) from public.stops s where s.id = any (p_stop_ids) and s.school_id = p_school and s.active) <> cardinality(p_stop_ids) then
    raise exception 'unknown_stop' using errcode = '22023';
  end if;
end;
$$;
revoke execute on function private.check_route_stops(uuid, uuid[]) from public;

-- Saves the order of the school's route (made the first time). A new order makes the drawn road out of date.
create function public.admin_save_route(p_stop_ids uuid[])
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_route uuid;
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  perform private.check_route_stops(v_school, p_stop_ids);
  v_route := private.school_route(v_school);
  if v_route is null then
    insert into public.routes (school_id) values (v_school) returning id into v_route;
  end if;
  delete from public.route_stops where route_id = v_route;
  insert into public.route_stops (route_id, stop_id, school_id, position)
  select v_route, x.id, v_school, x.n - 1 from unnest(p_stop_ids) with ordinality as x(id, n);
  update public.routes set updated_at = now() where id = v_route;
  perform private.write_audit(v_school, (select auth.uid()), 'route.saved', 'route', v_route, jsonb_build_object('stops', cardinality(p_stop_ids)));
  return v_route;
end;
$$;

-- Road-routing quota per school, kept for a day.
create table private.route_directions_usage (
  school_id uuid not null references public.schools (id) on delete cascade,
  at timestamptz not null default now()
);
create index route_directions_usage_idx on private.route_directions_usage (school_id, at);
alter table private.route_directions_usage enable row level security;
alter table private.route_directions_usage force row level security;
revoke all on private.route_directions_usage from public, anon, authenticated;

-- Called by the route-directions function with the admin's own token, before each call to the routing service. Counts
-- it (30 an hour, 300 a day per school; over that it answers PT429) and returns the waypoints in order: the saved
-- route's stops, or the given list (a preview, for a suggested route), then the campus; with the hash of the saved
-- route. A preview may include points that are not stops (a suggested new stop) as p_extra, inserted after the stop at
-- p_extra_after (-1 for the very start).
create function public.route_waypoints(
  p_stop_ids uuid[] default null,
  p_extra_lat double precision default null,
  p_extra_lng double precision default null,
  p_extra_name text default null,
  p_extra_after int default null
)
returns table (seq int, kind text, id uuid, name text, lat double precision, lng double precision, route_hash text)
language plpgsql security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_route uuid;
  v_ids uuid[];
  v_campus extensions.geography;
  v_campus_name text;
  v_hash text;
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  if (select count(*) from private.route_directions_usage u where u.school_id = v_school and u.at > now() - interval '1 hour') >= 30
     or (select count(*) from private.route_directions_usage u where u.school_id = v_school and u.at > now() - interval '1 day') >= 300 then
    raise exception 'Too many route requests' using errcode = 'PT429';
  end if;
  select sc.campus_location, sc.campus_name into v_campus, v_campus_name from public.schools sc where sc.id = v_school;
  if v_campus is null then
    raise exception 'no_campus' using errcode = '22023';
  end if;
  v_route := private.school_route(v_school);
  if p_stop_ids is null then
    if v_route is null then
      raise exception 'no_route' using errcode = '22023';
    end if;
    select array_agg(rs.stop_id order by rs.position) into v_ids from public.route_stops rs where rs.route_id = v_route;
    if v_ids is null then
      raise exception 'no_route' using errcode = '22023';
    end if;
  else
    perform private.check_route_stops(v_school, p_stop_ids);
    v_ids := p_stop_ids;
  end if;
  if p_extra_lat is not null and (p_extra_lat not between -85 and 85 or p_extra_lng is null or p_extra_lng not between -180 and 180) then
    raise exception 'invalid_point' using errcode = '22023';
  end if;
  v_hash := case when v_route is null then null else private.route_hash(v_route) end;

  delete from private.route_directions_usage where school_id = v_school and at < now() - interval '1 day';
  insert into private.route_directions_usage (school_id) values (v_school);

  return query
  with stops as (
    select x.n::int as n, s.id, s.name, s.location
    from unnest(v_ids) with ordinality as x(id, n)
    join public.stops s on s.id = x.id
  ),
  points as (
    select (st.n * 2)::int as ord, 'stop'::text as kind, st.id, st.name,
      extensions.st_y(st.location::extensions.geometry) as lat, extensions.st_x(st.location::extensions.geometry) as lng
    from stops st
    union all
    select (coalesce(p_extra_after, -1) + 1) * 2 + 1, 'extra', null, left(coalesce(nullif(btrim(p_extra_name), ''), 'Suggested stop'), 120), p_extra_lat, p_extra_lng
    where p_extra_lat is not null
    union all
    select 1000000, 'campus', null, coalesce(v_campus_name, 'Campus'),
      extensions.st_y(v_campus::extensions.geometry), extensions.st_x(v_campus::extensions.geometry)
  )
  select (row_number() over (order by p.ord))::int, p.kind, p.id, p.name, p.lat, p.lng, v_hash
  from points p
  order by p.ord;
end;
$$;

-- Stores the road the function drew, only if the route still is what it was drawn for. Service role only (the function
-- writes it, never a browser). Returns whether it was stored.
create function public.service_store_route(
  p_school uuid,
  p_hash text,
  p_geojson text,
  p_distance_m int,
  p_duration_s int,
  p_legs jsonb
)
returns boolean
language plpgsql security definer
set search_path = ''
as $$
declare
  v_route uuid := private.school_route(p_school);
begin
  if v_route is null or private.route_hash(v_route) is distinct from p_hash then
    return false;
  end if;
  update public.routes
  set geometry = extensions.st_geomfromgeojson(p_geojson)::extensions.geography,
      distance_m = p_distance_m, duration_s = p_duration_s, legs = p_legs, computed_at = now(), drawn_hash = p_hash
  where id = v_route;
  return true;
end;
$$;

-- The school's route for the portal and apps: the stops in order with their places, whether the drawn road is current,
-- the road as GeoJSON, totals and legs. Anyone verified at the school.
create function public.school_route()
returns table (
  route_id uuid,
  name text,
  stops jsonb,
  campus_name text,
  campus_lat double precision,
  campus_lng double precision,
  geometry jsonb,
  distance_m int,
  duration_s int,
  legs jsonb,
  computed_at timestamptz,
  current boolean
)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_route uuid;
begin
  if v_school is null then
    raise exception 'Not a member of a school' using errcode = '42501';
  end if;
  v_route := private.school_route(v_school);
  return query
  select v_route, r.name,
    coalesce((
      select jsonb_agg(jsonb_build_object('id', s.id, 'name', s.name, 'lat', extensions.st_y(s.location::extensions.geometry),
        'lng', extensions.st_x(s.location::extensions.geometry), 'active', s.active) order by rs.position)
      from public.route_stops rs join public.stops s on s.id = rs.stop_id where rs.route_id = v_route
    ), '[]'::jsonb),
    sc.campus_name, extensions.st_y(sc.campus_location::extensions.geometry), extensions.st_x(sc.campus_location::extensions.geometry),
    case when r.geometry is null then null else extensions.st_asgeojson(r.geometry::extensions.geometry)::jsonb end,
    r.distance_m, r.duration_s, r.legs, r.computed_at,
    r.drawn_hash is not null and r.drawn_hash = private.route_hash(v_route)
  from public.schools sc
  left join public.routes r on r.id = v_route
  where sc.id = v_school;
end;
$$;

revoke execute on function public.admin_set_campus(double precision, double precision, text), public.admin_save_route(uuid[]),
  public.route_waypoints(uuid[], double precision, double precision, text, int), public.school_route(),
  public.service_store_route(uuid, text, text, int, int, jsonb) from public, anon;
grant execute on function public.admin_set_campus(double precision, double precision, text), public.admin_save_route(uuid[]),
  public.route_waypoints(uuid[], double precision, double precision, text, int), public.school_route() to authenticated;
revoke execute on function public.service_store_route(uuid, text, text, int, int, jsonb) from authenticated;
grant execute on function public.service_store_route(uuid, text, text, int, int, jsonb) to service_role;
