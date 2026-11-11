-- Trip control for the ops app (phase 4): starting and ending trips, the bus position from a staff phone, and the
-- trip manifest. Owner decisions: the staff member assigned to a trip (its driver_id) starts and ends it; when nobody
-- is assigned, any verified staff member of the school can; admins always can. The position is shared by the assignee,
-- or, when nobody is assigned, by whoever started the trip.

alter table public.trips add column started_by uuid references public.profiles (id);

-- May the caller start or end this trip?
create function private.can_run_trip(p_trip public.trips) returns boolean
language sql stable security definer
set search_path = ''
as $$
  -- coalesce: a comparison with a missing driver is null, and a null here must mean no.
  select coalesce(p_trip.school_id = private.my_school_id()
    and (private.is_admin()
      or (private.is_staff() and (p_trip.driver_id is null or p_trip.driver_id = (select auth.uid())))), false)
$$;

-- May the caller share the bus position for this trip?
create function private.can_share_position(p_trip public.trips) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce(p_trip.school_id = private.my_school_id()
    and private.is_staff()
    and (p_trip.driver_id is not distinct from (select auth.uid())
      or (p_trip.driver_id is null and p_trip.started_by is not distinct from (select auth.uid()))
      or private.is_admin()), false)
$$;

revoke execute on function private.can_run_trip(public.trips), private.can_share_position(public.trips) from public;

