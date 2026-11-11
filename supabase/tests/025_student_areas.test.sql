begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

insert into public.schools (id, name, timezone) values ('10000000-0000-4000-8000-000000000001', 'School A', 'UTC'), ('10000000-0000-4000-8000-000000000002', 'School B', 'UTC');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
select ('a1000000-0000-4000-8000-00000000000' || i)::uuid, 's' || i || '@a.edu', '{"provider":"google"}', '{}' from generate_series(1, 6) i;
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data) values
  ('b1000000-0000-4000-8000-000000000001', 'b@b.edu', '{"provider":"google"}', '{}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}', '{}');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';
insert into public.stops (school_id, name, location) values
  ('10000000-0000-4000-8000-000000000001', 'Stop', extensions.st_point(11.5, 3.85)::extensions.geography);

-- Snapping: two points 100 m apart share a cell, the cell centre is not the point, and the cell is about 500 m.
select is(private.snap_area(3.8601, 11.5101), private.snap_area(3.8605, 11.5106), 'nearby points share a cell');
select ok(extensions.st_distance(private.snap_area(3.8601, 11.5101), extensions.st_point(11.5101, 3.8601)::extensions.geography) > 0, 'the exact point is not kept');
select ok(extensions.st_distance(private.snap_area(3.8601, 11.5101), private.snap_area(3.8601 + 0.0045, 11.5101)) between 450 and 550, 'cells are about 500 m apart');

select set_config('t.lat', round(extensions.st_y(private.snap_area(3.8601, 11.5101)::extensions.geometry)::numeric, 6)::text, true);
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.set_my_area(3.8601, 11.5101, 'Bastos', 'device')$$, 'a student sets their area');
select is((select label from public.my_area()), 'Bastos', 'and reads it back');
select is((select round(lat::numeric, 6) from public.my_area()), current_setting('t.lat')::numeric, 'snapped, as stored');
select lives_ok($$select public.set_my_area(3.87, 11.52, 'Etoudi', 'search')$$, 'and changes it (one row)');
select throws_ok($$select public.set_my_area(48.85, 2.35, 'Paris', 'search')$$, '22023', 'too_far', 'far from every stop of the school');
select throws_ok($$select public.set_my_area(3.87, 11.52, '  ', 'search')$$, '22023', 'invalid_label', 'a label is needed');
select throws_ok($$select public.set_my_area(3.87, 11.52, 'X', 'gps')$$, '22023', 'invalid_source', 'only device or search');
select throws_ok('select * from public.student_areas', '42501', null, 'the table itself is closed');
select throws_ok('select * from public.admin_area_counts()', '42501', null, 'a student cannot read the counts');
select lives_ok('select public.clear_my_area()', 'and removes it');
select is((select count(*)::int from public.my_area()), 0, 'gone');
reset role;

-- Five students in one cell, one alone in another.
insert into public.student_areas (user_id, school_id, area, label, source)
select ('a1000000-0000-4000-8000-00000000000' || i)::uuid, '10000000-0000-4000-8000-000000000001', private.snap_area(3.86, 11.51), 'Bastos', 'device' from generate_series(1, 5) i;
insert into public.student_areas (user_id, school_id, area, label, source)
values ('a1000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000001', private.snap_area(3.90, 11.55), 'Alone', 'device');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select results_eq('select students from public.admin_area_counts()', $$values (5)$$, 'admins see only cells with at least 5 students');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.my_area()), 0, 'another school''s student sees no area');
reset role;

select * from finish();
rollback;
