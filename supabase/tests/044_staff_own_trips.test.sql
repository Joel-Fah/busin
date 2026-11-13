begin;
create extension if not exists pgtap with schema extensions;
select plan(29);

insert into public.schools (id, name, timezone) values ('10000000-0000-4000-8000-000000000001', 'School A', 'Africa/Douala'), ('10000000-0000-4000-8000-000000000002', 'School B', 'Africa/Douala');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a2000000-0000-4000-8000-000000000001', 'sam@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000002', 'tess@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('b2000000-0000-4000-8000-000000000001', 'staff@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id in ('a2000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002', 'b2000000-0000-4000-8000-000000000001');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';

insert into public.buses (id, school_id, plate, capacity, name) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50, 'Blue'),
  ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'A-2', 50, null);
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', extract(year from current_date)::int, current_date - 60, current_date + 60);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('11000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('11000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved');

-- Sam (a2..01) and Tess (a2..02) are staff. Times are relative to now; every trip is within the last 12 weeks.
insert into public.trips (id, school_id, bus_id, driver_id, assistant_id, direction, status, origin, scheduled_start, started_at, ended_at, started_by, created_by) values
  -- Sam drives, Tess assists; started 5 minutes late (on time), 60 minutes on the road.
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002',
   'inbound', 'completed', 'scheduled', now() - interval '14 days', now() - interval '14 days' + interval '5 minutes', now() - interval '14 days' + interval '65 minutes', 'a2000000-0000-4000-8000-000000000001', null),
  -- Sam alone; 20 minutes late, 30 minutes on the road.
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-000000000001', null,
   'outbound', 'completed', 'scheduled', now() - interval '7 days', now() - interval '7 days' + interval '20 minutes', now() - interval '7 days' + interval '50 minutes', 'a2000000-0000-4000-8000-000000000001', null),
  -- Tess only.
  ('f1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-000000000002', null,
   'inbound', 'completed', 'scheduled', now() - interval '6 days', now() - interval '6 days', now() - interval '6 days' + interval '40 minutes', 'a2000000-0000-4000-8000-000000000002', null),
  -- Nobody assigned, today.
  ('f1000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', null, null,
   'inbound', 'scheduled', 'scheduled', now() + interval '1 minute', null, null, null, null),
  -- Sam started it in the field: 45 minutes, no schedule to be late on.
  ('f1000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', null,
   'outbound', 'completed', 'field', now() - interval '3 days', now() - interval '3 days', now() - interval '3 days' + interval '45 minutes', 'a2000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001'),
  -- Sam's, cancelled.
  ('f1000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', null,
   'inbound', 'cancelled', 'scheduled', now() - interval '8 days', null, null, null, null),
  -- Sam's, never started (missed).
  ('f1000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', null,
   'outbound', 'scheduled', 'scheduled', now() - interval '2 days', null, null, null, null),
  -- Sam's, tomorrow: not history, not stats.
  ('f1000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', null,
   'inbound', 'scheduled', 'scheduled', now() + interval '1 day', null, null, null, null);

-- Two students boarded Sam and Tess's trip (loaded by the database, not checked).
insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by, scanned_at) values
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', now() - interval '14 days' + interval '10 minutes'),
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', '11000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-000000000001', now() - interval '14 days' + interval '12 minutes');

-- ---------------------------------------------------------------- who reads which trips
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.trips), 6, 'a staff member reads only the trips they are on');
select is((select count(*)::int from public.trips where id in ('f1000000-0000-4000-8000-000000000003', 'f1000000-0000-4000-8000-000000000004')), 0,
  'not a colleague''s, and not one nobody is assigned to');
select throws_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000004')$$, '42501', null, 'nor start one nobody is assigned to');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select count(*)::int from public.trips), 2, 'the assistant reads the trip they assist on, and their own');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.trips), 8, 'an administrator reads the whole school');
select lives_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000004')$$, 'and runs a trip nobody is assigned to');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.trips), 8, 'students still read the trips of their school (they follow the buses)');
select throws_ok($$select * from public.my_trip_history(now(), 20)$$, '42501', null, 'but have no trip history');
select throws_ok($$select * from public.my_trip_stats(12)$$, '42501', null, 'nor trip stats');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.trips), 0, 'staff of another school read none');
reset role;

