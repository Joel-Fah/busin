begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);

-- the student asks: one event, the request
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id) values
  ('11000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001');
select is((select string_agg(action, ',' order by id) from public.subscription_events where subscription_id = '11000000-0000-4000-8000-000000000001'), 'requested', 'asking is recorded as a request');
select is((select actor_id from public.subscription_events where subscription_id = '11000000-0000-4000-8000-000000000001'), 'a1000000-0000-4000-8000-000000000001'::uuid, 'by the student');

-- the admin approves, revokes with a reason, reinstates
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select public.admin_review_subscription('11000000-0000-4000-8000-000000000001', 'approved');
select public.admin_revoke_subscription('11000000-0000-4000-8000-000000000001', 'Payment reversed');
select throws_ok($$select public.admin_reinstate_subscription('11000000-0000-4000-8000-000000000002')$$, 'P0002', 'Subscription not found', 'an unknown subscription is not found');
select lives_ok($$select public.admin_reinstate_subscription('11000000-0000-4000-8000-000000000001', 'Paid in cash')$$, 'an admin can reinstate a revoked subscription');
reset role;

select is((select status::text from public.subscriptions where id = '11000000-0000-4000-8000-000000000001'), 'approved', 'it is approved again');
select is((select string_agg(action, ',' order by id) from public.subscription_events where subscription_id = '11000000-0000-4000-8000-000000000001'), 'requested,approved,revoked,reinstated', 'every operation is kept, in order, on the same subscription');
select is((select note from public.subscription_events where subscription_id = '11000000-0000-4000-8000-000000000001' and action = 'revoked'), 'Payment reversed', 'the revoke keeps its reason');
select is((select note from public.subscription_events where subscription_id = '11000000-0000-4000-8000-000000000001' and action = 'reinstated'), 'Paid in cash', 'and the reinstatement its note');
select is((select actor_id from public.subscription_events where subscription_id = '11000000-0000-4000-8000-000000000001' and action = 'reinstated'), 'a3000000-0000-4000-8000-000000000001'::uuid, 'who reinstated it is recorded');
select is((select count(*)::int from public.audit_log where action = 'subscription.reinstated' and target_id = '11000000-0000-4000-8000-000000000001'), 1, 'and it is in the audit log');
select is((select count(*)::int from private.notification_outbox where kind = 'subscription_approved' and ref_id = '11000000-0000-4000-8000-000000000001'), 2, 'the student is told again (the approval and the reinstatement)');

-- only revoked ones can be reinstated, and not when a newer request is live
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_reinstate_subscription('11000000-0000-4000-8000-000000000001')$$, '55000', 'Only revoked subscriptions can be reinstated', 'an approved one cannot be reinstated');
select public.admin_revoke_subscription('11000000-0000-4000-8000-000000000001', 'Again');
reset role;
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id) values
  ('11000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001');
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_reinstate_subscription('11000000-0000-4000-8000-000000000001')$$, '55000', 'The student already has a live subscription for this semester', 'not while a newer request is waiting');
reset role;
select is((select count(*)::int from public.subscription_events where subscription_id = '11000000-0000-4000-8000-000000000002'), 1, 'the newer request is its own subscription with its own history');

-- who may do and read what
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_reinstate_subscription('11000000-0000-4000-8000-000000000001')$$, '42501', 'Admin access required', 'a student cannot reinstate');
select is((select count(*)::int from public.subscription_events), 6, 'a student reads the history of their own requests: five operations on the first, one on the second');
select throws_ok($$insert into public.subscription_events (school_id, subscription_id, student_id, action) values ('10000000-0000-4000-8000-000000000001', '11000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'approved')$$, '42501', null, 'but cannot write one');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select count(*)::int from public.subscription_events), 0, 'another student sees none of it');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.subscription_events), 0, 'nor does an admin of another school');
reset role;

select * from finish();
rollback;
