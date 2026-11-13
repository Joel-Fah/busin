-- Staff see only their own trips (owner decision, 2026-11-12).
--
-- A staff member who is not an administrator reads, starts, scans on and reads the boarding list of the trips they are
-- on: as driver, as assistant, or because they started it. A trip with nobody assigned is run by an administrator (a
-- missed assignment is covered by a trip started in the field, ADR 0020). Administrators keep the whole school, and
-- students keep reading the trips of their school (they follow the buses).
--
-- The staff member's history and weekly stats come from two functions, so the phone downloads one page or one summary
-- instead of every row. A trip counts as on time when it started no later than 10 minutes after its scheduled time;
-- trips started in the field have no schedule and stay out of punctuality.

-- ---------------------------------------------------------------- reading trips
drop policy trips_select on public.trips;
create policy trips_select on public.trips for select to authenticated
  using (
    school_id = (select private.my_school_id())
    and (
      not (select private.is_staff())
      or (select private.is_admin())
      or driver_id = (select auth.uid())
      or assistant_id = (select auth.uid())
      or started_by = (select auth.uid())
    )
  );

create index if not exists trips_driver_start_idx on public.trips (driver_id, scheduled_start desc) where driver_id is not null;
create index if not exists trips_assistant_start_idx on public.trips (assistant_id, scheduled_start desc) where assistant_id is not null;

-- Is the caller on this trip: driver, assistant, or the one who started it?
create or replace function private.is_on_trip(p_trip public.trips) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce(private.is_trip_crew(p_trip) or p_trip.started_by = (select auth.uid()), false)
$$;
revoke execute on function private.is_on_trip(public.trips) from public;
grant execute on function private.is_on_trip(public.trips) to authenticated;

-- ---------------------------------------------------------------- running trips
-- May the caller start or end this trip? The crew and administrators. Nobody assigned: administrators only.
create or replace function private.can_run_trip(p_trip public.trips) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce(p_trip.school_id = private.my_school_id()
    and (private.is_admin() or (private.is_staff() and private.is_trip_crew(p_trip))), false)
$$;

-- ---------------------------------------------------------------- scans
-- Every scan a staff member records (live, or sent later from the phone's queue: the recording function sets scanned_by
-- to the caller) is on a trip they are on, unless they are an administrator. Rows loaded by the database owner for
-- someone else (seeds, fixtures) are not checked.
create or replace function private.check_scan_crew() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_trip public.trips;
begin
  if (select auth.uid()) is null or new.scanned_by is distinct from (select auth.uid()) or private.is_admin() then
    return new;
  end if;
  select * into v_trip from public.trips where id = new.trip_id;
  if not found or not private.is_on_trip(v_trip) then
    raise exception 'not_trip_crew' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke execute on function private.check_scan_crew() from public;

create trigger scans_check_crew
  before insert on public.scans
  for each row execute function private.check_scan_crew();

-- ---------------------------------------------------------------- the boarding list
create or replace function public.trip_manifest(p_trip_id uuid)
returns table (scan_id uuid, student_id uuid, full_name text, avatar_url text, matricule text, stop_id uuid, scanned_at timestamptz)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_trip public.trips;
begin
  if not private.is_staff() then
    raise exception 'Staff access required' using errcode = '42501';
  end if;
  select * into v_trip from public.trips t where t.id = p_trip_id and t.school_id = private.my_school_id();
  -- A trip the caller is not on is not theirs to know about: the same answer as a trip that does not exist.
  if not found or not (private.is_admin() or private.is_on_trip(v_trip)) then
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

