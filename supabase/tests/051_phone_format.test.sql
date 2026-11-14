begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

-- Phone numbers in one form (ADR 0024): E.164 only, for students and schools; older numbers tidied by the migration.

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';

-- ---------------------------------------------------------------- tidying older numbers
select is(private.phone_e164_guess('677 12 34 56'), '+237677123456', 'a bare Cameroonian mobile gets its code');
select is(private.phone_e164_guess('0677123456'), '+237677123456', 'with a leading 0 too');
select is(private.phone_e164_guess('+237 677-123-456'), '+237677123456', 'spaces and dashes are dropped');
select is(private.phone_e164_guess('237677123456'), '+237677123456', 'the code without its plus');
select is(private.phone_e164_guess('+33 6 12 34 56 78'), '+33612345678', 'a foreign number in international form is kept');
select is(private.phone_e164_guess('call me'), null, 'anything else is cleared');

-- ---------------------------------------------------------------- the rule
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$update public.profiles set phone = '+237677123456' where id = 'a1000000-0000-4000-8000-000000000001'$$, 'a student saves an E.164 number');
select throws_ok($$update public.profiles set phone = '677 12 34 56' where id = 'a1000000-0000-4000-8000-000000000001'$$, '23514', null, 'not a local one');
select throws_ok($$update public.profiles set phone = '+237 677 12 34 56' where id = 'a1000000-0000-4000-8000-000000000001'$$, '23514', null, 'nor one with spaces');
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.admin_update_school_profile('School A', 'SA', null, null, '+237222000000', null, null, null, null, false, false)$$, 'a school saves an E.164 number');
select throws_ok($$select public.admin_update_school_profile('School A', 'SA', null, null, '+237 222 00 00 00', null, null, null, null, false, false)$$, '23514', null, 'not one with spaces');
reset role;
select is((select phone from public.schools where id = '10000000-0000-4000-8000-000000000001'), '+237222000000', 'and the saved one stays');

select * from finish();
rollback;
