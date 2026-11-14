begin;
create extension if not exists pgtap with schema extensions;
select plan(39);

-- School billing (ADR 0022): the school's choice, the student's preference, the price and period copied onto each
-- request, monthly subscriptions that cover one month, and refusals until billing is set.

insert into public.schools (id, name, timezone) values
  ('10000000-0000-4000-8000-000000000001', 'School A', 'Africa/Douala'),
  ('20000000-0000-4000-8000-000000000002', 'School B', 'Africa/Douala');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '20000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

-- A semester running for months around today, so this month and the next are inside it.
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall',
   extract(year from current_date)::int, date_trunc('month', current_date)::date - 60, date_trunc('month', current_date)::date + 120);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into storage.objects (bucket_id, name, owner) values
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/receipt.jpg', 'a1000000-0000-4000-8000-000000000001'),
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/receipt.jpg', 'a1000000-0000-4000-8000-000000000002');

create function pg_temp.request(p_student uuid, p_mode text default 'full', p_month date default null) returns void
language sql as $$
  insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path, payment_mode, period_start)
  values ('10000000-0000-4000-8000-000000000001', p_student, 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001',
          '10000000-0000-4000-8000-000000000001/' || p_student || '/receipt.jpg', p_mode, p_month)
$$;
grant execute on function pg_temp.request(uuid, text, date) to authenticated;

-- ---------------------------------------------------------------- before billing is set
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select pg_temp.request('a1000000-0000-4000-8000-000000000001')$$, '55000', 'billing_not_set', 'no request while the school has not set billing');
select throws_ok($$select public.admin_set_billing('semester', 30000)$$, '42501', null, 'a student cannot set billing');

-- ---------------------------------------------------------------- the school's choice
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_set_billing('weekly', 30000)$$, '22023', 'invalid_period', 'only per semester or per month');
select throws_ok($$select public.admin_set_billing('semester', 0)$$, '22023', 'invalid_price', 'a price above zero');
select throws_ok($$select public.admin_set_billing('semester', 10000001)$$, '22023', 'invalid_price', 'and not absurd');
select throws_ok($$select public.admin_set_billing('semester', 30000, '20-80')$$, '22023', 'invalid_plan', 'only the three plans');
select throws_ok($$select public.admin_set_billing('month', 6000, '50-50')$$, '22023', 'invalid_plan', 'no installments on a month');
select lives_ok($$select public.admin_set_billing('semester', 30000, '40-30-30')$$, 'an administrator sets billing');
select is((select row(billing_period, price_xaf, installment_plan, currency)::text from public.schools where id = '10000000-0000-4000-8000-000000000001'),
  '(semester,30000,40-30-30,XAF)', 'for their own school');
select is((select count(*)::int from public.audit_log where action = 'school.billing'), 1, 'and it is audited');

set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.admin_set_billing('month', 5000)$$, 'another school sets its own');
reset role;
select is((select price_xaf from public.schools where id = '10000000-0000-4000-8000-000000000001'), 30000, 'without touching the first');
select throws_ok($$update public.schools set billing_period = 'month', installment_plan = '50-50' where id = '10000000-0000-4000-8000-000000000001'$$,
  '23514', null, 'the table itself refuses installments on a month');

-- ---------------------------------------------------------------- the student's preference
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.set_payment_preference('later')$$, '22023', 'invalid_value', 'full or installments only');
select lives_ok($$select public.set_payment_preference('installments')$$, 'a student saves a preference');
select is((select payment_preference from public.profiles where id = 'a1000000-0000-4000-8000-000000000001'), 'installments', 'on their own profile');
select throws_ok($$update public.profiles set payment_preference = 'full' where id = 'a1000000-0000-4000-8000-000000000001'$$, '42501', null, 'only through the function');
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.set_payment_preference('full')$$, '42501', null, 'an administrator has none');

-- ---------------------------------------------------------------- a semester request, priced by the server
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path, amount_xaf)
  values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001',
          '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/receipt.jpg', 1)$$,
  '42501', null, 'a student cannot write a price');
select throws_ok($$insert into public.subscriptions (school_id, student_id, semester_id, stop_id, proof_path, period_end)
  values ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001',
          '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/receipt.jpg', current_date + 400)$$,
  '42501', null, 'nor an end date');
