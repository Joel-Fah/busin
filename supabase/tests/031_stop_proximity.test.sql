begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

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
insert into public.stops (id, school_id, name, location, active) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop X', extensions.st_point(11.5, 3.85)::extensions.geography, true),
  ('d1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Stop Y', extensions.st_point(11.6, 3.85)::extensions.geography, true),
  ('d1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'Stop Z', extensions.st_point(11.7, 3.85)::extensions.geography, false);

-- Students 1 to 7 at X (1 to 5 live in the cell next to it, 6 about 2.5 km north, 7 gave no area); 8 to 10 at Y (all
-- with areas, too few for figures); 11 pending at X; 12 approved at X but with a suspended account.
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status)
select '10000000-0000-4000-8000-000000000001', ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid,
  'c1000000-0000-4000-8000-000000000001',
  case when n between 8 and 10 then 'd1000000-0000-4000-8000-000000000002' else 'd1000000-0000-4000-8000-000000000001' end::uuid,
  case when n = 11 then 'pending' else 'approved' end::public.subscription_status
from generate_series(1, 12) n;
update public.profiles set status = 'suspended' where id = 'a1000000-0000-4000-8000-000000000012';

insert into public.student_areas (user_id, school_id, area, label, source)
select ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, '10000000-0000-4000-8000-000000000001',
  case when n = 6 then private.snap_area(3.87, 11.5) when n between 8 and 10 then private.snap_area(3.851, 11.601) else private.snap_area(3.851, 11.501) end,
  'Home', 'search'
from generate_series(1, 12) n where n not in (7);

-- ---------------------------------------------------------------- per stop
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select results_eq(
  $$select stop_id::text, subscribers, with_area, under_500, to_1k, to_2k, over_2k from public.admin_stop_proximity() order by stop_id$$,
  $$values ('d1000000-0000-4000-8000-000000000001', 7, 6, 5, 0, 0, 1), ('d1000000-0000-4000-8000-000000000002', 3, 3, null::int, null::int, null::int, null::int)$$,
  'subscribers, areas and bands per active stop; pending and suspended students do not count');
select ok((select median_m between 50 and 200 from public.admin_stop_proximity() where stop_id = 'd1000000-0000-4000-8000-000000000001'), 'the median is the distance most students live at');
select is((select median_m from public.admin_stop_proximity() where stop_id = 'd1000000-0000-4000-8000-000000000002'), null, 'no figure under 5 students with an area');
select is((select count(*)::int from public.admin_stop_proximity() where stop_id = 'd1000000-0000-4000-8000-000000000003'), 0, 'inactive stops are left out');

-- ---------------------------------------------------------------- desire lines
select is((select count(*)::int from public.admin_desire_lines()), 1, 'one line: the only cell with 5 students of one stop');
select is((select stop_id::text || ':' || students from public.admin_desire_lines()), 'd1000000-0000-4000-8000-000000000001:5', 'to its stop, with its count');
select ok((select distance_m between 50 and 200 from public.admin_desire_lines()), 'and the distance');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.admin_stop_proximity()), 0, 'another school sees none of it');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.admin_stop_proximity()$$, '42501', null, 'staff cannot read proximity');
select throws_ok($$select * from public.admin_desire_lines()$$, '42501', null, 'nor desire lines');
reset role;

set local role anon;
select throws_ok($$select * from public.admin_desire_lines()$$, '42501', null, 'nor anonymous visitors');
reset role;

select * from finish();
rollback;
