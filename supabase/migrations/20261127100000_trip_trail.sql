-- Where the bus has been on a running trip, for the faint trail on the student's bus map (issue #556). Built from the
-- thinned trip history (about one point every 30 seconds), simplified to about 10 m, at most the last 3 hours. Only
-- for a trip still running, and only for someone who may follow the school's buses (the same rule as live positions:
-- staff, or a student with an approved subscription covering today). Anyone else gets null, never an error, so the
-- map simply draws no trail.

create function public.trip_trail(p_trip_id uuid) returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_line extensions.geometry;
begin
  if v_school is null or p_trip_id is null or not private.can_follow_buses() then
    return null;
  end if;
  if not exists (select 1 from public.trips t where t.id = p_trip_id and t.school_id = v_school and t.status = 'active') then
    return null;
  end if;
  select extensions.st_makeline(p.location::extensions.geometry order by p.recorded_at)
    into v_line
  from public.trip_positions p
  where p.trip_id = p_trip_id and p.school_id = v_school and p.recorded_at > now() - interval '3 hours';
  if v_line is null or extensions.st_npoints(v_line) < 2 then
    return null;
  end if;
  -- About 10 m at the equator (degrees); keeps the shape of the streets, drops the jitter.
  return extensions.st_asgeojson(extensions.st_simplify(v_line, 0.0001), 6)::jsonb;
end;
$$;

revoke execute on function public.trip_trail(uuid) from public, anon;
grant execute on function public.trip_trail(uuid) to authenticated;
