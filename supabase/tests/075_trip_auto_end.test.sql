begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

-- Trips that end by themselves: an hour after the second reminder if still overdue, and 15 minutes after reaching the
-- campus on the way to school. The crew is told and the end is recorded.

insert into public.schools (id, name, timezone) values ('10000000-0000-4000-8000-000000000075', 'Auto End School', 'Africa/Douala');
insert into public.school_domains (domain, school_id) values ('autoend.edu', '10000000-0000-4000-8000-000000000075');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a7500000-0000-4000-8000-000000000001', 'driver@autoend.edu', '{"provider":"google"}'),
  ('a7500000-0000-4000-8000-000000000002', 'helper@autoend.edu', '{"provider":"google"}');
update public.profiles set role = 'staff', status = 'verified'
where id in ('a7500000-0000-4000-8000-000000000001', 'a7500000-0000-4000-8000-000000000002');
-- A zone where it is about noon now, so "5 hours ago" is the same school day (as in 071_trip_reminders).
update public.schools set timezone = (
  select case when o >= 0 then 'Etc/GMT-' || o else 'Etc/GMT+' || (-o) end
  from (select (((12 - extract(hour from now() at time zone 'UTC')::int) + 36) % 24) - 12 as o) x
) where id = '10000000-0000-4000-8000-000000000075';
insert into public.buses (id, school_id, plate, capacity)
select ('e7500000-0000-4000-8000-00000000000' || n)::uuid, '10000000-0000-4000-8000-000000000075', 'A-' || n, 40 from generate_series(1, 7) n;

-- t1 long, reminded twice, the last 61 minutes ago (field trip, two crew): ends.
-- t2 long, reminded twice, the last 30 minutes ago: not yet.
-- t3 long, reminded once: not yet.
-- t4 was silent and reminded twice, but reports again and is not long: keeps running.
-- t5 going to school, at the campus for 16 minutes: ends. t6 at the campus for 5 minutes: not yet.
-- t7 leaving school, "arrived" at the campus long ago: not a campus end.
insert into public.trips (id, school_id, bus_id, direction, origin, status, scheduled_start, started_at, driver_id, assistant_id, started_by) values
  ('f7500000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000075', 'e7500000-0000-4000-8000-000000000001', 'inbound', 'field', 'active', now() - interval '5 hours', now() - interval '5 hours', 'a7500000-0000-4000-8000-000000000001', 'a7500000-0000-4000-8000-000000000002', 'a7500000-0000-4000-8000-000000000001'),
  ('f7500000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000075', 'e7500000-0000-4000-8000-000000000002', 'inbound', 'scheduled', 'active', now() - interval '5 hours', now() - interval '5 hours', 'a7500000-0000-4000-8000-000000000001', null, null),
  ('f7500000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000075', 'e7500000-0000-4000-8000-000000000003', 'inbound', 'scheduled', 'active', now() - interval '4 hours', now() - interval '4 hours', 'a7500000-0000-4000-8000-000000000001', null, null),
  ('f7500000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000075', 'e7500000-0000-4000-8000-000000000004', 'inbound', 'scheduled', 'active', now() - interval '2 hours', now() - interval '2 hours', 'a7500000-0000-4000-8000-000000000001', null, null),
  ('f7500000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000075', 'e7500000-0000-4000-8000-000000000005', 'inbound', 'scheduled', 'active', now() - interval '1 hour', now() - interval '1 hour', 'a7500000-0000-4000-8000-000000000002', null, null),
  ('f7500000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000075', 'e7500000-0000-4000-8000-000000000006', 'inbound', 'scheduled', 'active', now() - interval '1 hour', now() - interval '1 hour', 'a7500000-0000-4000-8000-000000000002', null, null),
  ('f7500000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000075', 'e7500000-0000-4000-8000-000000000007', 'outbound', 'scheduled', 'active', now() - interval '1 hour', now() - interval '1 hour', 'a7500000-0000-4000-8000-000000000002', null, null);
