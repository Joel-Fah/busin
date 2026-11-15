begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

-- The platform console's access and first page (ADR 0027).

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('20000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '20000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'driver@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'stu@b.edu', '{"provider":"google"}'),
  -- The platform admin is also a student of School B: the console does not depend on the role inside a school.
  ('b1000000-0000-4000-8000-000000000002', 'owner@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
insert into private.platform_admins (user_id, note) values ('b1000000-0000-4000-8000-000000000002', 'test');

set local role authenticated;

-- ---------------------------------------------------------------- everyone else
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.am_platform_admin(), false, 'a school admin is not a platform admin');
select throws_ok($$select public.platform_overview()$$, '42501', null, 'a school admin cannot read the platform overview');
select throws_ok($$select * from public.platform_audit$$, '42501', null, 'a school admin cannot read the platform audit');
select throws_ok($$insert into public.platform_audit (actor_id, action) values ('a3000000-0000-4000-8000-000000000001', 'x')$$, '42501', null, 'nor write it');
select throws_ok($$select * from private.platform_admins$$, '42501', null, 'nor read the list of platform admins');
select throws_ok($$select private.write_platform_audit('x')$$, '42501', null, 'nor call the audit writer');

set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.am_platform_admin(), false, 'staff is not a platform admin');
select throws_ok($$select public.platform_overview()$$, '42501', null, 'staff cannot read the platform overview');

set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.am_platform_admin(), false, 'a student is not a platform admin');
select throws_ok($$select public.platform_overview()$$, '42501', null, 'a student cannot read the platform overview');

reset role;
set local role anon;
select throws_ok($$select public.am_platform_admin()$$, '42501', null, 'a visitor who is not signed in cannot even ask');

-- ---------------------------------------------------------------- the platform admin
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is(public.am_platform_admin(), true, 'a listed account is a platform admin, whatever its role in its school');
select lives_ok($$select public.platform_overview()$$, 'it reads the platform overview');
select ok((public.platform_overview()->'totals'->>'schools_active')::int >= 2, 'the totals count every active school');
select is(
  (select (s->>'staff')::int from jsonb_array_elements(public.platform_overview()->'schools') s where s->>'id' = '10000000-0000-4000-8000-000000000001'),
  1, 'each school has its own counts (School A: one staff member)');
select is(
  (select (s->>'students')::int from jsonb_array_elements(public.platform_overview()->'schools') s where s->>'id' = '20000000-0000-4000-8000-000000000002'),
  2, 'School B: two students');
select throws_ok($$select * from public.platform_audit$$, '42501', null, 'the audit is read through functions only, even by a platform admin');

-- Removing the row applies at once (read live, ADR 0005).
reset role;
delete from private.platform_admins where user_id = 'b1000000-0000-4000-8000-000000000002';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.platform_overview()$$, '42501', null, 'a removed platform admin is refused at once');

select * from finish();
rollback;
