-- Trip crew (ADR 0019): a trip has a driver and, optionally, an assistant (also staff) on board. Either of them can start
-- and end the trip and share the bus position; scans were already open to any staff. When nobody is assigned the old
-- rules stand (any staff can run the trip, and whoever started it shares the position). Administrators always can.
--
-- When both crew members share their position, one phone leads: its fixes are kept and the other's are set aside, until
-- the leader has sent nothing for 30 seconds, when the other phone takes over. So the bus dot never jumps between two
-- phones, and a dead phone or a lost signal hands the job over by itself.

alter table public.trips add column assistant_id uuid;
alter table public.trips add constraint trips_assistant_fk
  foreign key (assistant_id, school_id) references public.profiles (id, school_id);
-- One person cannot be both the driver and the assistant of a trip.
alter table public.trips add constraint trips_crew_distinct
  check (assistant_id is null or driver_id is null or assistant_id <> driver_id);
-- Who may set it is the same as for the driver: the columns are granted, and the update policy limits it to admins.
grant update (assistant_id) on public.trips to authenticated;

-- Is the caller the driver or the assistant of this trip?
create function private.is_trip_crew(p_trip public.trips) returns boolean
language sql stable security definer
set search_path = ''
as $$
  -- coalesce: a comparison with a missing person is null, and a null here must mean no.
  select coalesce((select auth.uid()) = p_trip.driver_id or (select auth.uid()) = p_trip.assistant_id, false)
$$;

-- May the caller start or end this trip? The crew, any staff when nobody is assigned, and administrators.
create or replace function private.can_run_trip(p_trip public.trips) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce(p_trip.school_id = private.my_school_id()
    and (private.is_admin()
      or (private.is_staff()
        and ((p_trip.driver_id is null and p_trip.assistant_id is null) or private.is_trip_crew(p_trip)))), false)
$$;

-- May the caller share the bus position for this trip? The crew; whoever started it when nobody is assigned; admins.
create or replace function private.can_share_position(p_trip public.trips) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce(p_trip.school_id = private.my_school_id()
    and private.is_staff()
    and (private.is_trip_crew(p_trip)
      or (p_trip.driver_id is null and p_trip.assistant_id is null and p_trip.started_by is not distinct from (select auth.uid()))
      or private.is_admin()), false)
$$;

revoke execute on function private.is_trip_crew(public.trips) from public;

-- Which phone leads a trip's position. One row per trip, written only by publish_position; nobody reads it directly
-- (it names staff, and students may read the position itself), the ops app asks trip_position_holder.
create table public.trip_position_leases (
  trip_id uuid primary key,
  school_id uuid not null,
  holder uuid not null references public.profiles (id) on delete cascade,
  renewed_at timestamptz not null default now(),
  foreign key (trip_id, school_id) references public.trips (id, school_id) on delete cascade
);
alter table public.trip_position_leases enable row level security;
alter table public.trip_position_leases force row level security;
revoke all on public.trip_position_leases from public, anon, authenticated;

-- The bus position, as before, with the lease: a fix from a phone that does not lead is set aside while the leader has
-- sent one in the last 30 seconds. Returns whether it was kept.
create or replace function public.publish_position(
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
  v_holder uuid;
  v_renewed timestamptz;
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

  -- Another phone leads while it keeps sending.
  select holder, renewed_at into v_holder, v_renewed from public.trip_position_leases where trip_id = v_trip.id;
  if v_holder is not null and v_holder <> (select auth.uid()) and v_renewed > now() - interval '30 seconds' then
    return false;
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

  -- A kept fix makes this phone the leader (or keeps it so).
  insert into public.trip_position_leases (trip_id, school_id, holder, renewed_at)
  values (v_trip.id, v_trip.school_id, (select auth.uid()), now())
  on conflict (trip_id) do update set holder = excluded.holder, renewed_at = excluded.renewed_at;

  if not exists (select 1 from public.trip_positions where trip_id = v_trip.id and recorded_at > now() - interval '30 seconds') then
    insert into public.trip_positions (trip_id, school_id, location, speed_mps) values (v_trip.id, v_trip.school_id, v_point, p_speed_mps);
  end if;
  return true;
end;
$$;

-- Whose phone leads the position of a trip right now, for the staff of the school: no row when nobody does (nothing
-- sent in the last 30 seconds). The ops app shows it, so the crew knows whether to keep sharing or stand by.
create function public.trip_position_holder(p_trip_id uuid)
returns table (holder_id uuid, holder_name text, is_me boolean, seconds_ago integer)
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
  select l.holder, coalesce(nullif(p.full_name, ''), p.email), l.holder = (select auth.uid()),
         greatest(0, floor(extract(epoch from now() - l.renewed_at))::integer)
  from public.trip_position_leases l join public.profiles p on p.id = l.holder
  where l.trip_id = p_trip_id and l.renewed_at > now() - interval '30 seconds';
end;
$$;

revoke execute on function public.trip_position_holder(uuid) from public, anon;
grant execute on function public.trip_position_holder(uuid) to authenticated;
