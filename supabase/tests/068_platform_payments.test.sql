begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

-- The platform's side of payments (ADR 0029): settings, a school's switch and terms, infrastructure costs, BusIn's
-- money and margin, the wallet against the books, and what needs a look. Platform admins only.

insert into public.schools (id, name, timezone, billing_period, price_xaf) values
  ('b9000000-0000-4000-8000-0000000000a1', 'Console School', 'Africa/Douala', 'semester', 20000);
insert into public.school_domains (domain, school_id) values ('console.edu', 'b9000000-0000-4000-8000-0000000000a1');
insert into auth.users (id, email, raw_app_meta_data) values
  ('ba000000-0000-4000-8000-0000000000a1', 'admin@console.edu', '{"provider":"google"}'),
  ('ba000000-0000-4000-8000-0000000000a2', 'stu@console.edu', '{"provider":"google"}'),
  ('ba000000-0000-4000-8000-0000000000f1', 'owner@gmail.com', '{"provider":"google"}');
update public.profiles set role = 'admin', status = 'verified' where id = 'ba000000-0000-4000-8000-0000000000a1';
update public.profiles set status = 'verified' where id = 'ba000000-0000-4000-8000-0000000000a2';
insert into private.platform_admins (user_id, note) values ('ba000000-0000-4000-8000-0000000000f1', 'test');
update private.provider_rates set mmo_percent = 0;
update private.payment_settings set pawapay_percent = 1, pawapay_vat_percent = 0, fee_buffer_percent = 0;

-- ---------------------------------------------------------------- only the platform
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"ba000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select public.platform_payment_settings()$$, '42501', null, 'a school admin cannot read the payment settings');
select throws_ok($$select public.platform_set_school_payment_terms('b9000000-0000-4000-8000-0000000000a1', true)$$, '42501', null, 'nor switch mobile money on');
select throws_ok($$select public.platform_payments_overview()$$, '42501', null, 'nor read BusIn''s money');
select throws_ok($$select public.platform_add_infra_cost(current_date, 'Supabase', 15000)$$, '42501', null, 'nor enter costs');

-- ---------------------------------------------------------------- settings
set local "request.jwt.claims" = '{"sub":"ba000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select is((public.platform_payment_settings()->>'pawapay_percent')::numeric, 1::numeric, 'the platform reads the settings');
select is(jsonb_array_length(public.platform_payment_settings()->'rates'), 6, 'with each operator''s rates');
select throws_ok($$select public.platform_set_payment_settings('{"hold_days": 999}')$$, '22023', 'bad_setting', 'a value out of range is refused');
select throws_ok($$select public.platform_set_payment_settings('{"made_up": 1}')$$, '22023', 'bad_setting', 'an unknown setting is refused');
select lives_ok($$select public.platform_set_payment_settings('{"charge_semester_xaf": 500, "pawapay_vat_percent": 19.25}')$$, 'settings change');
select is((public.platform_payment_settings()->>'charge_semester_xaf')::int, 500, 'one at a time, the rest kept');
select is((public.platform_payment_settings()->>'pawapay_percent')::numeric, 1::numeric, 'untouched settings stay');
select lives_ok($$select public.platform_set_payment_settings('{"pawapay_vat_percent": 0}')$$, 'VAT back to none');
select throws_ok($$select public.platform_set_provider_rate('MTN_MOMO_CMR', 'deposit', 50)$$, '22023', 'bad_setting', 'an operator rate is bounded');
select lives_ok($$select public.platform_set_provider_rate('ORANGE_CMR', 'refund', 0.5)$$, 'an operator rate is set');

-- ---------------------------------------------------------------- a school
select lives_ok($$select public.platform_set_school_payment_terms('b9000000-0000-4000-8000-0000000000a1', true, current_date, 600)$$,
  'the platform switches mobile money on, with charges from today at 600 a semester');
select is(public.platform_school_payments('b9000000-0000-4000-8000-0000000000a1')->'terms'->>'enabled', 'true', 'and reads it back');
select is(public.platform_school_payments('b9000000-0000-4000-8000-0000000000a9'), null, 'an unknown school has nothing');

-- ---------------------------------------------------------------- money
reset role;
set local "request.jwt.claims" = '{}';
insert into public.semesters (id, school_id, name, year, start_date, end_date)
values ('bd000000-0000-4000-8000-0000000000a1', 'b9000000-0000-4000-8000-0000000000a1', 'fall', 2095, current_date - 10, current_date + 100);
insert into public.stops (id, school_id, name, location)
values ('be000000-0000-4000-8000-0000000000a1', 'b9000000-0000-4000-8000-0000000000a1', 'Gate', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, payment_method) values
  ('bb000000-0000-4000-8000-0000000000a1', 'b9000000-0000-4000-8000-0000000000a1', 'ba000000-0000-4000-8000-0000000000a2',
   'bd000000-0000-4000-8000-0000000000a1', 'be000000-0000-4000-8000-0000000000a1', 'mobile_money');
insert into public.payments (id, school_id, paid_by, purpose, subscription_id, item_key, amount_xaf, fee_xaf, est_cost_xaf, provider, payer_masked) values
  ('bc000000-0000-4000-8000-0000000000a1', 'b9000000-0000-4000-8000-0000000000a1', 'ba000000-0000-4000-8000-0000000000a2', 'subscription',
   'bb000000-0000-4000-8000-0000000000a1', 'subscription:x', 20600, 420, 412, 'MTN_MOMO_CMR', '2376*****789');
select public.settle_payment('bc000000-0000-4000-8000-0000000000a1', 'COMPLETED', '21020', 'XAF');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"ba000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select lives_ok($$select public.platform_add_infra_cost(current_date, 'Supabase', 15000, 'Pro plan')$$, 'a month''s infrastructure cost is entered');
select throws_ok($$select public.platform_add_infra_cost(current_date, 'X', 15000)$$, '22023', 'bad_cost', 'with a real label');
select results_eq($$select (m->>'volume')::int, (m->>'fees')::int, (m->>'charges')::int, (m->>'transfer_costs')::int, (m->>'infra')::int, (m->>'margin')::int
                    from jsonb_array_elements(public.platform_payments_overview(1)->'months') m$$,
  $$values (21020, 420, 600, 412, 15000, 420 + 600 - 412 - 15000)$$,
  'this month: what students paid, BusIn''s fee and charge, the transfer costs, infrastructure, and the real margin');
select is((public.platform_payments_overview()->>'held_for_schools')::int, 20000, 'the money held for the school (its share less the charge)');
select is((public.platform_payments_overview()->>'book_balance')::int, 21020 - 211, 'the wallet should hold what was paid less pawaPay''s 1 percent');

-- ---------------------------------------------------------------- the wallet
reset role;
select public.record_wallet_balance(20500);
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"ba000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select is((public.platform_payments_overview()->'wallet'->>'balance_xaf')::int, 20500, 'the last reading of the wallet is shown beside the books');
select lives_ok($$select public.platform_add_wallet_movement('withdrawal', 300, 'To the bank')$$, 'BusIn records what it took out');

select * from finish();
rollback;
