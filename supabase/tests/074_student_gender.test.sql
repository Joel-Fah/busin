begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'student@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'other@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';

select is((select gender from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), null, 'not set until the student gives it');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
update public.profiles set gender = 'female' where id = 'a1000000-0000-4000-8000-000000000001';
select is((select gender from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), 'female', 'the student sets their own');
select throws_ok($$update public.profiles set gender = 'other' where id = 'a1000000-0000-4000-8000-000000000001'$$, '23514', null, 'only male or female');
update public.profiles set gender = 'male' where id = 'a1000000-0000-4000-8000-000000000002';
reset role;
select is((select gender from public.profiles where id = 'a1000000-0000-4000-8000-000000000002'), null, 'and nobody else''s');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
update public.profiles set gender = null where id = 'a1000000-0000-4000-8000-000000000001';
select is((select gender from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), null, 'and can clear it');
update public.profiles set gender = 'female' where id = 'a1000000-0000-4000-8000-000000000001';
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select gender from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), 'female', 'the school''s admin sees it');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), 0, 'staff do not read students'' profiles');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select count(*)::int from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), 0, 'nor do other students');
reset role;

update public.profiles set deleted_at = now(), full_name = 'Deleted account' where id = 'a1000000-0000-4000-8000-000000000001';
select is((select gender from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), null, 'erased with the account');

select * from finish();
rollback;
