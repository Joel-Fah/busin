begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

-- School health signals and levels for the platform console (ADR 0027, slice 2).

-- H: an established school with problems. N: created today (grace period). I: switched off.
insert into public.schools (id, name, created_at, contact_email, phone, address, about, logo_path, campus_location) values
  ('a0000000-0000-4000-8000-0000000000a1', 'Health School', now() - interval '60 days', 'office@h.edu', '+237677000000',
   'Main street', 'About us', 'x/logo.webp', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.schools (id, name) values ('a0000000-0000-4000-8000-0000000000b2', 'New School');
insert into public.schools (id, name, status) values ('a0000000-0000-4000-8000-0000000000c3', 'Off School', 'inactive');
insert into public.school_domains (domain, school_id) values ('h.edu', 'a0000000-0000-4000-8000-0000000000a1');

insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-0000000000a1', 'admin@h.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-0000000000a2', 'one@h.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-0000000000a3', 'two@h.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-0000000000a4', 'three@h.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-0000000000a5', 'joiner@gmail.com', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-0000000000f1', 'owner@gmail.com', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'a1000000-0000-4000-8000-0000000000a1';
-- A personal email asked to join School H 15 days ago.
update public.profiles set school_id = 'a0000000-0000-4000-8000-0000000000a1', join_requested_at = now() - interval '15 days'
where id = 'a1000000-0000-4000-8000-0000000000a5';
insert into private.platform_admins (user_id, note) values ('a1000000-0000-4000-8000-0000000000f1', 'test');

-- A semester that ends in 5 days (the school's own date), with nothing after it; one stop.
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('a2000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-0000000000a1', 'fall', 2092,
   (now() at time zone 'Africa/Douala')::date - 60, (now() at time zone 'Africa/Douala')::date + 5);
insert into public.stops (id, school_id, name, location) values
  ('a3000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-0000000000a1', 'Gate', extensions.st_point(11.5, 3.85)::extensions.geography);

-- Two requests answered in 2 and 3 days (median 2.5), one waiting with its proof for 8 days.
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path, status, created_at, reviewed_at) values
  ('a0000000-0000-4000-8000-0000000000a1', 'a1000000-0000-4000-8000-0000000000a2', 'a2000000-0000-4000-8000-0000000000a1', 'a3000000-0000-4000-8000-0000000000a1',
   'p/1.jpg', 'approved', now() - interval '10 days', now() - interval '8 days'),
  ('a0000000-0000-4000-8000-0000000000a1', 'a1000000-0000-4000-8000-0000000000a3', 'a2000000-0000-4000-8000-0000000000a1', 'a3000000-0000-4000-8000-0000000000a1',
   'p/2.jpg', 'approved', now() - interval '10 days', now() - interval '7 days'),
  ('a0000000-0000-4000-8000-0000000000a1', 'a1000000-0000-4000-8000-0000000000a4', 'a2000000-0000-4000-8000-0000000000a1', 'a3000000-0000-4000-8000-0000000000a1',
   'p/3.jpg', 'pending', now() - interval '8 days', null);

-- The administrator did something yesterday.
insert into public.audit_log (school_id, actor_id, action, target_type, created_at)
values ('a0000000-0000-4000-8000-0000000000a1', 'a1000000-0000-4000-8000-0000000000a1', 'subscription.approved', 'subscription', now() - interval '1 day');

create temporary table h as select * from private.school_signals('a0000000-0000-4000-8000-0000000000a1');
create temporary table n as select * from private.school_signals('a0000000-0000-4000-8000-0000000000b2');
grant select on h, n to authenticated;

-- ---------------------------------------------------------------- the signals
select is((select level from h where signal = 'oldest_pending_days'), 2::smallint, 'a request waiting 8 days with its proof needs help (more than 7)');
select is((select level from h where signal = 'oldest_request_days'), 3::smallint, 'a join request waiting 15 days is critical (more than 14)');
select is((select value from h where signal = 'answer_time_days'), 2.5, 'the time to answer is the median of the last 30 days');
select is((select level from h where signal = 'answer_time_days'), 1::smallint, '2.5 days to answer is to watch (more than 2)');
select is((select value from h where signal = 'profile_missing'), 1::numeric, 'one profile field is missing (the website)');
select is((select level from h where signal = 'profile_missing'), 1::smallint, 'one missing field is to watch');
-- Billing, route, buses and staff are missing: four.
select is((select value from h where signal = 'setup_missing'), 4::numeric, 'four things are missing to run');
select is((select detail from h where signal = 'setup_missing'), '["billing", "route", "buses", "staff"]'::jsonb, 'and the detail names them');
select is((select value from h where signal = 'semester_days_left'), 5::numeric, 'the last semester ends in 5 days');
select is((select level from h where signal = 'semester_days_left'), 2::smallint, 'with nothing after it, that needs help (fewer than 7 days)');
select is((select level from h where signal = 'admin_idle_days'), 0::smallint, 'an administrator active yesterday is fine');
select is((select value from h where signal = 'scanned_trips_pct'), null, 'with no trips, the share of scanned trips does not apply');

select is((select level from n where signal = 'profile_missing'), 1::smallint, 'a new school with an empty profile is only to watch during its first 14 days');
select is((select graced from n where signal = 'profile_missing'), true, 'and says so');
select is((select count(*)::int from private.school_signals('a0000000-0000-4000-8000-0000000000c3')), 0, 'a switched-off school is not scored');

-- ---------------------------------------------------------------- what the console reads
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select * from public.platform_schools()$$, '42501', null, 'a school admin cannot read the health of schools');
select throws_ok($$select public.platform_school('a0000000-0000-4000-8000-0000000000a1')$$, '42501', null, 'nor one school''s');

set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select ok(
  (select array_position(array_agg(id), 'a0000000-0000-4000-8000-0000000000a1') < array_position(array_agg(id), 'a0000000-0000-4000-8000-0000000000b2')
   from public.platform_schools()),
  'the most troubled schools come first');
select is(
  (select reasons->0->>'signal' from public.platform_schools() where id = 'a0000000-0000-4000-8000-0000000000a1'),
  'setup_missing', 'the first reason is the worst signal with the most weight');
select ok(
  (select public.platform_school('a0000000-0000-4000-8000-0000000000a1')->'admin_actions'->0 ?& array['action', 'at']
     and not (public.platform_school('a0000000-0000-4000-8000-0000000000a1')->'admin_actions'->0 ? 'actor_id')),
  'administrators'' actions show the kind and the time, never who');
select is(public.platform_school('a0000000-0000-4000-8000-000000000999'), null, 'an unknown school is null');
select throws_ok($$select * from public.school_health_daily$$, '42501', null, 'the nightly record is read through functions only');

-- ---------------------------------------------------------------- the nightly record
reset role;
select ok(private.record_school_health() >= 2, 'the nightly job records every active school');
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select is(
  jsonb_array_length(public.platform_school('a0000000-0000-4000-8000-0000000000a1')->'history'), 1,
  'the school page shows the record');

select * from finish();
rollback;
