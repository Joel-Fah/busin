begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A'), ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data)
select ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, 's' || n || '@a.edu', '{"provider":"google"}'
from generate_series(1, 12) n;
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2030, current_date - 30, current_date + 30);
-- X and Y are about 2.2 km apart on a north-south line; Z is closed, right where the students live.
insert into public.stops (id, school_id, name, location, active) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop X', extensions.st_point(11.5, 3.85)::extensions.geography, true),
  ('d1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Stop Y', extensions.st_point(11.5, 3.87)::extensions.geography, true),
  ('d1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'Stop Z', extensions.st_point(11.5, 3.8685)::extensions.geography, false);

-- Students 1 to 6 ride from X but live next to Y; 7 and 8 ride from X and live by X; 9 to 12 ride from Y and live
-- next to X (only 4: too few to show).
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status)
select '10000000-0000-4000-8000-000000000001', ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid,
  'c1000000-0000-4000-8000-000000000001',
  case when n <= 8 then 'd1000000-0000-4000-8000-000000000001' else 'd1000000-0000-4000-8000-000000000002' end::uuid, 'approved'
from generate_series(1, 12) n;
insert into public.student_areas (user_id, school_id, area, label, source)
select ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, '10000000-0000-4000-8000-000000000001',
  case when n <= 6 then private.snap_area(3.8695, 11.5) else private.snap_area(3.8505, 11.5) end, 'Home', 'search'
from generate_series(1, 12) n;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select results_eq(
  $$select from_stop::text, to_stop::text, students from public.admin_nearer_stops()$$,
  $$values ('d1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000002', 6)$$,
  'six students of X live nearer to Y; four of Y nearer to X are too few; a closed stop is never suggested');
select ok((select saved_m between 1500 and 2500 from public.admin_nearer_stops()), 'with about how much nearer');
reset role;

-- A small difference does not count: move Y so it is barely nearer for students 1 to 6.
update public.stops set location = extensions.st_point(11.5, 3.8615)::extensions.geography where id = 'd1000000-0000-4000-8000-000000000002';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.admin_nearer_stops() where from_stop = 'd1000000-0000-4000-8000-000000000001'), 1, 'still 300 m or more closer');
reset role;
update public.stops set location = extensions.st_point(11.5, 3.8605)::extensions.geography where id = 'd1000000-0000-4000-8000-000000000002';
update public.stops set location = extensions.st_point(11.5, 3.8640)::extensions.geography where id = 'd1000000-0000-4000-8000-000000000001';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.admin_nearer_stops() where from_stop = 'd1000000-0000-4000-8000-000000000001'), 0, 'under 300 m closer is not worth a move');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.admin_nearer_stops()), 0, 'another school sees none of it');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.admin_nearer_stops()$$, '42501', null, 'staff cannot read it');
reset role;

set local role anon;
select throws_ok($$select * from public.admin_nearer_stops()$$, '42501', null, 'nor anonymous visitors');
reset role;

select * from finish();
rollback;
