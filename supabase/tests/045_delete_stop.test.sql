begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A'), ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

insert into public.stops (id, school_id, name, location) values
  -- never used
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Fresh', extensions.st_point(11.50, 3.85)::extensions.geography),
  -- a subscription that was rejected
  ('d1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Asked once', extensions.st_point(11.51, 3.85)::extensions.geography),
  -- a boarding was scanned there
  ('d1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'Boarded', extensions.st_point(11.52, 3.85)::extensions.geography),
  -- on a bus route, never used
  ('d1000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'On a route', extensions.st_point(11.53, 3.85)::extensions.geography);
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', extract(year from current_date)::int, current_date - 30, current_date + 30);
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('11000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000002', 'rejected'),
  ('11000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000004', 'approved');
-- The approved subscription moves off "On a route" so that stop is unused; the scan records "Boarded".
update public.subscriptions set stop_id = 'd1000000-0000-4000-8000-000000000002' where id = '11000000-0000-4000-8000-000000000002';
insert into public.buses (id, school_id, plate, capacity) values ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50);
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'completed', now() - interval '1 day', now() - interval '1 day');
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by) values
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000003', 'a2000000-0000-4000-8000-000000000001');
insert into public.routes (id, school_id, name) values ('aa000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Morning');
insert into public.route_stops (route_id, stop_id, school_id, position) values
  ('aa000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 0);

-- ---------------------------------------------------------------- what the admin sees
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select subscriptions || ':' || boardings from public.admin_stop_history() where stop_id = 'd1000000-0000-4000-8000-000000000002'), '2:0',
  'the history counts subscriptions in any state');
select is((select subscriptions || ':' || boardings from public.admin_stop_history() where stop_id = 'd1000000-0000-4000-8000-000000000003'), '0:1', 'and boardings');
select is((select count(*)::int from public.admin_stop_history() where stop_id in ('d1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000004')), 0,
  'an unused stop is not in it');

-- ---------------------------------------------------------------- deleting
select throws_ok($$delete from public.stops where id = 'd1000000-0000-4000-8000-000000000001'$$, '42501', null, 'a stop is not deleted directly, only through the checked function');
select lives_ok($$select public.admin_delete_stop('d1000000-0000-4000-8000-000000000001')$$, 'a stop nothing ever used is deleted');
select throws_ok($$select public.admin_delete_stop('d1000000-0000-4000-8000-000000000002')$$, '55000', 'stop_in_use', 'one a subscription used is kept, even a rejected one');
select throws_ok($$select public.admin_delete_stop('d1000000-0000-4000-8000-000000000003')$$, '55000', 'stop_in_use', 'and one where someone boarded');
select lives_ok($$select public.admin_delete_stop('d1000000-0000-4000-8000-000000000004')$$, 'a stop on a bus route but never used is deleted');
select throws_ok($$select public.admin_delete_stop('d1000000-0000-4000-8000-000000000001')$$, 'P0002', 'Stop not found', 'deleting twice says it is gone');
reset role;

select is((select count(*)::int from public.stops where id in ('d1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000004')), 0, 'both are gone');
select is((select count(*)::int from public.route_stops where stop_id = 'd1000000-0000-4000-8000-000000000004'), 0, 'and it left the bus route');
select is((select count(*)::int from public.audit_log where action = 'stop.deleted' and created_at = now()), 2, 'each delete is audited');

-- ---------------------------------------------------------------- who may
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_delete_stop('d1000000-0000-4000-8000-000000000002')$$, '42501', null, 'staff cannot delete a stop');
select throws_ok($$select * from public.admin_stop_history()$$, '42501', null, 'nor read the history');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_delete_stop('d1000000-0000-4000-8000-000000000002')$$, 'P0002', 'Stop not found', 'another school''s administrator does not find it');
reset role;

select * from finish();
rollback;
