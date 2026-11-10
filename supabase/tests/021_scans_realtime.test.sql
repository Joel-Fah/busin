begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

select ok(exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'scans'),
  'scans are in the realtime publication');

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.buses (id, school_id, plate, capacity) values ('b0000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'LT 1', 50);
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001', 'inbound', 'active', now(), now());
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('11000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('11000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved');
insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by) values
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001'),
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', '11000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-000000000001');

-- What Realtime delivers follows the same policy as a select: a student gets only their own boardings.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.scans), 1, 'a student sees one boarding: their own');
select is((select student_id from public.scans), 'a1000000-0000-4000-8000-000000000001'::uuid, 'never another student''s');
reset role;

select * from finish();
rollback;
