begin;
create extension if not exists pgtap with schema extensions;
select plan(33);

-- Installments (ADR 0022): the parts of a request paid in installments, who reads them, the student's proofs, the
-- administrator's decisions, and the reminders.

insert into public.schools (id, name, timezone, billing_period, price_xaf, installment_plan) values
  ('10000000-0000-4000-8000-000000000001', 'School A', 'Africa/Douala', 'semester', 30001, '40-30-30'),
  ('20000000-0000-4000-8000-000000000002', 'School B', 'Africa/Douala', 'semester', 20000, '50-50');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '20000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

-- 120 days from today, so the parts fall on days 0, 40 and 80.
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', extract(year from current_date)::int, current_date, current_date + 119);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into storage.objects (bucket_id, name, owner) values
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/receipt.jpg', 'a1000000-0000-4000-8000-000000000001'),
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/part2.jpg', 'a1000000-0000-4000-8000-000000000001'),
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/receipt.jpg', 'a1000000-0000-4000-8000-000000000002');

-- ---------------------------------------------------------------- the parts of a request
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path, payment_mode)
values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001',
        '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/receipt.jpg', 'installments');
select results_eq($$select seq::int, percent::int, amount_xaf, due_date - current_date, status from public.subscription_installments order by seq$$,
  $$values (1, 40, 12000, 0, 'submitted'), (2, 30, 9000, 40, 'due'), (3, 30, 9001, 80, 'due')$$,
  'a request in installments gets its parts: shares of the price adding up exactly, due across the semester');
select is((select proof_path from public.subscription_installments where seq = 1), '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/receipt.jpg', 'part 1 is the request''s proof');
select throws_ok($$insert into public.subscription_installments (school_id, subscription_id, student_id, seq, percent, amount_xaf, due_date)
  select school_id, id, student_id, 4, 10, 1, current_date from public.subscriptions$$, '42501', null, 'a student cannot add a part');
select throws_ok($$update public.subscription_installments set status = 'paid'$$, '42501', null, 'nor mark one paid');

set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path)
values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001',
        '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/receipt.jpg');
select is((select count(*)::int from public.subscription_installments), 0, 'another student sees no parts of the first, and paying in full has none');
reset role;
select is((select count(*)::int from public.subscription_installments where student_id = 'a1000000-0000-4000-8000-000000000002'), 0, 'a request paid in full has no parts at all');

-- ---------------------------------------------------------------- who reads them
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.subscription_installments), 3, 'the school''s administrator reads them');
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.subscription_installments), 0, 'another school''s does not');
select throws_ok($$select public.admin_review_installment((select id from public.subscription_installments limit 1), 'paid')$$, 'P0002', null, 'nor can decide on them');

-- ---------------------------------------------------------------- deciding the request settles part 1
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.admin_review_subscription((select id from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001'), 'approved')$$, 'the administrator approves the request');
select is((select status from public.subscription_installments where seq = 1), 'paid', 'which marks part 1 paid');
select throws_ok($$select public.admin_review_installment((select id from public.subscription_installments where seq = 1), 'rejected', 'Not a real receipt at all')$$, '55000', 'installment_not_open', 'part 1 is not decided on its own');

-- ---------------------------------------------------------------- a later part
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.submit_installment_proof((select id from public.subscription_installments where seq = 1), '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/part2.jpg')$$,
  '55000', 'installment_not_open', 'a paid part takes no proof');
select throws_ok($$select public.submit_installment_proof((select id from public.subscription_installments where seq = 2), '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/receipt.jpg')$$,
  '22023', 'proof_required', 'the proof must be in the student''s own folder');
select throws_ok($$select public.submit_installment_proof((select id from public.subscription_installments where seq = 2), '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/never.jpg')$$,
  '22023', 'proof_missing', 'and uploaded');
select lives_ok($$select public.submit_installment_proof((select id from public.subscription_installments where seq = 2), '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/part2.jpg')$$,
  'the student sends a proof for part 2');
select is((select status from public.subscription_installments where seq = 2), 'submitted', 'which waits for the school');
select throws_ok($$select public.admin_review_installment((select id from public.subscription_installments where seq = 2), 'paid')$$, '42501', null, 'a student cannot decide on it');
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.submit_installment_proof((select id from public.subscription_installments where seq = 3), '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/receipt.jpg')$$,
  'P0002', null, 'nor send a proof for someone else''s part');

set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_review_installment((select id from public.subscription_installments where seq = 2), 'rejected')$$, '22023', 'reason_required', 'rejecting a part needs a reason');
select lives_ok($$select public.admin_review_installment((select id from public.subscription_installments where seq = 2), 'rejected', 'The amount on the receipt is wrong')$$, 'a proof is rejected with a reason');
select is((select row(status, review_note)::text from public.subscription_installments where seq = 2), '(rejected,"The amount on the receipt is wrong")', 'and the student sees why');

set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.submit_installment_proof((select id from public.subscription_installments where seq = 2), '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/part2.jpg')$$,
  'a rejected part can be sent again');
select is((select row(status, review_note)::text from public.subscription_installments where seq = 2), '(submitted,)', 'clearing the old reason');

set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.admin_review_installment((select id from public.subscription_installments where seq = 2), 'paid')$$, 'the administrator marks it paid');
select lives_ok($$select public.admin_review_installment((select id from public.subscription_installments where seq = 3), 'paid')$$, 'and part 3 too, paid at the office without a proof');
select throws_ok($$select public.admin_review_installment((select id from public.subscription_installments where seq = 3), 'paid')$$, '55000', 'installment_not_open', 'a paid part stays paid');
reset role;
select is((select count(*)::int from public.audit_log where action like 'installment.%'), 3, 'each decision is audited');
select results_eq($$select kind from private.notification_outbox where kind like 'installment_%' order by id$$,
  $$values ('installment_rejected'), ('installment_paid'), ('installment_paid')$$, 'and the student is told each time');

-- ---------------------------------------------------------------- reminders
update public.subscription_installments set status = 'due', due_date = current_date + 3, reminded_on = null where seq = 3;
-- At 7 school time nothing; at 8 the reminder; later that day not again.
select is(private.remind_installments(((current_date + time '07:30') at time zone 'Africa/Douala')), 0, 'not before 8 in the morning, school time');
select is(private.remind_installments(((current_date + time '08:30') at time zone 'Africa/Douala')), 1, 'a part due in three days is reminded at 8');
select is((select count(*)::int from private.notification_outbox where kind = 'installment_due'), 1, 'as an installment_due notification');
select is(private.remind_installments(((current_date + time '08:45') at time zone 'Africa/Douala')), 0, 'and only once that day');

select * from finish();
rollback;
