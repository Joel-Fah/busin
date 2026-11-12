begin;
create extension if not exists pgtap with schema extensions;
select plan(27);

insert into public.schools (id, name, accepts_open_signup, open_signup_domains) values
  ('10000000-0000-4000-8000-000000000001', 'School A', true, '{}'),
  ('10000000-0000-4000-8000-000000000002', 'School B', true, '{gmail.com}'),
  ('10000000-0000-4000-8000-000000000003', 'School C', false, '{}');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30);

-- sign-up
select is((select row(school_id, status)::text from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'),
  row('10000000-0000-4000-8000-000000000001'::uuid, 'verified'::public.account_status)::text, 'a school email still joins its school, verified');
insert into auth.users (id, email, raw_app_meta_data) values ('e1000000-0000-4000-8000-000000000001', 'ama@gmail.com', '{"provider":"google"}');
select is((select row(school_id, status)::text from public.profiles where id = 'e1000000-0000-4000-8000-000000000001'),
  row(null::uuid, 'pending'::public.account_status)::text, 'another email starts pending with no school');
update public.schools set accepts_open_signup = false where id in ('10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002');
select throws_ok($$insert into auth.users (id, email, raw_app_meta_data) values ('e1000000-0000-4000-8000-000000000009', 'x@yahoo.fr', '{"provider":"google"}')$$,
  '42501', 'This email domain is not enabled for BusIn', 'when no school accepts other emails, sign-up is refused as before');
update public.schools set accepts_open_signup = true where id in ('10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values ('e1000000-0000-4000-8000-000000000002', 'kofi@yahoo.fr', '{"provider":"google"}');
select throws_ok($$update public.profiles set status = 'verified' where id = 'e1000000-0000-4000-8000-000000000002'$$, '23514', null, 'an account with no school cannot be verified');

-- the gmail student sees the schools that accept gmail, and nothing of any school
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select array_agg(name order by name) from public.list_open_schools()), array['School A', 'School B'], 'a gmail account may ask School A (any email) and School B (gmail allowed), not School C');
select is((select count(*)::int from public.schools), 0, 'a pending account reads no school');
select is((select count(*)::int from public.semesters), 0, 'nor any school data');
select throws_ok($$select public.request_school('10000000-0000-4000-8000-000000000003')$$, '42501', 'This school does not accept your email address', 'not a school that does not accept other emails');
select lives_ok($$select public.request_school('10000000-0000-4000-8000-000000000001')$$, 'asks School A');
select is((select school_name from public.my_join_request()), 'School A', 'and sees its own request');
select throws_ok($$select public.request_school('10000000-0000-4000-8000-000000000002')$$, '54000', 'Too many requests', 'cannot switch again within 30 seconds');
select is((select count(*)::int from public.semesters), 0, 'still reads nothing of the school it asked');
select throws_ok($$update public.profiles set full_name = 'X' where id = 'e1000000-0000-4000-8000-000000000001'$$, '42501', null, 'and cannot edit its profile yet');
reset role;

-- the yahoo student only sees School A
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select array_agg(name) from public.list_open_schools()), array['School A'], 'a yahoo account sees only the school that accepts any email');
select throws_ok($$select public.request_school('10000000-0000-4000-8000-000000000002')$$, '42501', 'This school does not accept your email address', 'and cannot ask School B');
select lives_ok($$select public.request_school('10000000-0000-4000-8000-000000000001')$$, 'asks School A');
reset role;

-- a verified student cannot use request_school
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.request_school('10000000-0000-4000-8000-000000000002')$$, '42501', 'Only an account waiting for a school can ask to join one', 'a verified student cannot change school');
reset role;

-- School B's admin cannot act on School A's requests
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_verify_member('e1000000-0000-4000-8000-000000000001')$$, 'P0002', 'No request to verify', 'another school cannot verify the request');
select is((select count(*)::int from public.profiles where id = 'e1000000-0000-4000-8000-000000000001'), 0, 'nor even see it');
reset role;

-- School A's admin verifies one and declines the other
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.profiles where status = 'pending'), 2, 'School A''s admin sees both requests');
select lives_ok($$select public.admin_verify_member('e1000000-0000-4000-8000-000000000001')$$, 'verifies the gmail student');
select lives_ok($$select public.admin_decline_member('e1000000-0000-4000-8000-000000000002', 'Not one of our students')$$, 'declines the yahoo student with a reason');
reset role;

select is((select status::text from public.profiles where id = 'e1000000-0000-4000-8000-000000000001'), 'verified', 'the verified student is in');
select is((select count(*)::int from public.audit_log where school_id = '10000000-0000-4000-8000-000000000001' and action in ('member.verified', 'member.declined', 'member.join_requested')), 4, 'requests and decisions are audited');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.semesters), 1, 'once verified, the student reads the school');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select row(school_id, declined_school_name, decline_note)::text from public.my_join_request()), row(null::uuid, 'School A', 'Not one of our students')::text, 'the declined student sees who declined and why');
reset role;
update public.profiles set join_requested_at = now() - interval '1 minute' where id = 'e1000000-0000-4000-8000-000000000002';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.request_school(null)$$, 'and can withdraw or ask again');
reset role;

select * from finish();
rollback;
