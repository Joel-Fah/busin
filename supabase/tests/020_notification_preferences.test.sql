begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30),
  ('c1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'spring', 2020, '2020-01-01', '2020-05-01');
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status) values
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001', 'approved');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select row(riding_days, morning_on, morning_time, evening_on, bus_near_minutes)::text from public.my_notification_preferences()),
  row(31::smallint, true, '06:30'::time, false, 5::smallint)::text, 'the defaults before anything is saved: weekdays, a morning reminder at 6:30');
select lives_ok($$select public.set_notification_preferences(21::smallint, true, '06:45', true, '17:00', false, 10::smallint, true)$$, 'a student saves their preferences');
select is((select row(riding_days, evening_on, evening_time, bus_near_on)::text from public.my_notification_preferences()), row(21::smallint, true, '17:00'::time, false)::text, 'and reads them back');
select throws_ok($$select public.set_notification_preferences(200::smallint, true, '06:45', true, '17:00', false, 10::smallint, true)$$, '23514', null, 'days outside the week are refused');
select throws_ok($$select public.set_notification_preferences(31::smallint, true, '06:45', true, '17:00', true, 60::smallint, true)$$, '23514', null, 'a "bus near" warning more than 30 minutes ahead is refused');
select throws_ok($$insert into public.notification_preferences (user_id, school_id) values ('a1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001')$$, '42501', null, 'nobody writes the table directly');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select count(*)::int from public.notification_preferences), 0, 'a student never reads another student''s preferences');
reset role;

-- school notices
update public.semesters set end_date = end_date + 7 where id = 'c1000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox where kind = 'school_notice' and ref_id = 'c1000000-0000-4000-8000-000000000001'), 1, 'moving a running semester tells its subscribed students');
select is((select user_id from private.notification_outbox where kind = 'school_notice'), 'a1000000-0000-4000-8000-000000000001'::uuid, 'only them');
update public.semesters set end_date = end_date + 1 where id = 'c1000000-0000-4000-8000-000000000002';
select is((select count(*)::int from private.notification_outbox where kind = 'school_notice' and ref_id = 'c1000000-0000-4000-8000-000000000002'), 0, 'a semester long finished tells no one');
update public.semesters set name = 'summer' where id = 'c1000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox where kind = 'school_notice'), 1, 'and only a change of dates counts');

select * from finish();
rollback;
