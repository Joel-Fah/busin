begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.register_device_token('web-token-of-a-browser-aaaaaaaaaaaa', 'web', 'fr')$$, 'a browser registers its token as web');
select is((select platform from public.device_tokens where token = 'web-token-of-a-browser-aaaaaaaaaaaa'), 'web', 'and it is kept as web');
select throws_ok($$select public.register_device_token('web-token-of-a-browser-bbbbbbbbbbbb', 'desktop', 'en')$$, '22023', null, 'any other platform is still refused');
reset role;

select * from finish();
rollback;
