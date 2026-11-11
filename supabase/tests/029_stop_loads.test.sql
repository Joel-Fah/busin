begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A'), ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 's1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 's2@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000003', 's3@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 's1@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2030, current_date - 30, current_date + 30),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2030, current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop X', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Stop Y', extensions.st_point(11.51, 3.86)::extensions.geography),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Stop Z', extensions.st_point(11.52, 3.87)::extensions.geography);
insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 10),
  ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'A-2', 40),
  ('e2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'B-1', 20);
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at, ended_at) values
  ('f1000000-0000-4000-8000-000000000000', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'completed', now() - interval '10 days', now() - interval '10 days', now() - interval '10 days'),
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'completed', now() - interval '2 days', now() - interval '2 days', now() - interval '2 days'),
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', 'inbound', 'completed', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day'),
  ('f1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', 'inbound', 'cancelled', now() - interval '1 day', null, null),
  ('f2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'e2000000-0000-4000-8000-000000000001', 'inbound', 'completed', now() - interval '1 day', now() - interval '1 day', now() - interval '1 day');

insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('51000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('51000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('51000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000003', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000002', 'approved'),
  ('52000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001', 'd2000000-0000-4000-8000-000000000001', 'approved');

-- scans(trip, student, subscription, stop); scanned_by the staff member of the school
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by)
select '10000000-0000-4000-8000-000000000001', v.trip::uuid, v.student::uuid, v.sub::uuid, v.stop::uuid, 'a2000000-0000-4000-8000-000000000001'
from (values
  ('f1000000-0000-4000-8000-000000000000', 'a1000000-0000-4000-8000-000000000003', '51000000-0000-4000-8000-000000000003', 'd1000000-0000-4000-8000-000000000002'),
  ('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', '51000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001'),
  ('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', '51000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001'),
  ('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000003', '51000000-0000-4000-8000-000000000003', 'd1000000-0000-4000-8000-000000000002'),
  ('f1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000001', '51000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001'),
  ('f1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000002', '51000000-0000-4000-8000-000000000002', null),
  ('f1000000-0000-4000-8000-000000000003', 'a1000000-0000-4000-8000-000000000002', '51000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001')
) as v(trip, student, sub, stop);
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by) values
  ('10000000-0000-4000-8000-000000000002', 'f2000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', '52000000-0000-4000-8000-000000000001',
   'd2000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

-- ---------------------------------------------------------------- the nightly count
select is((select count(*)::int from cron.job where jobname = 'busin-stop-loads'), 1, 'the count runs every night');
select is(private.refresh_stop_loads(null, '10000000-0000-4000-8000-000000000001'), 4, 'everything recorded is counted');
select is(private.refresh_stop_loads(null, '10000000-0000-4000-8000-000000000002'), 1, 'one school at a time');
select is((select count(*)::int from private.stop_trip_loads where trip_id = 'f1000000-0000-4000-8000-000000000003'), 0, 'a cancelled trip does not count');
select is((select sum(boardings)::int from private.stop_trip_loads where trip_id = 'f1000000-0000-4000-8000-000000000002'), 1, 'a scan with no stop does not count');

-- A scan synced late is picked up by the next night's recount, which leaves older days alone.
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by) values
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000003', '51000000-0000-4000-8000-000000000003',
   'd1000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-000000000001');
select is(private.refresh_stop_loads(now() - interval '3 days', '10000000-0000-4000-8000-000000000001'), 4, 'the recent days are recounted');
select is((select count(*)::int from private.stop_trip_loads where trip_id = 'f1000000-0000-4000-8000-000000000000'), 1, 'older days are kept');

-- ---------------------------------------------------------------- what the admin sees
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select results_eq(
  $$select stop_id::text, departures, boardings, peak, round(load::numeric, 4), round(peak_load::numeric, 4) from public.admin_stop_loads()$$,
  $$values ('d1000000-0000-4000-8000-000000000001', 2, 3, 2, 0.1125, 0.2000), ('d1000000-0000-4000-8000-000000000002', 3, 3, 1, 0.0750, 0.1000)$$,
  'per stop: departures, boardings, peak and the share of the seats, fullest first');
select is((select departures from public.admin_stop_loads(7) where stop_id = 'd1000000-0000-4000-8000-000000000002'), 2, 'the window leaves older departures out');
select is((select count(*)::int from public.admin_stop_loads() where stop_id = 'd2000000-0000-4000-8000-000000000001'), 0, 'another school''s stops never show');
select throws_ok($$select * from private.stop_trip_loads$$, '42501', null, 'the table itself is closed');
select isnt(public.admin_refresh_stop_loads(), null, 'an admin can refresh their school');
select throws_ok($$select public.admin_refresh_stop_loads()$$, 'PT429', null, 'but not twice in five minutes');
reset role;
select is((select count(*)::int from public.audit_log where action = 'insights.refreshed'), 1, 'the refresh is audited');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.admin_stop_loads()$$, '42501', null, 'staff do not see the insights');
select throws_ok($$select public.admin_refresh_stop_loads()$$, '42501', null, 'nor refresh them');
reset role;

set local role anon;
select throws_ok($$select * from public.admin_stop_loads()$$, '42501', null, 'anonymous visitors cannot call it');
reset role;

select * from finish();
rollback;
