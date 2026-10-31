begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into public.schools (id, name)
values ('10000000-0000-4000-8000-000000000001', 'Test University');
insert into public.school_domains (domain, school_id)
values ('test.edu', '10000000-0000-4000-8000-000000000001');

-- A Google user from an allowed domain becomes a verified student.
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values (
  'a1000000-0000-4000-8000-000000000001', 'Ada@Test.edu',
  '{"provider":"google"}',
  '{"full_name":"Ada Lovelace","picture":"https://example.test/ada.png"}'
);

select is(
  (select role::text from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'),
  'student', 'sign-up always creates a student');
select is(
  (select status::text from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'),
  'verified', 'new account is verified');
select is(
  (select email from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'),
  'ada@test.edu', 'email is stored lower case');
select is(
  (select school_id from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'),
  '10000000-0000-4000-8000-000000000001'::uuid, 'school is matched by email domain');
select is(
  (select avatar_url from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'),
  'https://example.test/ada.png', 'google picture becomes the avatar');

select throws_ok(
  $$insert into auth.users (id, email, raw_app_meta_data)
    values ('a1000000-0000-4000-8000-000000000002', 'eve@other.edu', '{"provider":"google"}')$$,
  '42501', 'This email domain is not enabled for BusIn', 'unknown domain is rejected');

select throws_ok(
  $$insert into auth.users (id, email, raw_app_meta_data)
    values ('a1000000-0000-4000-8000-000000000003', 'bob@test.edu', '{"provider":"email"}')$$,
  '42501', 'Only Google sign-in is allowed', 'non-google sign-up is rejected');

update public.schools set status = 'inactive' where id = '10000000-0000-4000-8000-000000000001';
select throws_ok(
  $$insert into auth.users (id, email, raw_app_meta_data)
    values ('a1000000-0000-4000-8000-000000000004', 'cy@test.edu', '{"provider":"google"}')$$,
  '42501', 'This email domain is not enabled for BusIn', 'inactive school does not accept sign-ups');

-- The token hook copies school, role and status into app_metadata.
select is(
  public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'a1000000-0000-4000-8000-000000000001',
    'claims', '{"aud":"authenticated"}'::jsonb
  )) -> 'claims' -> 'app_metadata' ->> 'role',
  'student', 'hook adds the role');
select is(
  public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'a1000000-0000-4000-8000-000000000001',
    'claims', '{"aud":"authenticated"}'::jsonb
  )) -> 'claims' -> 'app_metadata' ->> 'school_id',
  '10000000-0000-4000-8000-000000000001', 'hook adds the school');

select * from finish();
rollback;
