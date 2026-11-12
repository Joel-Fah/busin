begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

-- School A is far ahead of UTC (Kiritimati, UTC+14), so its day is not the server's: that is what is being tested.
insert into public.schools (id, name, timezone) values ('10000000-0000-4000-8000-000000000001', 'School A', 'Pacific/Kiritimati');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50),
  ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'A-2', 50);

-- History, loaded the way a seed does (no signed-in user): allowed, and used below.
insert into public.semesters (id, school_id, name, year, start_date, end_date, created_by)
values ('b1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2020, '2020-09-01', '2021-01-31', 'a3000000-0000-4000-8000-000000000001');
select lives_ok($$insert into public.trips (id, school_id, bus_id, direction, scheduled_start)
  values ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', now() - interval '3 days')$$,
  'history can be loaded without a signed-in user, as seeds do');

select is(private.school_today('10000000-0000-4000-8000-000000000001'), (now() at time zone 'Pacific/Kiritimati')::date, 'the school''s day is read in its own timezone');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';

-- ---------------------------------------------------------------- semesters, by the school's own day
select throws_ok($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'spring', 2021, '2021-02-01', '2021-06-30', 'a3000000-0000-4000-8000-000000000001')$$,
  '22023', 'semester_in_past', 'a semester that has ended is refused');
select throws_ok(format($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'summer', 2026, %L, %L, 'a3000000-0000-4000-8000-000000000001')$$,
  ((now() at time zone 'Pacific/Kiritimati')::date - 30)::text, ((now() at time zone 'Pacific/Kiritimati')::date - 1)::text),
  '22023', 'semester_in_past', 'one that ended yesterday at the school is refused');
select lives_ok(format($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'summer', 2026, %L, %L, 'a3000000-0000-4000-8000-000000000001')$$,
  ((now() at time zone 'Pacific/Kiritimati')::date - 30)::text, ((now() at time zone 'Pacific/Kiritimati')::date)::text),
  'one that ends today at the school is the current one and is allowed');
select lives_ok(format($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'spring', 2027, %L, %L, 'a3000000-0000-4000-8000-000000000001')$$,
  ((now() at time zone 'Pacific/Kiritimati')::date - 10)::text, ((now() at time zone 'Pacific/Kiritimati')::date + 90)::text),
  'one that started already but runs on is allowed');
select throws_ok($$update public.semesters set end_date = '2021-03-01' where id = 'b1000000-0000-4000-8000-000000000001'$$,
  '22023', 'semester_in_past', 'dates cannot be moved into the past either');
select lives_ok($$update public.semesters set year = 2021 where id = 'b1000000-0000-4000-8000-000000000001'$$,
  'an old semester can still be edited when its dates are left alone');

-- ---------------------------------------------------------------- trips
select throws_ok($$insert into public.trips (school_id, bus_id, direction, scheduled_start)
  values ('10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', now() - interval '1 hour')$$,
  '22023', 'trip_start_in_past', 'a trip cannot be scheduled in the past');
select lives_ok($$insert into public.trips (school_id, bus_id, direction, scheduled_start)
  values ('10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', now() + interval '2 hours')$$,
  'a trip later today is allowed');
select lives_ok($$insert into public.trips (school_id, bus_id, direction, scheduled_start)
  values ('10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'outbound', now())$$,
  'one starting this very minute is allowed');
select throws_ok($$update public.trips set scheduled_start = now() - interval '2 hours' where id = 'f1000000-0000-4000-8000-000000000001'$$,
  '22023', 'trip_start_in_past', 'a start time cannot be moved into the past');
select lives_ok($$update public.trips set direction = 'outbound' where id = 'f1000000-0000-4000-8000-000000000001'$$,
  'an old trip can still be edited when its start is left alone');

-- ---------------------------------------------------------------- the staff field trip still starts now
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.start_field_trip('e1000000-0000-4000-8000-000000000002', 'inbound', 'driver')$$, 'a trip started in the field (starting now) is not in the past');
reset role;

-- ---------------------------------------------------------------- the school's timezone must be real
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$update public.schools set timezone = 'Mars/Olympus' where id = '10000000-0000-4000-8000-000000000001'$$, '23514', null, 'a timezone that does not exist is refused');
select lives_ok($$update public.schools set timezone = 'Africa/Douala' where id = '10000000-0000-4000-8000-000000000001'$$, 'a real one is accepted');
reset role;

select * from finish();
rollback;
