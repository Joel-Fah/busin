-- A realistic, varied schedule for ONE staff account, for LOCAL development only. Run it with:
--   npm run seed:staff -- <email>
--
-- Gives the staff member trips on their own demo bus (DEMO-107, so they never clash with the demo drivers):
--   * eight weeks back, every weekday: the morning trip to campus as driver; the trip home as driver on Mondays and
--     Wednesdays and as assistant on Tuesdays and Thursdays. Most start on time, about one in five late (11 to 30
--     minutes), a few were missed (never started), a few cancelled; boardings vary from an empty bus to a full one;
--   * a handful of field trips they started themselves (origin `field`, no schedule to be late against);
--   * today: the trips whose hour has passed are done, one as driver starts in about 20 minutes (to start and scan)
--     and one as assistant later;
--   * the next four weekdays: scheduled trips, one of them already cancelled by the school.
-- Running it again replaces this staff member's trips on that bus and moves them to the current dates. It needs the demo
-- data (npm run seed:demo) for the students who board. Never run it against a hosted project.
--
-- Variables from the caller: :staff_email.

create temp table seed_staff on commit drop as
select p.id, p.school_id from public.profiles p
where lower(p.email) = lower(:'staff_email') and p.role in ('staff', 'admin') and p.status = 'verified';

do $$
begin
  if not exists (select 1 from seed_staff) then
    raise exception 'No verified staff member with that email. Invite them, have them sign in once, then try again.';
  end if;
  if (select school_id from seed_staff) <> '00000000-0000-4000-8000-000000000001' then
    raise exception 'The staff member is not at the demo school (ICT University).';
  end if;
  if not exists (select 1 from public.profiles where email like 'demo.%') then
    raise exception 'The demo data is missing. Run npm run seed:demo first.';
  end if;
end;
$$;

-- ---------------------------------------------------------------- the bus
insert into public.buses (id, school_id, plate, capacity, in_service)
values ('de200000-0000-4000-8000-000000000007', '00000000-0000-4000-8000-000000000001', 'DEMO-107', 45, true)
on conflict (id) do update set in_service = true;

-- ---------------------------------------------------------------- remove this staff member's previous seeded trips
delete from public.scans where trip_id in (
  select t.id from public.trips t, seed_staff s
  where t.bus_id = 'de200000-0000-4000-8000-000000000007' and (t.driver_id = s.id or t.assistant_id = s.id));
delete from public.trips t using seed_staff s
where t.bus_id = 'de200000-0000-4000-8000-000000000007' and (t.driver_id = s.id or t.assistant_id = s.id);

-- ---------------------------------------------------------------- the trips
-- Times are Douala wall-clock times. `h` (0 to 99, stable for a trip) decides how each one went.
create temp table seed_staff_trips on commit drop as
select
  md5('seed-staff:' || s.id || ':' || g.d || ':' || v.dir)::uuid as id,
  case when v.dir = 'outbound' and extract(isodow from g.d) in (2, 4)
       then (select id from public.profiles where email = 'demo.driver1@ictuniversity.edu.cm') else s.id end as driver_id,
  case when v.dir = 'outbound' and extract(isodow from g.d) in (2, 4) then s.id
       when extract(day from g.d)::int % 2 = 0 then (select id from public.profiles where email = 'demo.driver2@ictuniversity.edu.cm') end as assistant_id,
  v.dir::public.trip_direction as direction,
  'scheduled'::text as origin,
  g.d as day,
  ((g.d + case when v.dir = 'inbound' then time '06:45' else time '16:45' end)::timestamp at time zone 'Africa/Douala') as scheduled_start,
  abs(hashtext('seed-staff:' || g.d || v.dir)) % 100 as h
from seed_staff s
cross join (select generate_series(current_date - 56, current_date + 6, interval '1 day')::date as d) g
cross join (values ('inbound'), ('outbound')) v(dir)
where extract(isodow from g.d) < 6
  and (v.dir = 'inbound' or extract(isodow from g.d) in (1, 2, 3, 4));

-- Field trips: about one a week, started by the staff member at midday when no trip was scheduled.
insert into seed_staff_trips
select md5('seed-staff:' || s.id || ':field:' || g.d)::uuid, s.id,
       case when extract(day from g.d)::int % 3 = 0 then (select id from public.profiles where email = 'demo.driver3@ictuniversity.edu.cm') end,
       (case when extract(day from g.d)::int % 2 = 0 then 'inbound' else 'outbound' end)::public.trip_direction,
       'field', g.d,
       ((g.d + time '12:30')::timestamp at time zone 'Africa/Douala'),
       abs(hashtext('seed-staff:field:' || g.d)) % 100
