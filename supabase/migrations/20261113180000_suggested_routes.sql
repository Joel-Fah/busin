-- Suggested routes (ADR 0017, slice 4). Each suggested new stop says where it fits in the school's route: after which
-- stop (-1: before the first) the bus would make the smallest detour, by straight lines through the stops and on to the
-- campus. And a route preview may take several suggested stops at once (to draw a route with every suggestion).

-- Where a point fits in the school's route with the least detour: the position of the stop it would follow (-1 before
-- the first; the last stop's position means between it and the campus). Null without a route.
create function private.route_insert_after(p_school uuid, p_point extensions.geography) returns int
language sql stable security definer
set search_path = ''
as $$
  with pts as (
    select rs.position as pos, s.location as g
    from public.route_stops rs join public.stops s on s.id = rs.stop_id
    where rs.route_id = private.school_route(p_school)
    union all
    select (select count(*)::int from public.route_stops rs where rs.route_id = private.school_route(p_school)), sc.campus_location
    from public.schools sc where sc.id = p_school and sc.campus_location is not null
  ),
  options as (
    select -1 as pos, extensions.st_distance(p_point, g) as cost from pts where pos = 0
    union all
    select a.pos, extensions.st_distance(a.g, p_point) + extensions.st_distance(p_point, b.g) - extensions.st_distance(a.g, b.g)
    from pts a join pts b on b.pos = a.pos + 1
  )
  select pos from options order by cost, pos limit 1;
$$;
revoke execute on function private.route_insert_after(uuid, extensions.geography) from public;

drop function public.admin_stop_suggestions();

