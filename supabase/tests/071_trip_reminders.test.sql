begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

-- Trips left running, in steps: whoever runs an overdue trip is reminded, a second time an hour later, never more.

insert into public.schools (id, name, timezone) values ('10000000-0000-4000-8000-000000000071', 'Remind School', 'Africa/Douala');
insert into public.school_domains (domain, school_id) values ('remind.edu', '10000000-0000-4000-8000-000000000071');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a7100000-0000-4000-8000-000000000001', 'driver@remind.edu', '{"provider":"google"}'),
  ('a7100000-0000-4000-8000-000000000002', 'helper@remind.edu', '{"provider":"google"}'),
  ('a7100000-0000-4000-8000-000000000003', 'starter@remind.edu', '{"provider":"google"}');
update public.profiles set role = 'staff', status = 'verified'
where id in ('a7100000-0000-4000-8000-000000000001', 'a7100000-0000-4000-8000-000000000002', 'a7100000-0000-4000-8000-000000000003');
-- A zone where it is about noon now, so "4 hours ago" is the same school day (as in 032_overdue_trips).
update public.schools set timezone = (
  select case when o >= 0 then 'Etc/GMT-' || o else 'Etc/GMT+' || (-o) end
  from (select (((12 - extract(hour from now() at time zone 'UTC')::int) + 36) % 24) - 12 as o) x
) where id = '10000000-0000-4000-8000-000000000071';
insert into public.buses (id, school_id, plate, capacity)
select ('e7100000-0000-4000-8000-00000000000' || n)::uuid, '10000000-0000-4000-8000-000000000071', 'R-' || n, 40 from generate_series(1, 5) n;

-- t1 fine (20 minutes, reporting); t2 silent (last position 45 minutes ago); t3 long (4 hours, reporting), run by three
-- people; t4 from an earlier day (it ends by itself); t5 completed.
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at, ended_at, driver_id, assistant_id, started_by) values
  ('f7100000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000071', 'e7100000-0000-4000-8000-000000000001', 'inbound', 'active', now() - interval '25 minutes', now() - interval '20 minutes', null, 'a7100000-0000-4000-8000-000000000001', null, null),
  ('f7100000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000071', 'e7100000-0000-4000-8000-000000000002', 'inbound', 'active', now() - interval '1 hour', now() - interval '1 hour', null, 'a7100000-0000-4000-8000-000000000001', null, 'a7100000-0000-4000-8000-000000000001'),
  ('f7100000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000071', 'e7100000-0000-4000-8000-000000000003', 'inbound', 'active', now() - interval '4 hours', now() - interval '4 hours', null, 'a7100000-0000-4000-8000-000000000001', 'a7100000-0000-4000-8000-000000000002', 'a7100000-0000-4000-8000-000000000003'),
  ('f7100000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000071', 'e7100000-0000-4000-8000-000000000004', 'inbound', 'active', now() - interval '2 days', now() - interval '2 days', null, 'a7100000-0000-4000-8000-000000000001', null, null),
  ('f7100000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000071', 'e7100000-0000-4000-8000-000000000005', 'inbound', 'completed', now() - interval '6 hours', now() - interval '6 hours', now() - interval '1 hour', 'a7100000-0000-4000-8000-000000000001', null, null);
insert into public.live_positions (bus_id, school_id, trip_id, location, recorded_at) values
  ('e7100000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000071', 'f7100000-0000-4000-8000-000000000001', extensions.st_point(11.5, 3.85)::extensions.geography, now() - interval '1 minute'),
  ('e7100000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000071', 'f7100000-0000-4000-8000-000000000002', extensions.st_point(11.5, 3.85)::extensions.geography, now() - interval '45 minutes'),
  ('e7100000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000071', 'f7100000-0000-4000-8000-000000000003', extensions.st_point(11.5, 3.85)::extensions.geography, now() - interval '1 minute');

create temp view reminders as
  select o.ref_id::text as trip, o.user_id::text as person from private.notification_outbox o
  where o.kind = 'trip_still_running' and o.school_id = '10000000-0000-4000-8000-000000000071';

select is((select schedule from cron.job where jobname = 'busin-remind-running-trips'), '*/10 * * * *', 'running trips are looked at every ten minutes');
select is(private.remind_running_trips(), 2, 'the silent trip and the long one are reminded');
select results_eq($$select person from reminders where trip = 'f7100000-0000-4000-8000-000000000003' order by person$$,
  $$values ('a7100000-0000-4000-8000-000000000001'), ('a7100000-0000-4000-8000-000000000002'), ('a7100000-0000-4000-8000-000000000003')$$,
  'everyone running it: the driver, the assistant and whoever started it');
select is((select count(*)::int from reminders where trip = 'f7100000-0000-4000-8000-000000000002'), 1, 'one reminder for one person, even when they drive and started it');
select is((select count(*)::int from reminders where trip in ('f7100000-0000-4000-8000-000000000001', 'f7100000-0000-4000-8000-000000000004', 'f7100000-0000-4000-8000-000000000005')), 0,
  'not a fresh trip, not one from an earlier day (it ends by itself), not a finished one');
select is(private.remind_running_trips(), 0, 'not again within the hour');

update private.trip_reminders set last_sent_at = now() - interval '61 minutes';
select is(private.remind_running_trips(), 2, 'a second reminder an hour later');
select is((select sent from private.trip_reminders where trip_id = 'f7100000-0000-4000-8000-000000000003'), 2::smallint, 'counted');
update private.trip_reminders set last_sent_at = now() - interval '3 hours';
select is(private.remind_running_trips(), 0, 'never a third');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a7100000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from private.trip_reminders$$, '42501', null, 'the reminders are not readable from the app');

select * from finish();
rollback;
