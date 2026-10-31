begin;
create extension if not exists pgtap with schema extensions;
select plan(35);

-- Fixtures (created as the database owner, which bypasses RLS).
insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');

insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a4000000-0000-4000-8000-000000000001', 'susp@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'stu@b.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');

update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';
update public.profiles set role = 'admin' where id = 'b3000000-0000-4000-8000-000000000001';
update public.profiles set status = 'suspended' where id = 'a4000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, '2026-09-01', '2027-01-31'),
  ('c1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'spring', 2027, '2027-02-01', '2027-06-30'),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2026, '2026-09-01', '2027-01-31');
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Stop B', extensions.st_point(11.6, 3.86)::extensions.geography);
insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50);
insert into public.trips (id, school_id, bus_id, direction, scheduled_start) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   'e1000000-0000-4000-8000-000000000001', 'inbound', now());
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('11000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001',
   'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('11000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002',
   'b1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001',
   'd2000000-0000-4000-8000-000000000001', 'approved');
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by) values
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001',
   'a1000000-0000-4000-8000-000000000002', '11000000-0000-4000-8000-000000000001',
   'd1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001');
insert into public.live_positions (bus_id, school_id, location) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.audit_log (school_id, action, target_type) values
  ('10000000-0000-4000-8000-000000000001', 'test', 'test'),
  ('10000000-0000-4000-8000-000000000002', 'test', 'test');

-- ---------------------------------------------------------------- student A1
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is((select count(*)::int from public.profiles), 1, 'student reads only their own profile');
select is((select count(*)::int from public.subscriptions), 0, 'student cannot read another student subscription');
select is((select count(*)::int from public.stops), 1, 'student reads stops of their school only');
select is((select count(*)::int from public.schools), 1, 'student reads only their own school');
select is((select count(*)::int from public.scans), 0, 'student cannot read another student scans');
select is((select count(*)::int from public.live_positions), 1, 'student reads live positions of their school');
select is((select count(*)::int from public.audit_log), 0, 'student cannot read the audit log');

select lives_ok(
  $$update public.profiles set full_name = 'Student One' where id = 'a1000000-0000-4000-8000-000000000001'$$,
  'student can edit their own name');
select throws_ok(
  $$update public.profiles set role = 'admin' where id = 'a1000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'student cannot change their own role');
select throws_ok(
  $$update public.profiles set status = 'verified' where id = 'a1000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'student cannot change their own status');
select throws_ok(
  $$update public.profiles set school_id = '10000000-0000-4000-8000-000000000002' where id = 'a1000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'student cannot change their own school');
select lives_ok(
  $$update public.profiles set full_name = 'Hijacked' where id = 'a1000000-0000-4000-8000-000000000002'$$,
  'editing someone else matches no rows');
select throws_ok(
  $$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000001', 'X', extensions.st_point(1, 1)::extensions.geography)$$,
  '42501', null, 'student cannot create a stop');

select lives_ok(
  $$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path)
    values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001',
            'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001',
            '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/proof.jpg')$$,
  'student can request a subscription for themselves');
select throws_ok(
  $$insert into public.subscriptions (school_id, student_id, semester_id, stop_id)
    values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001',
            'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001')$$,
  '23505', null, 'a second live request for the same semester is rejected');
select throws_ok(
  $$insert into public.subscriptions (school_id, student_id, semester_id, stop_id)
    values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002',
            'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001')$$,
  '42501', null, 'student cannot request a subscription for someone else');
select throws_ok(
  $$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status)
    values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001',
            'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001', 'approved')$$,
  '42501', null, 'student cannot approve their own request');
select throws_ok(
  $$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path)
    values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001',
            'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001',
            '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/proof.jpg')$$,
  '42501', null, 'proof path must belong to the requester');
select throws_ok(
  $$insert into public.subscriptions (school_id, student_id, semester_id, stop_id)
    values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001',
            'c1000000-0000-4000-8000-000000000002', 'd2000000-0000-4000-8000-000000000001')$$,
  '23503', null, 'a stop from another school is rejected by the database');
select throws_ok(
  $$insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by)
    values ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001',
            'a1000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000001',
            'a1000000-0000-4000-8000-000000000001')$$,
  '42501', null, 'clients cannot write scans directly');

-- ---------------------------------------------------------------- staff A
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is((select count(*)::int from public.profiles), 1, 'staff do not read other profiles');
select is((select count(*)::int from public.stops), 1, 'staff read stops of their school');
select is((select count(*)::int from public.scans), 1, 'staff read the scans they performed');
select throws_ok(
  $$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000001', 'X', extensions.st_point(1, 1)::extensions.geography)$$,
  '42501', null, 'staff cannot create a stop');

-- ---------------------------------------------------------------- admin A
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is((select count(*)::int from public.profiles), 5, 'admin reads every profile of their school and no other');
select is((select count(*)::int from public.subscriptions), 2, 'admin reads subscriptions of their school only');
select is((select count(*)::int from public.audit_log), 1, 'admin reads the audit log of their school only');
select lives_ok(
  $$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000001', 'New stop', extensions.st_point(11.4, 3.8)::extensions.geography)$$,
  'admin can create a stop in their school');
select throws_ok(
  $$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000002', 'Foreign stop', extensions.st_point(11.4, 3.8)::extensions.geography)$$,
  '42501', null, 'admin cannot create a stop in another school');
select throws_ok(
  $$update public.profiles set role = 'admin' where id = 'a1000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'admin cannot change roles with a plain update');

-- ---------------------------------------------------------------- admin B
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is((select count(*)::int from public.profiles), 2, 'admin of another school sees only their school');

-- ---------------------------------------------------------------- suspended
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a4000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is((select count(*)::int from public.profiles), 1, 'suspended user still reads their own profile');
select is((select count(*)::int from public.stops), 0, 'suspended user reads no school data');

reset role;
select is(
  (select full_name from public.profiles where id = 'a1000000-0000-4000-8000-000000000002'),
  'stu2', 'another student profile was not changed');

-- ---------------------------------------------------------------- anon
reset role;
set local role anon;
set local "request.jwt.claims" = '{"role":"anon"}';

select throws_ok(
  $$select count(*) from public.profiles$$,
  '42501', null, 'anonymous callers cannot read profiles');

reset role;
select * from finish();
rollback;