select lives_ok($$select pg_temp.request('a1000000-0000-4000-8000-000000000001', 'installments', current_date)$$, 'a request in installments');
select is((select row(billing_period, amount_xaf, payment_mode, installment_plan, period_start, period_end)::text from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001'),
  '(semester,30000,installments,40-30-30,,)', 'carries the price and plan of the day, and no month (the month sent was ignored)');
select throws_ok($$select pg_temp.request('a1000000-0000-4000-8000-000000000001')$$, '23505', 'already_requested', 'one live request per semester');

-- Billing changes later: the request keeps what it was.
reset role;
update public.schools set price_xaf = 45000 where id = '10000000-0000-4000-8000-000000000001';
select is((select amount_xaf from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000001'), 30000, 'a later price change leaves a request as it was');

-- Full only.
update public.schools set installment_plan = null where id = '10000000-0000-4000-8000-000000000001';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select pg_temp.request('a1000000-0000-4000-8000-000000000002', 'installments')$$, '22023', 'installments_not_offered', 'installments only where the school offers them');

-- ---------------------------------------------------------------- monthly billing
reset role;
update public.schools set billing_period = 'month', price_xaf = 5000 where id = '10000000-0000-4000-8000-000000000001';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select pg_temp.request('a1000000-0000-4000-8000-000000000002')$$, '22023', 'month_required', 'a monthly request names its month');
select throws_ok($$select pg_temp.request('a1000000-0000-4000-8000-000000000002', 'full', (date_trunc('month', current_date) + interval '2 months')::date)$$,
  '22023', 'month_not_allowed', 'this month or the next only');
select throws_ok($$select pg_temp.request('a1000000-0000-4000-8000-000000000002', 'full', date_trunc('month', current_date)::date + 3)$$,
  '22023', 'month_not_allowed', 'given by its first day');
select lives_ok($$select pg_temp.request('a1000000-0000-4000-8000-000000000002', 'full', date_trunc('month', current_date)::date)$$, 'this month');
select is((select row(billing_period, amount_xaf, period_start, period_end)::text from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000002'),
  row('month', 5000, date_trunc('month', current_date)::date, (date_trunc('month', current_date) + interval '1 month - 1 day')::date)::text,
  'covers exactly that month, at the monthly price');
select lives_ok($$select pg_temp.request('a1000000-0000-4000-8000-000000000002', 'full', (date_trunc('month', current_date) + interval '1 month')::date)$$,
  'and the next month can be asked for already');
select throws_ok($$select pg_temp.request('a1000000-0000-4000-8000-000000000002', 'full', date_trunc('month', current_date)::date)$$, '23505', 'already_requested', 'but not the same month twice');

-- ---------------------------------------------------------------- what "covered today" means for a month
reset role;
update public.subscriptions set status = 'approved' where student_id = 'a1000000-0000-4000-8000-000000000002' and period_start = date_trunc('month', current_date)::date;
select isnt(private.subscription_on('a1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', current_date), null, 'an approved month covers its days');
select is(private.subscription_on('a1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', (date_trunc('month', current_date) + interval '1 month')::date), null,
  'and not the day after it (the next month is still pending)');
select isnt(private.active_subscription_id('a1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001'), null, 'today counts for the boarding code');

-- A month that has passed cannot be approved (a request left pending from last month).
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status, proof_path, payment_mode, period_start)
values ('11000000-0000-4000-8000-000000000009', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001',
        'd1000000-0000-4000-8000-000000000001', 'pending', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/receipt.jpg', 'full',
        (date_trunc('month', current_date) - interval '1 month')::date);
select is((select period_end from public.subscriptions where id = '11000000-0000-4000-8000-000000000009'), (date_trunc('month', current_date) - interval '1 day')::date,
  'history loaded without a user is priced and dated too');
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000009', 'approved')$$, '55000', 'period_ended', 'a past month is not approved');
reset role;
select set_config('request.jwt.claims', '', true);
select lives_ok($$update public.subscriptions set status = 'approved' where id = '11000000-0000-4000-8000-000000000009'$$, 'loading history without a user is still possible');
select is(private.subscription_on('a1000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', current_date),
  (select id from public.subscriptions where student_id = 'a1000000-0000-4000-8000-000000000002' and period_start = date_trunc('month', current_date)::date),
  'and a past month never covers today: this month does');

select * from finish();
rollback;
