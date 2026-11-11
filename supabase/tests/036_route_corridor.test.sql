begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into public.schools (id, name, campus_location, campus_name) values
  ('10000000-0000-4000-8000-000000000001', 'School A', extensions.st_point(11.50, 3.90)::extensions.geography, 'Campus');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data)
select ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, 's' || n || '@a.edu', '{"provider":"google"}'
from generate_series(1, 7) n;
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2030, current_date - 30, current_date + 30);
-- A route straight north along longitude 11.50, from 3.80 to the campus at 3.90.
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'S1', extensions.st_point(11.50, 3.80)::extensions.geography),
  ('d1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'S2', extensions.st_point(11.50, 3.85)::extensions.geography);
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status)
select '10000000-0000-4000-8000-000000000001', ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid,
  'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'
from generate_series(1, 7) n;
-- Five live beside the line (in the middle, about 100 m east), one about 3.3 km east, one gave no area.
insert into public.student_areas (user_id, school_id, area, label, source)
select ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, '10000000-0000-4000-8000-000000000001',
  case when n = 6 then private.snap_area(3.825, 11.53) else private.snap_area(3.825, 11.501) end, 'Home', 'search'
from generate_series(1, 6) n;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select has_route from public.admin_route_corridor()), false, 'no route yet: nothing to measure against');
select is((select median_m from public.admin_route_corridor()), null, 'and no figure');
select public.admin_save_route(array['d1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000002']::uuid[]);
select results_eq($$select subscribers, with_area, under_500, to_1k, to_2k, over_2k, has_route from public.admin_route_corridor()$$,
  $$values (7, 6, 5, 0, 0, 1, true)$$, 'distances to the straight route through the stops to the campus, in bands');
select ok((select median_m < 300 from public.admin_route_corridor()), 'most live beside it');
reset role;

-- A drawn road, current, is used instead: one that bends far east makes everyone far.
select public.service_store_route('10000000-0000-4000-8000-000000000001',
  private.route_hash((select id from public.routes where school_id = '10000000-0000-4000-8000-000000000001')),
  '{"type":"LineString","coordinates":[[11.5,3.8],[11.6,3.8],[11.6,3.9],[11.5,3.9]]}', 30000, 3600, '[]'::jsonb);
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select ok((select median_m > 2000 from public.admin_route_corridor()), 'the drawn road counts once it is current');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.admin_route_corridor()$$, '42501', null, 'staff cannot read it');
reset role;
set local role anon;
select throws_ok($$select * from public.admin_route_corridor()$$, '42501', null, 'nor anonymous visitors');
reset role;

select * from finish();
rollback;
