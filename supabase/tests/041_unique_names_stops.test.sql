begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A'), ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

-- A stop in School A at 3.85, 11.5, loaded as a seed does.
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Main Gate', extensions.st_point(11.5, 3.85)::extensions.geography);
-- Seeds may hold stops closer than the rule allows: they are history, not what the API accepts.
select lives_ok($$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000001', 'Seed neighbour', extensions.st_point(11.5, 3.85005)::extensions.geography)$$, 'seeds are not held to the distance rule');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';

-- ---------------------------------------------------------------- faculties
select lives_ok($$insert into public.faculties (school_id, name) values ('10000000-0000-4000-8000-000000000001', 'Law')$$, 'a faculty is added');
select throws_ok($$insert into public.faculties (school_id, name) values ('10000000-0000-4000-8000-000000000001', 'law')$$, '23505', null, 'the same in lower case is the same faculty');
select throws_ok($$insert into public.faculties (school_id, name) values ('10000000-0000-4000-8000-000000000001', '  LAW ')$$, '23505', null, 'and in capitals with spaces around it');
select throws_ok($$insert into public.faculties (school_id, name) values ('10000000-0000-4000-8000-000000000001', 'LaW')$$, '23505', null, 'and in mixed case');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$insert into public.faculties (school_id, name) values ('10000000-0000-4000-8000-000000000002', 'Law')$$, 'another school may have its own Law');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$insert into public.faculties (id, school_id, name) values ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', E'  Business \n  School ')$$, 'padded and multi-line names are accepted');
select is((select name from public.faculties where id = 'e1000000-0000-4000-8000-000000000001'), 'Business School', 'and stored cleaned: trimmed, one space between words');
select throws_ok($$update public.faculties set name = 'BUSINESS SCHOOL' where school_id = '10000000-0000-4000-8000-000000000001' and name = 'Law'$$, '23505', null, 'renaming into a clash is refused too');

-- ---------------------------------------------------------------- departments (unique within a faculty)
select lives_ok($$insert into public.faculties (id, school_id, name) values ('e1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Science')$$, 'a second faculty');
select lives_ok($$insert into public.departments (school_id, faculty_id, name) values ('10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'Computer Science')$$, 'a department is added');
select throws_ok($$insert into public.departments (school_id, faculty_id, name) values ('10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'cOMPUTER sCIENCE')$$, '23505', null, 'the same department in another case, in the same faculty, is refused');
select lives_ok($$insert into public.departments (school_id, faculty_id, name) values ('10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000002', 'Computer Science')$$, 'another faculty may have a department of that name');

-- ---------------------------------------------------------------- programs
select lives_ok($$insert into public.programs (school_id, name) values ('10000000-0000-4000-8000-000000000001', 'Bachelor')$$, 'a program is added');
select throws_ok($$insert into public.programs (school_id, name) values ('10000000-0000-4000-8000-000000000001', ' BACHELOR')$$, '23505', null, 'the same in capitals is refused');

-- ---------------------------------------------------------------- stop names
select throws_ok($$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000001', 'main  gate', extensions.st_point(11.6, 3.9)::extensions.geography)$$, '23505', null, 'a stop name is unique ignoring case and extra spaces');

-- ---------------------------------------------------------------- bus plates
select lives_ok($$insert into public.buses (id, school_id, plate, capacity) values ('e2000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', ' ab  123 ', 50)$$, 'a bus is added');
select is((select plate from public.buses where id = 'e2000000-0000-4000-8000-000000000001'), 'AB 123', 'its plate is stored in capitals, cleaned');
select throws_ok($$insert into public.buses (school_id, plate, capacity) values ('10000000-0000-4000-8000-000000000001', 'ab 123', 50)$$, '23505', null, 'the same plate in lower case is refused');

-- ---------------------------------------------------------------- stops too close (25 m); 0.0001 degree of latitude is about 11 m
select throws_ok($$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000001', 'Same place', extensions.st_point(11.5, 3.85)::extensions.geography)$$, '22023', 'stop_too_close', 'a stop at the very same coordinates is refused');
select throws_ok($$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000001', 'Twenty metres', extensions.st_point(11.5, 3.85018)::extensions.geography)$$, '22023', 'stop_too_close', 'one about 20 m away is refused');
select lives_ok($$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000001', 'Thirty metres', extensions.st_point(11.5, 3.85030)::extensions.geography)$$, 'one about 33 m away is accepted (the portal warns, the database does not)');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000002', 'Other school same spot', extensions.st_point(11.5, 3.85)::extensions.geography)$$, 'another school''s stop at that spot does not count');
reset role;

update public.stops set active = false where id = 'd1000000-0000-4000-8000-000000000001' or name = 'Seed neighbour';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$insert into public.stops (school_id, name, location) values ('10000000-0000-4000-8000-000000000001', 'Where the old one was', extensions.st_point(11.5, 3.85)::extensions.geography)$$, 'a stop that is no longer in use does not block a new one');
reset role;

select throws_ok($$set local role authenticated; set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
  update public.stops set location = extensions.st_point(11.5, 3.85002)::extensions.geography where name = 'Thirty metres'$$, '22023', 'stop_too_close', 'moving a stop onto another is refused');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$update public.stops set name = 'Thirty metres north' where name = 'Thirty metres'$$, 'renaming a stop that is near another is not a move, so it is allowed');
reset role;

select * from finish();
rollback;
