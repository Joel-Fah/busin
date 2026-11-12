begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into public.schools (id, name, timezone) values
  ('10000000-0000-4000-8000-000000000001', 'School A', 'Africa/Douala'),
  ('10000000-0000-4000-8000-000000000002', 'School B', 'Africa/Douala');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000003', 'stu3@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'stu@b.edu', '{"provider":"google"}'),
  ('b2000000-0000-4000-8000-000000000001', 'staff@b.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id in ('a2000000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000001');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2030, current_date - 30, current_date + 30),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2030, current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Stop B', extensions.st_point(11.6, 3.86)::extensions.geography);
insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50),
  ('e2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'B-1', 50);
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'completed', now(), now()),
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'outbound', 'completed', now(), now()),
  ('f2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'e2000000-0000-4000-8000-000000000001', 'inbound', 'completed', now(), now());
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('51000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('51000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('51000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000003', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('52000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001', 'd2000000-0000-4000-8000-000000000001', 'approved');

-- School A: two boardings now, one three days ago, one far outside the window. School B: one now.
insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by, scanned_at) values
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', '51000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', now()),
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', '51000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-000000000001', now()),
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000001', '51000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', now() - interval '3 days'),
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000003', '51000000-0000-4000-8000-000000000003', 'a2000000-0000-4000-8000-000000000001', now() - interval '60 days'),
  ('10000000-0000-4000-8000-000000000002', 'f2000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', '52000000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000001', now());

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.admin_boardings_by_day(7)$$, '42501', 'Admin access required', 'staff cannot read the chart');

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.admin_boardings_by_day(7)), 7, 'one row per day, gaps included');
select is((select sum(boardings)::int from public.admin_boardings_by_day(7)), 3, 'only boardings inside the window and school are counted');
select is((select boardings from public.admin_boardings_by_day(7) order by day desc limit 1), 2, 'today holds today''s boardings');
select is((select count(*)::int from public.admin_boardings_by_day(7) where boardings = 0), 5, 'quiet days are zero');
select is((select count(*)::int from public.admin_boardings_by_day(1000)), 90, 'the window is capped at 90 days');
select is((select count(*)::int from public.admin_boardings_by_day(0)), 1, 'the window is at least one day');

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select sum(boardings)::int from public.admin_boardings_by_day(7)), 1, 'another school''s admin sees only their own');

select * from finish();
rollback;
