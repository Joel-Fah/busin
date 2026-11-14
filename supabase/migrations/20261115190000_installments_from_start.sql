-- Installments follow the student's start (ADR 0022, amended 2026-11-14). Students join the bus during the semester and
-- all pay the same price; their parts are spread over their own time on the bus instead of the semester's fixed dates:
-- part 1 on the day of the request, part k (k > 1) at (k - 1) / n of the way from the day they ask (or the semester's
-- first day, if they ask before it) to the semester's last day. Installments are offered only while the parts can be at
-- least two weeks apart (14 days times the number of parts left in the semester); later, a student pays in full
-- (`installments_too_late`). Requests already made keep their dates.

-- Whether a plan's parts fit two weeks apart between `p_today` (or the semester's start, if later) and its last day.
create or replace function private.installments_fit(p_today date, p_start date, p_end date, p_plan text) returns boolean
language sql immutable set search_path = ''
as $$
  select p_plan is not null and (p_end - greatest(p_today, p_start) + 1) >= 14 * coalesce(array_length(private.plan_percents(p_plan), 1), 0)
$$;
revoke execute on function private.installments_fit(date, date, date, text) from public;
grant execute on function private.installments_fit(date, date, date, text) to authenticated;

create or replace function private.price_subscription() returns trigger
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
      -- Too close to the end of the semester for the parts to be two weeks apart: in full only. Checked for students
      -- only, in its own block: the service role (tests, tools) cannot use the private schema, and an `and` in one
      -- condition does not keep it from being looked at.
      if v_student then
        if not private.installments_fit(v_today, v_sem.start_date, v_sem.end_date, v_school.installment_plan) then
          raise exception 'installments_too_late' using errcode = '22023';
        end if;
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

create or replace function private.create_installments() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_percents smallint[];
  v_start date;
  v_end date;
  v_today date;
  v_days int;
  v_n int;
  v_sum int := 0;
  v_amount int;
  v_status text;
begin
  if new.payment_mode <> 'installments' or new.installment_plan is null or new.amount_xaf is null then
    return new;
  end if;
  v_percents := private.plan_percents(new.installment_plan);
  v_n := array_length(v_percents, 1);
  select m.start_date, m.end_date into v_start, v_end from public.semesters m where m.id = new.semester_id;
  v_start := coalesce(new.period_start, v_start);
  v_end := coalesce(new.period_end, v_end);
  v_today := (now() at time zone (select sc.timezone from public.schools sc where sc.id = new.school_id))::date;
  -- The student's own time on the bus: from the day they ask (or the semester's first day, if they ask before it).
  v_start := greatest(v_today, v_start);
  v_days := greatest(v_end - v_start + 1, 1);

  for k in 1..v_n loop
    if k < v_n then
      v_amount := new.amount_xaf * v_percents[k] / 100;
      v_sum := v_sum + v_amount;
    else
      v_amount := new.amount_xaf - v_sum;
    end if;
    -- Part 1 travels with the request: its proof, and the request's own decision.
    v_status := case when k = 1 then case when new.status = 'approved' then 'paid' when new.status = 'rejected' then 'rejected' else 'submitted' end else 'due' end;
    insert into public.subscription_installments (school_id, subscription_id, student_id, seq, percent, amount_xaf, due_date, status, proof_path, submitted_at)
    values (new.school_id, new.id, new.student_id, k, v_percents[k], v_amount,
            case when k = 1 then v_today else v_start + ((k - 1) * v_days / v_n) end,
            v_status,
            case when k = 1 then new.proof_path end,
            case when k = 1 then now() end);
  end loop;
  return new;
end;
$$;
