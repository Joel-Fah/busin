begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000003', 'stu3@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000004', 'stu4@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'stu@b.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2090, '2090-09-01', '2091-01-31'),
  ('c1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'spring', 2020, '2020-02-01', '2020-06-30'),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2090, '2090-09-01', '2091-01-31');
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A1', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Stop A2', extensions.st_point(11.51, 3.86)::extensions.geography),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Stop B', extensions.st_point(11.6, 3.86)::extensions.geography);
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status) values
  -- Stop A1: two approved and one pending in the open semester, one approved in a finished one.
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000003', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'pending'),
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  -- Stop A2: only a rejected one, which does not count.
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000004', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000002', 'rejected'),
  -- Another school.
  ('10000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001', 'd2000000-0000-4000-8000-000000000001', 'approved');

-- ---------------------------------------------------------------- student
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.admin_stop_usage()$$, '42501', 'Admin access required', 'a student cannot read stop usage');

-- ---------------------------------------------------------------- admin
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.admin_stop_usage()), 1, 'only stops with live subscriptions in an open semester are returned');
select is((select students from public.admin_stop_usage() where stop_id = 'd1000000-0000-4000-8000-000000000001'), 2, 'approved students are counted');
select is((select pending from public.admin_stop_usage() where stop_id = 'd1000000-0000-4000-8000-000000000001'), 1, 'pending requests are counted apart');
select is((select count(*)::int from public.admin_stop_usage() where stop_id = 'd1000000-0000-4000-8000-000000000002'), 0, 'rejected requests do not count');
select is((select count(*)::int from public.admin_stop_usage() where stop_id = 'd2000000-0000-4000-8000-000000000001'), 0, 'another school is not visible');

-- ---------------------------------------------------------------- another school's admin
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select students from public.admin_stop_usage()), 1, 'an admin sees only their own school');
select is((select count(*)::int from public.admin_stop_usage() where stop_id = 'd1000000-0000-4000-8000-000000000001'), 0, 'and not the other school''s stops');

-- ---------------------------------------------------------------- anon
reset role;
set local role anon;
set local "request.jwt.claims" = '{"role":"anon"}';
select throws_ok($$select * from public.admin_stop_usage()$$, '42501', null, 'anonymous callers cannot call it');

reset role;
select * from finish();
rollback;
