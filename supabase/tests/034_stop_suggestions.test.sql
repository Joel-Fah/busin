begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A'), ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data)
select ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, 's' || n || '@a.edu', '{"provider":"google"}'
from generate_series(1, 6) n;
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2030, current_date - 30, current_date + 30);
-- S1 and S2 about 220 m apart; S3 far east.
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'S1', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'S2', extensions.st_point(11.502, 3.85)::extensions.geography),
  ('d1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'S3', extensions.st_point(11.6, 3.85)::extensions.geography);

-- Six students of S1 live together about 2.2 km north of it.
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status)
select '10000000-0000-4000-8000-000000000001', ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid,
  'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'
from generate_series(1, 6) n;
insert into public.student_areas (user_id, school_id, area, label, source)
select ('a1000000-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, '10000000-0000-4000-8000-000000000001',
  private.snap_area(3.87, 11.5), 'Home', 'search'
from generate_series(1, 6) n;

-- A landmark and a street next to them (the landmark wins a tie), a landmark beside S1 (never a new stop), another
-- school's landmark right there (never shown).
insert into public.places (school_id, osm_id, name, kind, location, search_key) values
  ('10000000-0000-4000-8000-000000000001', 'n1', 'Market', 'landmark', extensions.st_point(11.5, 3.8702)::extensions.geography, 'market'),
  ('10000000-0000-4000-8000-000000000001', 'w1', 'Main street', 'street', extensions.st_point(11.5, 3.8702)::extensions.geography, 'main street'),
  ('10000000-0000-4000-8000-000000000001', 'n2', 'Beside S1', 'landmark', extensions.st_point(11.5003, 3.8501)::extensions.geography, 'beside s1'),
  ('10000000-0000-4000-8000-000000000002', 'n3', 'Elsewhere', 'landmark', extensions.st_point(11.5, 3.8702)::extensions.geography, 'elsewhere');

-- S1 had boardings this month; S2 and S3 none.
insert into public.buses (id, school_id, plate, capacity) values ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 30);
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at, ended_at) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', 'completed', now() - interval '3 days', now() - interval '3 days', now() - interval '3 days');
insert into private.stop_trip_loads (trip_id, stop_id, school_id, day, direction, boardings, seats) values
  ('f1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', current_date - 3, 'inbound', 4, 30);

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select results_eq(
  $$select place_name, students from public.admin_stop_suggestions() where kind = 'new_stop'$$,
  $$values ('Market', 6)$$,
  'one new stop: the named landmark next to the six students, not the one beside a stop');
select ok((select metres between 1800 and 2600 from public.admin_stop_suggestions() where kind = 'new_stop'), 'with how far they live from a stop today');
select is((select insert_after from public.admin_stop_suggestions() where kind = 'new_stop'), null, 'no route: no place in it');
reset role;
-- A route S3 > S1 ending at a campus far north: the new stop (north of S1) fits between S1 and the campus.
update public.schools set campus_location = extensions.st_point(11.5, 3.95)::extensions.geography, campus_name = 'Campus' where id = '10000000-0000-4000-8000-000000000001';
insert into public.routes (id, school_id) values ('aa000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001');
insert into public.route_stops (route_id, stop_id, school_id, position) values
  ('aa000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 0),
  ('aa000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 1);
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select insert_after from public.admin_stop_suggestions() where kind = 'new_stop'), 1, 'with a route: after the stop it detours least from');
select results_eq(
  $$select stop_id::text, other_stop_id::text, students from public.admin_stop_suggestions() where kind = 'close_pair'$$,
  $$values ('d1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000002', 6)$$,
  'two stops about 220 m apart, with their subscribers');
select results_eq(
  $$select stop_id::text from public.admin_stop_suggestions() where kind = 'unused' order by 1$$,
  $$values ('d1000000-0000-4000-8000-000000000002'), ('d1000000-0000-4000-8000-000000000003')$$,
  'stops with no boarding for 6 weeks while another had some');
reset role;

-- Fewer than five far: no new stop.
delete from public.student_areas where user_id in ('a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002');
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.admin_stop_suggestions() where kind = 'new_stop'), 0, 'never a suggestion for fewer than 5 students');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.admin_stop_suggestions()), 0, 'another school sees none of it');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.admin_stop_suggestions()$$, '42501', null, 'staff cannot read suggestions');
reset role;

set local role anon;
select throws_ok($$select * from public.admin_stop_suggestions()$$, '42501', null, 'nor anonymous visitors');
reset role;

select * from finish();
rollback;
