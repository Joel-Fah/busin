begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';
insert into public.buses (id, school_id, plate, capacity) values
  ('b0000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'LT 100 AA', 60),
  ('b0000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'LT 200 AA', 60),
  ('b0000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'CE 300 BB', 60);

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$update public.buses set name = 'Blue Line' where id = 'b0000000-0000-4000-8000-000000000001'$$, 'an admin can name a bus');
select throws_ok($$update public.buses set name = 'blue line ' where id = 'b0000000-0000-4000-8000-000000000002'$$, '23505', null, 'two buses of a school cannot share a name, whatever the letter case');
select throws_ok($$update public.buses set name = '   ' where id = 'b0000000-0000-4000-8000-000000000002'$$, '23514', null, 'a name of only spaces is refused');
select throws_ok($$update public.buses set name = repeat('x', 41) where id = 'b0000000-0000-4000-8000-000000000002'$$, '23514', null, 'a name longer than 40 is refused');
select lives_ok($$update public.buses set name = null where id = 'b0000000-0000-4000-8000-000000000002'$$, 'a bus can have no name');
-- RLS: another school's bus is not touched
update public.buses set name = 'Blue Line' where id = 'b0000000-0000-4000-8000-000000000003';
reset role;
select is((select name from public.buses where id = 'b0000000-0000-4000-8000-000000000003'), null, 'an admin cannot name another school''s bus');
update public.buses set name = 'Blue Line' where id = 'b0000000-0000-4000-8000-000000000003';
select is((select name from public.buses where id = 'b0000000-0000-4000-8000-000000000003'), 'Blue Line', 'buses of different schools can share a name');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
update public.buses set name = 'Mine' where id = 'b0000000-0000-4000-8000-000000000002';
reset role;
select is((select name from public.buses where id = 'b0000000-0000-4000-8000-000000000002'), null, 'a student cannot name a bus');

select * from finish();
rollback;
