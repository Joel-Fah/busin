begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

-- Usage, costs and system health for the platform console (ADR 0027, slice 6).

insert into public.schools (id, name) values ('e0000000-0000-4000-8000-0000000000a1', 'Health School');
insert into public.school_domains (domain, school_id) values ('sys.edu', 'e0000000-0000-4000-8000-0000000000a1');
insert into auth.users (id, email, raw_app_meta_data) values
  ('e1000000-0000-4000-8000-0000000000a1', 'admin@sys.edu', '{"provider":"google"}'),
  ('e1000000-0000-4000-8000-0000000000f1', 'platform@sys.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'e1000000-0000-4000-8000-0000000000a1';
insert into private.platform_admins (user_id, note) values ('e1000000-0000-4000-8000-0000000000f1', 'test');
-- A trip running for an hour whose bus never sent a position.
insert into public.buses (id, school_id, plate, capacity) values ('e2000000-0000-4000-8000-0000000000a1', 'e0000000-0000-4000-8000-0000000000a1', 'SYS-1', 40);
insert into public.trips (school_id, bus_id, direction, status, scheduled_start, started_at)
values ('e0000000-0000-4000-8000-0000000000a1', 'e2000000-0000-4000-8000-0000000000a1', 'inbound', 'active', now() - interval '1 hour', now() - interval '1 hour');
insert into private.route_directions_usage (school_id) values ('e0000000-0000-4000-8000-0000000000a1'), ('e0000000-0000-4000-8000-0000000000a1');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select public.platform_system_health()$$, '42501', null, 'a school admin cannot read the system health');

set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select ok((public.platform_system_health() ->> 'database_bytes')::bigint > 0, 'the database size is read');
select ok((public.platform_system_health() -> 'usage' ->> 'directions_month')::int >= 2, 'map directions this month are counted');
select ok(jsonb_typeof(public.platform_system_health() -> 'storage') = 'array', 'storage is listed by bucket');
select ok((public.platform_system_health() -> 'accounts' ->> 'total')::int >= 2, 'accounts are counted');
select ok(exists (select 1 from jsonb_array_elements(public.platform_system_health() -> 'jobs') j where j ->> 'name' = 'busin-send-push'),
  'each scheduled job is listed');
select ok(exists (select 1 from jsonb_array_elements(public.platform_system_health() -> 'quiet_trips') q where q ->> 'school' = 'Health School'),
  'a running trip whose bus is quiet is listed');
select ok((public.platform_system_health() -> 'devices') ?& array['android', 'ios', 'web', 'stale_30d'], 'phones are counted by kind');

select * from finish();
rollback;
