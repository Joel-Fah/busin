begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

select is((select schedule from cron.job where jobname = 'busin-send-push'), '* * * * *', 'the outbox is drained every minute');

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}');

create temp table before_calls as select count(*) as n from net.http_request_queue;

-- Local development: no address or secret in Vault, so nothing is called, even with something waiting.
insert into private.notification_outbox (school_id, user_id, kind) values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'subscription_approved');
select lives_ok($$select private.dispatch_push()$$, 'without the settings the dispatcher does nothing and does not fail');
select is((select count(*) from net.http_request_queue) - (select n from before_calls), 0::bigint, 'and makes no call');

-- A project with its settings: one call to the function, carrying the secret.
select vault.create_secret('https://example.supabase.co/functions/v1/send-push', 'push_url');
select vault.create_secret('test-secret', 'push_secret');
select private.dispatch_push();
select is((select count(*) from net.http_request_queue) - (select n from before_calls), 1::bigint, 'with them, waiting notifications cause one call');

-- Nothing waiting: no call.
update private.notification_outbox set sent_at = now();
select private.dispatch_push();
select is((select count(*) from net.http_request_queue) - (select n from before_calls), 1::bigint, 'an empty outbox causes none');

select * from finish();
rollback;
