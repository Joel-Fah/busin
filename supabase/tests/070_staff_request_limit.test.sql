begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

-- Staff access is asked at most 3 times (issue #543); after that only an administrator lets the account in.

-- Independent of the local data: schools already in the database accept no open sign-up here (rolled back at the end).
update public.schools set accepts_open_signup = false, open_signup_domains = '{}', public_listing = false;

insert into public.schools (id, name, accepts_open_signup) values
  ('10000000-0000-4000-8000-000000000071', 'Limit School A', true),
  ('20000000-0000-4000-8000-000000000072', 'Limit School B', false);
insert into public.school_domains (domain, school_id) values ('limit-a.edu', '10000000-0000-4000-8000-000000000071'), ('limit-b.edu', '20000000-0000-4000-8000-000000000072');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000071', 'admin@limit-a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000072', 'admin@limit-b.edu', '{"provider":"google"}'),
  ('c1000000-0000-4000-8000-000000000071', 'asker@gmail.example', '{"provider":"google"}'),
  ('c1000000-0000-4000-8000-000000000072', 'fresh@gmail.example', '{"provider":"google"}');
update public.profiles set role = 'admin', status = 'verified', school_id = '10000000-0000-4000-8000-000000000071' where id = 'a3000000-0000-4000-8000-000000000071';
update public.profiles set role = 'admin', status = 'verified', school_id = '20000000-0000-4000-8000-000000000072' where id = 'b3000000-0000-4000-8000-000000000072';

set local role authenticated;

-- ---------------------------------------------------------------- three requests
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-000000000071","role":"authenticated"}';
select is((select requests_left from public.my_staff_request()), 3, 'a new account has 3 requests');
select lives_ok($$select public.request_staff_access('10000000-0000-4000-8000-000000000071')$$, 'first request');
select is((select requests_left from public.my_staff_request()), 2, 'then 2 left');

-- Pointing the waiting request at another school is the same attempt.
reset role;
update public.profiles set staff_requested_at = now() - interval '1 minute' where id = 'c1000000-0000-4000-8000-000000000071';
set local role authenticated;
select lives_ok($$select public.request_staff_access('20000000-0000-4000-8000-000000000072')$$, 'the waiting request goes to another school');
select results_eq($$select school_id, requests_left from public.my_staff_request()$$,
  $$values ('20000000-0000-4000-8000-000000000072'::uuid, 2)$$, 'changing the school does not use a request');

-- Withdrawing does not count either.
reset role;
update public.profiles set staff_requested_at = now() - interval '1 minute' where id = 'c1000000-0000-4000-8000-000000000071';
set local role authenticated;
select lives_ok($$select public.request_staff_access(null)$$, 'withdrawn');
select is((select requests_left from public.my_staff_request()), 2, 'withdrawing gives nothing back and takes nothing');

select lives_ok($$select public.request_staff_access('20000000-0000-4000-8000-000000000072')$$, 'second request');
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000072","role":"authenticated"}';
select is((select requests_left from public.admin_staff_requests() where id = 'c1000000-0000-4000-8000-000000000071'), 1, 'the school sees how many are left');
select lives_ok($$select public.admin_review_staff_request('c1000000-0000-4000-8000-000000000071', false)$$, 'School B declines');

set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-000000000071","role":"authenticated"}';
select lives_ok($$select public.request_staff_access('20000000-0000-4000-8000-000000000072')$$, 'third request');
select is((select requests_left from public.my_staff_request()), 0, 'none left');
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000072","role":"authenticated"}';
select is((select requests_left from public.admin_staff_requests() where id = 'c1000000-0000-4000-8000-000000000071'), 0, 'the school sees it is the last one');
select lives_ok($$select public.admin_review_staff_request('c1000000-0000-4000-8000-000000000071', false)$$, 'declined again');

-- ---------------------------------------------------------------- the fourth
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-000000000071","role":"authenticated"}';
select throws_ok($$select public.request_staff_access('20000000-0000-4000-8000-000000000072')$$, '55000', 'requests_used_up', 'the fourth request is refused');
select throws_ok($$update public.profiles set staff_request_count = 0 where id = 'c1000000-0000-4000-8000-000000000071'$$, '42501', null,
  'the count is not writable by the user');
reset role;
select is((select staff_request_count from public.profiles where id = 'c1000000-0000-4000-8000-000000000071'), 3::smallint, 'it stays at 3');
select is((select count(*)::int from public.audit_log where action = 'member.staff_requested' and target_id = 'c1000000-0000-4000-8000-000000000071'), 4,
  'each request and change is audited');
set local role authenticated;

-- ---------------------------------------------------------------- an administrator lets them in
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-000000000072","role":"authenticated"}';
select lives_ok($$select public.request_staff_access('20000000-0000-4000-8000-000000000072')$$, 'another account asks once');
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000072","role":"authenticated"}';
select throws_ok($$select public.admin_invite_staff('fresh@gmail.example', 'staff')$$, '55000', 'student_account',
  'a student account with requests left is not taken by an invite: its request is approved instead');
select throws_ok($$select public.admin_invite_staff('asker@gmail.example', 'admin')$$, '55000', 'student_account',
  'an account that used its requests is invited as staff, never straight to administrator');
select is(public.admin_invite_staff('asker@gmail.example', 'staff'), 'applied', 'inviting the email of an account that used its requests lets it in');
reset role;
select is((select row(role, status, school_id, staff_request_count)::text from public.profiles where id = 'c1000000-0000-4000-8000-000000000071'),
  row('staff'::public.user_role, 'verified'::public.account_status, '20000000-0000-4000-8000-000000000072'::uuid, 0::smallint)::text,
  'verified staff of the school, the count back to 0');

-- Made a student again by the school, the person can ask again (the invite reset the count).
update public.profiles set role = 'student' where id = 'c1000000-0000-4000-8000-000000000071';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-000000000071","role":"authenticated"}';
select is((select requests_left from public.my_staff_request()), 3, 'made a student again after an invite, they have 3 requests');

-- An approval lets the account in and leaves the count: becoming staff makes it moot.
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000072","role":"authenticated"}';
select lives_ok($$select public.admin_review_staff_request('c1000000-0000-4000-8000-000000000072', true)$$, 'the other request is approved');
reset role;
select is((select row(role, staff_request_count)::text from public.profiles where id = 'c1000000-0000-4000-8000-000000000072'),
  row('staff'::public.user_role, 1::smallint)::text, 'staff, with its count as it was');

-- A suspended account is not let in, and an account of another school is still not ours to take.
update public.profiles set status = 'suspended', role = 'student', staff_request_count = 3 where id = 'c1000000-0000-4000-8000-000000000072';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000072","role":"authenticated"}';
select throws_ok($$select public.admin_invite_staff('fresh@gmail.example', 'staff')$$, '55000', 'account_not_active',
  'a suspended account that used its requests is not let in by an invite');
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000071","role":"authenticated"}';
select throws_ok($$select public.admin_invite_staff('fresh@gmail.example', 'staff')$$, '55000', 'other_school',
  'an account of another school is not taken by an invite');

select * from finish();
rollback;
