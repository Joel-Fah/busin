begin;
create extension if not exists pgtap with schema extensions;
select plan(30);

-- Refunds (ADR 0029): a student asks, the school decides or refunds on its own, pawaPay's result is applied once, the
-- school's balance follows, and BusIn's own refunds are never put back in a school's balance.

insert into public.schools (id, name, timezone, billing_period, price_xaf) values
  ('d0000000-0000-4000-8000-0000000000a1', 'Refund School', 'Africa/Douala', 'semester', 20000),
  ('d0000000-0000-4000-8000-0000000000b2', 'Other School', 'Africa/Douala', 'semester', 20000);
insert into public.school_domains (domain, school_id) values ('ref.edu', 'd0000000-0000-4000-8000-0000000000a1'), ('oth.edu', 'd0000000-0000-4000-8000-0000000000b2');
insert into auth.users (id, email, raw_app_meta_data) values
  ('d1000000-0000-4000-8000-0000000000a1', 'admin@ref.edu', '{"provider":"google"}'),
  ('d1000000-0000-4000-8000-0000000000a2', 'ana@ref.edu', '{"provider":"google"}'),
  ('d1000000-0000-4000-8000-0000000000a3', 'ben@ref.edu', '{"provider":"google"}'),
  ('d1000000-0000-4000-8000-0000000000b1', 'admin@oth.edu', '{"provider":"google"}');
update public.profiles set role = 'admin', status = 'verified' where id in ('d1000000-0000-4000-8000-0000000000a1', 'd1000000-0000-4000-8000-0000000000b1');
update public.profiles set status = 'verified' where id in ('d1000000-0000-4000-8000-0000000000a2', 'd1000000-0000-4000-8000-0000000000a3');
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('d2000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000a1', 'fall', 2094,
   (now() at time zone 'Africa/Douala')::date - 10, (now() at time zone 'Africa/Douala')::date + 100);
insert into public.stops (id, school_id, name, location) values
  ('d3000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000a1', 'Gate', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into private.school_payment_terms (school_id, enabled) values ('d0000000-0000-4000-8000-0000000000a1', true);
update private.provider_rates set mmo_percent = 0;
update private.payment_settings set fee_buffer_percent = 0, pawapay_percent = 1, pawapay_vat_percent = 0;

-- Ana and Ben paid their requests by mobile money (20,000 to the school, 405 fee).
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, payment_method) values
  ('d4000000-0000-4000-8000-0000000000a2', 'd0000000-0000-4000-8000-0000000000a1', 'd1000000-0000-4000-8000-0000000000a2', 'd2000000-0000-4000-8000-0000000000a1', 'd3000000-0000-4000-8000-0000000000a1', 'mobile_money'),
  ('d4000000-0000-4000-8000-0000000000a3', 'd0000000-0000-4000-8000-0000000000a1', 'd1000000-0000-4000-8000-0000000000a3', 'd2000000-0000-4000-8000-0000000000a1', 'd3000000-0000-4000-8000-0000000000a1', 'mobile_money');
insert into public.payments (id, school_id, paid_by, purpose, subscription_id, item_key, amount_xaf, fee_xaf, provider, payer_masked) values
  ('d5000000-0000-4000-8000-0000000000a2', 'd0000000-0000-4000-8000-0000000000a1', 'd1000000-0000-4000-8000-0000000000a2', 'subscription', 'd4000000-0000-4000-8000-0000000000a2', 'subscription:a2', 20000, 405, 'MTN_MOMO_CMR', '2376*****789'),
  ('d5000000-0000-4000-8000-0000000000a3', 'd0000000-0000-4000-8000-0000000000a1', 'd1000000-0000-4000-8000-0000000000a3', 'subscription', 'd4000000-0000-4000-8000-0000000000a3', 'subscription:a3', 20000, 405, 'ORANGE_CMR', '2376*****111');
set local "request.jwt.claims" = '{}';
select public.settle_payment('d5000000-0000-4000-8000-0000000000a2', 'COMPLETED', '20405', 'XAF');
select public.settle_payment('d5000000-0000-4000-8000-0000000000a3', 'COMPLETED', '20405', 'XAF');

