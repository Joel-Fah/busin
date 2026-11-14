-- Installments (ADR 0022, point 7). A semester paid in installments has one row per part: its share, its amount and
-- when it is due. Part 1 is the request's own proof and is settled with the request (approved: paid; rejected:
-- rejected). For the later parts the student uploads a proof and an administrator marks it paid or rejects it; an
-- administrator can also mark a part paid without a proof (paid at the office). Students are reminded before a part is
-- due. Rows are written by the database only.

create table public.subscription_installments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  subscription_id uuid not null,
  student_id uuid not null,
  seq smallint not null check (seq between 1 and 4),
  percent smallint not null check (percent between 1 and 100),
  amount_xaf integer not null check (amount_xaf >= 0),
  due_date date not null,
  status text not null default 'due' check (status in ('due', 'submitted', 'paid', 'rejected')),
  proof_path text,
  submitted_at timestamptz,
  review_note text check (review_note is null or char_length(review_note) <= 500),
  reviewed_by uuid references public.profiles (id) on delete set null,
  reviewed_at timestamptz,
  -- The school day a reminder was last queued for this part, so it is sent once.
  reminded_on date,
  created_at timestamptz not null default now(),
  unique (subscription_id, seq),
  foreign key (subscription_id, school_id) references public.subscriptions (id, school_id) on delete cascade,
  foreign key (student_id, school_id) references public.profiles (id, school_id)
);
create index subscription_installments_student_idx on public.subscription_installments (student_id);
create index subscription_installments_school_due_idx on public.subscription_installments (school_id, due_date) where status <> 'paid';

alter table public.subscription_installments enable row level security;
alter table public.subscription_installments force row level security;
revoke all on public.subscription_installments from anon, authenticated;
grant select on public.subscription_installments to authenticated;
-- The student reads their own parts, an administrator their school's. Nobody writes directly.
create policy subscription_installments_select on public.subscription_installments for select to authenticated
  using (
    school_id = (select private.my_school_id())
    and ((select private.is_admin()) or student_id = (select auth.uid()))
  );

-- ---------------------------------------------------------------- the parts of a new request
-- Each part rounded down, the last taking what is left, so they add up to the price exactly. Part 1 is due on the day
-- of the request; part k on the semester's start plus (k - 1) / n of its length, or the day of the request if that has
-- passed.
create function private.plan_percents(p_plan text) returns smallint[]
language sql immutable set search_path = ''
as $$
  select case p_plan
    when '50-50' then array[50, 50]::smallint[]
    when '40-30-30' then array[40, 30, 30]::smallint[]
    when '30-60-10' then array[30, 60, 10]::smallint[]
  end
$$;

create function private.create_installments() returns trigger
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
  v_days := v_end - v_start + 1;

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
            case when k = 1 then v_today else greatest(v_today, v_start + ((k - 1) * v_days / v_n)) end,
            v_status,
            case when k = 1 then new.proof_path end,
            case when k = 1 then now() end);
  end loop;
  return new;
end;
$$;
revoke execute on function private.create_installments() from public;

create trigger subscriptions_installments after insert on public.subscriptions
  for each row execute function private.create_installments();

-- Deciding the request settles part 1.
create function private.settle_first_installment() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if old.status = 'pending' and new.status in ('approved', 'rejected') then
    update public.subscription_installments
    set status = case when new.status = 'approved' then 'paid' else 'rejected' end,
        review_note = new.review_note,
        reviewed_by = new.reviewed_by,
        reviewed_at = coalesce(new.reviewed_at, now())
    where subscription_id = new.id and seq = 1;
  end if;
  return new;
end;
$$;
revoke execute on function private.settle_first_installment() from public;

create trigger subscriptions_settle_first_installment after update of status on public.subscriptions
  for each row execute function private.settle_first_installment();

