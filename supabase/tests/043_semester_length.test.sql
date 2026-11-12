begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

insert into public.schools (id, name, timezone) values ('10000000-0000-4000-8000-000000000001', 'School A', 'UTC');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000001';

-- A long-running one that is already there (loaded as history: the owner's example).
insert into public.semesters (id, school_id, name, year, start_date, end_date, created_by)
values ('b1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'spring', 2021, '2021-02-04', '2026-04-04', 'a3000000-0000-4000-8000-000000000001');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';

select throws_ok(format($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'fall', %s, %L, %L, 'a3000000-0000-4000-8000-000000000001')$$,
  extract(year from current_date), current_date::text, (current_date + 5 * 365)::text), '22023', 'semester_length', 'a semester of five years is refused');
select throws_ok(format($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'fall', %s, %L, %L, 'a3000000-0000-4000-8000-000000000001')$$,
  extract(year from current_date), current_date::text, (current_date + 367)::text), '22023', 'semester_length', 'one of 367 days is refused');
select lives_ok(format($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'summer', %s, %L, %L, 'a3000000-0000-4000-8000-000000000001')$$,
  extract(year from current_date), current_date::text, (current_date + 366)::text), 'one of exactly 366 days is allowed');
select throws_ok(format($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'fall', %s, %L, %L, 'a3000000-0000-4000-8000-000000000001')$$,
  extract(year from current_date), (current_date + 1000)::text, (current_date + 1003)::text), '22023', 'semester_length', 'one of 3 days is too short');
select lives_ok(format($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'spring', %s, %L, %L, 'a3000000-0000-4000-8000-000000000001')$$,
  extract(year from current_date + 2000), (current_date + 2000)::text, (current_date + 2007)::text), 'one of 7 days is the shortest allowed');

-- The year is the year the semester starts or ends in.
select throws_ok(format($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'fall', 2040, %L, %L, 'a3000000-0000-4000-8000-000000000001')$$,
  (current_date + 3000)::text, (current_date + 3100)::text), '22023', 'semester_year', 'a year that is not in the dates is refused');
select lives_ok($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'fall', 2031, '2031-09-01', '2032-01-31', 'a3000000-0000-4000-8000-000000000001')$$, 'a fall semester of 2031 may end in January 2032');
select lives_ok($$insert into public.semesters (school_id, name, year, start_date, end_date, created_by)
  values ('10000000-0000-4000-8000-000000000001', 'summer', 2032, '2032-02-01', '2032-06-30', 'a3000000-0000-4000-8000-000000000001')$$, 'and the year may also be the one it ends in');

-- The existing long one is history: it can be renamed, but its dates cannot be moved to another bad span.
select lives_ok($$update public.semesters set name = 'summer' where id = 'b1000000-0000-4000-8000-000000000001'$$, 'an old row is still editable when its dates are left alone');
select throws_ok($$update public.semesters set end_date = '2026-06-01' where id = 'b1000000-0000-4000-8000-000000000001'$$, '22023', 'semester_in_past', 'its dates cannot be moved to another past span');
select throws_ok(format($$update public.semesters set end_date = %L where id = 'b1000000-0000-4000-8000-000000000001'$$, (current_date + 400)::text), '22023', 'semester_length', 'nor stretched');
reset role;

select * from finish();
rollback;
