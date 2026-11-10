begin;
create extension if not exists pgtap with schema extensions;
select plan(20);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');
insert into storage.objects (bucket_id, name) values
  ('school-logos', '10000000-0000-4000-8000-000000000001/logo-1.webp'),
  ('school-logos', '10000000-0000-4000-8000-000000000002/logo-1.webp');

-- the admin of school A
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.admin_update_school_profile(' Hill University ', 'HU', 'https://hill.example', 'Info@Hill.example', '+237 600 00 00 00', '1 Main St', 'Yaounde', 'Cameroon', 'A school on a hill.', true, false)$$, 'an admin saves the profile');
select throws_ok($$select public.admin_update_school_profile('Hill University', null, 'http://hill.example', null, null, null, null, null, null, false, false)$$, '23514', null, 'a website must use https');
select throws_ok($$select public.admin_update_school_profile('Hill University', null, null, 'not-an-email', null, null, null, null, null, false, false)$$, '23514', null, 'a contact email must look like one');
select throws_ok($$select public.admin_update_school_profile('Hill University', null, null, null, null, null, null, null, repeat('x', 281), false, false)$$, '23514', null, 'the about text is 280 characters at most');
select throws_ok($$select public.admin_update_school_profile('H', null, null, null, null, null, null, null, null, false, false)$$, '22023', 'The school name must be 2 to 120 characters', 'the name is required');
select throws_ok($$select public.admin_update_school_profile('Hill University', null, null, null, null, null, null, null, null, false, true)$$, '55000', 'Accept the terms before the school is shown publicly', 'the school cannot be listed before accepting the terms');
select lives_ok($$select public.admin_update_school_profile('Hill University', null, null, null, null, null, null, null, null, true, false, array[' @Gmail.com ', 'gmail.com', 'hill.example', ''])$$, 'allowed domains are saved');
select is((select open_signup_domains from public.schools where id = '10000000-0000-4000-8000-000000000001'), array['gmail.com', 'hill.example'], 'tidied: lowercase, no @, no duplicates or blanks');
select throws_ok($$select public.admin_update_school_profile('Hill University', null, null, null, null, null, null, null, null, true, false, array['not a domain'])$$, '22023', 'Invalid domain', 'a malformed domain is refused');
select lives_ok($$select public.admin_accept_school_terms('2026-11')$$, 'the admin accepts the terms');
select lives_ok($$select public.admin_update_school_profile('Hill University', 'HU', null, null, null, null, 'Yaounde', null, null, true, true)$$, 'then the school can be listed');
select lives_ok($$select public.admin_set_school_logo('10000000-0000-4000-8000-000000000001/logo-1.webp')$$, 'the admin sets a logo from the school folder');
select throws_ok($$select public.admin_set_school_logo('10000000-0000-4000-8000-000000000002/logo-1.webp')$$, '22023', 'The logo must be in the school''s folder', 'not a file of another school');
select throws_ok($$select public.admin_set_school_logo('10000000-0000-4000-8000-000000000001/missing.webp')$$, 'P0002', 'Logo file not found', 'not a file that does not exist');
reset role;

select is((select row(name, contact_email, city, accepts_open_signup, public_listing, terms_version)::text from public.schools where id = '10000000-0000-4000-8000-000000000001'),
  row('Hill University', null::text, 'Yaounde', true, true, '2026-11')::text, 'the profile is stored trimmed, empty fields cleared');
select is((select count(*)::int from public.audit_log where school_id = '10000000-0000-4000-8000-000000000001' and action like 'school.%'), 5, 'saves, terms and logo are audited');
select is((select name from public.schools where id = '10000000-0000-4000-8000-000000000002'), 'School B', 'the other school is untouched');

-- a student cannot use the admin functions
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_accept_school_terms('2026-11')$$, '42501', 'Admin access required', 'a student cannot accept terms');
reset role;

-- anyone sees only listed schools, and only public fields
set local role anon;
select is((select count(*)::int from public.public_schools()), 1, 'a visitor sees only the listed school');
select is((select row(name, city, logo_path)::text from public.public_schools()), row('Hill University', 'Yaounde', '10000000-0000-4000-8000-000000000001/logo-1.webp')::text, 'with its name, city and logo');
reset role;

select * from finish();
rollback;
