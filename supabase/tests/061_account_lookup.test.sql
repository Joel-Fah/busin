begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

-- Account lookup in the platform console (ADR 0027, slice 7).

insert into public.schools (id, name) values ('f0000000-0000-4000-8000-0000000000a1', 'Lookup School');
insert into public.school_domains (domain, school_id) values ('look.edu', 'f0000000-0000-4000-8000-0000000000a1');
insert into auth.users (id, email, raw_app_meta_data, last_sign_in_at) values
  ('f1000000-0000-4000-8000-0000000000a1', 'admin@look.edu', '{"provider":"google"}', now()),
  ('f1000000-0000-4000-8000-0000000000a2', 'student@look.edu', '{"provider":"google"}', now() - interval '2 days'),
  ('f1000000-0000-4000-8000-0000000000f1', 'platform@look.edu', '{"provider":"google"}', now());
update public.profiles set role = 'admin' where id = 'f1000000-0000-4000-8000-0000000000a1';
insert into private.platform_admins (user_id, note) values ('f1000000-0000-4000-8000-0000000000f1', 'test');
insert into public.staff_invites (email, school_id, role) values ('newcomer@example.org', 'f0000000-0000-4000-8000-0000000000a1', 'admin');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"f1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select public.platform_lookup_account('student@look.edu')$$, '42501', null, 'a school admin cannot look up accounts');

set local "request.jwt.claims" = '{"sub":"f1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select throws_ok($$select public.platform_lookup_account('not an email')$$, '22023', 'invalid_email', 'an email is needed');
select is(public.platform_lookup_account(' Student@Look.edu ') ->> 'school_name', 'Lookup School', 'an account is found by its exact email, in any case');
select is(public.platform_lookup_account('student@look.edu') ->> 'role', 'student', 'with its role');
select is(public.platform_lookup_account('student@look.edu') ->> 'status', 'verified', 'its status');
select ok((public.platform_lookup_account('student@look.edu') ->> 'last_sign_in_at') is not null, 'and its last sign-in');
select is(public.platform_lookup_account('someone@else.example') ->> 'found', 'false', 'an unknown email is not found');
select is(public.platform_lookup_account('student@look.ed') ->> 'found', 'false', 'nor is a partial one: no search, exact only');
select is(public.platform_lookup_account('newcomer@example.org') -> 'invite' ->> 'school_name', 'Lookup School', 'an open invite is shown');

reset role;
select is((select count(*)::int from public.platform_audit where actor_id = 'f1000000-0000-4000-8000-0000000000f1' and action = 'account.lookup'), 7,
  'each lookup is in the platform audit');
select ok(not exists (select 1 from public.platform_audit where actor_id = 'f1000000-0000-4000-8000-0000000000f1' and details::text like '%@%'),
  'the audit never keeps an email');

-- The thirtieth lookup in an hour is the last.
insert into public.platform_audit (actor_id, action) select 'f1000000-0000-4000-8000-0000000000f1', 'account.lookup' from generate_series(1, 23);
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"f1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select throws_ok($$select public.platform_lookup_account('student@look.edu')$$, '54000', 'too_many', 'thirty lookups an hour at most');
select throws_ok($$select * from public.platform_audit$$, '42501', null, 'and the audit itself stays closed');

select * from finish();
rollback;
