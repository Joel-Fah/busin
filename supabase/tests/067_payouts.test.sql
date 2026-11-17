begin;
create extension if not exists pgtap with schema extensions;
select plan(34);

-- Paying schools out and invoicing what they owe (ADR 0029): the payout number with a second administrator, weekly
-- payouts and their results, a replacement number held for 7 days, monthly invoices, and the school's summary.

insert into public.schools (id, name, timezone) values
  ('c7000000-0000-4000-8000-0000000000a1', 'Payout School', 'Africa/Douala'),
  ('c7000000-0000-4000-8000-0000000000b2', 'Solo School', 'Africa/Douala'),
  ('c7000000-0000-4000-8000-0000000000c3', 'Owing School', 'Africa/Douala');
insert into public.school_domains (domain, school_id) values
  ('pay.out', 'c7000000-0000-4000-8000-0000000000a1'), ('solo.edu', 'c7000000-0000-4000-8000-0000000000b2'), ('owe.edu', 'c7000000-0000-4000-8000-0000000000c3');
insert into auth.users (id, email, raw_app_meta_data) values
  ('c8000000-0000-4000-8000-0000000000a1', 'one@pay.out', '{"provider":"google"}'),
  ('c8000000-0000-4000-8000-0000000000a2', 'two@pay.out', '{"provider":"google"}'),
  ('c8000000-0000-4000-8000-0000000000a3', 'stu@pay.out', '{"provider":"google"}'),
  ('c8000000-0000-4000-8000-0000000000b1', 'solo@solo.edu', '{"provider":"google"}'),
  ('c8000000-0000-4000-8000-0000000000c1', 'admin@owe.edu', '{"provider":"google"}'),
  ('c8000000-0000-4000-8000-0000000000f1', 'platform@gmail.com', '{"provider":"google"}');
update public.profiles set role = 'admin', status = 'verified'
where id in ('c8000000-0000-4000-8000-0000000000a1', 'c8000000-0000-4000-8000-0000000000a2', 'c8000000-0000-4000-8000-0000000000b1', 'c8000000-0000-4000-8000-0000000000c1');
update public.profiles set status = 'verified' where id = 'c8000000-0000-4000-8000-0000000000a3';
insert into private.platform_admins (user_id, note) values ('c8000000-0000-4000-8000-0000000000f1', 'test');
update private.payment_settings set payout_min_xaf = 5000;

-- ---------------------------------------------------------------- the payout number
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"c8000000-0000-4000-8000-0000000000a3","role":"authenticated"}';
select throws_ok($$select public.admin_propose_payout_account('MTN_MOMO_CMR', '677123456', 'Payout School')$$, '42501', null, 'a student cannot set the payout number');
select is((select count(*)::int from public.school_payout_accounts), 0, 'nor read it');

set local "request.jwt.claims" = '{"sub":"c8000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select public.admin_propose_payout_account('MTN_MOMO_CMR', '12345', 'Payout School')$$, '22023', 'bad_phone', 'the number is checked');
select throws_ok($$select public.admin_propose_payout_account('MTN_MOMO_CMR', '677123456', ' ')$$, '22023', 'bad_name', 'the account holder''s name is required');
select lives_ok($$select set_config('test.acc1', public.admin_propose_payout_account('MTN_MOMO_CMR', '6 77 12 34 56', 'Payout School Ltd')::text, true)$$,
  'one administrator proposes the number');
select is((select phone from public.school_payout_accounts where id = current_setting('test.acc1')::uuid), '237677123456', 'stored in full form');
select throws_ok($$select public.admin_confirm_payout_account(current_setting('test.acc1')::uuid)$$, '55000', 'same_admin', 'who proposed it cannot confirm it');
set local "request.jwt.claims" = '{"sub":"c8000000-0000-4000-8000-0000000000a2","role":"authenticated"}';
select lives_ok($$select public.admin_confirm_payout_account(current_setting('test.acc1')::uuid)$$, 'another administrator confirms it');
select ok((select status = 'active' and usable_from <= now() from public.school_payout_accounts where id = current_setting('test.acc1')::uuid),
  'a first number is used at once');

-- ---------------------------------------------------------------- weekly payouts
reset role;
set local "request.jwt.claims" = '{}';
-- 30,000 available (its hold is over), 10,000 still on hold.
insert into public.school_ledger (school_id, kind, amount_xaf, available_at, note) values
  ('c7000000-0000-4000-8000-0000000000a1', 'adjustment', 30000, now() - interval '1 day', 'test: available'),
  ('c7000000-0000-4000-8000-0000000000a1', 'adjustment', 10000, now() + interval '3 days', 'test: on hold');
select is(private.plan_payouts(), 1, 'Monday: the school with money available and a number is paid');
select results_eq($$select amount_xaf, status, phone_masked from public.payouts where school_id = 'c7000000-0000-4000-8000-0000000000a1'$$,
  $$values (30000, 'queued'::text, '2376*****456'::text)$$, 'all of what is available, to the masked number');
select results_eq($$select * from private.school_balance('c7000000-0000-4000-8000-0000000000a1')$$, $$values (0, 10000, 0)$$,
  'it leaves the balance at once; what is on hold stays');
