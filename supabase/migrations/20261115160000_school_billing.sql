-- School billing (ADR 0022). A school chooses how students are billed (per semester, as before, or per calendar month),
-- the price, and whether students may pay a semester in installments (one of three set plans). Each subscription keeps
-- what applied when it was asked for: changing billing later only affects new requests. The price and the dates are
-- always worked out here; a student sends only how they pay and, for monthly billing, which month.

-- ---------------------------------------------------------------- the school's choice
alter table public.schools
  add column billing_period text check (billing_period in ('semester', 'month')),
  add column price_xaf integer check (price_xaf > 0 and price_xaf <= 10000000),
  add column installment_plan text check (installment_plan in ('50-50', '40-30-30', '30-60-10')),
  add column currency text not null default 'XAF' check (currency ~ '^[A-Z]{3}$'),
  -- Set together, or not set yet (then new requests are refused).
  add constraint schools_billing_complete check ((billing_period is null) = (price_xaf is null)),
  -- A month is paid in one go; installments split a semester.
  add constraint schools_installments_semester check (installment_plan is null or billing_period = 'semester');

-- Administrators only, for their own school; audited.
create function public.admin_set_billing(p_period text, p_price integer, p_plan text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  if p_period is null or p_period not in ('semester', 'month') then
    raise exception 'invalid_period' using errcode = '22023';
  end if;
  if p_price is null or p_price <= 0 or p_price > 10000000 then
    raise exception 'invalid_price' using errcode = '22023';
  end if;
  if p_plan is not null and (p_plan not in ('50-50', '40-30-30', '30-60-10') or p_period <> 'semester') then
    raise exception 'invalid_plan' using errcode = '22023';
  end if;
  update public.schools
  set billing_period = p_period, price_xaf = p_price, installment_plan = p_plan
  where id = v_school;
  perform private.write_audit(v_school, (select auth.uid()), 'school.billing', 'school', v_school,
    jsonb_build_object('period', p_period, 'price', p_price, 'plan', p_plan));
end;
$$;
revoke execute on function public.admin_set_billing(text, integer, text) from public, anon;
grant execute on function public.admin_set_billing(text, integer, text) to authenticated;

-- ---------------------------------------------------------------- the student's preference
-- How the student prefers to pay, used to fill in the request form. Null until they choose.
alter table public.profiles add column payment_preference text check (payment_preference in ('full', 'installments'));

create function public.set_payment_preference(p_preference text)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if private.my_school_id() is null or private.my_role() is distinct from 'student' then
    raise exception 'Only a student has a payment preference' using errcode = '42501';
  end if;
  if p_preference is not null and p_preference not in ('full', 'installments') then
    raise exception 'invalid_value' using errcode = '22023';
  end if;
  update public.profiles set payment_preference = p_preference where id = (select auth.uid());
end;
$$;
revoke execute on function public.set_payment_preference(text) from public, anon;
grant execute on function public.set_payment_preference(text) to authenticated;

-- ---------------------------------------------------------------- what each subscription covers and costs
-- period_start and period_end are set for a monthly subscription only; null means the whole semester (so moving a
-- semester's dates needs nothing else). The rest is a copy of the school's billing at the time of the request.
alter table public.subscriptions
  add column payment_mode text not null default 'full' check (payment_mode in ('full', 'installments')),
  add column period_start date,
  add column period_end date,
  add column billing_period text check (billing_period in ('semester', 'month')),
  add column amount_xaf integer check (amount_xaf > 0),
  add column installment_plan text check (installment_plan in ('50-50', '40-30-30', '30-60-10')),
  add constraint subscriptions_period_pair check ((period_start is null) = (period_end is null) and (period_end is null or period_end >= period_start)),
  add constraint subscriptions_installments_plan check (payment_mode = 'full' or installment_plan is not null);

-- One live request per period: per semester as before, per month for monthly billing.
drop index public.subscriptions_one_live_per_semester;
create unique index subscriptions_one_live_per_period
  on public.subscriptions (student_id, semester_id, coalesce(period_start, '-infinity'::date))
  where status in ('pending', 'approved');

-- A student also writes how they pay and, for monthly billing, the month (its first day). Never a price or an end date.
grant insert (payment_mode, period_start) on public.subscriptions to authenticated;

-- Fills in the price and the period from the school's billing, before the row is checked and stored. Runs as the caller
-- (like the request check), so it can tell a student using the API (`authenticated`) from seeds and fixtures; a student
-- reads their own school, its semesters and their own requests.
create function private.price_subscription() returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_school public.schools%rowtype;
  v_sem public.semesters%rowtype;
  v_today date;
  v_student boolean := current_user = 'authenticated';
  v_month date;
begin
  -- Someone else's row or another school: left to row-level security, which refuses it with its own error.
  if v_student then
    if new.student_id is distinct from (select auth.uid()) or new.school_id is distinct from private.my_school_id() then
      return new;
    end if;
  end if;

  select * into v_school from public.schools where id = new.school_id;
  select * into v_sem from public.semesters where id = new.semester_id and school_id = new.school_id;
  if v_school.billing_period is null then
    -- Seeds and fixtures may load history before billing exists; a student may not ask yet.
    if v_student then
      raise exception 'billing_not_set' using errcode = '55000';
    end if;
    return new;
  end if;
  -- The school's date, worked out here: the service role (tests, tools) does not use the private helpers.
  v_today := (now() at time zone v_school.timezone)::date;

  if v_school.billing_period = 'month' then
    if new.payment_mode = 'installments' then
      raise exception 'installments_not_offered' using errcode = '22023';
    end if;
    if new.period_start is null then
      if v_student then
        raise exception 'month_required' using errcode = '22023';
      end if;
      return new;
    end if;
    v_month := date_trunc('month', new.period_start)::date;
    -- The current month or the next one, and a month that overlaps the semester.
    if v_student and (new.period_start <> v_month or v_month not in (date_trunc('month', v_today)::date, (date_trunc('month', v_today) + interval '1 month')::date)) then
      raise exception 'month_not_allowed' using errcode = '22023';
    end if;
    new.period_start := greatest(v_month, v_sem.start_date);
    new.period_end := least((v_month + interval '1 month' - interval '1 day')::date, v_sem.end_date);
    if new.period_start > new.period_end then
      raise exception 'month_not_allowed' using errcode = '22023';
    end if;
    if v_student and new.period_end < v_today then
      raise exception 'period_ended' using errcode = '55000';
    end if;
    new.installment_plan := null;
  else
    -- A whole semester: no month.
    new.period_start := null;
    new.period_end := null;
    if new.payment_mode = 'installments' then
      if v_school.installment_plan is null then
        raise exception 'installments_not_offered' using errcode = '22023';
      end if;
      new.installment_plan := v_school.installment_plan;
    else
      new.installment_plan := null;
    end if;
  end if;

  new.billing_period := v_school.billing_period;
  new.amount_xaf := v_school.price_xaf;

  -- Already covered for some of this time (for example a whole-semester subscription and now a month of it).
  if new.status in ('pending', 'approved') and exists (
    select 1 from public.subscriptions s
    where s.student_id = new.student_id and s.semester_id = new.semester_id and s.status in ('pending', 'approved')
      and coalesce(s.period_start, v_sem.start_date) <= coalesce(new.period_end, v_sem.end_date)
      and coalesce(new.period_start, v_sem.start_date) <= coalesce(s.period_end, v_sem.end_date)
  ) then
    raise exception 'already_requested' using errcode = '23505';
  end if;
  return new;
end;
$$;
revoke execute on function private.price_subscription() from public;
grant execute on function private.price_subscription() to authenticated;

create trigger subscriptions_price before insert on public.subscriptions
  for each row execute function private.price_subscription();

-- Approving or giving back a subscription whose month has passed makes no sense (the semester rule already exists).
create function private.check_subscription_period() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is not null and new.status = 'approved' and old.status is distinct from 'approved'
     and new.period_end is not null and new.period_end < private.school_today(new.school_id) then
    raise exception 'period_ended' using errcode = '55000';
  end if;
  return new;
end;
$$;
revoke execute on function private.check_subscription_period() from public;

create trigger subscriptions_period_open before update of status on public.subscriptions
  for each row execute function private.check_subscription_period();

-- Giving back a revoked month is not blocked by a request for another month.
create or replace function public.admin_reinstate_subscription(p_subscription_id uuid, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_sub public.subscriptions;
  v_note text;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  v_note := private.clean_reason(p_note, true);

  select * into v_sub
  from public.subscriptions
  where id = p_subscription_id and school_id = v_school
  for update;
  if not found then
    raise exception 'Subscription not found' using errcode = 'P0002';
  end if;
  if v_sub.status <> 'revoked' then
    raise exception 'Only revoked subscriptions can be reinstated' using errcode = '55000';
  end if;
  if private.student_is_suspended(v_sub.student_id) then
    raise exception 'account_suspended' using errcode = '55000';
  end if;
  -- One live subscription per student and period (the semester, or the month): a newer request has to be dealt with first.
  if exists (
    select 1 from public.subscriptions s
    where s.student_id = v_sub.student_id and s.semester_id = v_sub.semester_id
      and s.period_start is not distinct from v_sub.period_start
      and s.id <> v_sub.id and s.status in ('pending', 'approved')
  ) then
    raise exception 'The student already has a live subscription for this semester' using errcode = '55000';
  end if;
  if exists (select 1 from public.semesters m where m.id = v_sub.semester_id and m.end_date < private.school_today(v_school)) then
    raise exception 'semester_ended' using errcode = '55000';
  end if;

  update public.subscriptions
  set status = 'approved',
      review_note = v_note,
      reviewed_by = v_actor,
      reviewed_at = now()
  where id = p_subscription_id;

  perform private.write_audit(
    v_school, v_actor, 'subscription.reinstated', 'subscription', p_subscription_id,
    jsonb_build_object('student_id', v_sub.student_id)
  );
end;
$$;

-- ---------------------------------------------------------------- "covers today" reads the period
-- A subscription covers a day when it is approved and the day is inside its month, or its semester when it has none.
create or replace function private.active_subscription_id(p_student uuid, p_school uuid) returns uuid
language sql stable security definer
set search_path = ''
as $$
  select s.id
  from public.subscriptions s
  join public.semesters sem on sem.id = s.semester_id and sem.school_id = s.school_id
  join public.schools sc on sc.id = s.school_id
  where s.student_id = p_student
    and s.school_id = p_school
    and s.status = 'approved'
    and (now() at time zone sc.timezone)::date between coalesce(s.period_start, sem.start_date) and coalesce(s.period_end, sem.end_date)
  limit 1
$$;

create or replace function private.subscription_on(p_student uuid, p_school uuid, p_day date) returns uuid
language sql stable security definer
set search_path = ''
as $$
  select s.id
  from public.subscriptions s
  join public.semesters sem on sem.id = s.semester_id and sem.school_id = s.school_id
  where s.student_id = p_student
    and s.school_id = p_school
    and s.status = 'approved'
    and p_day between coalesce(s.period_start, sem.start_date) and coalesce(s.period_end, sem.end_date)
  limit 1
$$;

-- Riders of a stop: subscriptions that have not ended, by their own end.
create or replace function private.stop_subscribers(p_school uuid)
returns table (student_id uuid, stop_id uuid, area extensions.geography)
language sql stable security definer
set search_path = ''
as $$
  select distinct on (s.student_id) s.student_id, s.stop_id, a.area
  from public.subscriptions s
  join public.semesters m on m.id = s.semester_id and m.school_id = s.school_id
  join public.profiles p on p.id = s.student_id and p.status = 'verified'
  left join public.student_areas a on a.user_id = s.student_id and a.school_id = s.school_id
  where s.school_id = p_school and s.status = 'approved' and coalesce(s.period_end, m.end_date) >= private.school_today(p_school)
  order by s.student_id, coalesce(s.period_end, m.end_date) desc;
$$;

create or replace function public.admin_stop_usage()
returns table (stop_id uuid, students int, pending int)
language plpgsql stable security invoker
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;

  return query
  select
    s.stop_id,
    (count(*) filter (where s.status = 'approved'))::int,
    (count(*) filter (where s.status = 'pending'))::int
  from public.subscriptions s
  join public.semesters m on m.id = s.semester_id and m.school_id = s.school_id
  where s.status in ('approved', 'pending')
    and coalesce(s.period_end, m.end_date) >= private.school_today(s.school_id)
  group by s.stop_id;
end;
$$;

-- "Your bus is near": only students covered today.
create or replace function private.notify_bus_near_stop() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_zone text;
  v_today date;
  v_dow int;
begin
  if new.trip_id is null then return new; end if;
  if not exists (
    select 1 from public.trips t
    where t.id = new.trip_id and t.school_id = new.school_id and t.status = 'active' and t.direction = 'inbound'
  ) then
    return new;
  end if;

  select sc.timezone into v_zone from public.schools sc where sc.id = new.school_id;
  v_today := (now() at time zone v_zone)::date;
  v_dow := extract(isodow from v_today)::int - 1;

  with waiting as (
    select s.student_id, s.school_id
    from public.subscriptions s
    join public.semesters se on se.id = s.semester_id
      and v_today between coalesce(s.period_start, se.start_date) and coalesce(s.period_end, se.end_date)
    join public.stops st on st.id = s.stop_id
    join public.profiles p on p.id = s.student_id and p.status = 'verified'
    left join public.notification_preferences n on n.user_id = s.student_id
    where s.school_id = new.school_id
      and s.status = 'approved'
      and coalesce(n.bus_near_on, true)
      and (coalesce(n.riding_days, 31) & (1 << v_dow)) <> 0
      and extensions.st_dwithin(st.location, new.location, private.bus_near_reach_m(new.speed_mps, coalesce(n.bus_near_minutes, 5)))
      and not exists (select 1 from public.scans x where x.trip_id = new.trip_id and x.student_id = s.student_id)
  ),
  fresh as (
    insert into private.bus_near_sent (trip_id, user_id)
    select new.trip_id, w.student_id from waiting w
    on conflict do nothing
    returning user_id
  )
  insert into private.notification_outbox (school_id, user_id, kind, ref_id)
  select new.school_id, f.user_id, 'bus_near_stop', new.trip_id from fresh f;

  return new;
end;
$$;