-- ---------------------------------------------------------------- the student sends a proof for a later part
create function public.submit_installment_proof(p_installment uuid, p_path text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_part public.subscription_installments;
  v_sub_status public.subscription_status;
begin
  if private.my_role() is distinct from 'student' then
    raise exception 'Students only' using errcode = '42501';
  end if;
  select * into v_part from public.subscription_installments
  where id = p_installment and student_id = v_uid and school_id = v_school
  for update;
  if not found then
    raise exception 'Installment not found' using errcode = 'P0002';
  end if;
  select s.status into v_sub_status from public.subscriptions s where s.id = v_part.subscription_id;
  if v_part.seq = 1 or v_part.status not in ('due', 'rejected') or v_sub_status not in ('pending', 'approved') then
    raise exception 'installment_not_open' using errcode = '55000';
  end if;
  if p_path is null or p_path not like v_school::text || '/' || v_uid::text || '/%' then
    raise exception 'proof_required' using errcode = '22023';
  end if;
  if not exists (select 1 from storage.objects o where o.bucket_id = 'proofs' and o.name = p_path) then
    raise exception 'proof_missing' using errcode = '22023';
  end if;
  update public.subscription_installments
  set status = 'submitted', proof_path = p_path, submitted_at = now(), review_note = null, reviewed_by = null, reviewed_at = null
  where id = p_installment;
end;
$$;
revoke execute on function public.submit_installment_proof(uuid, text) from public, anon;
grant execute on function public.submit_installment_proof(uuid, text) to authenticated;

-- ---------------------------------------------------------------- an administrator decides on a part
-- Paid (with or without a proof: paid at the office), or rejected with a reason when a proof was sent. Audited, and the
-- student is told.
create function public.admin_review_installment(p_installment uuid, p_decision text, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_part public.subscription_installments;
  v_note text;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if p_decision is null or p_decision not in ('paid', 'rejected') then
    raise exception 'Decision must be paid or rejected' using errcode = '22023';
  end if;
  v_note := private.clean_reason(p_note, p_decision = 'rejected');
  select * into v_part from public.subscription_installments where id = p_installment and school_id = v_school for update;
  if not found then
    raise exception 'Installment not found' using errcode = 'P0002';
  end if;
  -- Part 1 is decided with the request itself.
  if v_part.seq = 1 or v_part.status = 'paid' or (p_decision = 'rejected' and v_part.status <> 'submitted') then
    raise exception 'installment_not_open' using errcode = '55000';
  end if;
  update public.subscription_installments
  set status = p_decision, review_note = v_note, reviewed_by = v_actor, reviewed_at = now()
  where id = p_installment;
  perform private.write_audit(v_school, v_actor, 'installment.' || p_decision, 'subscription', v_part.subscription_id,
    jsonb_build_object('student_id', v_part.student_id, 'seq', v_part.seq));
  insert into private.notification_outbox (school_id, user_id, kind, ref_id)
  values (v_school, v_part.student_id, 'installment_' || p_decision, v_part.subscription_id);
end;
$$;
revoke execute on function public.admin_review_installment(uuid, text, text) from public, anon;
grant execute on function public.admin_review_installment(uuid, text, text) to authenticated;

-- ---------------------------------------------------------------- reminders
alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'subscription_revoked', 'subscription_restored', 'school_notice', 'bus_near_stop',
                  'crew_assigned', 'installment_paid', 'installment_rejected', 'installment_due'));

-- Three days before a part is due and on the day, at 8 in the morning school time, once a day: parts not yet sent or
-- paid, of subscriptions that are still running.
create function private.remind_installments(p_now timestamptz default now()) returns int
language plpgsql security definer
set search_path = ''
as $$
declare
  v_count int;
begin
  with due as (
    select i.id, i.school_id, i.student_id, i.subscription_id, (p_now at time zone sc.timezone)::date as today
    from public.subscription_installments i
    join public.schools sc on sc.id = i.school_id
    join public.subscriptions s on s.id = i.subscription_id and s.status = 'approved'
    where i.status in ('due', 'rejected')
      and extract(hour from p_now at time zone sc.timezone) = 8
      and i.due_date - (p_now at time zone sc.timezone)::date in (0, 3)
      and i.reminded_on is distinct from (p_now at time zone sc.timezone)::date
  ),
  marked as (
    update public.subscription_installments i set reminded_on = d.today from due d where i.id = d.id
    returning i.school_id, i.student_id, i.subscription_id
  )
  insert into private.notification_outbox (school_id, user_id, kind, ref_id)
  select m.school_id, m.student_id, 'installment_due', m.subscription_id from marked m;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
revoke execute on function private.remind_installments(timestamptz) from public;

select cron.schedule('busin-remind-installments', '10 * * * *', $$select private.remind_installments()$$);
