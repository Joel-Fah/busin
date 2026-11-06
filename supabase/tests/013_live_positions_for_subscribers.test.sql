begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'approved@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'pending@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000003', 'none@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000004', 'revoked@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000005', 'past@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'student@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30),
  ('c1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'spring', 2020, '2020-01-10', '2020-05-30'),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2026, current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Stop B', extensions.st_point(11.6, 3.86)::extensions.geography);
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status) values
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'pending'),
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000004', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'revoked'),
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000005', 'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('10000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001', 'd2000000-0000-4000-8000-000000000001', 'approved');
insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'BUS-A', 40),
  ('e2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'BUS-B', 40);
insert into public.live_positions (bus_id, school_id, location) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('e2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', extensions.st_point(11.6, 3.86)::extensions.geography);

create function pg_temp.as_user(p_id text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_id, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;

select pg_temp.as_user('a1000000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.live_positions), 1, 'an approved subscriber sees their own school''s bus, and only that');
select ok(public.can_follow_buses(), 'and is told they can follow');

reset role;
select pg_temp.as_user('a1000000-0000-4000-8000-000000000002');
select is((select count(*)::int from public.live_positions), 0, 'a pending request does not see the bus');
select ok(not public.can_follow_buses(), 'and is told they cannot');

reset role;
select pg_temp.as_user('a1000000-0000-4000-8000-000000000003');
select is((select count(*)::int from public.live_positions), 0, 'a student who never subscribed does not see the bus');

reset role;
select pg_temp.as_user('a1000000-0000-4000-8000-000000000004');
select is((select count(*)::int from public.live_positions), 0, 'a revoked subscription loses the bus');

reset role;
select pg_temp.as_user('a1000000-0000-4000-8000-000000000005');
select is((select count(*)::int from public.live_positions), 0, 'an approved subscription of a past semester does not count');

reset role;
select pg_temp.as_user('a2000000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.live_positions), 1, 'staff see their school''s buses');

reset role;
select pg_temp.as_user('a3000000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.live_positions), 1, 'an admin sees their school''s buses');

reset role;
select pg_temp.as_user('b1000000-0000-4000-8000-000000000001');
select is((select bus_id::text from public.live_positions), 'e2000000-0000-4000-8000-000000000001', 'a subscriber of another school sees only that school''s bus');

reset role;
set local role anon;
select throws_ok($$select public.can_follow_buses()$$, '42501', null, 'signed-out callers cannot even ask');

select * from finish();
rollback;
