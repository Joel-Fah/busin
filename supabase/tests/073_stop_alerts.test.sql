begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

insert into public.schools (id, name, campus_location, campus_name) values
  ('10000000-0000-4000-8000-000000000001', 'School A', extensions.st_point(11.60, 3.90)::extensions.geography, 'Main campus');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 's1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 's2@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000003', 's3@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000004', 's4@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000005', 's5@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'driver@a.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30);
-- Stop A and stop B, about 1.1 km apart; the campus further on.
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-00000000000a', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.50, 3.85)::extensions.geography),
  ('d1000000-0000-4000-8000-00000000000b', '10000000-0000-4000-8000-000000000001', 'Stop B', extensions.st_point(11.51, 3.85)::extensions.geography);
-- s1 at A; s2 at A with stop alerts off; s3 at B; s4 at A, boards; s5 at A with "trip started" off (stop alerts on).
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status)
select ('b1000000-0000-4000-8000-00000000000' || n)::uuid, '10000000-0000-4000-8000-000000000001', ('a1000000-0000-4000-8000-00000000000' || n)::uuid,
  'c1000000-0000-4000-8000-000000000001', case when n = 3 then 'd1000000-0000-4000-8000-00000000000b'::uuid else 'd1000000-0000-4000-8000-00000000000a'::uuid end, 'approved'
from generate_series(1, 5) n;
-- Every day a riding day, so the test does not depend on the weekday.
insert into public.notification_preferences (user_id, school_id, riding_days, stop_alerts_on, trip_started_on)
select ('a1000000-0000-4000-8000-00000000000' || n)::uuid, '10000000-0000-4000-8000-000000000001', 127, n <> 2, n <> 5
from generate_series(1, 5) n;
insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'BUS-1', 40),
  ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'BUS-2', 40),
  ('e1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'BUS-3', 40);
insert into public.trips (id, school_id, bus_id, driver_id, direction, status, scheduled_start) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', 'inbound', 'scheduled', now()),
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', null, 'inbound', 'scheduled', now()),
  ('f1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000003', null, 'outbound', 'scheduled', now());

create temporary view sent as
  select kind, string_agg(right(user_id::text, 1), ',' order by user_id) as who
  from private.notification_outbox
  where school_id = '10000000-0000-4000-8000-000000000001'
  group by kind;
grant select on sent to public;

-- ---------------------------------------------------------------- a trip starts
update public.trips set status = 'active', started_at = now() where id = 'f1000000-0000-4000-8000-000000000001';
select is((select who from sent where kind = 'trip_started'), '1,2,3,4', 'a trip to school starting tells the day''s riders, not those who turned it off');
update public.trips set status = 'active', started_at = now() where id = 'f1000000-0000-4000-8000-000000000002';
select is((select count(*)::int from private.notification_outbox where kind = 'trip_started'), 4, 'a second bus the same day says nothing more');
update public.trips set status = 'active', started_at = now() where id = 'f1000000-0000-4000-8000-000000000003';
select is((select count(*)::int from private.notification_outbox where kind = 'trip_started'), 4, 'nor does a trip leaving school');
update public.trips set status = 'active' where id = 'f1000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox where kind = 'trip_started'), 4, 'saving a running trip again is not a start');

-- s4 boards at stop A before the bus is seen there.
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by)
values ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000004',
  'b1000000-0000-4000-8000-000000000004', 'd1000000-0000-4000-8000-00000000000a', 'a2000000-0000-4000-8000-000000000001');

-- ---------------------------------------------------------------- the bus at and leaving stop A
insert into public.live_positions (bus_id, school_id, trip_id, location)
values ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', extensions.st_point(11.5003, 3.85)::extensions.geography);
select is((select who from sent where kind = 'bus_at_stop'), '1,5', 'at stop A: its waiting students with stop alerts on, not one already on board');
update public.live_positions set location = extensions.st_point(11.5004, 3.85)::extensions.geography where bus_id = 'e1000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox where kind = 'bus_at_stop'), 2, 'said once per trip and stop');
select is((select count(*)::int from private.notification_outbox where kind = 'bus_left_stop'), 0, 'still at the stop: not left');

update public.live_positions set location = extensions.st_point(11.503, 3.85)::extensions.geography where bus_id = 'e1000000-0000-4000-8000-000000000001';
select is((select who from sent where kind = 'bus_left_stop'), '1,5', 'over 150 m away: the stop''s waiting students hear it left');
update public.live_positions set location = extensions.st_point(11.504, 3.85)::extensions.geography where bus_id = 'e1000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox where kind = 'bus_left_stop'), 2, 'once');

update public.live_positions set location = extensions.st_point(11.5101, 3.85)::extensions.geography where bus_id = 'e1000000-0000-4000-8000-000000000001';
select is((select who from sent where kind = 'bus_at_stop'), '1,3,5', 'then stop B''s student');

-- ---------------------------------------------------------------- another bus, a trip leaving school
insert into public.live_positions (bus_id, school_id, trip_id, location)
values ('e1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000003', extensions.st_point(11.50, 3.85)::extensions.geography);
select is((select count(*)::int from private.notification_outbox where kind = 'bus_at_stop'), 3, 'a trip leaving school sends no stop alerts');
insert into public.live_positions (bus_id, school_id, trip_id, location)
values ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000002', extensions.st_point(11.50, 3.85)::extensions.geography);
select is((select count(*)::int from private.notification_outbox where kind = 'bus_at_stop' and ref_id = 'f1000000-0000-4000-8000-000000000002'), 2,
  'another bus going to school reaching stop A tells its waiting students too, not s4 who is on the first one');

-- ---------------------------------------------------------------- the campus
update public.live_positions set location = extensions.st_point(11.6005, 3.90)::extensions.geography where bus_id = 'e1000000-0000-4000-8000-000000000001';
select is((select who from sent where kind = 'bus_at_campus'), '4', 'at the campus: a welcome to those on board');
select is((select who from sent where kind = 'trip_at_campus'), '1', 'and the crew is offered to end the trip');
update public.live_positions set location = extensions.st_point(11.6006, 3.90)::extensions.geography where bus_id = 'e1000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox where kind in ('bus_at_campus', 'trip_at_campus')), 2, 'once per trip');

-- ---------------------------------------------------------------- the settings
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select stop_alerts_on from public.my_notification_preferences()), false, 'a student reads the new settings');
select lives_ok($$select public.set_notification_preferences(127::smallint, true, '06:30', false, '16:30', true, 5::smallint, true)$$,
  'an app that does not know the new settings can still save');
select is((select (trip_started_on, stop_alerts_on)::text from public.my_notification_preferences()), '(t,f)', 'and leaves them as they were');
reset role;

select * from finish();
rollback;
