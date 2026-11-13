begin;
create extension if not exists pgtap with schema extensions;
select plan(25);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A'), ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a2000000-0000-4000-8000-000000000001', 'driver@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000002', 'other@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'student@a.edu', '{"provider":"google"}'),
  ('b2000000-0000-4000-8000-000000000001', 'staff@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id in ('a2000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002', 'b2000000-0000-4000-8000-000000000001');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';

insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50),
  ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'A-2', 50),
  ('e2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'B-1', 50);
insert into public.trips (id, school_id, bus_id, driver_id, direction, scheduled_start) values
  -- assigned to the driver
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', 'inbound', now()),
  -- nobody assigned
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', null, 'inbound', now()),
  -- same bus as the first
  ('f1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', 'outbound', now()),
  -- another day, assigned to the second staff member
  ('f1000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-000000000002', 'outbound', now() + interval '3 days'),
  -- another school
  ('f2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'e2000000-0000-4000-8000-000000000001', null, 'inbound', now());

-- ---------------------------------------------------------------- starting
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000001')$$, '42501', null, 'another staff member cannot start a trip assigned to someone');
select throws_ok($$select public.start_trip('f2000000-0000-4000-8000-000000000001')$$, 'P0002', 'Trip not found', 'nor another school''s trip');
select throws_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000004')$$, '55000', 'trip_not_today', 'a trip of another day cannot start');
select throws_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000002')$$, '42501', null, 'a trip nobody is assigned to is not for staff to start (administrators run it)');
reset role;
-- That trip runs, started by the second staff member before staff were limited to their own trips.
update public.trips set status = 'active', started_at = now(), started_by = 'a2000000-0000-4000-8000-000000000002' where id = 'f1000000-0000-4000-8000-000000000002';

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000003')$$, '42501', null, 'a student cannot start a trip');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000001')$$, 'the assigned driver starts their trip');
select throws_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000003')$$, '55000', 'bus_busy', 'a bus runs one trip at a time');
select throws_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000001')$$, '55000', 'trip_not_scheduled', 'a running trip cannot start again');
reset role;
select is((select status::text || ':' || started_by::text from public.trips where id = 'f1000000-0000-4000-8000-000000000001'),
  'active:a2000000-0000-4000-8000-000000000001', 'the trip runs and remembers who started it');

-- ---------------------------------------------------------------- position
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.publish_position('f1000000-0000-4000-8000-000000000001', 3.85, 11.5)$$, '42501', null,
  'only the assignee shares the position of an assigned trip');
select is(public.publish_position('f1000000-0000-4000-8000-000000000002', 3.86, 11.51, 8, 90, 10), true,
  'on a trip nobody is assigned to, whoever started it shares the position');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.publish_position('f1000000-0000-4000-8000-000000000002', 3.85, 11.5)$$, '42501', null,
  'and nobody else');
select is(public.publish_position('f1000000-0000-4000-8000-000000000001', 3.85, 11.5, 6, 45, 8), true, 'the driver sends a position');
select is(public.publish_position('f1000000-0000-4000-8000-000000000001', 3.851, 11.5, 6, 45, 8), false, 'another within 5 seconds is dropped');
select throws_ok($$select public.publish_position('f1000000-0000-4000-8000-000000000001', 95, 11.5)$$, '22023', null, 'impossible coordinates are refused');
reset role;
select is((select trip_id::text || ':' || source from public.live_positions where bus_id = 'e1000000-0000-4000-8000-000000000001'),
  'f1000000-0000-4000-8000-000000000001:phone', 'the bus position is the trip''s, from a phone');
select is((select count(*)::int from public.trip_positions where trip_id = 'f1000000-0000-4000-8000-000000000001'), 1, 'and the history keeps a point');

-- ---------------------------------------------------------------- manifest
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select * from public.trip_manifest('f1000000-0000-4000-8000-000000000001')$$, 'P0002', 'Trip not found', 'staff do not read the manifest of a trip they are not on');
select is((select count(*)::int from public.trip_manifest('f1000000-0000-4000-8000-000000000002')), 0, 'but do read one they started (nobody yet)');
select throws_ok($$select * from public.trip_manifest('f2000000-0000-4000-8000-000000000001')$$, 'P0002', 'Trip not found', 'not another school''s');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.trip_manifest('f1000000-0000-4000-8000-000000000001')$$, '42501', null, 'students cannot read a manifest');
reset role;

-- ---------------------------------------------------------------- ending
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.end_trip('f1000000-0000-4000-8000-000000000001')$$, '42501', null, 'another staff member cannot end an assigned trip');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.end_trip('f1000000-0000-4000-8000-000000000001')$$, 'the driver ends it');
select throws_ok($$select public.end_trip('f1000000-0000-4000-8000-000000000001')$$, '55000', 'trip_not_active', 'once');
reset role;

select is((select count(*)::int from public.audit_log where target_id = 'f1000000-0000-4000-8000-000000000001' and action in ('trip.started', 'trip.ended')), 2,
  'starting and ending are audited');

select * from finish();
rollback;
