begin;
create extension if not exists pgtap with schema extensions;
select plan(27);

-- Reaching out to a school from the platform console (ADR 0027, slice 3).

insert into public.schools (id, name, contact_email, phone) values
  ('b0000000-0000-4000-8000-0000000000a1', 'School A', 'office@a.edu', '+237677000001'),
  ('b0000000-0000-4000-8000-0000000000b2', 'School B', null, null);
insert into public.school_domains (domain, school_id) values ('a.edu', 'b0000000-0000-4000-8000-0000000000a1'), ('b.edu', 'b0000000-0000-4000-8000-0000000000b2');
insert into auth.users (id, email, raw_app_meta_data) values
  ('b1000000-0000-4000-8000-0000000000a1', 'admin@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-0000000000b1', 'admin@b.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-0000000000a2', 'stu@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-0000000000f1', 'owner@gmail.com', '{"provider":"google"}');
update public.profiles set role = 'admin', full_name = 'Ada Admin', phone = '+237699000001' where id = 'b1000000-0000-4000-8000-0000000000a1';
update public.profiles set role = 'admin' where id = 'b1000000-0000-4000-8000-0000000000b1';
insert into private.platform_admins (user_id, note) values ('b1000000-0000-4000-8000-0000000000f1', 'test');

set local role authenticated;

-- ---------------------------------------------------------------- only the platform reaches out
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select public.platform_send_notice('b0000000-0000-4000-8000-0000000000a1', 'Hello')$$, '42501', null, 'a school admin cannot send a notice');
select throws_ok($$select public.platform_school_contacts('b0000000-0000-4000-8000-0000000000a1')$$, '42501', null, 'nor read the contacts');
select throws_ok($$select public.platform_log_outreach('b0000000-0000-4000-8000-0000000000a1', 'email')$$, '42501', null, 'nor log an outreach');
select throws_ok($$insert into public.school_notices (school_id, body, created_by) values ('b0000000-0000-4000-8000-0000000000a1', 'x', 'b1000000-0000-4000-8000-0000000000a1')$$,
  '42501', null, 'nor write a notice directly');
select throws_ok($$select * from public.platform_outreach$$, '42501', null, 'nor read the outreach log');

-- ---------------------------------------------------------------- the platform admin
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select is(public.platform_school_contacts('b0000000-0000-4000-8000-0000000000a1')->>'email', 'office@a.edu', 'the contacts give the school''s own email');
select is(public.platform_school_contacts('b0000000-0000-4000-8000-0000000000a1')->'admins'->0->>'phone', '+237699000001', 'and its administrators, with their phone');
select is(public.platform_school_contacts('b0000000-0000-4000-8000-000000000999'), null, 'an unknown school has no contacts');

select throws_ok($$select public.platform_send_notice('b0000000-0000-4000-8000-0000000000a1', '   ')$$, '22023', 'bad_body', 'an empty notice is refused');
select throws_ok($$select public.platform_send_notice('b0000000-0000-4000-8000-0000000000a1', 'Hi', 'https://evil.example')$$, '22023', 'bad_link', 'a notice only links to a portal page');
select throws_ok($$select public.platform_send_notice('b0000000-0000-4000-8000-0000000000a1', 'Hi', '//evil')$$, '22023', 'bad_link', 'not even a link to another host');
select throws_ok($$select public.platform_log_outreach('b0000000-0000-4000-8000-0000000000a1', 'pigeon')$$, '22023', 'bad_channel', 'an unknown channel is refused');
select throws_ok($$select public.platform_log_outreach('b0000000-0000-4000-8000-0000000000a1', 'call', '{}', null, 0, current_date - 1)$$, '22023', 'bad_follow_up', 'a follow-up is never in the past');

select lives_ok($$select public.platform_send_notice('b0000000-0000-4000-8000-0000000000a1', '12 students wait for an answer.', '/subscriptions',
  array['oldest_pending_days', 'made_up_signal'], 7, current_date)$$, 'it sends a notice, snoozing its signal for 7 days with a follow-up today');
select is(
  (select signals from public.platform_school_outreach('b0000000-0000-4000-8000-0000000000a1') x, jsonb_array_elements(x->'log') l, lateral (select l->'signals' as signals) s limit 1),
  '["oldest_pending_days"]'::jsonb, 'only known signals are kept');
select is(
  public.platform_school_outreach('b0000000-0000-4000-8000-0000000000a1')->'snoozed'->'oldest_pending_days'->>'until',
  (current_date + 7)::text, 'the signal is snoozed for 7 days');
select ok(
  (select snoozed ? 'oldest_pending_days' from public.platform_schools() where id = 'b0000000-0000-4000-8000-0000000000a1'),
  'the schools list says so');
select ok(
  (select last_outreach_at is not null from public.platform_schools() where id = 'b0000000-0000-4000-8000-0000000000a1'),
  'with the last contact');
select is((select count(*)::int from public.platform_follow_ups() where school_id = 'b0000000-0000-4000-8000-0000000000a1'), 1, 'the follow-up is due today');
select lives_ok($$select public.platform_complete_follow_up((select id from public.platform_follow_ups() where school_id = 'b0000000-0000-4000-8000-0000000000a1'))$$,
  'it is marked done');
select is((select count(*)::int from public.platform_follow_ups() where school_id = 'b0000000-0000-4000-8000-0000000000a1'), 0, 'and is no longer due');

-- ---------------------------------------------------------------- the school's administrators
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select is((select body from public.school_notices where school_id = 'b0000000-0000-4000-8000-0000000000a1'), '12 students wait for an answer.', 'the school''s admin reads the notice');
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-0000000000b1","role":"authenticated"}';
select is((select count(*)::int from public.school_notices), 0, 'another school''s admin does not');
select throws_ok($$select public.dismiss_school_notice((select id from public.school_notices limit 1))$$, 'P0002', 'no_notice', 'nor dismisses it');
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-0000000000a2","role":"authenticated"}';
select is((select count(*)::int from public.school_notices), 0, 'a student of the school does not see it');

set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select lives_ok($$select public.dismiss_school_notice((select id from public.school_notices where school_id = 'b0000000-0000-4000-8000-0000000000a1'))$$,
  'the school''s admin dismisses it');

reset role;
select is((select count(*)::int from public.platform_audit where school_id = 'b0000000-0000-4000-8000-0000000000a1' and action = 'school.contacts_viewed'), 2,
  'each view of the contacts is in the platform audit');

select * from finish();
rollback;