select is(private.plan_payouts(), 0, 'no second payout while one is going');
select results_eq($$select action, phone from public.payouts_to_send()$$, $$values ('send'::text, '237677123456'::text)$$,
  'the reconciler sends it, with the full number only the server reads');
select set_config('test.p1', (select id::text from public.payouts where school_id = 'c7000000-0000-4000-8000-0000000000a1'), true);
select is(public.settle_payout(current_setting('test.p1')::uuid, 'ACCEPTED')->>'status', 'accepted', 'pawaPay accepts it');
select is(public.settle_payout(current_setting('test.p1')::uuid, 'FAILED', null, null, null, 'PAWAPAY_WALLET_OUT_OF_FUNDS')->>'status', 'failed', 'a payout can fail');
select is((select available_xaf from private.school_balance('c7000000-0000-4000-8000-0000000000a1')), 30000, 'and the money is back in the balance');
select is(private.plan_payouts(), 1, 'next time it is paid again');
select set_config('test.p2', (select id::text from public.payouts where school_id = 'c7000000-0000-4000-8000-0000000000a1' and status = 'queued'), true);
select is(public.settle_payout(current_setting('test.p2')::uuid, 'COMPLETED', '29000', 'XAF')->>'status', 'needs_attention', 'an amount that does not match is set aside');
update public.payouts set status = 'accepted' where id = current_setting('test.p2')::uuid;
select is(public.settle_payout(current_setting('test.p2')::uuid, 'COMPLETED', '30000', 'XAF', 'PO1')->>'status', 'completed', 'a payout completes');
select is(public.settle_payout(current_setting('test.p2')::uuid, 'FAILED')->>'changed', 'false', 'and stays completed');

-- ---------------------------------------------------------------- a replacement number waits 7 days
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"c8000000-0000-4000-8000-0000000000a2","role":"authenticated"}';
select set_config('test.acc2', public.admin_propose_payout_account('ORANGE_CMR', '699000111', 'Payout School Ltd')::text, true);
set local "request.jwt.claims" = '{"sub":"c8000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select public.admin_confirm_payout_account(current_setting('test.acc2')::uuid);
select is((select status from public.school_payout_accounts where id = current_setting('test.acc1')::uuid), 'retired', 'the old number is retired');
select ok((select usable_from > now() + interval '6 days' from public.school_payout_accounts where id = current_setting('test.acc2')::uuid),
  'a replacement is used only after 7 days');
reset role;
insert into public.school_ledger (school_id, kind, amount_xaf, available_at, note)
values ('c7000000-0000-4000-8000-0000000000a1', 'adjustment', 8000, now() - interval '1 day', 'test: more');
select is(private.plan_payouts(), 0, 'so no payout goes to it meanwhile');

-- ---------------------------------------------------------------- one administrator: the platform confirms
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"c8000000-0000-4000-8000-0000000000b1","role":"authenticated"}';
select set_config('test.acc3', public.admin_propose_payout_account('MTN_MOMO_CMR', '650111222', 'Solo School')::text, true);
select throws_ok($$select public.platform_confirm_payout_account(current_setting('test.acc3')::uuid)$$, '42501', null, 'a school admin is not the platform');
set local "request.jwt.claims" = '{"sub":"c8000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select lives_ok($$select public.platform_confirm_payout_account(current_setting('test.acc3')::uuid)$$, 'the platform confirms for a school with one administrator');
reset role;
select is((select count(*)::int from public.platform_audit where action = 'payout_account.confirmed' and school_id = 'c7000000-0000-4000-8000-0000000000b2'), 1, 'in the platform audit');

-- ---------------------------------------------------------------- invoices
insert into public.school_ledger (school_id, kind, amount_xaf, note) values ('c7000000-0000-4000-8000-0000000000c3', 'adjustment', -700, 'test: a charge');
select is(private.issue_invoices(), 1, 'a school that owes gets an invoice');
select results_eq($$select amount_xaf, status from public.busin_invoices where school_id = 'c7000000-0000-4000-8000-0000000000c3'$$,
  $$values (700, 'open'::text)$$, 'for what it owes');
select is(private.issue_invoices(), 0, 'once');
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"c8000000-0000-4000-8000-0000000000c1","role":"authenticated"}';
select is(public.admin_payment_summary()->'open_invoice'->>'amount_xaf', '700', 'the school sees it in its summary');
reset role;
insert into public.school_ledger (school_id, kind, amount_xaf, available_at, note) values ('c7000000-0000-4000-8000-0000000000c3', 'adjustment', 2000, now() - interval '1 day', 'test: paid');
select private.plan_payouts();
select is((select status from public.busin_invoices where school_id = 'c7000000-0000-4000-8000-0000000000c3'), 'void', 'covered by later payments, the invoice is voided');

-- ---------------------------------------------------------------- the summary
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"c8000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select is(jsonb_array_length(public.admin_payment_summary(6)->'months'), 6, 'the summary covers the last six months');
set local "request.jwt.claims" = '{"sub":"c8000000-0000-4000-8000-0000000000a3","role":"authenticated"}';
select throws_ok($$select public.admin_payment_summary()$$, '42501', null, 'a student cannot read it');

select * from finish();
rollback;
