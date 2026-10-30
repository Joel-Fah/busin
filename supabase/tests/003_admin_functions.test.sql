begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'stu@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, '2026-09-01', '2027-01-31'),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2026, '2026-09-01', '2027-01-31');
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Stop B', extensions.st_point(11.6, 3.86)::extensions.geography);
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id) values
  ('11000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001'),
  ('11000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001',
   'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001'),
  ('11000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002',
   'b1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001', 'd2000000-0000-4000-8000-000000000001');

-- ---------------------------------------------------------------- student
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';

select throws_ok(
  $$select public.admin_review_subscription('11000000-0000-4000-8000-000000000001', 'approved')$$,
  '42501', 'Admin access required', 'student cannot review subscriptions');
select throws_ok(
  $$select public.admin_set_user_role('a1000000-0000-4000-8000-000000000002', 'admin')$$,
  '42501', 'Admin access required', 'student cannot change roles');
select throws_ok(
  $$select public.admin_set_user_status('a1000000-0000-4000-8000-000000000002', 'suspended')$$,
  '42501', 'Admin access required', 'student cannot suspend users');

-- ---------------------------------------------------------------- staff
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';

select throws_ok(
  $$select public.admin_review_subscription('11000000-0000-4000-8000-000000000001', 'approved')$$,
  '42501', 'Admin access required', 'staff cannot review subscriptions');

-- ---------------------------------------------------------------- admin
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';

select lives_ok(
  $$select public.admin_review_subscription('11000000-0000-4000-8000-000000000001', 'approved')$$,
  'admin can approve a pending subscription');
select is(
  (select status::text from public.subscriptions where id = '11000000-0000-4000-8000-000000000001'),
  'approved', 'the subscription is approved');
select is(
  (select reviewed_by from public.subscriptions where id = '11000000-0000-4000-8000-000000000001'),
  'a3000000-0000-4000-8000-000000000001'::uuid, 'the reviewer is recorded');
select is(
  (select count(*)::int from public.audit_log where action = 'subscription.approved'),
  1, 'approval is written to the audit log');
select throws_ok(
  $$select public.admin_review_subscription('11000000-0000-4000-8000-000000000001', 'rejected', 'late')$$,
  '55000', 'Only pending subscriptions can be reviewed', 'a reviewed subscription cannot be reviewed again');
select throws_ok(
  $$select public.admin_review_subscription('11000000-0000-4000-8000-000000000002', 'rejected')$$,
  '22023', 'A reason is required to reject a subscription', 'rejection needs a reason');
select throws_ok(
  $$select public.admin_review_subscription('11000000-0000-4000-8000-000000000002', 'maybe')$$,
  '22023', 'Decision must be approved or rejected', 'unknown decision is rejected');
select lives_ok(
  $$select public.admin_review_subscription('11000000-0000-4000-8000-000000000002', 'rejected', 'Receipt is unreadable')$$,
  'admin can reject with a reason');
select is(
  (select review_note from public.subscriptions where id = '11000000-0000-4000-8000-000000000002'),
  'Receipt is unreadable', 'the reason is stored');
select throws_ok(
  $$select public.admin_review_subscription('11000000-0000-4000-8000-000000000003', 'approved')$$,
  'P0002', 'Subscription not found', 'admin cannot review another school subscription');

select lives_ok(
  $$select public.admin_set_user_role('a1000000-0000-4000-8000-000000000002', 'staff')$$,
  'admin can promote a student to staff');
select is(
  (select role::text from public.profiles where id = 'a1000000-0000-4000-8000-000000000002'),
  'staff', 'the role changed');
select throws_ok(
  $$select public.admin_set_user_role('a3000000-0000-4000-8000-000000000001', 'student')$$,
  '42501', 'You cannot change your own role', 'admin cannot change their own role');
select throws_ok(
  $$select public.admin_set_user_role('b1000000-0000-4000-8000-000000000001', 'staff')$$,
  'P0002', 'User not found', 'admin cannot change a user of another school');
select lives_ok(
  $$select public.admin_set_user_status('a1000000-0000-4000-8000-000000000002', 'suspended')$$,
  'admin can suspend a user');
select throws_ok(
  $$select public.admin_set_user_status('a3000000-0000-4000-8000-000000000001', 'suspended')$$,
  '42501', 'You cannot change your own status', 'admin cannot suspend themselves');
select is(
  (select count(*)::int from public.audit_log where action like 'user.%'),
  2, 'role and status changes are audited');

-- A suspended user loses access on the very next request, without waiting for the token to refresh.
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select count(*)::int from public.stops), 0, 'suspension applies immediately');

-- ---------------------------------------------------------------- anon
reset role;
set local role anon;
set local "request.jwt.claims" = '{"role":"anon"}';
select throws_ok(
  $$select public.admin_review_subscription('11000000-0000-4000-8000-000000000001', 'approved')$$,
  '42501', null, 'anonymous callers cannot run admin functions');

reset role;
select * from finish();
rollback;
