begin;
create extension if not exists pgtap with schema extensions;
select plan(30);

-- Staff access requests and student/staff role changes (ADR 0026).

-- Independent of the local data: schools already in the database accept no open sign-up here (rolled back at the end).
update public.schools set accepts_open_signup = false, open_signup_domains = '{}', public_listing = false;

insert into public.schools (id, name, accepts_open_signup) values
  ('10000000-0000-4000-8000-000000000001', 'School A', true),
  ('20000000-0000-4000-8000-000000000002', 'School B', false);
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '20000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'subscribed@a.edu', '{"provider":"google"}'),
  ('c1000000-0000-4000-8000-000000000001', 'someone@gmail.com', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'driver@a.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2091, current_date - 10, current_date + 60);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path) values
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'e1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'x/y/p.jpg');
insert into public.buses (id, school_id, plate, capacity) values ('f2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50);
insert into public.trips (id, school_id, bus_id, driver_id, direction, scheduled_start) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'f2000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', 'inbound', now() + interval '1 day');

set local role authenticated;

-- ---------------------------------------------------------------- asking
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select status::text from public.profiles where id = 'c1000000-0000-4000-8000-000000000001'), 'pending', 'a personal email starts as a pending student with no school');
select ok((select count(*) from public.list_staff_request_schools()) >= 2, 'an account with no school may ask any active school');
select lives_ok($$select public.request_staff_access('20000000-0000-4000-8000-000000000002')$$, 'it asks School B');
select throws_ok($$select public.request_staff_access('10000000-0000-4000-8000-000000000001')$$, '54000', 'too_many', 'not twice within 30 seconds');
select results_eq($$select school_id, school_name from public.my_staff_request()$$, $$values ('20000000-0000-4000-8000-000000000002'::uuid, 'School B')$$, 'it sees its own request');
select throws_ok($$select public.request_staff_access('99999999-0000-4000-8000-000000000009')$$, '54000', null, 'an unknown school is refused too (after the wait, school_unknown)');

set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select results_eq($$select id from public.list_staff_request_schools()$$, $$values ('10000000-0000-4000-8000-000000000001'::uuid)$$, 'a student of a school sees only their own school');
select throws_ok($$select public.request_staff_access('20000000-0000-4000-8000-000000000002')$$, '42501', 'not_your_school', 'and cannot ask another');
select lives_ok($$select public.request_staff_access('10000000-0000-4000-8000-000000000001')$$, 'they ask their own school');
select throws_ok($$update public.profiles set staff_request_school = null where id = 'a1000000-0000-4000-8000-000000000001'$$, '42501', null, 'the request columns are not writable directly');

set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.request_staff_access('10000000-0000-4000-8000-000000000001')$$, 'a subscribed student may ask too');

set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.request_staff_access('10000000-0000-4000-8000-000000000001')$$, '42501', 'not_student', 'staff do not ask');

-- ---------------------------------------------------------------- who sees them
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select results_eq($$select id, student_here, live_subscription from public.admin_staff_requests() order by email$$,
  $$values ('a1000000-0000-4000-8000-000000000001'::uuid, true, false), ('a1000000-0000-4000-8000-000000000002'::uuid, true, true)$$,
  'School A''s admin sees its two requests, with who is a student here and who has a live subscription');
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select results_eq($$select id from public.admin_staff_requests()$$, $$values ('c1000000-0000-4000-8000-000000000001'::uuid)$$, 'School B''s admin sees only the one asked of it');
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.admin_staff_requests()$$, '42501', null, 'a student cannot list requests');
select throws_ok($$select public.admin_review_staff_request('a1000000-0000-4000-8000-000000000001', true)$$, '42501', null, 'nor decide one');

-- ---------------------------------------------------------------- deciding
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_review_staff_request('a1000000-0000-4000-8000-000000000002', true)$$, '55000', 'live_subscription', 'a student with a live subscription is not made staff');
select throws_ok($$select public.admin_review_staff_request('c1000000-0000-4000-8000-000000000001', true)$$, 'P0002', 'no_request', 'an admin decides only requests made to their school');
select lives_ok($$select public.admin_review_staff_request('a1000000-0000-4000-8000-000000000001', true)$$, 'approved');
select is((select row(role, status, school_id, staff_request_school)::text from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'),
  row('staff'::public.user_role, 'verified'::public.account_status, '10000000-0000-4000-8000-000000000001'::uuid, null::uuid)::text, 'the account is verified staff of the school');

set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.admin_review_staff_request('c1000000-0000-4000-8000-000000000001', false, 'We did not invite you.')$$, 'School B declines, with a note');
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select results_eq($$select school_id, declined_school_name, decline_note from public.my_staff_request()$$,
  $$values (null::uuid, 'School B', 'We did not invite you.')$$, 'the person sees the decline and its note');
select is((select row(role, status, school_id)::text from public.profiles where id = 'c1000000-0000-4000-8000-000000000001'),
  row('student'::public.user_role, 'pending'::public.account_status, null::uuid)::text, 'the account is unchanged: still a student, free to join a school as one');
select lives_ok($$select public.request_school('10000000-0000-4000-8000-000000000001')$$, 'the same email can still ask to join a school as a student');
select lives_ok($$select public.request_staff_access('20000000-0000-4000-8000-000000000002')$$, 'or ask for staff access again: nothing is blocked');

-- ---------------------------------------------------------------- the role of a person
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_set_user_role('a2000000-0000-4000-8000-000000000001', 'student')$$, '55000', 'upcoming_trips', 'staff on a coming trip stays staff until it is reassigned');
reset role;
update public.trips set status = 'active', started_at = now() where id = 'f1000000-0000-4000-8000-000000000001';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_set_user_role('a2000000-0000-4000-8000-000000000001', 'student')$$, '55000', 'active_trip', 'nor while on a running trip');
select lives_ok($$select public.admin_set_user_role('a1000000-0000-4000-8000-000000000001', 'student')$$, 'the new staff member can be made a student again');
select throws_ok($$select public.admin_set_user_role('a1000000-0000-4000-8000-000000000001', 'admin')$$, '22023', 'role_family', 'a student is never made an administrator directly');
reset role;
select is((select count(*)::int from public.audit_log where action in ('member.staff_requested', 'member.staff_approved', 'member.staff_declined')), 6, 'requests and decisions are audited');

select * from finish();
rollback;
