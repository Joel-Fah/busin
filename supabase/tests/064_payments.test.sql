begin;
create extension if not exists pgtap with schema extensions;
select plan(63);

-- Mobile money payments (ADR 0029): opening a payment, settling it once, approving the request, the school's ledger,
-- BusIn's charge, refunds of what cannot be applied, and who reads what.

insert into public.schools (id, name, timezone, billing_period, price_xaf, installment_plan) values
  ('e0000000-0000-4000-8000-0000000000a1', 'Pay School', 'Africa/Douala', 'semester', 20000, '50-50'),
  ('e0000000-0000-4000-8000-0000000000b2', 'Other School', 'Africa/Douala', 'semester', 15000, null);
insert into public.school_domains (domain, school_id) values ('pay.edu', 'e0000000-0000-4000-8000-0000000000a1'), ('other.edu', 'e0000000-0000-4000-8000-0000000000b2');
insert into auth.users (id, email, raw_app_meta_data) values
  ('e1000000-0000-4000-8000-0000000000a1', 'admin@pay.edu', '{"provider":"google"}'),
  ('e1000000-0000-4000-8000-0000000000a2', 'ana@pay.edu', '{"provider":"google"}'),
  ('e1000000-0000-4000-8000-0000000000a3', 'ben@pay.edu', '{"provider":"google"}'),
  ('e1000000-0000-4000-8000-0000000000a4', 'cy@pay.edu', '{"provider":"google"}'),
  ('e1000000-0000-4000-8000-0000000000b1', 'admin@other.edu', '{"provider":"google"}');
update public.profiles set role = 'admin', status = 'verified' where id in ('e1000000-0000-4000-8000-0000000000a1', 'e1000000-0000-4000-8000-0000000000b1');
update public.profiles set status = 'verified' where id in ('e1000000-0000-4000-8000-0000000000a2', 'e1000000-0000-4000-8000-0000000000a3', 'e1000000-0000-4000-8000-0000000000a4');

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('e2000000-0000-4000-8000-0000000000a1', 'e0000000-0000-4000-8000-0000000000a1', 'fall', 2093,
   (now() at time zone 'Africa/Douala')::date - 10, (now() at time zone 'Africa/Douala')::date + 100);
insert into public.stops (id, school_id, name, location) values
  ('e3000000-0000-4000-8000-0000000000a1', 'e0000000-0000-4000-8000-0000000000a1', 'Gate', extensions.st_point(11.5, 3.85)::extensions.geography);

-- ---------------------------------------------------------------- asking without a receipt
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a2","role":"authenticated"}';
select throws_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, payment_method)
  values ('e0000000-0000-4000-8000-0000000000a1', 'e1000000-0000-4000-8000-0000000000a2', 'e2000000-0000-4000-8000-0000000000a1', 'e3000000-0000-4000-8000-0000000000a1', 'mobile_money')$$,
  '55000', 'mobile_money_off', 'a school that does not offer mobile money takes no request without a receipt');
select throws_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id)
  values ('e0000000-0000-4000-8000-0000000000a1', 'e1000000-0000-4000-8000-0000000000a2', 'e2000000-0000-4000-8000-0000000000a1', 'e3000000-0000-4000-8000-0000000000a1')$$,
  '22023', 'proof_required', 'a receipt request still needs its receipt');

reset role;
insert into private.school_payment_terms (school_id, enabled) values ('e0000000-0000-4000-8000-0000000000a1', true);
set local role authenticated;

-- Ana pays in full (asking as a student), Ben in installments, Cy in full.
select lives_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, payment_method)
  values ('e0000000-0000-4000-8000-0000000000a1', 'e1000000-0000-4000-8000-0000000000a2', 'e2000000-0000-4000-8000-0000000000a1', 'e3000000-0000-4000-8000-0000000000a1', 'mobile_money')$$,
  'once the school offers it, a request to pay by mobile money needs no receipt');
select is((select status::text from public.subscriptions where student_id = 'e1000000-0000-4000-8000-0000000000a2' and set_config('test.subA', id::text, true) is not null),
  'pending', 'it waits for its payment');
