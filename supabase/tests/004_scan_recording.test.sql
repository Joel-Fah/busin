begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'ok@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'nosub@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000003', 'susp@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000004', 'old@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000005', 'geo@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('b2000000-0000-4000-8000-000000000001', 'staff@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id in
  ('a2000000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000001');
update public.profiles set status = 'suspended' where id = 'a1000000-0000-4000-8000-000000000003';

-- One semester that includes today and one that ended yesterday.
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2030,
   current_date - 30, current_date + 30),
  ('c1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'spring', 2030,
   current_date - 200, current_date - 1);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Stop B', extensions.st_point(11.6, 3.86)::extensions.geography);
insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50),
  ('e2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'B-1', 50);
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   'e1000000-0000-4000-8000-000000000001', 'inbound', 'active', now(), now()),
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001',
   'e1000000-0000-4000-8000-000000000001', 'outbound', 'scheduled', now(), null),
  ('f2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002',
   'e2000000-0000-4000-8000-000000000001', 'inbound', 'active', now(), now());
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status) values
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001',
   'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000003',
   'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000004',
   'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000005',
   'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved');

-- The internal function is called as the database owner with the caller identity set,
-- the way the public QR wrapper will call it.
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is(
  (private.record_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001'))
    ->> 'valid',
  'true', 'a verified student with an approved subscription is accepted');
select is((select count(*)::int from public.scans), 1, 'the scan is recorded');
select is(
  (private.record_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001'))
    ->> 'duplicate',
  'true', 'a repeat scan on the same trip is flagged as a duplicate');
select is((select count(*)::int from public.scans), 1, 'a repeat scan does not create another row');

select is(
  (private.record_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002'))
    ->> 'reason',
  'no_active_subscription', 'a student without a subscription is refused');
select is(
  (private.record_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000003'))
    ->> 'reason',
  'account_not_verified', 'a suspended student is refused');
select is(
  (private.record_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000004'))
    ->> 'reason',
  'no_active_subscription', 'a subscription from a finished semester is refused');
select is(
  (private.record_scan('f1000000-0000-4000-8000-000000000001', 'a9000000-0000-4000-8000-000000000009'))
    ->> 'reason',
  'student_not_found', 'an unknown id is refused');
select is(
  (private.record_scan('f1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001'))
    ->> 'reason',
  'student_not_found', 'a staff account is not a boarding student');

select throws_ok(
  $$select private.record_scan('f1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000001')$$,
  '55000', 'The trip is not active', 'scanning on a trip that has not started is refused');
select throws_ok(
  $$select private.record_scan('f2000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001')$$,
  'P0002', 'Trip not found', 'staff cannot scan on another school trip');
select throws_ok(
  $$select private.record_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000005', 'd2000000-0000-4000-8000-000000000001')$$,
  'P0002', 'Stop not found', 'staff cannot use a stop of another school');
select throws_ok(
  $$select private.record_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000005', null, 100, 11.5)$$,
  '22023', 'Coordinates are out of range', 'impossible coordinates are refused');
select throws_ok(
  $$select private.record_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000005', null, 3.85, null)$$,
  '22023', 'Latitude and longitude must be given together', 'half a coordinate pair is refused');

select lives_ok(
  $$select private.record_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000005',
      'd1000000-0000-4000-8000-000000000001', 3.85, 11.5, 12)$$,
  'a scan with a stop and location is accepted');
select is(
  (select round(extensions.st_y(location::extensions.geometry)::numeric, 2)
     from public.scans where student_id = 'a1000000-0000-4000-8000-000000000005'),
  3.85, 'the boarding location is stored');
select is(
  (select stop_id from public.scans where student_id = 'a1000000-0000-4000-8000-000000000005'),
  'd1000000-0000-4000-8000-000000000001'::uuid, 'the boarding stop is stored');

-- A student caller is refused.
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select private.record_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001')$$,
  '42501', 'Staff access required', 'a student cannot record scans');

select * from finish();
rollback;