-- ---------------------------------------------------------------- history
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select array_agg(id::text order by scheduled_start desc) from public.my_trip_history(now(), 20)),
  array['f1000000-0000-4000-8000-000000000007', 'f1000000-0000-4000-8000-000000000005', 'f1000000-0000-4000-8000-000000000002',
        'f1000000-0000-4000-8000-000000000006', 'f1000000-0000-4000-8000-000000000001'],
  'the history is their past trips, newest first, without tomorrow''s');
select is((select count(*)::int from public.my_trip_history(now() + interval '30 days', 20)), 5, 'a cursor in the future does not bring upcoming trips');
select is((select array_agg(id::text) from public.my_trip_history(now() - interval '7 days' - interval '1 second', 2)),
  array['f1000000-0000-4000-8000-000000000006', 'f1000000-0000-4000-8000-000000000001'], 'and it pages from the cursor');
select is((select bus_label || ':' || my_role || ':' || boarded from public.my_trip_history(now(), 20) where id = 'f1000000-0000-4000-8000-000000000001'),
  'Blue:driver:2', 'each with the bus name, their role and how many boarded');
select is((select bus_label from public.my_trip_history(now(), 20) where id = 'f1000000-0000-4000-8000-000000000002'), 'A-2', 'a bus without a name shows its plate');
select throws_ok($$select * from public.my_trip_history(now(), 51)$$, '22023', 'invalid_limit', 'a page is at most 50');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select my_role from public.my_trip_history(now(), 20) where id = 'f1000000-0000-4000-8000-000000000001'), 'assistant', 'the assistant sees the trip as assistant');
reset role;

-- ---------------------------------------------------------------- weekly stats
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.my_trip_stats(12)), 12, 'one row per week, empty weeks included');
select is((select bool_and(extract(isodow from week_start) = 1) from public.my_trip_stats(12)), true, 'weeks start on Monday');
select is((select row(sum(trips), sum(completed), sum(cancelled), sum(missed), sum(field_trips))::text from public.my_trip_stats(12)), row(5, 3, 1, 1, 1)::text,
  'trips, completed, cancelled, missed and started in the field (tomorrow''s not counted)');
select is((select row(sum(on_time), sum(late))::text from public.my_trip_stats(12)), row(1, 1)::text,
  'on time within 10 minutes; the field trip has no schedule to be late on');
select is((select row(sum(boarded), sum(minutes_on_road), sum(as_driver), sum(as_assistant))::text from public.my_trip_stats(12)), row(2, 135, 5, 0)::text,
  'students boarded, minutes on the road, as driver and as assistant');
select is((select max(avg_delay_minutes) from public.my_trip_stats(12)), 20.0, 'the week of the late start shows its delay');
select throws_ok($$select * from public.my_trip_stats(27)$$, '22023', 'invalid_weeks', 'at most 26 weeks');
reset role;

-- ---------------------------------------------------------------- scans and the boarding list
-- Tess scanning on Sam's own trip: refused, whatever the way in.
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by) values
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002')$$,
  '42501', 'not_trip_crew', 'a staff member cannot record a scan on a trip they are not on');
select lives_ok($$insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by) values
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000003', 'a1000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002')$$,
  'but can on their own');
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by) values
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000002', '11000000-0000-4000-8000-000000000002', 'a3000000-0000-4000-8000-000000000001')$$,
  'an administrator can on any trip of the school');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select * from public.trip_manifest('f1000000-0000-4000-8000-000000000002')$$, 'P0002', 'Trip not found', 'nor read the boarding list of a trip they are not on');
select is((select count(*)::int from public.trip_manifest('f1000000-0000-4000-8000-000000000001')), 2, 'the assistant reads the boarding list of their trip');
reset role;

select * from finish();
rollback;