reset role;
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, payment_method, payment_mode) values
  ('e4000000-0000-4000-8000-0000000000a3', 'e0000000-0000-4000-8000-0000000000a1', 'e1000000-0000-4000-8000-0000000000a3', 'e2000000-0000-4000-8000-0000000000a1', 'e3000000-0000-4000-8000-0000000000a1', 'mobile_money', 'installments'),
  ('e4000000-0000-4000-8000-0000000000a4', 'e0000000-0000-4000-8000-0000000000a1', 'e1000000-0000-4000-8000-0000000000a4', 'e2000000-0000-4000-8000-0000000000a1', 'e3000000-0000-4000-8000-0000000000a1', 'mobile_money', 'full');
set local role authenticated;

-- ---------------------------------------------------------------- the quote and opening a payment
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a2","role":"authenticated"}';
select results_eq($$select amount_xaf, fee_xaf, total_xaf from public.payment_quote('subscription', current_setting('test.subA')::uuid)$$,
  $$values (20000, 500, 20500)$$, 'the quote: the school''s price, 2.5 percent on top, and the total');
select throws_ok($$select * from public.payment_quote('subscription', 'e4000000-0000-4000-8000-0000000000a3')$$, 'P0002', 'not_found', 'another student''s request is not found');
select throws_ok($$select * from public.start_payment('subscription', current_setting('test.subA')::uuid, 'WAVE_CMR', '237653456789')$$, '22023', 'bad_provider', 'an unknown operator is refused');
select throws_ok($$select * from public.start_payment('subscription', current_setting('test.subA')::uuid, 'MTN_MOMO_CMR', '+237 653456789')$$, '22023', 'bad_phone', 'the number is checked');
select throws_ok($$insert into public.payments (school_id, paid_by, purpose, subscription_id, item_key, amount_xaf, fee_xaf, fee_percent, provider, payer_masked)
  values ('e0000000-0000-4000-8000-0000000000a1', 'e1000000-0000-4000-8000-0000000000a2', 'subscription', current_setting('test.subA')::uuid, 'x', 1, 0, 0, 'ORANGE_CMR', 'x')$$,
  '42501', null, 'nobody writes a payment directly');

select lives_ok($$select set_config('test.pay1', (select id::text from public.start_payment('subscription', current_setting('test.subA')::uuid, 'MTN_MOMO_CMR', '237653456789')), true)$$,
  'the student opens a payment');
select is((select payer_masked from public.payments where id = current_setting('test.pay1')::uuid), '2376*****789', 'the number is kept partly hidden');
select is((select total_xaf from public.payments where id = current_setting('test.pay1')::uuid), 20500, 'with the total fixed when it starts');
select throws_ok($$select * from public.start_payment('subscription', current_setting('test.subA')::uuid, 'ORANGE_CMR', '237693456789')$$,
  '55000', 'payment_in_progress', 'only one payment at a time for the same request');

-- Nobody decides on the request while it is being paid; it cannot be approved without a receipt anyway.
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select public.admin_review_subscription(current_setting('test.subA')::uuid, 'rejected', 'Not now please')$$,
  '55000', 'payment_in_progress', 'the school cannot reject a request while it is being paid');
select throws_ok($$select public.admin_review_subscription('e4000000-0000-4000-8000-0000000000a4', 'approved')$$,
  '22023', 'proof_required', 'nor approve a mobile money request that has not been paid');
select is((select count(*)::int from public.payments), 1, 'the school''s administrator reads the school''s payments');
select throws_ok($$select * from public.start_payment('subscription', current_setting('test.subA')::uuid, 'MTN_MOMO_CMR', '237653456789')$$,
  '42501', 'not_allowed', 'an administrator does not pay a student''s request');
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000b1","role":"authenticated"}';
select is((select count(*)::int from public.payments), 0, 'another school''s administrator reads none');
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a3","role":"authenticated"}';
select is((select count(*)::int from public.payments), 0, 'another student reads none');
select throws_ok($$select public.settle_payment(current_setting('test.pay1')::uuid, 'COMPLETED')$$, '42501', null, 'only the server settles a payment');