-- ---------------------------------------------------------------- the student asks
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"d1000000-0000-4000-8000-0000000000a2","role":"authenticated"}';
select throws_ok($$select public.request_refund('d5000000-0000-4000-8000-0000000000a2', 'short')$$, '22023', 'reason_too_short', 'a reason is needed');
select throws_ok($$select public.request_refund('d5000000-0000-4000-8000-0000000000a3', 'I am leaving the school')$$, 'P0002', 'not_found', 'only for their own payment');
select lives_ok($$select set_config('test.r1', public.request_refund('d5000000-0000-4000-8000-0000000000a2', 'I am leaving the school this month')::text, true)$$,
  'the student asks for a refund');
select results_eq($$select kind, status, amount_xaf, fee_xaf from public.refunds where id = current_setting('test.r1')::uuid$$,
  $$values ('student'::text, 'requested'::text, 20000, 0)$$, 'for the school''s price; the fee paid for the transfers');
select throws_ok($$select public.request_refund('d5000000-0000-4000-8000-0000000000a2', 'Asking a second time please')$$, '55000', 'not_refundable', 'one refund per payment');
select throws_ok($$select public.admin_decide_refund(current_setting('test.r1')::uuid, true)$$, '42501', null, 'a student cannot decide');
select throws_ok($$insert into public.refunds (school_id, payment_id, student_id, kind, amount_xaf) values ('d0000000-0000-4000-8000-0000000000a1', 'd5000000-0000-4000-8000-0000000000a2', 'd1000000-0000-4000-8000-0000000000a2', 'student', 1)$$,
  '42501', null, 'nobody writes a refund directly');
set local "request.jwt.claims" = '{"sub":"d1000000-0000-4000-8000-0000000000a3","role":"authenticated"}';
select is((select count(*)::int from public.refunds), 0, 'another student does not see it');

-- ---------------------------------------------------------------- the school decides
set local "request.jwt.claims" = '{"sub":"d1000000-0000-4000-8000-0000000000b1","role":"authenticated"}';
select throws_ok($$select public.admin_decide_refund(current_setting('test.r1')::uuid, true)$$, 'P0002', 'not_found', 'another school''s admin cannot decide');
set local "request.jwt.claims" = '{"sub":"d1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select is((select count(*)::int from public.refunds), 1, 'the school''s admin sees the request');
select throws_ok($$select public.admin_decide_refund(current_setting('test.r1')::uuid, false)$$, '22023', 'reason_required', 'declining needs a reason');
select throws_ok($$select public.admin_decide_refund(current_setting('test.r1')::uuid, true, 25000)$$, '22023', 'bad_amount', 'never more than the school''s price');
select lives_ok($$select public.admin_decide_refund(current_setting('test.r1')::uuid, true, 15000, 'Pro rata for the months left')$$, 'the school approves part of it');
select is((select status from public.refunds where id = current_setting('test.r1')::uuid), 'queued', 'it waits to be sent');
select results_eq($$select * from public.school_balance()$$, $$values (0, 25000, 0)$$, 'and is taken from the payment while it is on hold');

-- ---------------------------------------------------------------- pawaPay's result
reset role;
set local "request.jwt.claims" = '{}';
select is((select action from public.refunds_to_send() where id = current_setting('test.r1')::uuid), 'send', 'the reconciler sends it');
select is(public.settle_refund(current_setting('test.r1')::uuid, 'NOT_FOUND')->>'status', 'queued', 'never sent yet: it stays queued');
select is(public.settle_refund(current_setting('test.r1')::uuid, 'ACCEPTED')->>'status', 'accepted', 'pawaPay accepts it');
select is(public.settle_refund(current_setting('test.r1')::uuid, 'COMPLETED', '15000', 'XAF', 'RF1')->>'status', 'completed', 'and completes it');
select matches((select receipt_no from public.refunds where id = current_setting('test.r1')::uuid), '^BR-[0-9]{4}-[0-9]{6}$', 'with a numbered receipt');
select is((select amount_xaf from public.school_ledger where refund_id = current_setting('test.r1')::uuid and kind = 'refund_fee'), -150,
  'the school pays what sending it cost (1 percent)');
