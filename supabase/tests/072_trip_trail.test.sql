begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'rider@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'none@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'rider@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2026, current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Stop B', extensions.st_point(11.6, 3.86)::extensions.geography);
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status) values
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('10000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001', 'd2000000-0000-4000-8000-000000000001', 'approved');
insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'BUS-A', 40),
  ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'BUS-A2', 40);
-- f1 runs with five points along a street; f2 has ended.
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at, ended_at) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'active', now() - interval '30 minutes', now() - interval '30 minutes', null),
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', 'inbound', 'completed', now() - interval '3 hours', now() - interval '3 hours', now() - interval '2 hours');
insert into public.trip_positions (trip_id, school_id, location, recorded_at)
select 'f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
  extensions.st_point(11.50 + n * 0.002, 3.85 + (n % 2) * 0.002)::extensions.geography, now() - (5 - n) * interval '2 minutes'
from generate_series(0, 4) n;
insert into public.trip_positions (trip_id, school_id, location, recorded_at)
select 'f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001',
  extensions.st_point(11.50 + n * 0.002, 3.85)::extensions.geography, now() - interval '150 minutes' + n * interval '1 minute'
from generate_series(0, 4) n;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.trip_trail('f1000000-0000-4000-8000-000000000001') ->> 'type', 'LineString', 'a rider gets the trail of a running trip as a line');
select is(jsonb_array_length(public.trip_trail('f1000000-0000-4000-8000-000000000001') -> 'coordinates'), 5, 'through the points, in order');
select is((public.trip_trail('f1000000-0000-4000-8000-000000000001') -> 'coordinates' -> 0 ->> 0)::numeric, 11.5, 'starting where the trip started');
select is(public.trip_trail('f1000000-0000-4000-8000-000000000002'), null, 'nothing for a trip that has ended');
select is((select count(*)::int from public.trip_positions), 0, 'the history itself stays closed to students');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is(public.trip_trail('f1000000-0000-4000-8000-000000000001'), null, 'nothing for a student without a subscription');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.trip_trail('f1000000-0000-4000-8000-000000000001'), null, 'nothing for another school''s rider');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.trip_trail('f1000000-0000-4000-8000-000000000001') ->> 'type', 'LineString', 'staff get it too');
reset role;

select * from finish();
rollback;
