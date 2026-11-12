begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A'), ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a2000000-0000-4000-8000-000000000001', 'driver@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000002', 'assistant@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000003', 'other@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'student@a.edu', '{"provider":"google"}'),
  ('b2000000-0000-4000-8000-000000000001', 'staff@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id in ('a2000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-000000000003', 'b2000000-0000-4000-8000-000000000001');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';
update public.profiles set full_name = 'Dina Driver' where id = 'a2000000-0000-4000-8000-000000000001';
update public.profiles set full_name = 'Alex Assistant' where id = 'a2000000-0000-4000-8000-000000000002';

insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50),
  ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'A-2', 50),
  ('e1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'A-3', 50);
insert into public.trips (id, school_id, bus_id, driver_id, assistant_id, direction, scheduled_start) values
  -- a driver and an assistant
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002', 'inbound', now()),
  -- an assistant only
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', null, 'a2000000-0000-4000-8000-000000000002', 'inbound', now()),
  -- a driver only
  ('f1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000003', 'a2000000-0000-4000-8000-000000000001', null, 'inbound', now());

-- ---------------------------------------------------------------- who sets the crew
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$update public.trips set assistant_id = 'a2000000-0000-4000-8000-000000000002' where id = 'f1000000-0000-4000-8000-000000000003'$$, 'an administrator adds an assistant to a trip');
select throws_ok($$update public.trips set assistant_id = driver_id where id = 'f1000000-0000-4000-8000-000000000003'$$, '23514', null, 'the assistant cannot also be the driver');
select throws_ok($$update public.trips set assistant_id = 'b2000000-0000-4000-8000-000000000001' where id = 'f1000000-0000-4000-8000-000000000003'$$, '22023', 'crew_not_staff', 'nor someone from another school');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000003","role":"authenticated"}';
update public.trips set assistant_id = null where id = 'f1000000-0000-4000-8000-000000000003';
reset role;
select is((select assistant_id::text from public.trips where id = 'f1000000-0000-4000-8000-000000000003'), 'a2000000-0000-4000-8000-000000000002',
  'a staff member who is not an administrator cannot change the crew');

-- ---------------------------------------------------------------- starting and ending
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000001')$$, '42501', null, 'other staff cannot start a trip with a crew');
select throws_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000002')$$, '42501', null, 'nor a trip that has only an assistant');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000001')$$, 'the assistant starts the trip');
select lives_ok($$select public.start_trip('f1000000-0000-4000-8000-000000000002')$$, 'a trip with only an assistant is started by that assistant');
reset role;

-- ---------------------------------------------------------------- one phone leads the position
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.publish_position('f1000000-0000-4000-8000-000000000001', 3.85, 11.5, 6, 45, 8), true, 'the driver sends the first position and leads');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is(public.publish_position('f1000000-0000-4000-8000-000000000001', 3.86, 11.5, 6, 45, 8), false, 'the assistant''s fix is set aside while the driver leads');
select is((select holder_name || ':' || is_me::text from public.trip_position_holder('f1000000-0000-4000-8000-000000000001')), 'Dina Driver:false',
  'the assistant sees that the driver leads');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select is_me from public.trip_position_holder('f1000000-0000-4000-8000-000000000001')), true, 'and the driver sees that they lead');
reset role;

-- The driver goes quiet for a while: the lease and the last fix get old.
update public.trip_position_leases set renewed_at = now() - interval '31 seconds' where trip_id = 'f1000000-0000-4000-8000-000000000001';
update public.live_positions set recorded_at = now() - interval '1 minute' where bus_id = 'e1000000-0000-4000-8000-000000000001';

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000003","role":"authenticated"}';
select is((select count(*) from public.trip_position_holder('f1000000-0000-4000-8000-000000000001')), 0::bigint, 'nobody leads once the leader has been quiet for 30 seconds');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is(public.publish_position('f1000000-0000-4000-8000-000000000001', 3.87, 11.5, 6, 45, 8), true, 'the assistant takes over');
select is((select holder_name || ':' || is_me::text from public.trip_position_holder('f1000000-0000-4000-8000-000000000001')), 'Alex Assistant:true', 'and now leads');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.publish_position('f1000000-0000-4000-8000-000000000001', 3.88, 11.5, 6, 45, 8), false, 'the driver''s fix is now the one set aside');
reset role;
select is((select ST_Y(location::extensions.geometry) from public.live_positions where bus_id = 'e1000000-0000-4000-8000-000000000001'), 3.87::double precision,
  'the bus shows the leader''s position only');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.publish_position('f1000000-0000-4000-8000-000000000001', 3.85, 11.5)$$, '42501', null, 'staff outside the crew cannot send the position of a trip with a crew');
reset role;

-- ---------------------------------------------------------------- ending
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.end_trip('f1000000-0000-4000-8000-000000000001')$$, 'the driver can end a trip the assistant started');
reset role;

-- ---------------------------------------------------------------- who may ask, and who may read
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.trip_position_holder('f1000000-0000-4000-8000-000000000001')$$, '42501', null, 'a student cannot ask who leads');
select throws_ok($$select * from public.trip_position_leases$$, '42501', null, 'nor read the leases');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.trip_position_holder('f1000000-0000-4000-8000-000000000001')$$, 'P0002', 'Trip not found', 'staff of another school do not see the trip');
reset role;

select * from finish();
rollback;
