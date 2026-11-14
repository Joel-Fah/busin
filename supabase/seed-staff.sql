-- A realistic schedule for ONE staff account, for LOCAL development only. Run it with: npm run seed:staff -- <email>
--
-- Gives the staff member trips on their own demo bus (DEMO-107, so they never clash with the demo drivers):
--   * the last two weeks of weekdays, as driver in the morning and sometimes as assistant in the afternoon, with
--     boardings by demo students, and one cancelled trip (their History and Stats);
--   * today: a trip as driver that starts in about 20 minutes (to start and scan) and one as assistant later;
--   * the next four weekdays: scheduled trips.
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
-- Mornings to campus as the driver (a demo driver assists every other day); afternoons home as the assistant of a demo
-- driver on Tuesdays and Thursdays. Times are Douala wall-clock times.
create temp table seed_staff_trips on commit drop as
select
  md5('seed-staff:' || s.id || ':' || g.d || ':' || v.dir)::uuid as id,
  case when v.dir = 'inbound' then s.id else (select id from public.profiles where email = 'demo.driver1@ictuniversity.edu.cm') end as driver_id,
  case when v.dir = 'inbound' then (case when extract(day from g.d)::int % 2 = 0 then (select id from public.profiles where email = 'demo.driver2@ictuniversity.edu.cm') end) else s.id end as assistant_id,
  v.dir::public.trip_direction as direction,
  g.d as day,
  ((g.d + case when v.dir = 'inbound' then time '06:45' else time '16:45' end)::timestamp at time zone 'Africa/Douala') as scheduled_start
from seed_staff s
cross join (select generate_series(current_date - 14, current_date + 6, interval '1 day')::date as d) g
cross join (values ('inbound'), ('outbound')) v(dir)
where extract(isodow from g.d) < 6
  and g.d <> current_date
  and (v.dir = 'inbound' or extract(isodow from g.d) in (2, 4));

-- Today, whatever the hour: one to start soon as the driver, one later as the assistant.
insert into seed_staff_trips
select md5('seed-staff:' || s.id || ':today-soon')::uuid, s.id, (select id from public.profiles where email = 'demo.driver2@ictuniversity.edu.cm'),
       'inbound'::public.trip_direction, current_date, date_trunc('minute', now()) + interval '20 minutes'
from seed_staff s
union all
select md5('seed-staff:' || s.id || ':today-later')::uuid, (select id from public.profiles where email = 'demo.driver1@ictuniversity.edu.cm'), s.id,
       'outbound'::public.trip_direction, current_date, date_trunc('minute', now()) + interval '3 hours'
from seed_staff s;

insert into public.trips (id, school_id, bus_id, driver_id, assistant_id, direction, status, scheduled_start, started_at, ended_at, started_by, archived_at)
select
  t.id, '00000000-0000-4000-8000-000000000001', 'de200000-0000-4000-8000-000000000007', t.driver_id, t.assistant_id, t.direction,
  st.status::public.trip_status, t.scheduled_start,
  case when st.status = 'completed' then t.scheduled_start + (hashtext(t.id::text) % 9 + 1) * interval '1 minute' end,
  case when st.status = 'completed' then t.scheduled_start + interval '55 minutes' end,
  case when st.status = 'completed' then t.driver_id end,
  case when st.status in ('completed', 'cancelled') and t.day < current_date - 7 then t.scheduled_start + interval '1 day' end
from seed_staff_trips t
cross join lateral (
  select case
    -- One morning last week was cancelled (a breakdown): the Wednesday in the seven days before last week's end.
    when t.direction = 'inbound' and t.day = (select max(d) from generate_series(current_date - 12, current_date - 6, interval '1 day') d where extract(isodow from d) = 3)::date then 'cancelled'
    when t.scheduled_start + interval '60 minutes' < now() then 'completed'
    else 'scheduled' end as status
) st;

-- ---------------------------------------------------------------- boardings
-- About thirty demo students ride this bus; most board each finished trip, in the first forty minutes. Mornings at their
-- stop, afternoons at the campus.
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by, scanned_at, location, accuracy_m)
select
  '00000000-0000-4000-8000-000000000001', tr.id, sub.student_id, sub.id,
  case when tr.direction = 'inbound' then sub.stop_id end,
  (select id from seed_staff),
  tr.started_at + random() * interval '40 minutes',
  case when tr.direction = 'inbound' then st.location else (select campus_location from public.schools where id = '00000000-0000-4000-8000-000000000001') end,
  round((5 + random() * 20)::numeric, 1)
from public.trips tr
join seed_staff_trips t on t.id = tr.id
join public.profiles p on p.email like 'demo.student%' and p.role = 'student'
join public.subscriptions sub on sub.student_id = p.id and sub.status = 'approved'
  and sub.semester_id = (select id from public.semesters where school_id = '00000000-0000-4000-8000-000000000001' and tr.scheduled_start::date between start_date and end_date limit 1)
join public.stops st on st.id = sub.stop_id
where tr.status = 'completed'
  and (hashtext(p.id::text) % 10 + 10) % 10 = 3
  and random() < 0.8;
