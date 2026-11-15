begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

-- School onboarding from the platform console (ADR 0027, slice 4).

update public.schools set accepts_open_signup = false, open_signup_domains = '{}', public_listing = false;
insert into public.schools (id, name) values ('c0000000-0000-4000-8000-0000000000a1', 'Old School');
insert into public.school_domains (domain, school_id) values ('old.edu', 'c0000000-0000-4000-8000-0000000000a1');
insert into auth.users (id, email, raw_app_meta_data) values
  ('c1000000-0000-4000-8000-0000000000a1', 'admin@old.edu', '{"provider":"google"}'),
  ('c1000000-0000-4000-8000-0000000000a2', 'teacher@old.edu', '{"provider":"google"}'),
  ('c1000000-0000-4000-8000-0000000000f1', 'platform@old.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'c1000000-0000-4000-8000-0000000000a1';
insert into private.platform_admins (user_id, note) values ('c1000000-0000-4000-8000-0000000000f1', 'test');

set local role authenticated;

-- ---------------------------------------------------------------- only the platform
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select public.platform_create_school('New', null, 'Africa/Douala')$$, '42501', null, 'a school admin cannot create a school');
select throws_ok($$select public.platform_invite_school_admin('c0000000-0000-4000-8000-0000000000a1', 'x@y.org')$$, '42501', null, 'nor invite an administrator for any school');
select throws_ok($$select public.platform_set_school_status('c0000000-0000-4000-8000-0000000000a1', false)$$, '42501', null, 'nor switch a school off');

-- ---------------------------------------------------------------- creating
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select throws_ok($$select public.platform_create_school('X', null, 'Africa/Douala')$$, '22023', 'bad_name', 'a name is two characters at least');
select throws_ok($$select public.platform_create_school('New School', null, 'Mars/Olympus')$$, '22023', 'bad_timezone', 'the time zone must exist');
select throws_ok($$select public.platform_create_school('New School', null, null)$$, '22023', 'bad_timezone', 'and is required');
select throws_ok($$select public.platform_create_school('New School', null, 'Africa/Douala', null, null, array['not a domain'])$$, '22023', 'bad_domain', 'a domain must look like one');
select throws_ok($$select public.platform_create_school('OLD school', null, 'Africa/Douala')$$, '23505', 'name_taken', 'the same name twice is refused');
select throws_ok($$select public.platform_create_school('New School', null, 'Africa/Douala', null, null, array['new.edu', 'Old.edu'])$$, '23505', 'domain_taken', 'a domain of another school is refused');

select lives_ok($$select set_config('test.school', public.platform_create_school('New School', 'NS', 'Africa/Lagos', 'NG', 'Lagos', array[' New.edu ', 'new.edu', 'staff.new.edu'])::text, true)$$,
  'a school is created');
-- The platform admin reads schools through platform functions only (Row Level Security shows them their own), so the
-- checks read the tables directly.
reset role;
select is((select timezone from public.schools where name = 'New School'), 'Africa/Lagos', 'in its time zone');
select is((select array_agg(domain order by domain) from public.school_domains d join public.schools s on s.id = d.school_id where s.name = 'New School'),
  array['new.edu', 'staff.new.edu'], 'with its domains, cleaned and without repeats');
select is((select status from public.schools where name = 'New School'), 'active', 'and is active');
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';

-- ---------------------------------------------------------------- the first administrator
select throws_ok($$select public.platform_invite_school_admin(current_setting('test.school')::uuid, 'nope')$$, '22023', 'invalid_email', 'a bad email is refused');
select throws_ok($$select public.platform_invite_school_admin(current_setting('test.school')::uuid, 'teacher@old.edu')$$, '55000', 'other_school',
  'an account of another school is not taken');
select is(public.platform_invite_school_admin(current_setting('test.school')::uuid, 'Registrar@New.edu'), 'invited', 'a new email is invited');
select is((select count(*)::int from public.platform_school_invites(current_setting('test.school')::uuid)), 1, 'the invite is listed');

-- The invited person signs in with Google for the first time and lands as a verified administrator of the new school.
reset role;
insert into auth.users (id, email, raw_app_meta_data) values ('c1000000-0000-4000-8000-0000000000b1', 'registrar@new.edu', '{"provider":"google"}');
select is((select role::text || ' ' || status::text from public.profiles where id = 'c1000000-0000-4000-8000-0000000000b1'), 'admin verified',
  'the first sign-in makes them a verified administrator');
select is((select s.name from public.profiles p join public.schools s on s.id = p.school_id where p.id = 'c1000000-0000-4000-8000-0000000000b1'), 'New School',
  'of the new school');

-- ---------------------------------------------------------------- switching off
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select lives_ok($$select public.platform_set_school_status(current_setting('test.school')::uuid, false)$$, 'the school is switched off');
reset role;
select throws_ok($$insert into auth.users (id, email, raw_app_meta_data) values ('c1000000-0000-4000-8000-0000000000b2', 'student@new.edu', '{"provider":"google"}')$$,
  '42501', null, 'a switched-off school takes no new sign-up');
select is((select count(*)::int from public.platform_audit where school_id = current_setting('test.school')::uuid
    and action in ('school.created', 'school.admin_invited', 'school.switched_off')), 3,
  'creating, inviting and switching off are in the platform audit');

select * from finish();
rollback;
