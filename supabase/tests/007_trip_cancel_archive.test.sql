begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'LT 1 A', 40);
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at, ended_at) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'scheduled', now() + interval '1 day', null, null),
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'scheduled', now() + interval '2 days', null, null),
  ('f1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'active', now(), now(), null),
  ('f1000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'outbound', 'completed', now() - interval '1 day', now() - interval '1 day', now() - interval '23 hours'),
  ('f1000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'outbound', 'cancelled', now() - interval '2 days', null, null);

-- ---------------------------------------------------------------- student and staff
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000001')$$,
  '42501', 'Admin access required', 'a student cannot cancel a trip');
select throws_ok(
  $$select public.admin_set_trip_archived('f1000000-0000-4000-8000-000000000004', true)$$,
  '42501', 'Admin access required', 'a student cannot archive a trip');

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000001')$$,
  '42501', 'Admin access required', 'staff cannot cancel a trip');

-- ---------------------------------------------------------------- admin of another school
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000001')$$,
  'P0002', 'Trip not found', 'an admin of another school cannot find the trip');
select throws_ok(
  $$select public.admin_set_trip_archived('f1000000-0000-4000-8000-000000000004', true)$$,
  'P0002', 'Trip not found', 'nor archive it');

-- ---------------------------------------------------------------- admin
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';

select lives_ok(
  $$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000001', '  The bus is in the garage.  ')$$,
  'an admin can cancel a scheduled trip');
select is((select status::text from public.trips where id = 'f1000000-0000-4000-8000-000000000001'), 'cancelled', 'the trip is now cancelled');
select is(
  (select details->>'reason' from public.audit_log where action = 'trip.cancelled' and target_id = 'f1000000-0000-4000-8000-000000000001'),
  'The bus is in the garage.', 'the trimmed reason is kept in the audit log');
select lives_ok($$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000002')$$, 'a reason is optional');

select throws_ok(
  $$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000003')$$,
  '55000', 'Only a trip that has not started can be cancelled', 'a running trip cannot be cancelled');
select throws_ok(
  $$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000004')$$,
  '55000', null, 'a completed trip cannot be cancelled');
select throws_ok(
  $$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000001')$$,
  '55000', null, 'a trip cannot be cancelled twice');
select throws_ok(
  $$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000002', repeat('x', 301))$$,
  '22023', null, 'a reason over 300 characters is refused');

select lives_ok($$select public.admin_set_trip_archived('f1000000-0000-4000-8000-000000000004', true)$$, 'a completed trip can be archived');
select ok((select archived_at is not null from public.trips where id = 'f1000000-0000-4000-8000-000000000004'), 'it carries an archive mark');
select lives_ok($$select public.admin_set_trip_archived('f1000000-0000-4000-8000-000000000005', true)$$, 'a cancelled trip can be archived');
select throws_ok(
  $$select public.admin_set_trip_archived('f1000000-0000-4000-8000-000000000003', true)$$,
  '55000', 'Only a finished or cancelled trip can be archived', 'a running trip cannot be archived');
select lives_ok($$select public.admin_set_trip_archived('f1000000-0000-4000-8000-000000000004', false)$$, 'an archived trip can be brought back');
select ok((select archived_at is null from public.trips where id = 'f1000000-0000-4000-8000-000000000004'), 'the archive mark is cleared');

select is(
  (select count(*)::int from public.audit_log where action in ('trip.cancelled', 'trip.archived', 'trip.unarchived')),
  5, 'every cancel and archive is audited');

-- Clients cannot write the status or the archive mark, and cannot delete a trip.
select throws_ok(
  $$update public.trips set archived_at = now() where id = 'f1000000-0000-4000-8000-000000000004'$$,
  '42501', null, 'the archive mark cannot be written directly');
select throws_ok(
  $$delete from public.trips where id = 'f1000000-0000-4000-8000-000000000005'$$,
  '42501', null, 'an admin can no longer delete a trip');

-- ---------------------------------------------------------------- anon
reset role;
set local role anon;
set local "request.jwt.claims" = '{"role":"anon"}';
select throws_ok(
  $$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000001')$$,
  '42501', null, 'anonymous callers cannot cancel trips');

reset role;
select * from finish();
rollback;
