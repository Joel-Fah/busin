begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

insert into public.schools (id, name, timezone) values ('10000000-0000-4000-8000-000000000001', 'School A', 'UTC'), ('10000000-0000-4000-8000-000000000002', 'School B', 'UTC');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'other@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'stu@b.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2026, current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.buses (id, school_id, plate, capacity) values ('b0000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'LT 1', 50);
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('11000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved');

-- A trip every day of the last ten, except four days ago (no service).
insert into public.trips (school_id, bus_id, direction, status, scheduled_start)
select '10000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001', 'inbound', 'completed', (current_date - k)::timestamp + interval '7 hours'
from generate_series(1, 10) k where k <> 4;
-- Rode 10, 9, 8 days ago; missed 7; rode 6, 5; no service 4; rode 3; rest 2; rode 1. Today not yet.
-- Each boarding is on that day's trip (a scan is unique per trip and student).
insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by, scanned_at)
select '10000000-0000-4000-8000-000000000001', t.id, 'a1000000-0000-4000-8000-000000000001',
  '11000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', t.scheduled_start + interval '10 minutes'
from public.trips t
where t.school_id = '10000000-0000-4000-8000-000000000001' and t.scheduled_start::date in (current_date - 10, current_date - 9, current_date - 8, current_date - 6, current_date - 5, current_date - 3, current_date - 1);
-- Riding days: every day except the weekday of two days ago (a rest day).
insert into public.notification_preferences (user_id, school_id, riding_days)
values ('a1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', (127 & ~(1 << (extract(isodow from current_date - 2)::int - 1)))::smallint);

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.my_ride_days('c1000000-0000-4000-8000-000000000001')), 0, 'nothing before opting in');
select is((select count(*)::int from public.my_streak('c1000000-0000-4000-8000-000000000001')), 0, 'no streak before opting in');
select lives_ok($$select public.set_streak_opt_in(true)$$, 'the student opts in');
reset role;
-- As if they had opted in ten days ago.
update public.profiles set streak_opt_in_at = (current_date - 10)::timestamp where id = 'a1000000-0000-4000-8000-000000000001';

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select string_agg(state, ',' order by day) from public.my_ride_days('c1000000-0000-4000-8000-000000000001') where day < current_date),
  'rode,rode,rode,missed,rode,rode,no_service,rode,rest,rode', 'each past day has its state');
select is((select state from public.my_ride_days('c1000000-0000-4000-8000-000000000001') where day = current_date), 'today', 'today is still open');
select is((select state from public.my_ride_days('c1000000-0000-4000-8000-000000000001') where day = current_date + 1), 'future', 'tomorrow is to come');
select is((select min(day) from public.my_ride_days('c1000000-0000-4000-8000-000000000001')), current_date - 10, 'days start when they opted in, not at the semester start');
select is((select row(current_streak, best_streak, rides)::text from public.my_streak('c1000000-0000-4000-8000-000000000001')), row(4, 4, 7)::text,
  'current 4 (rest and no-service days do not break it), best 4, 7 rides');
select is((select count(*)::int from public.my_streak('c2000000-0000-4000-8000-000000000001')), 0, 'never another school''s semester');
reset role;

-- A boarding recorded late (offline queue) on the missed day mends the streak.
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start) values
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001', 'inbound', 'completed', current_date - 29);
insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by, scanned_at) values
  ('10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000001',
   'a2000000-0000-4000-8000-000000000001', (current_date - 7)::timestamp + interval '7 hours');
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select row(current_streak, best_streak, rides)::text from public.my_streak('c1000000-0000-4000-8000-000000000001')), row(8, 8, 8)::text, 'a late boarding mends the streak');
select lives_ok($$select public.set_streak_opt_in(false)$$, 'the student opts out');
select is((select count(*)::int from public.my_streak('c1000000-0000-4000-8000-000000000001')), 0, 'and has no streak any more');
reset role;

select * from finish();
rollback;