from seed_staff s
cross join (select generate_series(current_date - 56, current_date - 1, interval '1 day')::date as d) g
where extract(isodow from g.d) = 5 and abs(hashtext('field' || g.d)) % 3 <> 0;

-- Today, whatever the hour: one to start soon as the driver, one later as the assistant.
insert into seed_staff_trips
select md5('seed-staff:' || s.id || ':today-soon')::uuid, s.id, (select id from public.profiles where email = 'demo.driver2@ictuniversity.edu.cm'),
       'inbound'::public.trip_direction, 'scheduled', current_date, date_trunc('minute', now()) + interval '20 minutes', 50
from seed_staff s
union all
select md5('seed-staff:' || s.id || ':today-later')::uuid, (select id from public.profiles where email = 'demo.driver1@ictuniversity.edu.cm'), s.id,
       'outbound'::public.trip_direction, 'scheduled', current_date, date_trunc('minute', now()) + interval '3 hours', 50
from seed_staff s;

create temp table seed_staff_status on commit drop as
select t.*,
  case
    -- The next weekday's trip home was cancelled ahead of time by the school.
    when t.scheduled_start > now() and t.direction = 'outbound' and t.day = (select min(d)::date from generate_series(current_date + 1, current_date + 6, interval '1 day') d where extract(isodow from d) in (1, 2, 3, 4)) then 'cancelled'
    when t.scheduled_start > now() then 'scheduled'
    when t.origin = 'field' then 'completed'
    when t.h < 5 then 'cancelled'
    -- Missed: never started, and its day is over.
    when t.h < 9 and t.day < current_date then 'scheduled'
    when t.scheduled_start + interval '60 minutes' < now() then 'completed'
    else 'scheduled' end as status,
  -- Minutes after the scheduled time it started: about one in five late (11 to 30), the rest on time (up to 8, some early).
  case when t.origin = 'field' then 0
       when t.h between 9 and 27 then 11 + t.h % 20
       else (t.h % 11) - 2 end as delay
from seed_staff_trips t;

insert into public.trips (id, school_id, bus_id, driver_id, assistant_id, direction, status, scheduled_start, started_at, ended_at, started_by, origin, created_by, archived_at)
select
  t.id, '00000000-0000-4000-8000-000000000001', 'de200000-0000-4000-8000-000000000007', t.driver_id, t.assistant_id, t.direction,
  t.status::public.trip_status, t.scheduled_start,
  case when t.status = 'completed' then t.scheduled_start + t.delay * interval '1 minute' end,
  case when t.status = 'completed' then t.scheduled_start + t.delay * interval '1 minute' + (40 + t.h % 25) * interval '1 minute' end,
  case when t.status = 'completed' then (case when t.origin = 'field' then (select id from seed_staff) else t.driver_id end) end,
  t.origin,
  case when t.origin = 'field' then (select id from seed_staff) end,
  case when t.status in ('completed', 'cancelled') and t.day < current_date - 7 then t.scheduled_start + interval '1 day' end
from seed_staff_status t;

-- ---------------------------------------------------------------- boardings
-- The demo students who ride this bus (about one in seven, some forty with an approved subscription). Each finished
-- trip has its own turnout, from an empty bus (now and then) to nearly everyone; field trips carry a few. Mornings at
-- their stop, afternoons at the campus.
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by, scanned_at, location, accuracy_m)
select
  '00000000-0000-4000-8000-000000000001', tr.id, sub.student_id, sub.id,
  case when tr.direction = 'inbound' then sub.stop_id end,
  (select id from seed_staff),
  tr.started_at + random() * least(interval '40 minutes', tr.ended_at - tr.started_at),
  case when tr.direction = 'inbound' then st.location else (select campus_location from public.schools where id = '00000000-0000-4000-8000-000000000001') end,
  round((5 + random() * 20)::numeric, 1)
from public.trips tr
join seed_staff_status t on t.id = tr.id
join public.profiles p on p.email like 'demo.student%' and p.role = 'student'
join public.subscriptions sub on sub.student_id = p.id and sub.status = 'approved'
  and sub.semester_id = (select id from public.semesters where school_id = '00000000-0000-4000-8000-000000000001' and tr.scheduled_start::date between start_date and end_date limit 1)
join public.stops st on st.id = sub.stop_id
where tr.status = 'completed'
  and (hashtext(p.id::text) % 7 + 7) % 7 = 3
  and t.h % 13 <> 0
  -- Decided per trip and student (a draw that only involves the trip is made once per trip, all or nothing).
  and abs(hashtext(tr.id::text || p.id::text)) % 100 < case when t.origin = 'field' then 25 else 35 + t.h % 60 end;
