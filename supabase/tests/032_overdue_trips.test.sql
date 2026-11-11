begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

insert into public.schools (id, name, timezone) values
  ('10000000-0000-4000-8000-000000000001', 'School A', 'Africa/Douala'),
  ('10000000-0000-4000-8000-000000000002', 'School B', 'Africa/Douala');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
-- Both schools sit in a zone where it is about noon now, so "4 hours ago" is always the same school day.
update public.schools set timezone = (
  select case when o >= 0 then 'Etc/GMT-' || o else 'Etc/GMT+' || (-o) end
  from (select (((12 - extract(hour from now() at time zone 'UTC')::int) + 36) % 24) - 12 as o) x
) where id in ('10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002');

insert into public.buses (id, school_id, plate, capacity)
select ('e1000000-0000-4000-8000-00000000000' || n)::uuid, '10000000-0000-4000-8000-000000000001', 'A-' || n, 40 from generate_series(1, 5) n;
insert into public.buses (id, school_id, plate, capacity) values ('e2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'B-1', 40);

-- t1 fine (started 20 min ago, reporting); t2 silent (last position 45 min ago); t3 long (started 4 hours ago, still
-- reporting); t4 from an earlier day; t5 completed; t6 another school's, from an earlier day.
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at, ended_at) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'active', now() - interval '25 minutes', now() - interval '20 minutes', null),
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', 'inbound', 'active', now() - interval '1 hour', now() - interval '1 hour', null),
  ('f1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000003', 'inbound', 'active', now() - interval '4 hours', now() - interval '4 hours', null),
  ('f1000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000004', 'inbound', 'active', now() - interval '2 days', now() - interval '2 days', null),
  ('f1000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000005', 'inbound', 'completed', now() - interval '2 days', now() - interval '2 days', now() - interval '2 days'),
  ('f2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'e2000000-0000-4000-8000-000000000001', 'inbound', 'active', now() - interval '2 days', now() - interval '2 days', null);
insert into public.live_positions (bus_id, school_id, trip_id, location, recorded_at) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', extensions.st_point(11.5, 3.85)::extensions.geography, now() - interval '1 minute'),
  ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000002', extensions.st_point(11.5, 3.85)::extensions.geography, now() - interval '45 minutes'),
  ('e1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000003', extensions.st_point(11.5, 3.85)::extensions.geography, now() - interval '1 minute');

-- ---------------------------------------------------------------- what the admin sees
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select results_eq(
  $$select trip_id::text, reason from public.admin_overdue_trips()$$,
  $$values ('f1000000-0000-4000-8000-000000000004', 'earlier_day'), ('f1000000-0000-4000-8000-000000000003', 'long'), ('f1000000-0000-4000-8000-000000000002', 'silent')$$,
  'overdue trips, oldest first, each with its reason; a fresh trip and a finished one are not overdue');
select ok((select last_position_at is not null from public.admin_overdue_trips() where trip_id = 'f1000000-0000-4000-8000-000000000002'), 'with when the bus last reported');
select lives_ok($$select public.end_trip('f1000000-0000-4000-8000-000000000002')$$, 'an admin ends a trip someone else started');
select is((select count(*)::int from public.admin_overdue_trips()), 2, 'and it is no longer overdue');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.admin_overdue_trips()), 1, 'each school sees only its own');
select throws_ok($$select public.end_trip('f1000000-0000-4000-8000-000000000003')$$, 'P0002', 'Trip not found', 'and cannot end another school''s trip');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.admin_overdue_trips()$$, '42501', null, 'staff do not get the overdue list');
reset role;

-- ---------------------------------------------------------------- the safety net
select is((select count(*)::int from cron.job where jobname = 'busin-end-stale-trips'), 1, 'the safety net runs every hour');
select cmp_ok(private.end_stale_trips(), '>=', 2, 'it ends trips left running from an earlier day');
select is((select string_agg(status::text, ',' order by id) from public.trips where id in ('f1000000-0000-4000-8000-000000000003', 'f1000000-0000-4000-8000-000000000004', 'f2000000-0000-4000-8000-000000000001')),
  'active,completed,completed', 'in every school, and only those');
select is((select count(*)::int from public.audit_log where action = 'trip.auto_ended' and target_id in ('f1000000-0000-4000-8000-000000000004', 'f2000000-0000-4000-8000-000000000001')), 2, 'each recorded');
select ok((select ended_at is not null from public.trips where id = 'f1000000-0000-4000-8000-000000000004'), 'with the time it ended');

select * from finish();
rollback;
