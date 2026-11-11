-- How far the school's subscribers live from the bus route itself (ADR 0017): the road when it is drawn and current,
-- otherwise straight lines from stop to stop and on to the campus. One row: subscribers, how many gave an area, and
-- (5 or more only) the median distance and the bands under 500 m, 500 m to 1 km, 1 to 2 km, over 2 km. Areas are ~500 m
-- cells, so distances are "about".

-- The line of the school's route: the drawn road if current, else straight through its stops to the campus; null when
-- there is no route.
create function private.route_line(p_school uuid) returns extensions.geography
language sql stable security definer
set search_path = ''
as $$
  with r as (select private.school_route(p_school) as id)
  select case
    when rt.geometry is not null and rt.drawn_hash = private.route_hash(rt.id) then rt.geometry
    else (
      select extensions.st_makeline(p.g order by p.ord)::extensions.geography
      from (
        select rs.position as ord, s.location::extensions.geometry as g
        from public.route_stops rs join public.stops s on s.id = rs.stop_id
        where rs.route_id = rt.id
        union all
        select 1000000, sc.campus_location::extensions.geometry
        from public.schools sc where sc.id = p_school and sc.campus_location is not null
      ) p
      having count(*) >= 2
    )
  end
  from r
  join public.routes rt on rt.id = r.id;
$$;
revoke execute on function private.route_line(uuid) from public;

create function public.admin_route_corridor()
returns table (subscribers int, with_area int, median_m int, under_500 int, to_1k int, to_2k int, over_2k int, has_route boolean)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_line extensions.geography;
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  v_line := private.route_line(v_school);
  return query
  with d as (
    select case when sub.area is null or v_line is null then null else extensions.st_distance(sub.area, v_line) end as m
    from private.stop_subscribers(v_school) sub
  ),
  g as (
    select count(*)::int as total, count(d.m)::int as n, percentile_cont(0.5) within group (order by d.m) as median,
      count(*) filter (where d.m < 500)::int as b1,
      count(*) filter (where d.m >= 500 and d.m < 1000)::int as b2,
      count(*) filter (where d.m >= 1000 and d.m < 2000)::int as b3,
      count(*) filter (where d.m >= 2000)::int as b4
    from d
  )
  select g.total, g.n,
    case when g.n >= 5 then round(g.median)::int end,
    case when g.n >= 5 then g.b1 end,
    case when g.n >= 5 then g.b2 end,
    case when g.n >= 5 then g.b3 end,
    case when g.n >= 5 then g.b4 end,
    v_line is not null
  from g;
end;
$$;

revoke execute on function public.admin_route_corridor() from public, anon;
grant execute on function public.admin_route_corridor() to authenticated;
