begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into public.schools (id, name, timezone) values ('10000000-0000-4000-8000-000000000001', 'School A', 'UTC');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'near@a.edu', '{"provider":"google"}', '{"full_name":"Near One"}'),
  ('a1000000-0000-4000-8000-000000000002', 'off@a.edu', '{"provider":"google"}', '{"full_name":"Turned Off"}'),
  ('a1000000-0000-4000-8000-000000000003', 'far@a.edu', '{"provider":"google"}', '{"full_name":"Far Away"}'),
  ('a1000000-0000-4000-8000-000000000004', 'aboard@a.edu', '{"provider":"google"}', '{"full_name":"Already Aboard"}'),
  ('a1000000-0000-4000-8000-000000000005', 'rest@a.edu', '{"provider":"google"}', '{"full_name":"Rest Day"}'),
  ('a1000000-0000-4000-8000-000000000006', 'pending@a.edu', '{"provider":"google"}', '{"full_name":"Still Pending"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}', '{}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30);
-- The bus is at (11.5, 3.85). The near stop is about 200 m away, the far one about 5 km.
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Near', extensions.st_point(11.5, 3.8518)::extensions.geography),
  ('d1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Far', extensions.st_point(11.5, 3.895)::extensions.geography);
insert into public.buses (id, school_id, plate, capacity) values
  ('b0000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'LT 1', 50),
  ('b0000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'LT 2', 50),
  ('b0000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'LT 3', 50);
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001', 'inbound', 'active', now()),
  ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000002', 'outbound', 'active', now()),
  ('e1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000003', 'inbound', 'scheduled', now());

insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status)
select gen_random_uuid(), '10000000-0000-4000-8000-000000000001', u, 'c1000000-0000-4000-8000-000000000001', stop, st::public.subscription_status
from (values
  ('a1000000-0000-4000-8000-000000000001'::uuid, 'd1000000-0000-4000-8000-000000000001'::uuid, 'approved'),
  ('a1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('a1000000-0000-4000-8000-000000000003', 'd1000000-0000-4000-8000-000000000002', 'approved'),
  ('a1000000-0000-4000-8000-000000000004', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('a1000000-0000-4000-8000-000000000005', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('a1000000-0000-4000-8000-000000000006', 'd1000000-0000-4000-8000-000000000001', 'pending')
) v(u, stop, st);

-- Every day is a riding day, except today for the rest-day student; one student turned the alert off.
insert into public.notification_preferences (user_id, school_id, riding_days, bus_near_on)
select p.id, '10000000-0000-4000-8000-000000000001',
  case when p.id = 'a1000000-0000-4000-8000-000000000005' then 127 & ~(1 << (extract(isodow from (now() at time zone 'UTC')::date)::int - 1)) else 127 end,
  p.id <> 'a1000000-0000-4000-8000-000000000002'
from public.profiles p where p.school_id = '10000000-0000-4000-8000-000000000001' and p.role = 'student';

insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by, scanned_at)
select s.school_id, 'e1000000-0000-4000-8000-000000000001', s.student_id, s.id, 'a2000000-0000-4000-8000-000000000001', now()
from public.subscriptions s where s.student_id = 'a1000000-0000-4000-8000-000000000004';

create temp view near_sent as
  select user_id, ref_id from private.notification_outbox where kind = 'bus_near_stop' and school_id = '10000000-0000-4000-8000-000000000001';

select is(private.bus_near_reach_m(null, 5), 1650::double precision, 'no speed: a town pace of 5.5 m/s');
select is(private.bus_near_reach_m(0.1, 1), 300::double precision, 'never under 300 m');
select is(private.bus_near_reach_m(30, 30), 15000::double precision, 'never over 15 km');

-- The inbound bus that is under way reports its position, without a speed.
insert into public.live_positions (bus_id, school_id, trip_id, location)
values ('b0000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', extensions.st_point(11.5, 3.85)::extensions.geography);
select results_eq('select user_id from near_sent', $$values ('a1000000-0000-4000-8000-000000000001'::uuid)$$,
  'only the student waiting near the bus is told (not turned off, scanned, resting, pending or far)');
select is((select ref_id from near_sent), 'e1000000-0000-4000-8000-000000000001'::uuid, 'the push points at the trip');

update public.live_positions set location = extensions.st_point(11.5, 3.8501)::extensions.geography where bus_id = 'b0000000-0000-4000-8000-000000000001';
select is((select count(*)::int from near_sent), 1, 'once per trip and student');

-- Faster: the far stop is now within five minutes.
update public.live_positions set location = extensions.st_point(11.5, 3.8502)::extensions.geography, speed_mps = 20 where bus_id = 'b0000000-0000-4000-8000-000000000001';
select ok(exists (select 1 from near_sent where user_id = 'a1000000-0000-4000-8000-000000000003'), 'a fast bus reaches further');

insert into public.live_positions (bus_id, school_id, trip_id, location) values
  ('b0000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('b0000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000003', extensions.st_point(11.5, 3.85)::extensions.geography);
select is((select count(*)::int from near_sent where ref_id <> 'e1000000-0000-4000-8000-000000000001'), 0,
  'a bus heading away from the stops, or a trip not under way, tells no one');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok('select count(*) from private.bus_near_sent', '42501', null, 'students cannot read who was told');
select throws_ok($$select private.bus_near_reach_m(1, 1)$$, '42501', null, 'nor call the internal functions');
reset role;

select * from finish();
rollback;
