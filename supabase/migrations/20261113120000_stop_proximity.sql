-- Proximity per stop (phase 5, second insight). How far the subscribers of each stop live from it, from their coarse
-- areas (ADR 0013, cells of about 500 m). Distances are straight lines from the centre of a cell, so "about": a walk is
-- longer. Privacy: no figure is returned for fewer than 5 students with an area; desire lines (a cell to a stop) only
-- for 5 or more; no single student is ever placed. Subscribers: approved, in a semester that has not ended.

-- The subscribers of the caller's school with their stop and, when they gave one, their area.
create function private.stop_subscribers(p_school uuid)
returns table (student_id uuid, stop_id uuid, area extensions.geography)
language sql stable security definer
set search_path = ''
as $$
  select distinct on (s.student_id) s.student_id, s.stop_id, a.area
  from public.subscriptions s
  join public.semesters m on m.id = s.semester_id and m.school_id = s.school_id
  join public.profiles p on p.id = s.student_id and p.status = 'verified'
  left join public.student_areas a on a.user_id = s.student_id and a.school_id = s.school_id
  where s.school_id = p_school and s.status = 'approved' and m.end_date >= current_date
  order by s.student_id, m.end_date desc;
$$;
revoke execute on function private.stop_subscribers(uuid) from public;

-- Per active stop: subscribers, how many gave an area, and (5 or more only) the median distance in metres and the
-- count in each band: under 500 m, 500 m to 1 km, 1 to 2 km, over 2 km.
create function public.admin_stop_proximity()
returns table (
  stop_id uuid,
  subscribers int,
  with_area int,
  median_m int,
  under_500 int,
  to_1k int,
  to_2k int,
  over_2k int
)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  return query
  with d as (
    select sub.stop_id, sub.area, case when sub.area is null then null else extensions.st_distance(sub.area, st.location) end as m
    from private.stop_subscribers(v_school) sub
    join public.stops st on st.id = sub.stop_id
  ),
  g as (
    select d.stop_id, count(*)::int as subscribers, count(d.m)::int as with_area,
      percentile_cont(0.5) within group (order by d.m) as median,
      count(*) filter (where d.m < 500)::int as b1,
      count(*) filter (where d.m >= 500 and d.m < 1000)::int as b2,
      count(*) filter (where d.m >= 1000 and d.m < 2000)::int as b3,
      count(*) filter (where d.m >= 2000)::int as b4
    from d group by d.stop_id
  )
  select st.id,
    coalesce(g.subscribers, 0),
    coalesce(g.with_area, 0),
    case when g.with_area >= 5 then round(g.median)::int end,
    case when g.with_area >= 5 then g.b1 end,
    case when g.with_area >= 5 then g.b2 end,
    case when g.with_area >= 5 then g.b3 end,
    case when g.with_area >= 5 then g.b4 end
  from public.stops st
  left join g on g.stop_id = st.id
  where st.school_id = v_school and st.active
  order by st.name;
end;
$$;

-- Desire lines: from a cell where 5 or more subscribers of the same stop live, to that stop, with how many and the
-- straight-line distance. Longest first, at most 500.
create function public.admin_desire_lines()
returns table (lat double precision, lng double precision, stop_id uuid, students int, distance_m int)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  return query
  with cells as (
    select sub.area::extensions.geometry as cell, sub.stop_id, count(*)::int as students
    from private.stop_subscribers(v_school) sub
    where sub.area is not null
    group by 1, 2
    having count(*) >= 5
  )
  select extensions.st_y(c.cell), extensions.st_x(c.cell), c.stop_id, c.students,
    round(extensions.st_distance(c.cell::extensions.geography, st.location))::int
  from cells c
  join public.stops st on st.id = c.stop_id and st.active
  order by 5 desc
  limit 500;
end;
$$;

revoke execute on function public.admin_stop_proximity(), public.admin_desire_lines() from public, anon;
grant execute on function public.admin_stop_proximity(), public.admin_desire_lines() to authenticated;
