begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
-- Students can only ask once their school has set billing (ADR 0022).
update public.schools set billing_period = 'semester', price_xaf = 30000;
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'stu@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, '2026-09-01', '2027-01-31'),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2026, '2026-09-01', '2027-01-31');
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Stop B', extensions.st_point(11.6, 3.86)::extensions.geography);
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('11000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved'),
  ('11000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'pending'),
  ('11000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001', 'd2000000-0000-4000-8000-000000000001', 'approved');

-- a student cannot revoke
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.admin_revoke_subscription('11000000-0000-4000-8000-000000000001', 'no longer enrolled')$$,
  '42501', 'Admin access required', 'a student cannot revoke a subscription');

-- an admin of another school cannot see it, so it is not found
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.admin_revoke_subscription('11000000-0000-4000-8000-000000000001', 'no longer enrolled')$$,
  'P0002', 'Subscription not found', 'an admin of another school cannot revoke it');

-- the admin of the school
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.admin_revoke_subscription('11000000-0000-4000-8000-000000000001', '   ')$$,
  '22023', 'reason_required', 'a reason is required');
select throws_ok(
  $$select public.admin_revoke_subscription('11000000-0000-4000-8000-000000000001', repeat('x', 501))$$,
  '22023', 'reason_too_long', 'the reason has a limit');
select throws_ok(
  $$select public.admin_revoke_subscription('11000000-0000-4000-8000-000000000002', 'changed my mind')$$,
  '55000', 'Only approved subscriptions can be revoked', 'a pending one cannot be revoked (it is reviewed instead)');

select lives_ok(
  $$select public.admin_revoke_subscription('11000000-0000-4000-8000-000000000001', 'Payment was reversed')$$,
  'an admin can revoke an approved subscription');
select is((select status::text from public.subscriptions where id = '11000000-0000-4000-8000-000000000001'), 'revoked', 'it is revoked');
select is((select review_note from public.subscriptions where id = '11000000-0000-4000-8000-000000000001'), 'Payment was reversed', 'the reason is kept for the student');
select is((select reviewed_by from public.subscriptions where id = '11000000-0000-4000-8000-000000000001'), 'a3000000-0000-4000-8000-000000000001'::uuid, 'who revoked it is recorded');
select throws_ok(
  $$select public.admin_revoke_subscription('11000000-0000-4000-8000-000000000001', 'Trying to revoke it again')$$,
  '55000', 'Only approved subscriptions can be revoked', 'a revoked one cannot be revoked twice');

reset role;
select is((select count(*)::int from public.audit_log where action = 'subscription.revoked' and target_id = '11000000-0000-4000-8000-000000000001'), 1, 'the revocation is in the audit log');

-- the student can ask again once it is revoked (the live-subscription rule no longer blocks)
reset role;
insert into storage.objects (bucket_id, name, owner) values
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/again.jpg', 'a1000000-0000-4000-8000-000000000001');
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok(
  $$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path) values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/again.jpg')$$,
  'the student can request again after a revocation');

-- and a revoked subscription is not counted as a way to board
reset role;
select is(
  (select count(*)::int from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001' and status = 'approved'),
  0, 'the student has no approved subscription left');

select * from finish();
rollback;
