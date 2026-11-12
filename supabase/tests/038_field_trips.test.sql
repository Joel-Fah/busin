begin;
create extension if not exists pgtap with schema extensions;
select plan(29);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A'), ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a2000000-0000-4000-8000-000000000001', 'driver@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000002', 'assistant@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'student@a.edu', '{"provider":"google"}'),
  ('b2000000-0000-4000-8000-000000000001', 'staff@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id in ('a2000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002', 'b2000000-0000-4000-8000-000000000001');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';
update public.profiles set full_name = 'Dina Driver' where id = 'a2000000-0000-4000-8000-000000000001';
update public.profiles set full_name = 'Alex Assistant' where id = 'a2000000-0000-4000-8000-000000000002';

insert into public.buses (id, school_id, plate, capacity, in_service) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50, true),
  ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'A-2', 50, true),
  ('e1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'A-3', 50, false),
  ('e1000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'A-4', 50, true),
  ('e1000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'A-5', 50, true),
  ('e2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'B-1', 50, true);
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at) values
  -- bus 2 has an inbound trip scheduled today
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', 'inbound', 'scheduled', now(), null),
  -- bus 4 is on a trip already
  ('f1000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000004', 'inbound', 'active', now(), now());

-- ---------------------------------------------------------------- what the app is offered
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.field_trip_options()$$, '42501', null, 'a student cannot ask for the options');
select throws_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000001', 'inbound', 'driver')$$, '42501', null, 'nor start a trip');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((public.field_trip_options() ->> 'allowed')::boolean, true, 'staff are offered field trips by default');
select is((select array_agg(b ->> 'plate' order by b ->> 'plate') from jsonb_array_elements(public.field_trip_options() -> 'buses') b), array['A-1', 'A-2', 'A-5'],
  'only buses in service and not on a trip are offered');
select is((select array_agg(s ->> 'name') from jsonb_array_elements(public.field_trip_options() -> 'staff') s), array['Alex Assistant'],
  'the crew to pick from is the verified staff of the school, without the caller, administrators or other schools');

-- ---------------------------------------------------------------- starting as the driver
select throws_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000001', 'inbound', 'captain')$$, '22023', 'invalid_request', 'the role is the driver or the assistant');
select throws_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000001', 'inbound', 'driver', 'a2000000-0000-4000-8000-000000000001')$$, '22023', 'invalid_crew', 'the other crew member is someone else');
select throws_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000001', 'inbound', 'driver', 'a1000000-0000-4000-8000-000000000001')$$, '22023', 'invalid_crew', 'who must be staff');
select throws_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000001', 'inbound', 'driver', 'b2000000-0000-4000-8000-000000000001')$$, '22023', 'invalid_crew', 'of the same school');
select throws_ok($$select public.start_field_trip('e2000000-0000-4000-8000-000000000001', 'inbound', 'driver')$$, 'P0002', 'Bus not found', 'another school''s bus is not found');
select throws_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000003', 'inbound', 'driver')$$, '55000', 'bus_out_of_service', 'a bus out of service cannot be used');
select throws_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000004', 'inbound', 'driver')$$, '55000', 'bus_busy', 'nor a bus already on a trip');
select throws_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000002', 'inbound', 'driver')$$, '55000', 'use_scheduled_trip', 'a scheduled trip for this bus and direction today is started instead');

select lives_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000001', 'inbound', 'driver', 'a2000000-0000-4000-8000-000000000002')$$, 'a staff member starts a trip nobody scheduled, as the driver');
reset role;
select is((select origin || ':' || status::text || ':' || driver_id::text || ':' || assistant_id::text || ':' || created_by::text || ':' || started_by::text from public.trips where bus_id = 'e1000000-0000-4000-8000-000000000001'),
  'field:active:a2000000-0000-4000-8000-000000000001:a2000000-0000-4000-8000-000000000002:a2000000-0000-4000-8000-000000000001:a2000000-0000-4000-8000-000000000001',
  'it runs at once, marked as started in the field, with the caller as driver and the other as assistant');
select is((select count(*) from private.notification_outbox o join public.trips t on t.id = o.ref_id
  where o.kind = 'crew_assigned' and o.user_id = 'a2000000-0000-4000-8000-000000000002' and t.bus_id = 'e1000000-0000-4000-8000-000000000001'), 1::bigint, 'the other crew member is told');
select is((select count(*) from public.audit_log where action = 'trip.started_in_field' and actor_id = 'a2000000-0000-4000-8000-000000000001'), 1::bigint, 'and it is in the audit log');

-- ---------------------------------------------------------------- the creator runs it
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.publish_position((select id from public.trips where bus_id = 'e1000000-0000-4000-8000-000000000001'), 3.85, 11.5, 6, 45, 8), true, 'the driver who started it shares the position');
select lives_ok($$select public.end_trip((select id from public.trips where bus_id = 'e1000000-0000-4000-8000-000000000001'))$$, 'and ends it');
reset role;

-- ---------------------------------------------------------------- starting as the assistant
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000002', 'outbound', 'assistant', 'a2000000-0000-4000-8000-000000000001')$$, 'the assistant starts one and picks the driver (another direction than the scheduled trip)');
reset role;
select is((select driver_id::text || ':' || assistant_id::text from public.trips where bus_id = 'e1000000-0000-4000-8000-000000000002' and origin = 'field'),
  'a2000000-0000-4000-8000-000000000001:a2000000-0000-4000-8000-000000000002', 'the caller is the assistant and the picked person the driver');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000005', 'inbound', 'assistant')$$, 'the driver may be left for later');
reset role;
select is((select driver_id from public.trips where bus_id = 'e1000000-0000-4000-8000-000000000005'), null, 'it then has no driver yet');

-- ---------------------------------------------------------------- the daily limit
insert into public.trips (school_id, bus_id, direction, status, scheduled_start, started_at, ended_at, origin, created_by)
select '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'completed', now(), now(), now(), 'field', 'a2000000-0000-4000-8000-000000000002'
from generate_series(1, 3);
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000001', 'outbound', 'driver')$$, 'PT429', 'too_many_field_trips', 'five a day is the most for one person');
reset role;

-- ---------------------------------------------------------------- the school's switch
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_set_field_trips(false)$$, '42501', null, 'staff cannot change the switch');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.admin_set_field_trips(false)$$, 'an administrator turns field trips off');
reset role;
select is((select count(*) from public.audit_log where action = 'school.field_trips'), 1::bigint, 'and it is in the audit log');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((public.field_trip_options() ->> 'allowed')::boolean, false, 'staff are then offered nothing');
select throws_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000005', 'outbound', 'driver')$$, '42501', 'field_trips_off', 'and cannot start one');
reset role;

select * from finish();
rollback;
