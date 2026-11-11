-- Stop suggestions (phase 5, fourth insight). Short, explainable sentences with the number behind them; the admin
-- decides, nothing changes by itself, and the page says that a suggestion does not know whether a bus can reach the spot.
--
-- 'new_stop'   A named place (a landmark or a street from the school's copy of OpenStreetMap) near which a new stop would
--              bring 5 or more subscribers within 500 m who today live further than 500 m from any active stop. Picked
--              greedily, up to three: the best place, then the best among the students it does not cover, and so on. A
--              place within 300 m of an active stop is not a new stop. Areas are ~500 m cells, so distances are "about".
-- 'close_pair' Two active stops within 400 m of each other, with their subscribers: one may be enough.
-- 'unused'     An active stop with no boarding counted for 6 weeks, while the school's other stops had some.
-- Privacy: a new-stop figure is never under 5 students and no student is placed; the other two use counts the portal
-- already shows per stop.

create index if not exists places_location_idx on public.places using gist (location);

create function public.admin_stop_suggestions()
returns table (
  kind text,
  stop_id uuid,
  other_stop_id uuid,
  place_name text,
  lat double precision,
  lng double precision,
  students int,
  metres int
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
    return next;
    v_covered := v_covered || v_pick.who;
    v_pick := null;
  end loop;

  -- Stops very close together.
  return query
  select 'close_pair', a.id, b.id, null::text, null::double precision, null::double precision,
    ((select count(*) from private.stop_subscribers(v_school) x where x.stop_id in (a.id, b.id)))::int,
    round(extensions.st_distance(a.location, b.location))::int
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
      ((select count(*) from private.stop_subscribers(v_school) x where x.stop_id = s.id))::int, 42
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
