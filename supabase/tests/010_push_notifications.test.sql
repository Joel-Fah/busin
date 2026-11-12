begin;
create extension if not exists pgtap with schema extensions;
select plan(36);
-- The test counts the whole outbox, so it starts from an empty one (inside this transaction, which is rolled back: a local database
-- that already holds queued notifications is not touched).
delete from private.notification_outbox;

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000003', 'susp@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'stu@b.edu', '{"provider":"google"}');
update public.profiles set status = 'suspended' where id = 'a1000000-0000-4000-8000-000000000003';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2090, '2090-09-01', '2091-01-31'),
  ('c2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'fall', 2090, '2090-09-01', '2091-01-31');
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Stop B', extensions.st_point(11.6, 3.86)::extensions.geography);
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('51000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'pending'),
  ('52000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001', 'd2000000-0000-4000-8000-000000000001', 'pending');

-- ---------------------------------------------------------------- registering a token
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';

select lives_ok($$select public.register_device_token('token-of-student-one-aaaaaaaaaaaa', 'android', 'fr')$$, 'a verified student registers a token');
select is((select count(*)::int from public.device_tokens), 1, 'and sees it');
select is((select locale from public.device_tokens), 'fr', 'with the language the phone uses');
select throws_ok($$select public.register_device_token('short', 'android')$$, '22023', 'That does not look like a device token', 'a token that is too short is refused');
select throws_ok($$select public.register_device_token('token-of-student-one-bbbbbbbbbbbb', 'windows')$$, '22023', 'The platform must be android or ios', 'an unknown platform is refused');
select throws_ok($$select public.register_device_token('token-of-student-one-cccccccccccc', 'ios', 'de')$$, '22023', 'The language must be en or fr', 'an unknown language is refused');
select throws_ok($$insert into public.device_tokens (school_id, user_id, token, platform) values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'token-inserted-directly-xxxx', 'android')$$, '42501', null, 'a table write is not allowed, only the function');
select throws_ok($$delete from public.device_tokens$$, '42501', null, 'neither is a delete');

-- ---------------------------------------------------------------- who can see what
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select count(*)::int from public.device_tokens), 0, 'another student sees none of them');

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.register_device_token('token-of-suspended-aaaaaaaaaa', 'android')$$, '42501', null, 'a suspended account cannot register');

reset role;
set local role anon;
select throws_ok($$select public.register_device_token('token-by-anonymous-aaaaaaaa', 'android')$$, '42501', null, 'a signed-out caller cannot register');

-- ---------------------------------------------------------------- a phone that changes hands
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.register_device_token('token-of-student-one-aaaaaaaaaaaa', 'android', 'en')$$, 'the same phone, signed in by someone else, registers the same token');
select is((select count(*)::int from public.device_tokens), 1, 'it now belongs to them');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.device_tokens), 0, 'and no longer to the first student');

-- ---------------------------------------------------------------- the cap and unregistering
select lives_ok($$select public.register_device_token('token-bulk-' || lpad(n::text, 10, '0'), 'android') from generate_series(1, 12) n$$, 'twelve registrations');
select is((select count(*)::int from public.device_tokens), 10, 'only the ten most recent are kept');
select public.unregister_device_token((select token from public.device_tokens order by token limit 1));
select is((select count(*)::int from public.device_tokens), 9, 'a user can forget their own token');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select public.unregister_device_token((select token from public.device_tokens where user_id = 'a1000000-0000-4000-8000-000000000001' limit 1));
reset role;
select is((select count(*)::int from public.device_tokens where user_id = 'a1000000-0000-4000-8000-000000000001'), 9, 'but not someone else''s');

-- ---------------------------------------------------------------- the outbox
update public.subscriptions set status = 'approved' where id = '51000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox where kind = 'subscription_approved' and ref_id = '51000000-0000-4000-8000-000000000001' and user_id = 'a1000000-0000-4000-8000-000000000001'), 1, 'approving a subscription queues one notification for that student');
update public.subscriptions set status = 'expired' where id = '51000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox), 1, 'later changes of status queue nothing');
update public.subscriptions set status = 'rejected' where id = '52000000-0000-4000-8000-000000000001';
select is((select kind from private.notification_outbox where user_id = 'b1000000-0000-4000-8000-000000000001'), 'subscription_rejected', 'a rejection is queued as one');
select is((select count(*)::int from private.notification_outbox), 2, 'two in all');

-- ---------------------------------------------------------------- only the sender may claim
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select * from public.claim_notifications(10)$$, '42501', null, 'a signed-in user cannot claim notifications');
reset role;

create temp table outbox_ids as select id, kind from private.notification_outbox;
grant select on outbox_ids to service_role;

set local role service_role;
select is((select count(*)::int from public.claim_notifications(10)), 2, 'the sender claims both');
reset role;
select is((select attempts from private.notification_outbox where kind = 'subscription_approved'), 1, 'and each claim counts as an attempt');

set local role service_role;
select is((select jsonb_array_length(tokens) from public.claim_notifications(10) where kind = 'subscription_rejected'), 0, 'a student with no registered phone has an empty list, not an error');
select is((select jsonb_array_length(tokens) from public.claim_notifications(10) where kind = 'subscription_approved'), 9, 'a student with phones gets their tokens');
select is((select (tokens -> 0 ->> 'locale') from public.claim_notifications(10) where kind = 'subscription_approved'), 'en', 'with each phone''s language');
reset role;
update private.notification_outbox set attempts = 0;

-- finishing: sent ones are not claimed again; failed ones stay queued
set local role service_role;
select public.complete_notification((select id from outbox_ids where kind = 'subscription_approved'));
select is((select count(*)::int from public.claim_notifications(10)), 1, 'a notification that was sent is not claimed again');
select public.complete_notification((select id from outbox_ids where kind = 'subscription_rejected'), 'FCM said no');
reset role;
select is((select last_error from private.notification_outbox where kind = 'subscription_rejected'), 'FCM said no', 'a failure is recorded');
select ok((select sent_at is null from private.notification_outbox where kind = 'subscription_rejected'), 'and the notification stays queued');
select ok((select sent_at is not null from private.notification_outbox where kind = 'subscription_approved'), 'while a sent one is stamped');

-- a failing notification is tried five times in all, then left alone
update private.notification_outbox set attempts = 3 where sent_at is null;
set local role service_role;
select is((select count(*)::int from public.claim_notifications(10)), 1, 'the fourth try is claimed');
select is((select count(*)::int from public.claim_notifications(10)), 1, 'and the fifth');
select is((select count(*)::int from public.claim_notifications(10)), 0, 'but not a sixth');

select public.drop_device_token((select token from public.device_tokens where user_id = 'a1000000-0000-4000-8000-000000000001' limit 1));
reset role;
select is((select count(*)::int from public.device_tokens where user_id = 'a1000000-0000-4000-8000-000000000001'), 8, 'a token FCM reports dead is dropped');

select * from finish();
rollback;