insert into public.live_positions (bus_id, school_id, trip_id, location, recorded_at)
select ('e7500000-0000-4000-8000-00000000000' || n)::uuid, '10000000-0000-4000-8000-000000000075', ('f7500000-0000-4000-8000-00000000000' || n)::uuid,
  extensions.st_point(11.5, 3.85)::extensions.geography, now() - interval '1 minute'
from generate_series(1, 7) n;
insert into private.trip_reminders (trip_id, sent, last_sent_at) values
  ('f7500000-0000-4000-8000-000000000001', 2, now() - interval '61 minutes'),
  ('f7500000-0000-4000-8000-000000000002', 2, now() - interval '30 minutes'),
  ('f7500000-0000-4000-8000-000000000003', 1, now() - interval '2 hours'),
  ('f7500000-0000-4000-8000-000000000004', 2, now() - interval '2 hours');
insert into private.trip_campus_arrivals (trip_id, arrived_at) values
  ('f7500000-0000-4000-8000-000000000005', now() - interval '16 minutes'),
  ('f7500000-0000-4000-8000-000000000006', now() - interval '5 minutes'),
  ('f7500000-0000-4000-8000-000000000007', now() - interval '1 hour');

create temp view still as
  select string_agg(right(id::text, 1), ',' order by id) as running from public.trips
  where school_id = '10000000-0000-4000-8000-000000000075' and status = 'active';

select is((select schedule from cron.job where jobname = 'busin-end-overdue-trips'), '3-59/10 * * * *', 'looked at every ten minutes');
select is(private.end_overdue_trips(), 2, 'two trips are due');
select is((select running from still), '2,3,4,6,7', 'the long trip an hour after its second reminder and the bus at the campus for 15 minutes end');
select isnt((select ended_at from public.trips where id = 'f7500000-0000-4000-8000-000000000001'), null, 'with the time it ended');
select results_eq($$select user_id::text from private.notification_outbox where kind = 'trip_auto_ended' and ref_id = 'f7500000-0000-4000-8000-000000000001' order by user_id$$,
  $$values ('a7500000-0000-4000-8000-000000000001'), ('a7500000-0000-4000-8000-000000000002')$$,
  'its crew is told, once each');
select is((select count(*)::int from private.notification_outbox where kind = 'trip_auto_ended' and ref_id = 'f7500000-0000-4000-8000-000000000005'), 1, 'and the campus trip''s driver');
select results_eq($$select target_id::text, details ->> 'reason' from public.audit_log where action = 'trip.auto_ended' and school_id = '10000000-0000-4000-8000-000000000075' order by target_id$$,
  $$values ('f7500000-0000-4000-8000-000000000001', 'reminded'), ('f7500000-0000-4000-8000-000000000005', 'at_campus')$$,
  'recorded with why');
select is(private.end_overdue_trips(), 0, 'nothing more to end right away');

update private.trip_reminders set last_sent_at = now() - interval '61 minutes' where trip_id = 'f7500000-0000-4000-8000-000000000002';
update private.trip_campus_arrivals set arrived_at = now() - interval '15 minutes' where trip_id = 'f7500000-0000-4000-8000-000000000006';
select is(private.end_overdue_trips(), 2, 'the others end when their time comes');
select is((select running from still), '3,4,7', 'not the one reminded once, not the one reporting again, not the one leaving school');
select is((select count(*)::int from private.notification_outbox where kind = 'trip_auto_ended' and school_id = '10000000-0000-4000-8000-000000000075'), 5, 'one notice per crew member per trip: two, then one for each of the three others');

-- A phone still sharing is refused once its trip ended, so it stops.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a7500000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.publish_position('f7500000-0000-4000-8000-000000000001', 3.85, 11.5)$$, '55000', 'trip_not_active', 'the driver''s phone is told the trip is over');
select throws_ok($$select private.end_overdue_trips()$$, '42501', null, 'the app cannot run it');
reset role;

select * from finish();
rollback;
