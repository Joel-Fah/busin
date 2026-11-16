begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

-- The nightly housekeeping (ADR 0010's follow-up): old working rows go, recent ones and everything people read stay.

insert into public.schools (id, name) values ('a8000000-0000-4000-8000-0000000000a1', 'Prune School');
insert into public.school_domains (domain, school_id) values ('prune.edu', 'a8000000-0000-4000-8000-0000000000a1');
insert into auth.users (id, email, raw_app_meta_data) values ('a8100000-0000-4000-8000-0000000000a1', 'stu@prune.edu', '{"provider":"google"}');

insert into private.notification_outbox (school_id, user_id, kind, created_at, sent_at, attempts) values
  ('a8000000-0000-4000-8000-0000000000a1', 'a8100000-0000-4000-8000-0000000000a1', 'subscription_approved', now() - interval '40 days', now() - interval '40 days', 1),
  ('a8000000-0000-4000-8000-0000000000a1', 'a8100000-0000-4000-8000-0000000000a1', 'subscription_approved', now() - interval '2 days', now() - interval '2 days', 1),
  ('a8000000-0000-4000-8000-0000000000a1', 'a8100000-0000-4000-8000-0000000000a1', 'subscription_rejected', now() - interval '100 days', null, 5),
  ('a8000000-0000-4000-8000-0000000000a1', 'a8100000-0000-4000-8000-0000000000a1', 'subscription_rejected', now() - interval '1 hour', null, 0);
insert into private.place_search_usage (user_id, at) values
  ('a8100000-0000-4000-8000-0000000000a1', now() - interval '120 days'), ('a8100000-0000-4000-8000-0000000000a1', now());
insert into private.route_directions_usage (school_id, at) values
  ('a8000000-0000-4000-8000-0000000000a1', now() - interval '120 days'), ('a8000000-0000-4000-8000-0000000000a1', now());

select ok((private.prune_old_rows() ->> 'push_sent')::int >= 1, 'the run reports what it removed');

select is((select count(*)::int from private.notification_outbox where user_id = 'a8100000-0000-4000-8000-0000000000a1' and sent_at < now() - interval '30 days'), 0,
  'a push sent more than 30 days ago is gone');
select is((select count(*)::int from private.notification_outbox where user_id = 'a8100000-0000-4000-8000-0000000000a1' and sent_at > now() - interval '30 days'), 1,
  'a recent one stays');
select is((select count(*)::int from private.notification_outbox where user_id = 'a8100000-0000-4000-8000-0000000000a1' and attempts >= 5), 0,
  'a push that failed long ago is gone');
select is((select count(*)::int from private.notification_outbox where user_id = 'a8100000-0000-4000-8000-0000000000a1' and sent_at is null and attempts < 5), 1,
  'one still waiting to be sent stays, whatever its age');
select is((select count(*)::int from private.place_search_usage where user_id = 'a8100000-0000-4000-8000-0000000000a1'), 1, 'old place searches are gone, this month''s stay');
select is((select count(*)::int from private.route_directions_usage where school_id = 'a8000000-0000-4000-8000-0000000000a1'), 1, 'the same for map directions');
select ok(exists (select 1 from cron.job where jobname = 'busin-prune-old-rows'), 'it runs every night');

select * from finish();
rollback;