select is((select status::text from public.subscriptions where id = 'd4000000-0000-4000-8000-0000000000a2'), 'approved', 'a part refunded leaves the subscription running');
select is((select kind from private.notification_outbox where user_id = 'd1000000-0000-4000-8000-0000000000a2' and kind like 'refund%'), 'refund_completed', 'the student is told');
select is(public.settle_refund(current_setting('test.r1')::uuid, 'COMPLETED', '15000', 'XAF')->>'changed', 'false', 'the same result twice changes nothing');

-- The school refunds Ben in full on its own; pawaPay fails it, so it is put back.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"d1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select lives_ok($$select set_config('test.r2', public.admin_refund_payment('d5000000-0000-4000-8000-0000000000a3', 20000, 'The bus no longer goes to his stop')::text, true)$$,
  'the school refunds a payment on its own');
reset role;
set local "request.jwt.claims" = '{}';
select is(public.settle_refund(current_setting('test.r2')::uuid, 'REJECTED', null, null, null, 'PAWAPAY_WALLET_OUT_OF_FUNDS')->>'status', 'failed', 'a refund can fail');
select is((select sum(amount_xaf)::int from public.school_ledger where refund_id = current_setting('test.r2')::uuid), 0, 'and is put back in the school''s balance');

-- Sent again, completed in full: the subscription ends.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"d1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select set_config('test.r3', public.admin_refund_payment('d5000000-0000-4000-8000-0000000000a3', 20000, 'The bus no longer goes to his stop')::text, true);
reset role;
set local "request.jwt.claims" = '{}';
select public.settle_refund(current_setting('test.r3')::uuid, 'ACCEPTED');
select public.settle_refund(current_setting('test.r3')::uuid, 'COMPLETED', '20000', 'XAF');
select is((select status::text from public.subscriptions where id = 'd4000000-0000-4000-8000-0000000000a3'), 'revoked', 'a whole price refunded ends the subscription');

-- BusIn's own refund that fails is set aside, not put back in the school's balance.
insert into public.payments (id, school_id, paid_by, purpose, subscription_id, item_key, amount_xaf, fee_xaf, provider, payer_masked, status, outcome) values
  ('d5000000-0000-4000-8000-0000000000a9', 'd0000000-0000-4000-8000-0000000000a1', 'd1000000-0000-4000-8000-0000000000a2', 'subscription', 'd4000000-0000-4000-8000-0000000000a2',
   'subscription:a9', 5000, 405, 'MTN_MOMO_CMR', '2376*****789', 'completed', 'refunded');
insert into public.refunds (id, school_id, payment_id, student_id, kind, reason, amount_xaf, fee_xaf, status)
values ('d6000000-0000-4000-8000-0000000000a9', 'd0000000-0000-4000-8000-0000000000a1', 'd5000000-0000-4000-8000-0000000000a9', 'd1000000-0000-4000-8000-0000000000a2',
        'system', 'not_pending', 5000, 405, 'accepted');
select is(public.settle_refund('d6000000-0000-4000-8000-0000000000a9', 'FAILED')->>'status', 'needs_attention', 'a failed BusIn refund goes to the platform');

-- The reconciler is called for a refund waiting to be sent.
create temp table before_calls as select count(*) as n from net.http_request_queue;
select vault.create_secret('https://example.supabase.co/functions/v1/payments-reconcile', 'payments_reconcile_url');
select vault.create_secret('test-secret', 'payments_reconcile_secret');
update public.refunds set status = 'queued' where id = 'd6000000-0000-4000-8000-0000000000a9';
select private.dispatch_payment_checks();
select is((select count(*) from net.http_request_queue) - (select n from before_calls), 1::bigint, 'a refund waiting to be sent calls the reconciler');

select * from finish();
rollback;
