begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

insert into public.faculties (id, school_id, name, code) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Faculty One', 'F1'),
  ('f2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Faculty Two', 'F2');
insert into public.departments (id, school_id, faculty_id, name) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'Department One'),
  ('d2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'f2000000-0000-4000-8000-000000000001', 'Department Two');
insert into public.programs (id, school_id, name) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Bachelor'),
  ('e2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Master');

-- a department cannot sit under another school's faculty
select throws_ok(
  $$insert into public.departments (school_id, faculty_id, name) values ('10000000-0000-4000-8000-000000000001', 'f2000000-0000-4000-8000-000000000001', 'Crossed')$$,
  '23503', null, 'a department cannot belong to a faculty of another school');

-- a student reads their own school only
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::int from public.faculties), 1, 'a student sees only their school''s faculties');
select is((select count(*)::int from public.departments), 1, 'a student sees only their school''s departments');
select is((select count(*)::int from public.programs), 1, 'a student sees only their school''s programs');

select throws_ok(
  $$insert into public.faculties (school_id, name) values ('10000000-0000-4000-8000-000000000001', 'Mine')$$,
  '42501', null, 'a student cannot add a faculty');

-- a student chooses theirs; the readable text follows
select lives_ok(
  $$update public.profiles set department_id = 'd1000000-0000-4000-8000-000000000001', program_id = 'e1000000-0000-4000-8000-000000000001' where id = 'a1000000-0000-4000-8000-000000000001'$$,
  'a student can choose a department and a program');
select is((select department || '/' || program from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), 'Department One/Bachelor', 'the text copy follows the choice');
select throws_ok(
  $$update public.profiles set department_id = 'd2000000-0000-4000-8000-000000000001' where id = 'a1000000-0000-4000-8000-000000000001'$$,
  '23503', null, 'a student cannot choose a department of another school');
select throws_ok(
  $$update public.profiles set department = 'Typed by hand' where id = 'a1000000-0000-4000-8000-000000000001'$$,
  '42501', null, 'the text copy cannot be written by a client');

-- an admin renames, and the students follow
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
update public.departments set name = 'Department Renamed' where id = 'd1000000-0000-4000-8000-000000000001';
reset role;
select is((select department from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), 'Department Renamed', 'renaming a department updates the students''s copy');

-- the admin of another school cannot touch it
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
update public.departments set name = 'Hijacked' where id = 'd1000000-0000-4000-8000-000000000001';
reset role;
select is((select name from public.departments where id = 'd1000000-0000-4000-8000-000000000001'), 'Department Renamed', 'another school''s admin cannot rename it');

-- removing a department clears the choice
delete from public.departments where id = 'd1000000-0000-4000-8000-000000000001';
select ok((select department_id is null and department is null from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), 'deleting a department clears the student''s choice');

select * from finish();
rollback;
