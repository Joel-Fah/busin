begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

-- Every call through the API loads the safeupdate extension (the `authenticator` role preloads it), which refuses an
-- UPDATE or DELETE without a WHERE. pgTAP connects as another role and cannot load it, so this file reads the source of
-- every function for such a statement, then goes through every payment function that writes, as the role that calls it
-- (ADR 0029).

insert into public.schools (id, name, timezone, billing_period, price_xaf) values
  ('a9000000-0000-4000-8000-0000000000a1', 'Safe School', 'Africa/Douala', 'semester', 20000),
  ('a9000000-0000-4000-8000-0000000000b2', 'Solo Safe School', 'Africa/Douala', 'semester', 20000);
insert into public.school_domains (domain, school_id) values ('safe.edu', 'a9000000-0000-4000-8000-0000000000a1'), ('solosafe.edu', 'a9000000-0000-4000-8000-0000000000b2');
insert into auth.users (id, email, raw_app_meta_data) values
  ('aa000000-0000-4000-8000-0000000000a1', 'one@safe.edu', '{"provider":"google"}'),
  ('aa000000-0000-4000-8000-0000000000a2', 'two@safe.edu', '{"provider":"google"}'),
  ('aa000000-0000-4000-8000-0000000000a3', 'stu@safe.edu', '{"provider":"google"}'),
  ('aa000000-0000-4000-8000-0000000000b1', 'solo@solosafe.edu', '{"provider":"google"}'),
  ('aa000000-0000-4000-8000-0000000000f1', 'platform@gmail.com', '{"provider":"google"}');
update public.profiles set role = 'admin', status = 'verified'
where id in ('aa000000-0000-4000-8000-0000000000a1', 'aa000000-0000-4000-8000-0000000000a2', 'aa000000-0000-4000-8000-0000000000b1');
update public.profiles set status = 'verified' where id = 'aa000000-0000-4000-8000-0000000000a3';
insert into private.platform_admins (user_id, note) values ('aa000000-0000-4000-8000-0000000000f1', 'test');
insert into private.school_payment_terms (school_id, enabled) values ('a9000000-0000-4000-8000-0000000000a1', true);
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('ab000000-0000-4000-8000-0000000000a1', 'a9000000-0000-4000-8000-0000000000a1', 'fall', 2096, current_date - 10, current_date + 100);
insert into public.stops (id, school_id, name, location) values
  ('ac000000-0000-4000-8000-0000000000a1', 'a9000000-0000-4000-8000-0000000000a1', 'Gate', extensions.st_point(11.5, 3.85)::extensions.geography);
update private.provider_rates set mmo_percent = 0 where true;

-- No function updates or deletes without a WHERE (an ON CONFLICT DO UPDATE and a SELECT ... FOR UPDATE are not such
-- statements).
select is(array(
  with src as (
    select n.nspname || '.' || p.proname as fn,
           regexp_replace(regexp_replace(regexp_replace(regexp_replace(p.prosrc, '--[^\n]*', '', 'g'),
             '\mdo\s+update\s+set[^;]*', '', 'gi'), '\mfor\s+(no\s+key\s+)?update(\s+(of\s+\w+|skip\s+locked|nowait))*', '', 'gi'),
             '\mon\s+update\M', '', 'gi') as body
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private')
  )
  select distinct fn from src, regexp_matches(body, '((?:\mupdate\s+[a-z_.]+(?:\s+[a-z]\w*)?\s+set\M|\mdelete\s+from\M)[^;]*);', 'gi') m
  where m[1] !~* '\mwhere\M' order by 1
), array[]::text[], 'no function updates or deletes without a WHERE (the API refuses it)');

-- ---------------------------------------------------------------- the platform
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"aa000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select lives_ok($$select public.platform_set_payment_settings('{"charge_semester_xaf": 0, "fee_buffer_percent": 0.2}')$$, 'changing a setting');
select lives_ok($$select public.platform_set_provider_rate('MTN_MOMO_CMR', 'refund', 0)$$, 'an operator rate');
select lives_ok($$select public.platform_set_school_payment_terms('a9000000-0000-4000-8000-0000000000a1', true, current_date, null, null)$$, 'a school''s terms');
select lives_ok($$select set_config('test.cost', public.platform_add_infra_cost(current_date, 'Supabase', 15000)::text, true)$$, 'adding a cost');
select lives_ok($$select public.platform_delete_infra_cost(current_setting('test.cost')::uuid)$$, 'deleting it');
select lives_ok($$select public.platform_add_wallet_movement('withdrawal', 300, 'To the bank')$$, 'a wallet movement');
select lives_ok($$select public.platform_delete_wallet_movement((select id from public.platform_wallet_movements(1)))$$, 'listing and deleting it');

