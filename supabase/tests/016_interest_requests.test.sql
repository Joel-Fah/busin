begin;
create extension if not exists pgtap with schema extensions;
select plan(20);

-- Start from an empty table (inside this test's transaction, rolled back at the end), so requests already in the
-- database do not change the counts.
delete from public.interest_requests;

-- closed table
select ok((select relrowsecurity and relforcerowsecurity from pg_class where oid = 'public.interest_requests'::regclass), 'RLS is on and forced');
select is((select count(*)::int from pg_policies where schemaname = 'public' and tablename = 'interest_requests'), 0, 'with no policies');
select ok(not has_table_privilege('anon', 'public.interest_requests', 'select'), 'a visitor cannot read the requests');
select ok(not has_table_privilege('anon', 'public.interest_requests', 'insert'), 'nor write them directly');
select ok(not has_table_privilege('authenticated', 'public.interest_requests', 'select'), 'nor can a signed-in user read them');

-- a visitor sends requests through the function
set local role anon;
select is(public.submit_interest('notify', '  Ama@Example.com ', p_locale => 'fr'), 'stored', 'a notify-me request is stored');
select is(public.submit_interest('notify', 'ama@example.com'), 'already', 'the same request again is not stored twice');
select is(public.submit_interest('school', 'head@school.example', 'Ada Head', 'Hill School', 'We have 3 buses.'), 'stored', 'a school request is stored');
select is(public.submit_interest('notify', 'bot@spam.example', p_trap => 'http://spam'), 'stored', 'spam caught by the hidden field looks accepted');
select throws_ok($$select public.submit_interest('school', 'x@school.example', 'Only Name')$$, '22023', 'A school request needs a name and a school', 'a school request needs the school');
select throws_ok($$select public.submit_interest('notify', 'not-an-email')$$, '22023', 'Invalid email', 'a bad address is refused');
select throws_ok($$select public.submit_interest('notify_android', 'a@b.example')$$, '22023', 'Unknown request kind', 'the old per-platform kinds and unknown kinds are refused');
select throws_ok($$select public.submit_interest('school', 'a@b.example', 'A', 'B', repeat('x', 1001))$$, '22023', 'Message too long', 'a long message is refused');
select throws_ok($$select * from public.interest_requests$$, '42501', null, 'the visitor still cannot read the table');
reset role;

select is((select count(*)::int from public.interest_requests), 2, 'two rows: no duplicate, no spam');
select is((select email from public.interest_requests where kind = 'notify'), 'ama@example.com', 'the address is trimmed and lower-cased');
select is((select locale from public.interest_requests where kind = 'notify'), 'fr', 'the language is kept');

-- floods: per address
insert into public.interest_requests (kind, email, name, organisation) values
  ('notify', 'busy@school.example', null, null),
  ('school', 'busy@school.example', 'A', 'B'),
  ('school', 'busy@school.example', 'A', 'C');
set local role anon;
select throws_ok($$select public.submit_interest('school', 'busy@school.example', 'A', 'Other school')$$, '54000', 'Too many requests', 'a fourth request from one address in an hour is refused');
reset role;

-- floods: overall
insert into public.interest_requests (kind, email, created_at)
select 'notify', 'n' || g || '@flood.example', now() - interval '5 minutes' from generate_series(1, 200) g;
set local role anon;
select throws_ok($$select public.submit_interest('notify', 'late@example.com')$$, '54000', 'Too many requests', 'past the hourly limit for everyone, requests are refused');
reset role;
select is((select count(*)::int from public.interest_requests where email = 'late@example.com'), 0, 'and nothing was stored');

select * from finish();
rollback;
