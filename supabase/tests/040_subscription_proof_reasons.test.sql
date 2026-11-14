begin;
create extension if not exists pgtap with schema extensions;
select plan(27);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A');
-- Students can only ask once their school has set billing (ADR 0022).
update public.schools set billing_period = 'semester', price_xaf = 30000;
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000003', 'stu3@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30),
  ('c1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'spring', 2020, '2020-01-10', '2020-06-30');
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);

-- Stored proofs (what the student app uploads first).
insert into storage.objects (bucket_id, name, owner) values
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/receipt.jpg', 'a1000000-0000-4000-8000-000000000001'),
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000003/receipt.jpg', 'a1000000-0000-4000-8000-000000000003');

-- History loaded without a signed-in user (seeds do): a request without a proof, and one in an ended semester.
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('11000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'pending');
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status, proof_path) values
  ('11000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000003', 'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001', 'pending',
   '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000003/receipt.jpg');

-- ---------------------------------------------------------------- a student's request needs a proof that exists
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id)
  values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001')$$,
  '22023', 'proof_required', 'a request without a proof is refused');
select throws_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path)
  values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/never-uploaded.jpg')$$,
  '22023', 'proof_missing', 'nor with the path of a file that was never uploaded');
select throws_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path)
  values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/receipt.jpg')$$,
  '55000', 'semester_ended', 'nor for a semester that has ended');
select lives_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path)
  values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/receipt.jpg')$$,
  'a request with a stored proof for a running semester is accepted');
reset role;

-- ---------------------------------------------------------------- approving
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000002', 'approved')$$, '22023', 'proof_required', 'a subscription without a proof cannot be approved');
select throws_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000004', 'approved')$$, '55000', 'semester_ended', 'nor one whose semester has ended');
select lives_ok($$select public.admin_review_subscription((select id from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001'), 'approved')$$, 'one with a proof is approved');
select lives_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000002', 'rejected', 'No payment proof was uploaded.')$$,
  'a request that has none can be rejected, which is what an admin does with the old ones');

-- ---------------------------------------------------------------- reasons: required, trimmed, 10 to 500
select throws_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000004', 'rejected', '   ')$$, '22023', 'reason_required', 'rejecting needs a reason');
select throws_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000004', 'rejected', E'  too \n short  ')$$, '22023', 'reason_too_short', 'a reason under 10 characters (after trimming) is too short');
select throws_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000004', 'rejected', repeat('x', 501))$$, '22023', 'reason_too_long', 'and over 500 is too long');
select lives_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000004', 'rejected', E'   The   receipt\n\nis   unreadable.   ')$$, 'a padded, multi-line reason is accepted');
select is((select review_note from public.subscriptions where id = '11000000-0000-4000-8000-000000000004'), 'The receipt is unreadable.', 'and stored trimmed with its spaces collapsed');

select throws_ok($$select public.admin_revoke_subscription((select id from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001'), 'short')$$, '22023', 'reason_too_short', 'a revoke reason is held to the same rule');
select lives_ok($$select public.admin_revoke_subscription((select id from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001'), '  Payment was reversed by the bank  ')$$, 'a good one revokes');
select throws_ok($$select public.admin_reinstate_subscription((select id from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001'))$$, '22023', 'reason_required', 'giving it back now needs a reason too');
select throws_ok($$select public.admin_reinstate_subscription((select id from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001'), 'ok')$$, '22023', 'reason_too_short', 'a sensible one');
select lives_ok($$select public.admin_reinstate_subscription((select id from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001'), 'Paid in cash at the office')$$, 'a good reason gives it back');
select is((select review_note from public.subscriptions where id = (select id from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001')), 'Paid in cash at the office', 'and is the note kept');

-- ---------------------------------------------------------------- restoring in a semester that has ended
reset role;
update public.subscriptions set status = 'revoked' where id = '11000000-0000-4000-8000-000000000004';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_reinstate_subscription('11000000-0000-4000-8000-000000000004', 'It was approved by mistake')$$, '55000', 'semester_ended', 'a subscription of an ended semester is not given back');

-- ---------------------------------------------------------------- trips and join requests
reset role;
insert into public.buses (id, school_id, plate, capacity) values ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50);
insert into public.trips (id, school_id, bus_id, direction, scheduled_start) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', now() + interval '1 day'),
  ('f1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'outbound', now() + interval '1 day');
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000001', 'rain')$$, '22023', 'reason_too_short', 'cancelling a trip with a reason that is too short is refused');
select throws_ok($$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000001', repeat('x', 301))$$, '22023', 'reason_too_long', 'or too long (300 here)');
select lives_ok($$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000001')$$, 'the reason for cancelling a trip stays optional');
select lives_ok($$select public.admin_cancel_trip('f1000000-0000-4000-8000-000000000002', 'The bus is in the garage')$$, 'and a good one is accepted');

reset role;
insert into auth.users (id, email, raw_app_meta_data) values ('a1000000-0000-4000-8000-000000000009', 'joiner@a.edu', '{"provider":"google"}');
update public.profiles set status = 'pending', join_requested_at = now() where id = 'a1000000-0000-4000-8000-000000000009';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_decline_member('a1000000-0000-4000-8000-000000000009', 'no')$$, '22023', 'reason_too_short', 'declining a join request with a reason that is too short is refused');
select lives_ok($$select public.admin_decline_member('a1000000-0000-4000-8000-000000000009', 'This email is not on our list')$$, 'a good reason declines it');
reset role;
select is((select join_decline_note from public.profiles where id = 'a1000000-0000-4000-8000-000000000009'), 'This email is not on our list', 'and is stored');

select * from finish();
rollback;