-- ---------------------------------------------------------------- the school
set local "request.jwt.claims" = '{"sub":"aa000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select lives_ok($$select public.admin_set_fees_paid_by('student')$$, 'who pays the fees');
select lives_ok($$select set_config('test.acc', public.admin_propose_payout_account('MTN_MOMO_CMR', '677123456', 'Safe School')::text, true)$$, 'proposing a payout number');
select lives_ok($$select public.admin_propose_payout_account('ORANGE_CMR', '699123456', 'Safe School')$$, 'proposing another replaces it');
select lives_ok($$select public.admin_decline_payout_account((select id from public.school_payout_accounts where status = 'proposed'))$$, 'declining one');
select lives_ok($$select set_config('test.acc', public.admin_propose_payout_account('MTN_MOMO_CMR', '677123456', 'Safe School')::text, true)$$, 'proposing again');
set local "request.jwt.claims" = '{"sub":"aa000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select throws_ok($$select public.platform_confirm_payout_account(current_setting('test.acc')::uuid)$$, '55000', 'two_admins',
  'the platform does not confirm for a school with two administrators');
set local "request.jwt.claims" = '{"sub":"aa000000-0000-4000-8000-0000000000a2","role":"authenticated"}';
select lives_ok($$select public.admin_confirm_payout_account(current_setting('test.acc')::uuid)$$, 'the second administrator confirms it');

-- ---------------------------------------------------------------- a payment, a refund, a payout
set local "request.jwt.claims" = '{"sub":"aa000000-0000-4000-8000-0000000000a3","role":"authenticated"}';
select lives_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, payment_method)
  values ('a9000000-0000-4000-8000-0000000000a1', 'aa000000-0000-4000-8000-0000000000a3', 'ab000000-0000-4000-8000-0000000000a1', 'ac000000-0000-4000-8000-0000000000a1', 'mobile_money')$$,
  'a request to pay by mobile money');
select lives_ok($$select set_config('test.pay', (select p.id::text from public.start_payment('subscription',
  (select s.id from public.subscriptions s where s.student_id = 'aa000000-0000-4000-8000-0000000000a3'), 'MTN_MOMO_CMR', '237677123456') p), true)$$, 'starting the payment');
reset role;
set local "request.jwt.claims" = '{}';
select lives_ok($$select public.settle_payment(current_setting('test.pay')::uuid, 'ACCEPTED')$$, 'settling: accepted');
select lives_ok($$select public.settle_payment(current_setting('test.pay')::uuid, 'COMPLETED',
  (select total_xaf::text from public.payments where id = current_setting('test.pay')::uuid), 'XAF')$$, 'settling: completed, approving the request');
select is((select status::text from public.subscriptions where student_id = 'aa000000-0000-4000-8000-0000000000a3'), 'approved', 'it went through');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"aa000000-0000-4000-8000-0000000000a3","role":"authenticated"}';
select lives_ok($$select set_config('test.ref', public.request_refund(current_setting('test.pay')::uuid, 'I am leaving the school this month')::text, true)$$, 'asking a refund');
set local "request.jwt.claims" = '{"sub":"aa000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select lives_ok($$select public.admin_decide_refund(current_setting('test.ref')::uuid, true)$$, 'approving it');
reset role;
set local "request.jwt.claims" = '{}';
select lives_ok($$select public.settle_refund(current_setting('test.ref')::uuid, 'ACCEPTED')$$, 'settling the refund: accepted');
select lives_ok($$select public.settle_refund(current_setting('test.ref')::uuid, 'COMPLETED', '20000', 'XAF')$$, 'completed, ending the subscription');

insert into public.school_ledger (school_id, kind, amount_xaf, available_at, note)
values ('a9000000-0000-4000-8000-0000000000a1', 'adjustment', 9000, now() - interval '8 days', 'test');
select lives_ok($$select private.plan_payouts()$$, 'planning payouts');
select lives_ok($$select public.settle_payout((select id from public.payouts where school_id = 'a9000000-0000-4000-8000-0000000000a1'), 'FAILED')$$,
  'a payout that fails is put back');

select * from finish();
rollback;
