begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

-- Installments follow the student's start (ADR 0022, amended): the parts are spread from the day the student asks to the
-- end of the semester, everyone pays the same price, and installments stop when the parts cannot be two weeks apart.

insert into public.schools (id, name, timezone, billing_period, price_xaf, installment_plan) values
  ('10000000-0000-4000-8000-000000000001', 'School A', 'Africa/Douala', 'semester', 30000, '50-50');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'late@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'tooLate@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000003', 'early@a.edu', '{"provider":"google"}');

-- A semester that started 60 days ago and has 40 days left (today included); one that ends in 20 days; one in the future.
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2090, (now() at time zone 'Africa/Douala')::date - 60, (now() at time zone 'Africa/Douala')::date + 39),
  ('c1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'spring', 2091, (now() at time zone 'Africa/Douala')::date - 100, (now() at time zone 'Africa/Douala')::date + 19),
  ('c1000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'summer', 2092, (now() at time zone 'Africa/Douala')::date + 10, (now() at time zone 'Africa/Douala')::date + 109);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into storage.objects (bucket_id, name, owner) values
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/r.jpg', 'a1000000-0000-4000-8000-000000000001'),
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/r.jpg', 'a1000000-0000-4000-8000-000000000002'),
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000003/r.jpg', 'a1000000-0000-4000-8000-000000000003');

select ok(private.installments_fit((now() at time zone 'Africa/Douala')::date, (now() at time zone 'Africa/Douala')::date, (now() at time zone 'Africa/Douala')::date + 27, '50-50'), 'two parts fit in 28 days');
select ok(not private.installments_fit((now() at time zone 'Africa/Douala')::date, (now() at time zone 'Africa/Douala')::date, (now() at time zone 'Africa/Douala')::date + 26, '50-50'), 'but not in 27');
select ok(not private.installments_fit((now() at time zone 'Africa/Douala')::date, (now() at time zone 'Africa/Douala')::date, (now() at time zone 'Africa/Douala')::date + 40, '40-30-30'), 'three parts need 42 days');

set local role authenticated;
-- Joining late: the parts follow the student's own 40 days, not the semester's dates.
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path, payment_mode)
values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001',
        '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/r.jpg', 'installments');
select results_eq($$select seq::int, amount_xaf, due_date - (now() at time zone 'Africa/Douala')::date from public.subscription_installments order by seq$$,
  $$values (1, 15000, 0), (2, 15000, 20)$$,
  'a late joiner pays the same price, part 2 halfway through their own time (not the day they join)');
select is((select amount_xaf from public.subscriptions), 30000, 'the whole price, like everyone');

-- 20 days left: in full only.
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path, payment_mode)
  values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001',
          '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/r.jpg', 'installments')$$,
  '22023', 'installments_too_late', 'too close to the end of the semester for installments');
select lives_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path, payment_mode)
  values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001',
          '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/r.jpg', 'full')$$,
  'paying in full is still open');

-- Asking before the semester starts: part 1 now, the rest spread from the semester's first day.
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000003","role":"authenticated"}';
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path, payment_mode)
values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000003', 'c1000000-0000-4000-8000-000000000003', 'd1000000-0000-4000-8000-000000000001',
        '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000003/r.jpg', 'installments');
select results_eq($$select seq::int, due_date - (now() at time zone 'Africa/Douala')::date from public.subscription_installments order by seq$$,
  $$values (1, 0), (2, 60)$$,
  'asked before the semester: part 1 today, part 2 halfway through the semester');
reset role;
select is((select count(*)::int from public.subscription_installments where school_id = '10000000-0000-4000-8000-000000000001'), 4, 'the refused request made no parts');

select * from finish();
rollback;
