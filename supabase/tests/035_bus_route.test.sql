begin;
create extension if not exists pgtap with schema extensions;
select plan(25);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A'), ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'student@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');
insert into public.stops (id, school_id, name, location, active) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'First', extensions.st_point(11.50, 3.80)::extensions.geography, true),
  ('d1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Second', extensions.st_point(11.50, 3.82)::extensions.geography, true),
  ('d1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'Closed', extensions.st_point(11.50, 3.83)::extensions.geography, false),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Theirs', extensions.st_point(11.60, 3.80)::extensions.geography, true);

-- ---------------------------------------------------------------- campus and order
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.route_waypoints()$$, '22023', 'no_campus', 'no route can be drawn without a campus');
select lives_ok($$select public.admin_set_campus(3.86, 11.50, 'Main campus')$$, 'an admin sets the campus');
select throws_ok($$select public.admin_set_campus(95, 11.5, 'X')$$, '22023', 'invalid_point', 'the campus point is checked');
select throws_ok($$select * from public.route_waypoints()$$, '22023', 'no_route', 'nor without stops in order');
select throws_ok($$select public.admin_save_route(array[]::uuid[])$$, '22023', 'empty_route', 'a route has stops');
select throws_ok($$select public.admin_save_route(array['d1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001']::uuid[])$$, '22023', 'repeated_stop', 'once each');
select throws_ok($$select public.admin_save_route(array['d1000000-0000-4000-8000-000000000003']::uuid[])$$, '22023', 'unknown_stop', 'only active stops');
select throws_ok($$select public.admin_save_route(array['d2000000-0000-4000-8000-000000000001']::uuid[])$$, '22023', 'unknown_stop', 'only the school''s stops');
select isnt(public.admin_save_route(array['d1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001']::uuid[]), null, 'the order is saved');
select is(public.admin_save_route(array['d1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000002']::uuid[]),
  (select id from public.routes where school_id = '10000000-0000-4000-8000-000000000001'), 'and changed on the same route');
select results_eq($$select kind, name from public.route_waypoints() order by seq$$,
  $$values ('stop', 'First'), ('stop', 'Second'), ('campus', 'Main campus')$$, 'waypoints: the stops in order, then the campus');
select results_eq($$select kind, name from public.route_waypoints(array['d1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000002']::uuid[], array[3.81], array[11.51], array['Market'], array[0]) order by seq$$,
  $$values ('stop', 'First'), ('extra', 'Market'), ('stop', 'Second'), ('campus', 'Main campus')$$, 'a preview inserts a suggested stop where asked');
select results_eq($$select kind from public.route_waypoints(array['d1000000-0000-4000-8000-000000000002']::uuid[], array[3.79], array[11.5], array['Start'], array[-1]) order by seq$$,
  $$values ('extra'), ('stop'), ('campus')$$, 'even before the first stop');
select results_eq($$select name from public.route_waypoints(array['d1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000002']::uuid[],
    array[3.815, 3.805], array[11.5, 11.5], array['Far', 'Near'], array[0, 0]) where kind = 'extra' order by seq$$,
  $$values ('Near'), ('Far')$$, 'several suggested stops after the same stop go nearest first');
select is((select current from public.school_route()), false, 'not drawn yet');
reset role;

-- ---------------------------------------------------------------- storing the road
select is(public.service_store_route('10000000-0000-4000-8000-000000000001', 'stale', '{"type":"LineString","coordinates":[[11.5,3.8],[11.5,3.86]]}', 7000, 900, '[]'::jsonb),
  false, 'a road drawn for another order is not stored');
select is(public.service_store_route('10000000-0000-4000-8000-000000000001',
  private.route_hash((select id from public.routes where school_id = '10000000-0000-4000-8000-000000000001')),
  '{"type":"LineString","coordinates":[[11.5,3.8],[11.5,3.82],[11.5,3.86]]}', 7000, 900,
  '[{"distance_m":2300,"duration_s":300},{"distance_m":4700,"duration_s":600}]'::jsonb), true, 'the current one is');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select current::text || ':' || distance_m || ':' || jsonb_array_length(stops) from public.school_route()), 'true:7000:2', 'students of the school read the route');
select throws_ok($$select public.admin_save_route(array['d1000000-0000-4000-8000-000000000001']::uuid[])$$, '42501', null, 'but cannot change it');
select throws_ok($$select public.service_store_route('10000000-0000-4000-8000-000000000001', 'x', '{}', 1, 1, '[]'::jsonb)$$, '42501', null, 'nor store a road');
reset role;

-- A new order makes the drawn road out of date.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select public.admin_save_route(array['d1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001']::uuid[]);
select is((select current from public.school_route()), false, 'a new order needs a new road');
reset role;

-- ---------------------------------------------------------------- other school, quota
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.routes), 0, 'another school sees no route of ours');
select is((select route_id from public.school_route()), null, 'and its own is empty');
reset role;

insert into private.route_directions_usage (school_id, at)
select '10000000-0000-4000-8000-000000000001', now() from generate_series(1, 30);
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.route_waypoints()$$, 'PT429', null, 'at most 30 road requests an hour');
reset role;
select is((select count(*)::int from public.audit_log where action in ('route.saved', 'route.campus_set') and school_id = '10000000-0000-4000-8000-000000000001'), 4, 'changes are audited');

select * from finish();
rollback;
