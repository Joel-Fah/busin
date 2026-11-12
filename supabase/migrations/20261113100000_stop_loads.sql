-- Stop load (phase 5, first insight): how full the bus gets at each stop.
--
-- One row per trip and stop: the boardings scanned there (the ops app tags each scan with its nearest stop) and the
-- seats of the bus that ran the trip. Kept in a private aggregate table so the portal never reads raw scans for the
-- map. pg_cron refreshes it every night; the last three days are recounted each time because offline scans can arrive
-- up to a day late. An admin can refresh their own school at most once every five minutes.

create extension if not exists pg_cron;

create table private.stop_trip_loads (
  trip_id uuid not null references public.trips (id) on delete cascade,
  stop_id uuid not null references public.stops (id) on delete cascade,
  school_id uuid not null references public.schools (id),
  day date not null,
  direction public.trip_direction not null,
  boardings int not null check (boardings > 0),
  seats int not null check (seats > 0),
  refreshed_at timestamptz not null default now(),
  primary key (trip_id, stop_id)
);
create index stop_trip_loads_school_day_idx on private.stop_trip_loads (school_id, day desc);
alter table private.stop_trip_loads enable row level security;
alter table private.stop_trip_loads force row level security;
revoke all on private.stop_trip_loads from public, anon, authenticated;

-- When each school was last refreshed by hand (the five-minute limit).
create table private.stop_load_refreshes (
  school_id uuid primary key references public.schools (id) on delete cascade,
  at timestamptz not null
);
alter table private.stop_load_refreshes enable row level security;
alter table private.stop_load_refreshes force row level security;
revoke all on private.stop_load_refreshes from public, anon, authenticated;

-- Recounts the trips scheduled since p_since (every trip when null), for one school or all. Cancelled and scheduled
-- trips are left out; only scans tagged with a stop count. Returns the number of rows written.
create function private.refresh_stop_loads(p_since timestamptz, p_school uuid default null)
returns int
language plpgsql security definer
set search_path = ''
as $$
declare
  v_rows int;
begin
  delete from private.stop_trip_loads l
  using public.trips t
  where t.id = l.trip_id
    and (p_since is null or t.scheduled_start >= p_since)
    and (p_school is null or l.school_id = p_school);

  insert into private.stop_trip_loads (trip_id, stop_id, school_id, day, direction, boardings, seats)
  select t.id, s.stop_id, t.school_id, (t.scheduled_start at time zone sc.timezone)::date, t.direction, count(*)::int, b.capacity
  from public.trips t
  join public.schools sc on sc.id = t.school_id
  join public.buses b on b.id = t.bus_id
  join public.scans s on s.trip_id = t.id and s.stop_id is not null
  where t.status in ('active', 'completed')
    and (p_since is null or t.scheduled_start >= p_since)
    and (p_school is null or t.school_id = p_school)
  group by t.id, s.stop_id, t.school_id, sc.timezone, t.direction, b.capacity;
  get diagnostics v_rows = row_count;
  return v_rows;
end;
$$;
revoke execute on function private.refresh_stop_loads(timestamptz, uuid) from public;

-- Every night at 01:30 UTC (02:30 in Douala), after the last trips of the day.
select cron.schedule('busin-stop-loads', '30 1 * * *', $$select private.refresh_stop_loads(now() - interval '3 days')$$);

-- Everything already recorded.
select private.refresh_stop_loads(null);

-- Per stop of the admin's school, over the last p_days days (7 to 365): the departures that boarded someone there,
-- the boardings, the average and the most in one departure, and the same against the bus's seats (0 to 1, can pass 1
-- when a bus is overfull). Stops with no boarding are not returned.
create function public.admin_stop_loads(p_days int default 56)
returns table (
  stop_id uuid,
  departures int,
  boardings int,
  per_departure real,
  peak int,
  load real,
  peak_load real,
  last_day date,
  refreshed_at timestamptz
)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_days int := least(greatest(coalesce(p_days, 56), 7), 365);
  v_zone text;
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  select sc.timezone into v_zone from public.schools sc where sc.id = v_school;
  return query
  select
    l.stop_id,
    count(*)::int,
    sum(l.boardings)::int,
    avg(l.boardings)::real,
    max(l.boardings)::int,
    avg(l.boardings::real / l.seats)::real,
    max(l.boardings::real / l.seats)::real,
    max(l.day),
    max(l.refreshed_at)
  from private.stop_trip_loads l
  where l.school_id = v_school
    and l.day > (now() at time zone v_zone)::date - v_days
  group by l.stop_id
  order by 6 desc;
end;
$$;

-- Recounts the admin's school now, over the last year, at most once every five minutes. Returns when it ran.
create function public.admin_refresh_stop_loads()
returns timestamptz
language plpgsql security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_last timestamptz;
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  select r.at into v_last from private.stop_load_refreshes r where r.school_id = v_school for update;
  if v_last is not null and v_last > now() - interval '5 minutes' then
    raise exception 'Refreshed a moment ago' using errcode = 'PT429';
  end if;
  insert into private.stop_load_refreshes (school_id, at) values (v_school, now())
  on conflict (school_id) do update set at = excluded.at;
  perform private.refresh_stop_loads(now() - interval '366 days', v_school);
  perform private.write_audit(v_school, (select auth.uid()), 'insights.refreshed', 'school', v_school, '{}'::jsonb);
  return now();
end;
$$;

revoke execute on function public.admin_stop_loads(int), public.admin_refresh_stop_loads() from public, anon;
grant execute on function public.admin_stop_loads(int), public.admin_refresh_stop_loads() to authenticated;