create function public.admin_stop_suggestions()
returns table (
  kind text,
  stop_id uuid,
  other_stop_id uuid,
  place_name text,
  lat double precision,
  lng double precision,
  students int,
  metres int,
  insert_after int
)
language plpgsql stable security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_school uuid := private.my_school_id();
  v_covered uuid[] := '{}';
  v_pick record;
  v_zone text;
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;

  -- New stops, greedily.
  for i in 1..3 loop
    with far as (
      -- The exact nearest distance (a school has tens of stops; the index's ordering is only approximate on geography).
      select sub.student_id, sub.area, n.m as nearest_m
      from private.stop_subscribers(v_school) sub
      cross join lateral (
        select min(extensions.st_distance(sub.area, s.location)) as m
        from public.stops s
        where s.school_id = v_school and s.active
      ) n
      where sub.area is not null and n.m > 500 and not (sub.student_id = any (v_covered))
    )
    select p.id, p.name, p.location, count(*)::int as n, round(percentile_cont(0.5) within group (order by far.nearest_m))::int as walk,
           array_agg(far.student_id) as who
    into v_pick
    from public.places p
    join far on extensions.st_dwithin(p.location, far.area, 500)
    where p.school_id = v_school and p.kind in ('landmark', 'street')
      and not exists (
        select 1 from public.stops s
        where s.school_id = v_school and s.active and extensions.st_dwithin(s.location, p.location, 300)
      )
    group by p.id, p.name, p.location, p.kind
    having count(*) >= 5
    order by count(*) desc, (p.kind = 'landmark') desc, p.id
    limit 1;
    exit when v_pick is null or v_pick.id is null;

    kind := 'new_stop';
    stop_id := null;
    other_stop_id := null;
    place_name := v_pick.name;
    lat := extensions.st_y(v_pick.location::extensions.geometry);
    lng := extensions.st_x(v_pick.location::extensions.geometry);
    students := v_pick.n;
    metres := v_pick.walk;
    insert_after := private.route_insert_after(v_school, v_pick.location);
    return next;
    v_covered := v_covered || v_pick.who;
    v_pick := null;
  end loop;

  -- Stops very close together.
  return query
  select 'close_pair', a.id, b.id, null::text, null::double precision, null::double precision,
    ((select count(*) from private.stop_subscribers(v_school) x where x.stop_id in (a.id, b.id)))::int,
    round(extensions.st_distance(a.location, b.location))::int, null::int
  from public.stops a
  join public.stops b on b.school_id = a.school_id and b.active and a.id < b.id and extensions.st_dwithin(a.location, b.location, 400)
  where a.school_id = v_school and a.active
  order by 8
  limit 10;

  -- Stops nobody boarded at for 6 weeks, when the school did have boardings then.
  select sc.timezone into v_zone from public.schools sc where sc.id = v_school;
  if exists (
    select 1 from private.stop_trip_loads l
    where l.school_id = v_school and l.day > (now() at time zone v_zone)::date - 42
  ) then
    return query
    select 'unused', s.id, null::uuid, null::text, null::double precision, null::double precision,
      ((select count(*) from private.stop_subscribers(v_school) x where x.stop_id = s.id))::int, 42, null::int
    from public.stops s
    where s.school_id = v_school and s.active
      and not exists (
        select 1 from private.stop_trip_loads l
        where l.stop_id = s.id and l.day > (now() at time zone v_zone)::date - 42
      )
    order by s.name
    limit 20;
  end if;
end;
$$;

revoke execute on function public.admin_stop_suggestions() from public, anon;
grant execute on function public.admin_stop_suggestions() to authenticated;

-- Previews with several suggested stops: each extra point goes after the stop at its position (-1 before the first);
-- several after the same stop go in order of distance from it.
drop function public.route_waypoints(uuid[], double precision, double precision, text, int);
create function public.route_waypoints(
  p_stop_ids uuid[] default null,
  p_extra_lats double precision[] default null,
  p_extra_lngs double precision[] default null,
  p_extra_names text[] default null,
  p_extra_afters int[] default null
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
  if coalesce(cardinality(p_extra_lats), 0) > 10
     or coalesce(cardinality(p_extra_lats), 0) <> coalesce(cardinality(p_extra_lngs), 0)
     or coalesce(cardinality(p_extra_lats), 0) <> coalesce(cardinality(p_extra_afters), 0)
     or exists (select 1 from unnest(p_extra_lats, p_extra_lngs) as e(la, lo) where la is null or lo is null or la not between -85 and 85 or lo not between -180 and 180) then
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
    select (st.n * 2)::numeric as ord, 'stop'::text as kind, st.id, st.name,
      extensions.st_y(st.location::extensions.geometry) as lat, extensions.st_x(st.location::extensions.geometry) as lng
    from stops st
    union all
    -- After the stop at its position; several after the same one in order of distance from that stop (or from the first
    -- stop when before it).
    select (greatest(coalesce(e.af, -1), -1) + 1) * 2 + 1
        + (rank() over (partition by greatest(coalesce(e.af, -1), -1) order by extensions.st_distance(
             extensions.st_setsrid(extensions.st_makepoint(e.lo, e.la), 4326)::extensions.geography,
             coalesce((select st.location from stops st where st.n - 1 = greatest(e.af, 0)), v_campus))) - 1) * 0.001,
      'extra', null, left(coalesce(nullif(btrim(e.nm), ''), 'Suggested stop'), 120), e.la, e.lo
    from unnest(p_extra_lats, p_extra_lngs, p_extra_names, p_extra_afters) as e(la, lo, nm, af)
    union all
    select 1000000::numeric, 'campus', null, coalesce(v_campus_name, 'Campus'),
      extensions.st_y(v_campus::extensions.geometry), extensions.st_x(v_campus::extensions.geometry)
  )
  select (row_number() over (order by p.ord))::int, p.kind, p.id, p.name, p.lat, p.lng, v_hash
  from points p
  order by p.ord;
end;
$$;

revoke execute on function public.route_waypoints(uuid[], double precision[], double precision[], text[], int[]) from public, anon;
grant execute on function public.route_waypoints(uuid[], double precision[], double precision[], text[], int[]) to authenticated;
