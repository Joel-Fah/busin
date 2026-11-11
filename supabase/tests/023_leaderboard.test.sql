begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into public.schools (id, name, timezone) values ('10000000-0000-4000-8000-000000000001', 'School A', 'UTC'), ('10000000-0000-4000-8000-000000000002', 'School B', 'UTC');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'ama@a.edu', '{"provider":"google"}', '{"full_name":"Amara Ngono Ekotto"}'),
  ('a1000000-0000-4000-8000-000000000002', 'kofi@a.edu', '{"provider":"google"}', '{"full_name":"Kofi Mensah"}'),
  ('a1000000-0000-4000-8000-000000000003', 'lea@a.edu', '{"provider":"google"}', '{"full_name":"Lea Fotso"}'),
  ('a1000000-0000-4000-8000-000000000004', 'quiet@a.edu', '{"provider":"google"}', '{"full_name":"Not Opted"}'),
  ('b1000000-0000-4000-8000-000000000001', 'bob@b.edu', '{"provider":"google"}', '{"full_name":"Bob B"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}', '{}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
update public.profiles set streak_opt_in = true, streak_opt_in_at = current_date - 5
where id in ('a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-000000000001');
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2026, current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.buses (id, school_id, plate, capacity) values ('b0000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'LT 1', 50);
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status)
select gen_random_uuid(), '10000000-0000-4000-8000-000000000001', u, 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'
from unnest(array['a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000003', 'a1000000-0000-4000-8000-000000000004']::uuid[]) u;
-- A trip each of the last five days; everyone rides every day (riding days default to Monday to Friday, so let
-- every day count for this test).
insert into public.trips (school_id, bus_id, direction, status, scheduled_start)
select '10000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001', 'inbound', 'completed', (current_date - k)::timestamp + interval '7 hours'
from generate_series(1, 5) k;
insert into public.notification_preferences (user_id, school_id, riding_days)
select p.id, '10000000-0000-4000-8000-000000000001', 127 from public.profiles p where p.school_id = '10000000-0000-4000-8000-000000000001' and p.role = 'student';
-- Ama rode 5 days, Kofi the last 2, Lea 3 then missed the last 2, the quiet one every day (but did not opt in).
insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by, scanned_at)
select '10000000-0000-4000-8000-000000000001', t.id, s.student_id, s.id, 'a2000000-0000-4000-8000-000000000001', t.scheduled_start
from public.trips t
join public.subscriptions s on s.semester_id = 'c1000000-0000-4000-8000-000000000001'
where t.school_id = '10000000-0000-4000-8000-000000000001' and (
  s.student_id in ('a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000004')
  or (s.student_id = 'a1000000-0000-4000-8000-000000000002' and t.scheduled_start::date >= current_date - 2)
  or (s.student_id = 'a1000000-0000-4000-8000-000000000003' and t.scheduled_start::date <= current_date - 3)
);

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select string_agg(display_name || ':' || current_streak, ', ' order by rank) from public.school_leaderboard('c1000000-0000-4000-8000-000000000001')),
  'Amara E.:5, Kofi M.:2, Lea F.:0', 'ranked by current streak, names shortened, only those who opted in');
select is((select display_name from public.school_leaderboard('c1000000-0000-4000-8000-000000000001') where is_me), 'Kofi M.', 'the caller is marked');
select is((select count(*)::int from public.school_leaderboard('c1000000-0000-4000-8000-000000000001') where display_name like 'Not%'), 0, 'a student who did not opt in never appears');
select is((select count(*)::int from public.school_leaderboard('c2000000-0000-4000-8000-000000000001')), 0, 'another school''s board is empty for the caller');
select is((select string_agg(display_name, ',' order by rank) from public.school_leaderboard('c1000000-0000-4000-8000-000000000001', 1)), 'Amara E.,Kofi M.',
  'a short board still includes the caller');
select is((select max(rank) from public.school_leaderboard('c1000000-0000-4000-8000-000000000001', 1000)), 3, 'the limit is capped and the board lists its students');
reset role;

-- School B's student sees only school B
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.school_leaderboard('c1000000-0000-4000-8000-000000000001')), 0, 'never another school''s students');
select is((select string_agg(display_name, ',') from public.school_leaderboard('c2000000-0000-4000-8000-000000000001')), 'Bob B.', 'only their own school');
reset role;

select is(private.short_name('  Amara   Ngono Ekotto '), 'Amara E.', 'extra spaces do not matter');

select * from finish();
rollback;
