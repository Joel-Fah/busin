-- admin_nearer_stops picked each student's nearest stop with the index's distance ordering, which is only approximate on
-- geography and can choose a farther stop. A school has tens of stops, so order by the exact distance instead.

create or replace function public.admin_nearer_stops()
returns table (from_stop uuid, to_stop uuid, students int, saved_m int)
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
  with mine as (
    select sub.student_id, sub.stop_id, sub.area, extensions.st_distance(sub.area, st.location) as own_m
    from private.stop_subscribers(v_school) sub
    join public.stops st on st.id = sub.stop_id
    where sub.area is not null
  ),
  nearest as (
    select m.student_id, m.stop_id, m.own_m, n.id as near_id, n.m as near_m
    from mine m
    cross join lateral (
      select s.id, extensions.st_distance(m.area, s.location) as m
      from public.stops s
      where s.school_id = v_school and s.active
      order by extensions.st_distance(m.area, s.location)
      limit 1
    ) n
  )
  select n.stop_id, n.near_id, count(*)::int, round(percentile_cont(0.5) within group (order by n.own_m - n.near_m))::int
  from nearest n
  where n.near_id <> n.stop_id and n.own_m - n.near_m >= 300
  group by n.stop_id, n.near_id
  having count(*) >= 5
  order by 3 desc
  limit 200;
end;
$$;