-- Starts a scheduled trip on its own school day. A bus runs one trip at a time.
create function public.start_trip(p_trip_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_trip public.trips;
  v_zone text;
begin
  select * into v_trip from public.trips where id = p_trip_id and school_id = private.my_school_id() for update;
  if not found then
    raise exception 'Trip not found' using errcode = 'P0002';
  end if;
  if not private.can_run_trip(v_trip) then
    raise exception 'Only the staff member assigned to this trip can start it' using errcode = '42501';
  end if;
  if v_trip.status <> 'scheduled' then
    raise exception 'trip_not_scheduled' using errcode = '55000';
  end if;
  select sc.timezone into v_zone from public.schools sc where sc.id = v_trip.school_id;
  if (v_trip.scheduled_start at time zone v_zone)::date <> (now() at time zone v_zone)::date then
    raise exception 'trip_not_today' using errcode = '55000';
  end if;
  if exists (select 1 from public.trips t where t.bus_id = v_trip.bus_id and t.status = 'active' and t.id <> v_trip.id) then
    raise exception 'bus_busy' using errcode = '55000';
  end if;

  update public.trips set status = 'active', started_at = now(), started_by = (select auth.uid()) where id = v_trip.id;
  perform private.write_audit(v_trip.school_id, (select auth.uid()), 'trip.started', 'trip', v_trip.id, '{}'::jsonb);
end;
$$;

-- Ends a running trip.
create function public.end_trip(p_trip_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_trip public.trips;
begin
  select * into v_trip from public.trips where id = p_trip_id and school_id = private.my_school_id() for update;
  if not found then
    raise exception 'Trip not found' using errcode = 'P0002';
  end if;
  if not (private.can_run_trip(v_trip) or coalesce(v_trip.started_by = (select auth.uid()), false)) then
    raise exception 'Only the staff member assigned to this trip can end it' using errcode = '42501';
  end if;
  if v_trip.status <> 'active' then
    raise exception 'trip_not_active' using errcode = '55000';
  end if;

  update public.trips set status = 'completed', ended_at = now() where id = v_trip.id;
  perform private.write_audit(v_trip.school_id, (select auth.uid()), 'trip.ended', 'trip', v_trip.id, '{}'::jsonb);
end;
$$;

-- A thinned history of each trip's positions (about one point every 30 seconds), for arrival-time estimates later.
-- Written only by publish_position; administrators of the school may read it.
create table public.trip_positions (
  id bigint generated always as identity primary key,
  trip_id uuid not null,
  school_id uuid not null,
  location extensions.geography(Point, 4326) not null,
  speed_mps real,
  recorded_at timestamptz not null default now(),
  foreign key (trip_id, school_id) references public.trips (id, school_id) on delete cascade
);
create index trip_positions_trip_idx on public.trip_positions (trip_id, recorded_at);

alter table public.trip_positions enable row level security;
alter table public.trip_positions force row level security;
revoke all on public.trip_positions from public, anon, authenticated;
grant select on public.trip_positions to authenticated;
create policy trip_positions_select on public.trip_positions for select to authenticated
  using (school_id = private.my_school_id() and private.is_admin());

-- The bus position from the phone on board, every few seconds while the trip runs. Returns whether it was kept:
-- updates closer together than 5 seconds, and readings worse than 100 m, are dropped (they would only add noise and
-- wake the bus-near-stop trigger for nothing).
create function public.publish_position(
  p_trip_id uuid,
  p_lat double precision,
  p_lng double precision,
  p_speed_mps real default null,
  p_heading_deg real default null,
  p_accuracy_m real default null
) returns boolean
language plpgsql security definer
set search_path = ''
as $$
declare
  v_trip public.trips;
  v_point extensions.geography;
  v_last timestamptz;
begin
  select * into v_trip from public.trips where id = p_trip_id and school_id = private.my_school_id();
  if not found then
    raise exception 'Trip not found' using errcode = 'P0002';
  end if;
  if not private.can_share_position(v_trip) then
    raise exception 'Only the staff member sharing this bus can send its position' using errcode = '42501';
  end if;
  if v_trip.status <> 'active' then
    raise exception 'trip_not_active' using errcode = '55000';
  end if;
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'Coordinates are out of range' using errcode = '22023';
  end if;
  if p_speed_mps is not null and (p_speed_mps < 0 or p_speed_mps > 60) then
    p_speed_mps := null;
  end if;
  if p_heading_deg is not null and (p_heading_deg < 0 or p_heading_deg > 360) then
    p_heading_deg := null;
  end if;
  if p_accuracy_m is not null and p_accuracy_m > 100 then
    return false;
  end if;

  select recorded_at into v_last from public.live_positions where bus_id = v_trip.bus_id;
  if v_last is not null and v_last > now() - interval '5 seconds' then
    return false;
  end if;

  v_point := extensions.st_point(p_lng, p_lat)::extensions.geography;
  insert into public.live_positions (bus_id, school_id, trip_id, location, speed_mps, heading_deg, accuracy_m, source, recorded_at)
  values (v_trip.bus_id, v_trip.school_id, v_trip.id, v_point, p_speed_mps, p_heading_deg, p_accuracy_m, 'phone', now())
  on conflict (bus_id) do update
    set trip_id = excluded.trip_id, location = excluded.location, speed_mps = excluded.speed_mps,
        heading_deg = excluded.heading_deg, accuracy_m = excluded.accuracy_m, source = excluded.source,
        recorded_at = excluded.recorded_at;

  if not exists (select 1 from public.trip_positions where trip_id = v_trip.id and recorded_at > now() - interval '30 seconds') then
    insert into public.trip_positions (trip_id, school_id, location, speed_mps) values (v_trip.id, v_trip.school_id, v_point, p_speed_mps);
  end if;
  return true;
end;
$$;

-- Who has boarded a trip, for staff of the school: newest first, at most 500 (a bus holds far fewer).
create function public.trip_manifest(p_trip_id uuid)
returns table (scan_id uuid, student_id uuid, full_name text, avatar_url text, matricule text, stop_id uuid, scanned_at timestamptz)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_staff() then
    raise exception 'Staff access required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.trips t where t.id = p_trip_id and t.school_id = private.my_school_id()) then
    raise exception 'Trip not found' using errcode = 'P0002';
  end if;
  return query
  select s.id, p.id, p.full_name, p.avatar_url, p.matricule, s.stop_id, s.scanned_at
  from public.scans s join public.profiles p on p.id = s.student_id
  where s.trip_id = p_trip_id
  order by s.scanned_at desc
  limit 500;
end;
$$;

revoke execute on function public.start_trip(uuid), public.end_trip(uuid),
  public.publish_position(uuid, double precision, double precision, real, real, real), public.trip_manifest(uuid) from public, anon;
grant execute on function public.start_trip(uuid), public.end_trip(uuid),
  public.publish_position(uuid, double precision, double precision, real, real, real), public.trip_manifest(uuid) to authenticated;