-- ---------------------------------------------------------------- settling
reset role;
set local "request.jwt.claims" = '{}';
select is(public.settle_payment(current_setting('test.pay1')::uuid, 'ACCEPTED')->>'status', 'accepted', 'pawaPay accepted it');
select is(public.settle_payment('e9000000-0000-4000-8000-000000000999', 'COMPLETED'), null, 'an unknown payment is ignored');
select is(public.settle_payment(current_setting('test.pay1')::uuid, 'COMPLETED', '20500', 'XAF', 'MP123')->>'status', 'completed', 'then completed it');
select is((select status::text from public.subscriptions where id = current_setting('test.subA')::uuid), 'approved', 'the request is approved by its payment');
select matches((select receipt_no from public.payments where id = current_setting('test.pay1')::uuid), '^BI-[0-9]{4}-[0-9]{6}$', 'with a numbered receipt');
select is((select outcome from public.payments where id = current_setting('test.pay1')::uuid), 'applied', 'the money was applied');
select results_eq($$select kind from private.notification_outbox where user_id = 'e1000000-0000-4000-8000-0000000000a2' order by created_at$$,
  $$values ('payment_completed'::text)$$, 'the student is told once, as a payment');
select is(public.settle_payment(current_setting('test.pay1')::uuid, 'COMPLETED', '20500', 'XAF')->>'changed', 'false', 'the same result twice changes nothing');
select is((select count(*)::int from public.school_ledger where payment_id = current_setting('test.pay1')::uuid), 1, 'and credits the school once');
select results_eq($$select * from private.school_balance('e0000000-0000-4000-8000-0000000000a1')$$, $$values (0, 20000, 0)$$,
  'the school''s share is on hold, not available yet');
select ok((select available_at > now() + interval '6 days' from public.school_ledger where payment_id = current_setting('test.pay1')::uuid), 'for 7 days');

-- ---------------------------------------------------------------- failures and retries
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a4","role":"authenticated"}';
select ok(set_config('test.pay2', (select id::text from public.start_payment('subscription', 'e4000000-0000-4000-8000-0000000000a4', 'ORANGE_CMR', '237693456039')), true) is not null, 'another student opens a payment');
reset role;
set local "request.jwt.claims" = '{}';
select is(public.settle_payment(current_setting('test.pay2')::uuid, 'FAILED', null, null, null, 'PAYER_LIMIT_REACHED', 'Limit')->>'status', 'failed', 'a payment can fail');
select is((select failure_code from public.payments where id = current_setting('test.pay2')::uuid), 'PAYER_LIMIT_REACHED', 'with pawaPay''s reason');
select is((select status::text from public.subscriptions where id = 'e4000000-0000-4000-8000-0000000000a4'), 'pending', 'the request stays pending');
select is((select kind from private.notification_outbox where user_id = 'e1000000-0000-4000-8000-0000000000a4'), 'payment_failed', 'and the student is told');
select is(public.settle_payment(current_setting('test.pay2')::uuid, 'PROCESSING')->>'changed', 'false', 'a failed payment does not come back to life on a late status');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a4","role":"authenticated"}';
select lives_ok($$select set_config('test.pay3', (select id::text from public.start_payment('subscription', 'e4000000-0000-4000-8000-0000000000a4', 'MTN_MOMO_CMR', '237653456789')), true)$$,
  'the student tries again');
reset role;
set local "request.jwt.claims" = '{}';
select is(public.settle_payment(current_setting('test.pay3')::uuid, 'COMPLETED', '20000', 'XAF')->>'status', 'needs_attention', 'an amount that does not match is set aside');
select is((select status::text from public.subscriptions where id = 'e4000000-0000-4000-8000-0000000000a4'), 'pending', 'and approves nothing');

-- pawaPay has never heard of it: left alone while young, failed after 15 minutes.
update public.payments set status = 'failed' where id = current_setting('test.pay3')::uuid;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a4","role":"authenticated"}';
select ok(set_config('test.pay4', (select id::text from public.start_payment('subscription', 'e4000000-0000-4000-8000-0000000000a4', 'MTN_MOMO_CMR', '237653456789')), true) is not null, 'once set aside, a new payment can start');
reset role;
set local "request.jwt.claims" = '{}';
select is(public.settle_payment(current_setting('test.pay4')::uuid, 'NOT_FOUND')->>'status', 'initiated', 'a young payment pawaPay does not know yet is left alone');
select is((select count(*)::int from public.payments_to_check() where id = current_setting('test.pay4')::uuid), 0, 'and not checked again before two minutes');
update public.payments set created_at = now() - interval '20 minutes', last_checked_at = null where id = current_setting('test.pay4')::uuid;
select is((select count(*)::int from public.payments_to_check() where id = current_setting('test.pay4')::uuid), 1, 'the reconciler picks up an old open payment');
select is(public.settle_payment(current_setting('test.pay4')::uuid, 'NOT_FOUND')->>'status', 'failed', 'and fails it when pawaPay never received it');

