begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

-- The payment reconciler's scheduler (ADR 0029).

select is((select schedule from cron.job where jobname = 'busin-check-payments'), '*/2 * * * *', 'open payments are checked every two minutes');

insert into public.schools (id, name) values ('f0000000-0000-4000-8000-0000000000a1', 'Check School');
insert into public.school_domains (domain, school_id) values ('check.edu', 'f0000000-0000-4000-8000-0000000000a1');
insert into auth.users (id, email, raw_app_meta_data) values ('f1000000-0000-4000-8000-0000000000a1', 'stu@check.edu', '{"provider":"google"}');
insert into public.busin_invoices (id, school_id, number, month, amount_xaf, due_date)
values ('f5000000-0000-4000-8000-0000000000a1', 'f0000000-0000-4000-8000-0000000000a1', 'BF-2093-000009', date_trunc('month', now())::date, 5000, current_date + 14);
insert into public.payments (school_id, paid_by, purpose, invoice_id, item_key, amount_xaf, fee_xaf, provider, payer_masked, created_at)
values ('f0000000-0000-4000-8000-0000000000a1', 'f1000000-0000-4000-8000-0000000000a1', 'invoice', 'f5000000-0000-4000-8000-0000000000a1',
        'invoice:f5', 5000, 0, 'MTN_MOMO_CMR', '2376*****789', now() - interval '5 minutes');

create temp table before_calls as select count(*) as n from net.http_request_queue;

-- Local development: no address or secret in Vault, so nothing is called, even with a payment waiting.
select lives_ok($$select private.dispatch_payment_checks()$$, 'without the settings the dispatcher does nothing and does not fail');
select is((select count(*) from net.http_request_queue) - (select n from before_calls), 0::bigint, 'and makes no call');

select vault.create_secret('https://example.supabase.co/functions/v1/payments-reconcile', 'payments_reconcile_url');
select vault.create_secret('test-secret', 'payments_reconcile_secret');
select private.dispatch_payment_checks();
select is((select count(*) from net.http_request_queue) - (select n from before_calls), 1::bigint, 'with them, an open payment causes one call');

-- Nothing open: no call.
update public.payments set status = 'completed';
select private.dispatch_payment_checks();
select is((select count(*) from net.http_request_queue) - (select n from before_calls), 1::bigint, 'nothing open causes none');

select * from finish();
rollback;