-- ---------------------------------------------------------------- my history
-- The caller's past trips, newest first, one page at a time: those scheduled before [p_before] (the client passes the
-- start of its today first, then the last trip's time). With the bus's name and how many students boarded.
create or replace function public.my_trip_history(p_before timestamptz, p_limit integer default 20)
returns table (
  id uuid,
  bus_id uuid,
  bus_label text,
  direction public.trip_direction,
  status public.trip_status,
  origin text,
  scheduled_start timestamptz,
  started_at timestamptz,
  ended_at timestamptz,
  my_role text,
  boarded integer
)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_me uuid := (select auth.uid());
begin
  if not private.is_staff() then
    raise exception 'Staff access required' using errcode = '42501';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 50 then
    raise exception 'invalid_limit' using errcode = '22023';
  end if;
  return query
  select t.id, t.bus_id, coalesce(nullif(btrim(b.name), ''), b.plate), t.direction, t.status, t.origin, t.scheduled_start,
         t.started_at, t.ended_at,
         case when t.driver_id = v_me then 'driver' when t.assistant_id = v_me then 'assistant' else 'starter' end,
         (select count(*)::integer from public.scans s where s.trip_id = t.id)
  from public.trips t
  join public.buses b on b.id = t.bus_id
  where t.school_id = private.my_school_id()
    and (t.driver_id = v_me or t.assistant_id = v_me or t.started_by = v_me)
    and t.scheduled_start < least(coalesce(p_before, now()), now())
  order by t.scheduled_start desc, t.id
  limit p_limit;
end;
$$;
revoke execute on function public.my_trip_history(timestamptz, integer) from public, anon;
grant execute on function public.my_trip_history(timestamptz, integer) to authenticated;

-- ---------------------------------------------------------------- my weekly stats
-- The caller's last [p_weeks] weeks (Monday to Sunday at the school, this week included), one row per week even when it
-- is empty, so a chart has no gaps. Trips still ahead are not counted.
create or replace function public.my_trip_stats(p_weeks integer default 12)
returns table (
  week_start date,
  trips integer,
  completed integer,
  cancelled integer,
  missed integer,
  on_time integer,
  late integer,
  avg_delay_minutes numeric,
  boarded integer,
  minutes_on_road integer,
  as_driver integer,
  as_assistant integer,
  field_trips integer
)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_me uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_zone text;
  v_today date;
  v_first date;
begin
  if not private.is_staff() then
    raise exception 'Staff access required' using errcode = '42501';
  end if;
  if p_weeks is null or p_weeks < 1 or p_weeks > 26 then
    raise exception 'invalid_weeks' using errcode = '22023';
  end if;
  select sc.timezone into v_zone from public.schools sc where sc.id = v_school;
  v_zone := coalesce(v_zone, 'UTC');
  v_today := (now() at time zone v_zone)::date;
  v_first := date_trunc('week', v_today)::date - (p_weeks - 1) * 7;

  return query
  with mine as (
    select t.*, date_trunc('week', (t.scheduled_start at time zone v_zone))::date as wk,
           -- Late by how many minutes (an early start counts as zero); null when not a scheduled trip that started.
           case when t.origin = 'scheduled' and t.started_at is not null
                then greatest(0, extract(epoch from (t.started_at - t.scheduled_start)) / 60.0) end as delay
    from public.trips t
    where t.school_id = v_school
      and (t.driver_id = v_me or t.assistant_id = v_me or t.started_by = v_me)
      and t.scheduled_start >= (v_first::timestamp at time zone v_zone)
      and t.scheduled_start < now()
  ),
  weeks as (
    select generate_series(v_first, date_trunc('week', v_today)::date, interval '1 week')::date as wk
  )
  select w.wk,
         count(m.id)::integer,
         count(m.id) filter (where m.status = 'completed')::integer,
         count(m.id) filter (where m.status = 'cancelled')::integer,
         -- Scheduled, never started, and its day is over.
         count(m.id) filter (where m.status = 'scheduled' and (m.scheduled_start at time zone v_zone)::date < v_today)::integer,
         count(m.id) filter (where m.delay is not null and m.delay <= 10)::integer,
         count(m.id) filter (where m.delay > 10)::integer,
         round(avg(m.delay), 1),
         coalesce(sum((select count(*) from public.scans s where s.trip_id = m.id)), 0)::integer,
         coalesce(sum(extract(epoch from (m.ended_at - m.started_at)) / 60) filter (where m.ended_at is not null), 0)::integer,
         count(m.id) filter (where m.driver_id = v_me)::integer,
         count(m.id) filter (where m.assistant_id = v_me)::integer,
         count(m.id) filter (where m.origin = 'field')::integer
  from weeks w
  left join mine m on m.wk = w.wk
  group by w.wk
  order by w.wk;
end;
$$;
revoke execute on function public.my_trip_stats(integer) from public, anon;
grant execute on function public.my_trip_stats(integer) to authenticated;