-- It turns out pawaPay did take the money after all, but meanwhile the request was paid another way: refunded in full.
update public.subscriptions set status = 'approved', proof_path = 'x/y.jpg' where id = 'e4000000-0000-4000-8000-0000000000a4';
select is(public.settle_payment(current_setting('test.pay4')::uuid, 'COMPLETED', '20500', 'XAF')->>'status', 'completed', 'a late success is honoured');
select is((select outcome from public.payments where id = current_setting('test.pay4')::uuid), 'refunded', 'but the request no longer takes it');
select results_eq($$select kind, amount_xaf, fee_xaf, status from public.refunds where payment_id = current_setting('test.pay4')::uuid$$,
  $$values ('system'::text, 20000, 500, 'queued'::text)$$, 'so it is refunded in full, fee included');
select is((select sum(amount_xaf)::int from public.school_ledger where payment_id = current_setting('test.pay4')::uuid), 0, 'and the school''s ledger nets to nothing');

-- ---------------------------------------------------------------- installments, and BusIn's charge
update private.school_payment_terms set charges_from = (now() at time zone 'Africa/Douala')::date where school_id = 'e0000000-0000-4000-8000-0000000000a1';
update private.payment_settings set charge_semester_xaf = 700;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a3","role":"authenticated"}';
select results_eq($$select amount_xaf, fee_xaf from public.payment_quote('subscription', 'e4000000-0000-4000-8000-0000000000a3')$$,
  $$values (10000, 250)$$, 'paying in installments, the first payment is part 1 with its own fee');
select ok(set_config('test.pay5', (select id::text from public.start_payment('subscription', 'e4000000-0000-4000-8000-0000000000a3', 'MTN_MOMO_CMR', '237653456789')), true) is not null, 'the student pays part 1');
reset role;
set local "request.jwt.claims" = '{}';
select is(public.settle_payment(current_setting('test.pay5')::uuid, 'COMPLETED', '10250', 'XAF')->>'status', 'completed', 'part 1 is paid');
select is((select status from public.subscription_installments where subscription_id = 'e4000000-0000-4000-8000-0000000000a3' and seq = 1), 'paid', 'part 1 is paid with the request');
select is((select amount_xaf from public.busin_charges where subscription_id = 'e4000000-0000-4000-8000-0000000000a3'), 700, 'BusIn charges the school for a paying student');
select is((select amount_xaf from public.school_ledger where kind = 'charge'), -700, 'taken from the school''s balance');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a3","role":"authenticated"}';
select ok(set_config('test.part2', (select id::text from public.subscription_installments where subscription_id = 'e4000000-0000-4000-8000-0000000000a3' and seq = 2), true) is not null
  and set_config('test.pay6', (select id::text from public.start_payment('installment', current_setting('test.part2')::uuid, 'ORANGE_CMR', '237693456789')), true) is not null,
  'part 2 is paid in the app once the request is approved');
reset role;
set local "request.jwt.claims" = '{}';
select is(public.settle_payment(current_setting('test.pay6')::uuid, 'COMPLETED', '10250', 'XAF')->>'status', 'completed', 'and completes');
select is((select status from public.subscription_installments where id = current_setting('test.part2')::uuid), 'paid', 'a later part is paid in the app');
select is((select payment_id::text from public.installment_receipts where installment_id = current_setting('test.part2')::uuid), current_setting('test.pay6'),
  'and its receipt line points to the payment');

-- ---------------------------------------------------------------- limits and the ledger
select throws_ok($$update public.school_ledger set amount_xaf = 1$$, '55000', 'ledger_append_only', 'the ledger is never edited');
update private.payment_settings set max_starts_per_hour = 2;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a4","role":"authenticated"}';
select throws_ok($$select * from public.payment_quote('subscription', 'e4000000-0000-4000-8000-0000000000a4')$$, '55000', 'not_payable', 'an approved request is not paid again');
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a3","role":"authenticated"}';
select throws_ok($$select * from public.start_payment('subscription', 'e4000000-0000-4000-8000-0000000000a3', 'MTN_MOMO_CMR', '237653456789')$$,
  '54000', 'too_many_attempts', 'a student cannot start payments without end');

set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select results_eq($$select * from public.school_balance()$$, $$values (0, 40000, 700)$$,
  'the school sees its balance: the payments on hold (the refunded one cancelled out), and what it owes (the charge)');

select * from finish();
rollback;
