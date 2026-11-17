-- Mobile money payments through pawaPay (ADR 0029, proposed). A student pays a pending request or a later installment
-- part from the app; a school administrator pays BusIn's invoice from the portal. The `payments` Edge Function opens the
-- payment here (`start_payment`, as the caller) before calling pawaPay; every result pawaPay gives, from its callback,
-- the reconciler or a status check, goes through `settle_payment` (service role), which applies a completed payment
-- once. The school's share goes to its ledger, one signed row per movement, never edited.
--
-- Amounts are whole francs (XAF has no decimals). "Open" payments, refunds and payouts are those pawaPay may still
-- finish: initiated (or queued), accepted, processing, in reconciliation, or set aside for the platform.

-- ---------------------------------------------------------------- the platform's settings
create table private.payment_settings (
  id boolean primary key default true check (id),
  -- pawaPay's own share of every transaction (payments, payouts, refunds), in percent. The operators' shares are in
  -- `provider_rates`.
  pawapay_percent numeric(5, 2) not null default 1.00 check (pawapay_percent between 0 and 20),
  -- Added to the transaction costs, in percent of the price, for rounding and the fixed part of a payout.
  fee_buffer_percent numeric(5, 2) not null default 0.20 check (fee_buffer_percent between 0 and 5),
  -- The smallest service fee.
  fee_min_xaf integer not null default 0 check (fee_min_xaf >= 0),
  -- VAT on pawaPay's fee, in percent of it. None for now (owner, 2026-11-17).
  pawapay_vat_percent numeric(5, 2) not null default 0 check (pawapay_vat_percent between 0 and 50),
  -- Whether a school may pass mobile money's costs on to its students as a fee on top (each school chooses, see
  -- schools.fees_paid_by). pawaPay's sub-merchant terms forbid surcharging end users (Appendix 1, 3.5.1): this stands
  -- only if pawaPay confirms it in writing. Switched off, every school bears those costs; BusIn's charge can still be
  -- in the price, as it applies to every way of paying.
  student_fee_allowed boolean not null default true,
  -- Days a payment stays on hold before the school can be paid it.
  hold_days smallint not null default 7 check (hold_days between 0 and 60),
  -- The smallest weekly payout.
  payout_min_xaf integer not null default 5000 check (payout_min_xaf >= 0),
  -- BusIn's charge per paying student, by billing period; a school may have its own. This is BusIn's margin: the
  -- student's service fee only covers what moving the money costs.
  charge_semester_xaf integer not null default 0 check (charge_semester_xaf >= 0),
  charge_month_xaf integer not null default 0 check (charge_month_xaf >= 0),
  -- Payments a person may start in an hour.
  max_starts_per_hour smallint not null default 6 check (max_starts_per_hour between 1 and 60),
  updated_at timestamptz not null default now(),
  updated_by uuid
);
insert into private.payment_settings default values;
revoke all on private.payment_settings from public, anon, authenticated;

-- What each operator takes on top of pawaPay's share, by kind of transaction. A rate not set (null) stops payments with
-- that operator. pawaPay told the owner (2026-11-17) that every transaction, refunds included, costs its 1% and nothing
-- more, so all start at 0. Its public fee page listed operator shares (collections MTN 0.75%, Orange 0.77%; payouts MTN
-- 0.30%): confirm in the signed agreement, and change them here if they apply.
create table private.provider_rates (
  provider text not null check (provider in ('MTN_MOMO_CMR', 'ORANGE_CMR')),
  operation text not null check (operation in ('deposit', 'payout', 'refund')),
  mmo_percent numeric(5, 2) check (mmo_percent is null or mmo_percent between 0 and 20),
  mmo_fixed_xaf integer not null default 0 check (mmo_fixed_xaf >= 0),
  updated_at timestamptz not null default now(),
  primary key (provider, operation)
);
insert into private.provider_rates (provider, operation)
select p, o from unnest(array['MTN_MOMO_CMR', 'ORANGE_CMR']) p, unnest(array['deposit', 'payout', 'refund']) o;
update private.provider_rates set mmo_percent = 0;

-- pawaPay's share with its VAT, in percent.
create function private.pawapay_rate() returns numeric
language sql stable security definer
set search_path = ''
as $$
  select s.pawapay_percent * (1 + s.pawapay_vat_percent / 100) from private.payment_settings s
$$;
revoke execute on function private.pawapay_rate() from public;
revoke all on private.provider_rates from public, anon, authenticated;

-- Per school: whether its students can pay by mobile money, and from when BusIn charges it per paying student.
create table private.school_payment_terms (
  school_id uuid primary key references public.schools (id) on delete cascade,
  enabled boolean not null default false,
  charges_from date,
  -- Null: the platform's default.
  charge_semester_xaf integer check (charge_semester_xaf >= 0),
  charge_month_xaf integer check (charge_month_xaf >= 0),
  updated_at timestamptz not null default now(),
  updated_by uuid
);
revoke all on private.school_payment_terms from public, anon, authenticated;

-- BusIn's monthly infrastructure costs, entered in the platform console, to show the real margin.
create table private.infra_costs (
  id uuid primary key default gen_random_uuid(),
  month date not null check (month = date_trunc('month', month)::date),
  label text not null check (char_length(label) between 2 and 80),
  amount_xaf integer not null check (amount_xaf > 0),
  note text check (note is null or char_length(note) <= 300),
  created_by uuid,
  created_at timestamptz not null default now()
);
create index infra_costs_month_idx on private.infra_costs (month);
revoke all on private.infra_costs from public, anon, authenticated;

-- Receipt numbers: BI- payments, BR- refunds, BF- invoices; per year, without gaps.
create table private.receipt_counters (
  prefix text not null check (prefix in ('BI', 'BR', 'BF')),
  year integer not null,
  last integer not null,
  primary key (prefix, year)
);
revoke all on private.receipt_counters from public, anon, authenticated;

create function private.next_receipt_no(p_prefix text) returns text
language plpgsql security definer
set search_path = ''
as $$
declare
  v_year integer := extract(year from now() at time zone 'UTC')::integer;
  v_n integer;
begin
  insert into private.receipt_counters (prefix, year, last) values (p_prefix, v_year, 1)
  on conflict (prefix, year) do update set last = private.receipt_counters.last + 1
  returning last into v_n;
  return p_prefix || '-' || v_year || '-' || lpad(v_n::text, 6, '0');
end;
$$;
revoke execute on function private.next_receipt_no(text) from public;

-- What moving an amount costs with an operator: pawaPay's share plus the operator's, rounded up. Null while the
-- operator's rate is not set.
create function private.transfer_cost(p_provider text, p_operation text, p_amount integer) returns integer
language sql stable security definer
set search_path = ''
as $$
  select ceil(p_amount * (private.pawapay_rate() + r.mmo_percent) / 100 + r.mmo_fixed_xaf)::integer
  from private.provider_rates r
  where r.provider = p_provider and r.operation = p_operation
$$;
revoke execute on function private.transfer_cost(text, text, integer) from public;

-- The service fee: what the payer adds so that, once pawaPay and the operator have taken their share of the payment
-- and of the payout to the school, the school receives its whole price. For BusIn's own invoice (no payout), the
-- payment's cost only. Null while the operator's rates are not set. Whether the payer pays it is decided by the caller.
create function private.service_fee(p_provider text, p_amount integer, p_with_payout boolean) returns integer
language sql stable security definer
set search_path = ''
as $$
  -- greatest() skips nulls, so rates not set are caught first.
  select case when d.mmo_percent is null or o.mmo_percent is null then null else greatest(s.fee_min_xaf,
    ceil((p_amount * (1 + case when p_with_payout then (private.pawapay_rate() + o.mmo_percent + s.fee_buffer_percent) / 100 else 0 end)
          + d.mmo_fixed_xaf)
         / (1 - (private.pawapay_rate() + d.mmo_percent) / 100))::integer - p_amount) end
  from private.payment_settings s
  join private.provider_rates d on d.provider = p_provider and d.operation = 'deposit'
  join private.provider_rates o on o.provider = p_provider and o.operation = 'payout'
$$;
revoke execute on function private.service_fee(text, integer, boolean) from public;

create function private.mobile_money_enabled(p_school uuid) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce((select t.enabled from private.school_payment_terms t where t.school_id = p_school), false)
$$;
revoke execute on function private.mobile_money_enabled(uuid) from public;
grant execute on function private.mobile_money_enabled(uuid) to authenticated;

-- ---------------------------------------------------------------- BusIn's invoices to a school
-- What a school owes BusIn when its balance cannot cover the charges (a school paid only by receipts). Issued monthly.
create table public.busin_invoices (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  number text not null unique,
  month date not null check (month = date_trunc('month', month)::date),
  amount_xaf integer not null check (amount_xaf > 0),
  status text not null default 'open' check (status in ('open', 'paid', 'void')),
  issued_at timestamptz not null default now(),
  due_date date not null,
  paid_at timestamptz,
  unique (school_id, month)
);

-- ---------------------------------------------------------------- payments
create table public.payments (
  -- Also pawaPay's depositId, and so its idempotency key.
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  paid_by uuid not null references public.profiles (id),
  purpose text not null check (purpose in ('subscription', 'installment', 'invoice')),
  subscription_id uuid,
  installment_id uuid references public.subscription_installments (id),
  invoice_id uuid references public.busin_invoices (id),
  -- The thing being paid, so only one payment for it is open at a time.
  item_key text not null check (char_length(item_key) <= 80),
  -- What goes to the school (or to BusIn, for an invoice), and the service fee on top; both fixed when it starts.
  amount_xaf integer not null check (amount_xaf > 0),
  fee_xaf integer not null check (fee_xaf >= 0),
  total_xaf integer generated always as (amount_xaf + fee_xaf) stored,
  -- What pawaPay and the operator should take, on this payment and on paying the school its share, by the rates in
  -- force when it started. BusIn's cost: not shown to schools or students.
  est_cost_xaf integer not null default 0 check (est_cost_xaf >= 0),
  -- The school bears those costs (taken from its share), by the setting in force when it started.
  school_pays_costs boolean not null default false,
  currency text not null default 'XAF' check (currency = 'XAF'),
  provider text not null check (provider in ('MTN_MOMO_CMR', 'ORANGE_CMR')),
  -- The payer's number, partly hidden. pawaPay keeps the full one under the payment's id.
  payer_masked text not null check (char_length(payer_masked) <= 20),
  status text not null default 'initiated'
    check (status in ('initiated', 'accepted', 'processing', 'in_reconciliation', 'completed', 'failed', 'needs_attention')),
  failure_code text check (failure_code is null or char_length(failure_code) <= 64),
  failure_message text check (failure_message is null or char_length(failure_message) <= 300),
  provider_txn text check (provider_txn is null or char_length(provider_txn) <= 100),
  -- What pawaPay actually took on this payment, from its statements. BusIn's cost too.
  provider_fee_xaf integer check (provider_fee_xaf is null or provider_fee_xaf >= 0),
  receipt_no text unique,
  -- What the money did once completed: applied to the item, or refunded because the item could no longer take it.
  outcome text check (outcome in ('applied', 'refunded')),
  checks smallint not null default 0,
  last_checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  foreign key (subscription_id, school_id) references public.subscriptions (id, school_id),
  -- A part keeps its subscription too.
  constraint payments_item_check check (
    (purpose = 'subscription' and subscription_id is not null and installment_id is null and invoice_id is null)
    or (purpose = 'installment' and subscription_id is not null and installment_id is not null and invoice_id is null)
    or (purpose = 'invoice' and subscription_id is null and installment_id is null and invoice_id is not null))
);
create unique index payments_one_open_per_item on public.payments (item_key)
  where status in ('initiated', 'accepted', 'processing', 'in_reconciliation', 'needs_attention');
create index payments_open_idx on public.payments (last_checked_at nulls first)
  where status in ('initiated', 'accepted', 'processing', 'in_reconciliation');
create index payments_paid_by_idx on public.payments (paid_by, created_at desc);
create index payments_school_idx on public.payments (school_id, created_at desc);
create index payments_subscription_idx on public.payments (subscription_id) where subscription_id is not null;
create index payments_installment_idx on public.payments (installment_id) where installment_id is not null;

alter table public.payments enable row level security;
alter table public.payments force row level security;
revoke all on public.payments from anon, authenticated;
grant select (id, school_id, paid_by, purpose, subscription_id, installment_id, invoice_id, amount_xaf, fee_xaf, total_xaf,
              currency, provider, payer_masked, status, failure_code, failure_message, provider_txn, receipt_no,
              outcome, created_at, updated_at, completed_at)
  on public.payments to authenticated;
-- The payer reads their own; a school administrator reads the school's.
create policy payments_select on public.payments for select to authenticated
  using (
    paid_by = (select auth.uid())
    or (school_id = (select private.my_school_id()) and (select private.is_admin()))
  );
-- The student's screen follows its payment live.
alter publication supabase_realtime add table public.payments;

-- ---------------------------------------------------------------- refunds
create table public.refunds (
  -- Also pawaPay's refundId.
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  payment_id uuid not null references public.payments (id),
  student_id uuid not null references public.profiles (id),
  -- system: BusIn could not apply the payment, refunded in full; school: decided by the school; student: asked for.
  kind text not null check (kind in ('system', 'school', 'student')),
  reason text check (reason is null or char_length(reason) <= 500),
  -- From the school's share, and the service fee given back (system errors only).
  amount_xaf integer not null check (amount_xaf >= 0),
  fee_xaf integer not null default 0 check (fee_xaf >= 0),
  total_xaf integer generated always as (amount_xaf + fee_xaf) stored,
  status text not null default 'requested'
    check (status in ('requested', 'declined', 'queued', 'accepted', 'processing', 'in_reconciliation', 'completed', 'failed', 'needs_attention')),
  requested_by uuid references public.profiles (id),
  requested_at timestamptz not null default now(),
  decided_by uuid references public.profiles (id),
  decided_at timestamptz,
  decision_note text check (decision_note is null or char_length(decision_note) <= 500),
  failure_code text check (failure_code is null or char_length(failure_code) <= 64),
  provider_txn text check (provider_txn is null or char_length(provider_txn) <= 100),
  receipt_no text unique,
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  check (amount_xaf + fee_xaf > 0)
);
create unique index refunds_one_open_per_payment on public.refunds (payment_id)
  where status in ('requested', 'queued', 'accepted', 'processing', 'in_reconciliation', 'needs_attention');
create index refunds_school_idx on public.refunds (school_id, requested_at desc);
create index refunds_student_idx on public.refunds (student_id);
create index refunds_queued_idx on public.refunds (requested_at) where status = 'queued';

alter table public.refunds enable row level security;
alter table public.refunds force row level security;
revoke all on public.refunds from anon, authenticated;
grant select on public.refunds to authenticated;
create policy refunds_select on public.refunds for select to authenticated
  using (
    student_id = (select auth.uid())
    or (school_id = (select private.my_school_id()) and (select private.is_admin()))
  );

-- ---------------------------------------------------------------- payout numbers and payouts
-- Where a school is paid. A new number is proposed by one administrator and confirmed by another (or by the platform);
-- replacing a number holds payouts for 7 days.
create table public.school_payout_accounts (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  provider text not null check (provider in ('MTN_MOMO_CMR', 'ORANGE_CMR')),
  phone text not null check (phone ~ '^2376[0-9]{8}$'),
  -- The name the operator holds for the number, to check it is the school's.
  account_name text check (account_name is null or char_length(account_name) <= 120),
  status text not null default 'proposed' check (status in ('proposed', 'active', 'retired', 'declined')),
  proposed_by uuid references public.profiles (id),
  proposed_at timestamptz not null default now(),
  confirmed_by uuid references public.profiles (id),
  confirmed_at timestamptz,
  usable_from timestamptz,
  retired_at timestamptz,
  check (confirmed_by is null or confirmed_by is distinct from proposed_by)
);
create unique index school_payout_accounts_one_active on public.school_payout_accounts (school_id) where status = 'active';
create unique index school_payout_accounts_one_proposed on public.school_payout_accounts (school_id) where status = 'proposed';

alter table public.school_payout_accounts enable row level security;
alter table public.school_payout_accounts force row level security;
revoke all on public.school_payout_accounts from anon, authenticated;
grant select on public.school_payout_accounts to authenticated;
create policy school_payout_accounts_select on public.school_payout_accounts for select to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

create table public.payouts (
  -- Also pawaPay's payoutId.
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  account_id uuid not null references public.school_payout_accounts (id),
  amount_xaf integer not null check (amount_xaf > 0),
  provider text not null check (provider in ('MTN_MOMO_CMR', 'ORANGE_CMR')),
  phone_masked text not null check (char_length(phone_masked) <= 20),
  status text not null default 'queued'
    check (status in ('queued', 'accepted', 'processing', 'in_reconciliation', 'completed', 'failed', 'needs_attention')),
  failure_code text check (failure_code is null or char_length(failure_code) <= 64),
  provider_txn text check (provider_txn is null or char_length(provider_txn) <= 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);
create unique index payouts_one_open_per_school on public.payouts (school_id)
  where status in ('queued', 'accepted', 'processing', 'in_reconciliation', 'needs_attention');
create index payouts_school_idx on public.payouts (school_id, created_at desc);

alter table public.payouts enable row level security;
alter table public.payouts force row level security;
revoke all on public.payouts from anon, authenticated;
grant select on public.payouts to authenticated;
create policy payouts_select on public.payouts for select to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

-- ---------------------------------------------------------------- BusIn's charge per paying student
create table public.busin_charges (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  subscription_id uuid not null unique,
  billing_period text check (billing_period in ('semester', 'month')),
  amount_xaf integer not null check (amount_xaf > 0),
  created_at timestamptz not null default now(),
  foreign key (subscription_id, school_id) references public.subscriptions (id, school_id)
);
create index busin_charges_school_idx on public.busin_charges (school_id, created_at desc);

alter table public.busin_charges enable row level security;
alter table public.busin_charges force row level security;
revoke all on public.busin_charges from anon, authenticated;
grant select on public.busin_charges to authenticated;
create policy busin_charges_select on public.busin_charges for select to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

alter table public.busin_invoices enable row level security;
alter table public.busin_invoices force row level security;
revoke all on public.busin_invoices from anon, authenticated;
grant select on public.busin_invoices to authenticated;
create policy busin_invoices_select on public.busin_invoices for select to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

-- ---------------------------------------------------------------- the school's ledger
-- Credits are positive (a payment, an invoice paid, a failed payout or refund put back), debits negative (a refund,
-- BusIn's charge, a payout). A credit from a payment is available after the hold; everything else at once. The
-- balance is always the sum of the rows. Each movement is written once.
create table public.school_ledger (
  id bigint generated always as identity primary key,
  school_id uuid not null references public.schools (id) on delete cascade,
  -- refund_fee: what sending a refund the school decided costs (the school pays it).
  -- transaction_fee: what a payment cost to collect and pay out, when the school bears it.
  kind text not null check (kind in ('payment', 'transaction_fee', 'refund', 'refund_fee', 'refund_reversal', 'charge', 'payout', 'payout_reversal',
                                     'invoice_payment', 'reversal', 'adjustment')),
  amount_xaf integer not null check (amount_xaf <> 0),
  available_at timestamptz not null default now(),
  payment_id uuid references public.payments (id),
  refund_id uuid references public.refunds (id),
  payout_id uuid references public.payouts (id),
  charge_id uuid references public.busin_charges (id),
  invoice_id uuid references public.busin_invoices (id),
  note text check (note is null or char_length(note) <= 300),
  created_at timestamptz not null default now()
);
create unique index school_ledger_once on public.school_ledger (kind, payment_id, refund_id, payout_id, charge_id, invoice_id)
  nulls not distinct where kind <> 'adjustment';
create index school_ledger_school_idx on public.school_ledger (school_id, created_at desc);

alter table public.school_ledger enable row level security;
alter table public.school_ledger force row level security;
revoke all on public.school_ledger from anon, authenticated;
grant select on public.school_ledger to authenticated;
create policy school_ledger_select on public.school_ledger for select to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

create function private.ledger_is_append_only() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'ledger_append_only' using errcode = '55000';
end;
$$;
revoke execute on function private.ledger_is_append_only() from public;
create trigger school_ledger_append_only before update on public.school_ledger
  for each row execute function private.ledger_is_append_only();

-- What the school can be paid now, what is still on hold, and what it owes BusIn.
create function private.school_balance(p_school uuid)
returns table (available_xaf integer, on_hold_xaf integer, owed_xaf integer)
language sql stable security definer
set search_path = ''
as $$
  with b as (
    select coalesce(sum(l.amount_xaf) filter (where l.available_at <= now()), 0)::integer as now_xaf,
           coalesce(sum(l.amount_xaf) filter (where l.available_at > now()), 0)::integer as later_xaf
    from public.school_ledger l where l.school_id = p_school
  )
  select greatest(b.now_xaf, 0), b.later_xaf, greatest(-b.now_xaf, 0) from b
$$;
revoke execute on function private.school_balance(uuid) from public;

-- An administrator's view of their school's balance.
create function public.school_balance()
returns table (available_xaf integer, on_hold_xaf integer, owed_xaf integer)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  return query select * from private.school_balance(private.my_school_id());
end;
$$;
revoke execute on function public.school_balance() from public, anon;
grant execute on function public.school_balance() to authenticated;

-- ---------------------------------------------------------------- who pays the fees: each school chooses
-- 'student': students pay the price plus BusIn's charge (whatever the way of paying), and mobile money's costs on top
-- when they pay that way (if the platform allows it), so the school receives its whole price. 'school': students pay
-- the price only; BusIn's charge and mobile money's costs come out of the school's share.
alter table public.schools
  add column fees_paid_by text not null default 'student' check (fees_paid_by in ('student', 'school'));

create function public.admin_set_fees_paid_by(p_who text)
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
  if p_who is null or p_who not in ('student', 'school') then
    raise exception 'invalid_value' using errcode = '22023';
  end if;
  update public.schools set fees_paid_by = p_who where id = v_school;
  perform private.write_audit(v_school, (select auth.uid()), 'school.fees_paid_by', 'school', v_school, jsonb_build_object('who', p_who));
end;
$$;
revoke execute on function public.admin_set_fees_paid_by(text) from public, anon;
grant execute on function public.admin_set_fees_paid_by(text) to authenticated;

-- BusIn's charge for one paying student of a school today, by billing period: zero before the school's charges start.
create function private.busin_charge_for(p_school uuid, p_period text) returns integer
language sql stable security definer
set search_path = ''
as $$
  select case when t.charges_from is null or t.charges_from > private.school_today(p_school) then 0
    else coalesce(case when p_period = 'month' then coalesce(t.charge_month_xaf, s.charge_month_xaf)
                       else coalesce(t.charge_semester_xaf, s.charge_semester_xaf) end, 0) end
  from private.payment_settings s
  left join private.school_payment_terms t on t.school_id = p_school
$$;
revoke execute on function private.busin_charge_for(uuid, text) from public;
grant execute on function private.busin_charge_for(uuid, text) to authenticated;

-- The charge fixed when the request is made (null for requests made before payments existed).
alter table public.subscriptions add column charge_xaf integer check (charge_xaf >= 0);

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
  v_charge integer := 0;
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
  -- BusIn's charge for a paying student, fixed now; in the price when the school passes its fees on (ADR 0029). The
  -- service role (tools) cannot use the private schema: no charge then.
  begin
    v_charge := private.busin_charge_for(new.school_id, v_school.billing_period);
  exception when insufficient_privilege then
    v_charge := 0;
  end;
  new.charge_xaf := v_charge;
  new.amount_xaf := v_school.price_xaf + case when v_school.fees_paid_by = 'student' then v_charge else 0 end;

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

-- ---------------------------------------------------------------- what a price means, for the school and its students
-- For each way of paying: what the student pays, BusIn's charge, what moving the money costs, and what the school
-- receives. An administrator can try a price before saving it (p_price); a student sees their school's. The school
-- portal shows it where the price is set, the apps before paying.
create function public.price_breakdown(p_price integer default null)
returns table (method text, student_pays integer, busin_charge integer, transaction_cost integer, school_receives integer)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school public.schools;
  v_settings private.payment_settings;
  v_price integer;
  v_charge integer;
  v_amount integer;
  v_with_fee boolean;
  v_fee integer;
  v_cost integer;
  v_provider text;
begin
  if (select auth.uid()) is null or private.my_school_id() is null then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  select * into v_school from public.schools where id = private.my_school_id();
  v_price := case when p_price is not null and private.is_admin() then p_price else v_school.price_xaf end;
  if v_price is null then
    return;
  end if;
  if v_price <= 0 or v_price > 10000000 then
    raise exception 'invalid_price' using errcode = '22023';
  end if;
  select * into v_settings from private.payment_settings;
  v_charge := private.busin_charge_for(v_school.id, coalesce(v_school.billing_period, 'semester'));
  v_amount := v_price + case when v_school.fees_paid_by = 'student' then v_charge else 0 end;
  method := 'receipt'; student_pays := v_amount; busin_charge := v_charge; transaction_cost := 0; school_receives := v_amount - v_charge;
  return next;
  if not private.mobile_money_enabled(v_school.id) then
    return;
  end if;
  v_with_fee := v_school.fees_paid_by = 'student' and v_settings.student_fee_allowed;
  foreach v_provider in array array['MTN_MOMO_CMR', 'ORANGE_CMR'] loop
    v_fee := private.service_fee(v_provider, v_amount, true);
    continue when v_fee is null;
    if not v_with_fee then
      v_fee := 0;
    end if;
    v_cost := private.transfer_cost(v_provider, 'deposit', v_amount + v_fee) + private.transfer_cost(v_provider, 'payout', v_amount);
    method := v_provider; student_pays := v_amount + v_fee; busin_charge := v_charge; transaction_cost := v_cost;
    school_receives := v_amount - v_charge - case when v_with_fee then 0 else v_cost end;
    return next;
  end loop;
end;
$$;
revoke execute on function public.price_breakdown(integer) from public, anon;
grant execute on function public.price_breakdown(integer) to authenticated;

-- ---------------------------------------------------------------- requests paid by mobile money
-- A request is still made by the student first; `mobile_money` ones have no receipt and are approved by their payment.
alter table public.subscriptions
  add column payment_method text not null default 'receipt' check (payment_method in ('receipt', 'mobile_money'));
grant insert (payment_method) on public.subscriptions to authenticated;

-- The parts paid in the app keep their payment in the history.
alter table public.installment_receipts add column payment_id uuid references public.payments (id);

-- A request needs a receipt that exists, unless it is paid by mobile money at a school that offers it.
create or replace function private.check_subscription_request() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Runs as the student: they can read their own proof and their school's semesters. Only people using the API are held
  -- to it (the writing role is `authenticated`); seeds and fixtures load history on purpose.
  if current_user <> 'authenticated' then
    return new;
  end if;
  if new.payment_method = 'mobile_money' then
    if not private.mobile_money_enabled(new.school_id) then
      raise exception 'mobile_money_off' using errcode = '55000';
    end if;
  else
    if new.proof_path is null or btrim(new.proof_path) = '' then
      raise exception 'proof_required' using errcode = '22023';
    end if;
    if not exists (select 1 from storage.objects o where o.bucket_id = 'proofs' and o.name = new.proof_path) then
      raise exception 'proof_missing' using errcode = '22023';
    end if;
  end if;
  if exists (select 1 from public.semesters m where m.id = new.semester_id and m.end_date < private.school_today(new.school_id)) then
    raise exception 'semester_ended' using errcode = '55000';
  end if;
  return new;
end;
$$;

-- Whether a payment for this request or part may still finish.
create function private.has_open_payment(p_subscription uuid, p_installment uuid) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.payments p
    where p.status in ('initiated', 'accepted', 'processing', 'in_reconciliation', 'needs_attention')
      and ((p_subscription is not null and p.subscription_id = p_subscription and p.purpose = 'subscription')
        or (p_installment is not null and p.installment_id = p_installment))
  )
$$;
revoke execute on function private.has_open_payment(uuid, uuid) from public;

-- Nobody decides on a request or a part while its payment may still finish (the payment itself is not a person).
create function private.hold_while_paying() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is not null and new.status is distinct from old.status then
    if tg_table_name = 'subscriptions' and private.has_open_payment(new.id, null) then
      raise exception 'payment_in_progress' using errcode = '55000';
    elsif tg_table_name = 'subscription_installments' and private.has_open_payment(null, new.id) then
      raise exception 'payment_in_progress' using errcode = '55000';
    end if;
  end if;
  return new;
end;
$$;
revoke execute on function private.hold_while_paying() from public;
create trigger subscriptions_hold_while_paying before update of status on public.subscriptions
  for each row execute function private.hold_while_paying();
create trigger subscription_installments_hold_while_paying before update of status on public.subscription_installments
  for each row execute function private.hold_while_paying();

-- A request approved by its payment is told once, as a payment ("payment_completed"), not also as an approval.
create or replace function private.notify_subscription_decision() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_kind text;
begin
  if old.status = 'pending' and new.status in ('approved', 'rejected') then
    if new.status = 'approved' and new.reviewed_by is null and exists (
      select 1 from public.payments p where p.subscription_id = new.id and p.purpose = 'subscription' and p.status = 'completed' and p.outcome is null
    ) then
      return new;
    end if;
    v_kind := 'subscription_' || new.status::text;
  elsif old.status = 'revoked' and new.status = 'approved' then
    v_kind := 'subscription_restored';
  elsif old.status = 'approved' and new.status = 'revoked' then
    v_kind := 'subscription_revoked';
  end if;
  if v_kind is not null then
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    values (new.school_id, new.student_id, v_kind, new.id);
  end if;
  return new;
end;
$$;

alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'subscription_revoked', 'subscription_restored', 'school_notice', 'bus_near_stop',
                  'crew_assigned', 'installment_paid', 'installment_rejected', 'installment_due', 'trip_still_running',
                  'payment_completed', 'payment_failed', 'refund_completed', 'refund_failed'));

-- ---------------------------------------------------------------- BusIn's charge, when a subscription is approved
-- Each subscription approved (whatever the payment method) from the day the school's charges start is charged once, and
-- the charge is taken from the school's balance.
create function private.charge_paying_student() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_terms private.school_payment_terms;
  v_settings private.payment_settings;
  v_amount integer;
  v_charge uuid;
begin
  if new.status <> 'approved' or old.status = 'approved' then
    return new;
  end if;
  select * into v_terms from private.school_payment_terms where school_id = new.school_id;
  if v_terms.charges_from is null or v_terms.charges_from > private.school_today(new.school_id) then
    return new;
  end if;
  select * into v_settings from private.payment_settings;
  -- The charge fixed with the request (and in its price, when passed on); computed now for older requests.
  v_amount := coalesce(new.charge_xaf, case when new.billing_period = 'month'
    then coalesce(v_terms.charge_month_xaf, v_settings.charge_month_xaf)
    else coalesce(v_terms.charge_semester_xaf, v_settings.charge_semester_xaf) end);
  if coalesce(v_amount, 0) <= 0 then
    return new;
  end if;
  insert into public.busin_charges (school_id, subscription_id, billing_period, amount_xaf)
  values (new.school_id, new.id, new.billing_period, v_amount)
  on conflict (subscription_id) do nothing
  returning id into v_charge;
  if v_charge is not null then
    insert into public.school_ledger (school_id, kind, amount_xaf, charge_id)
    values (new.school_id, 'charge', -v_amount, v_charge);
  end if;
  return new;
end;
$$;
revoke execute on function private.charge_paying_student() from public;
create trigger subscriptions_charge_paying_student after update of status on public.subscriptions
  for each row execute function private.charge_paying_student();

-- ---------------------------------------------------------------- what a payment is for
-- The item, checked for the caller: its school, the amount that goes to the school (or BusIn), whether it is paid out
-- to the school afterwards, whether the payer pays mobile money's costs on top, and its key. Refusals: 42501 not allowed, P0002 not found, 55000 not payable now, 22023 bad input.
create function private.payment_item(p_purpose text, p_target uuid)
returns table (school_id uuid, amount_xaf integer, with_payout boolean, with_fee boolean, item_key text)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_sub public.subscriptions;
  v_part public.subscription_installments;
  v_invoice public.busin_invoices;
  v_today date;
  v_with_fee boolean;
begin
  if v_uid is null or v_school is null then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_purpose is null or p_purpose not in ('subscription', 'installment', 'invoice') or p_target is null then
    raise exception 'bad_item' using errcode = '22023';
  end if;
  if not exists (select 1 from public.profiles p where p.id = v_uid and p.status = 'verified') then
    raise exception 'account_not_verified' using errcode = '42501';
  end if;
  v_today := private.school_today(v_school);

  if p_purpose = 'invoice' then
    if not private.is_admin() then
      raise exception 'not_allowed' using errcode = '42501';
    end if;
    select * into v_invoice from public.busin_invoices i where i.id = p_target and i.school_id = v_school;
    if not found then
      raise exception 'not_found' using errcode = 'P0002';
    end if;
    if v_invoice.status <> 'open' then
      raise exception 'not_payable' using errcode = '55000';
    end if;
    return query select v_school, v_invoice.amount_xaf, false, true, 'invoice:' || v_invoice.id::text;
    return;
  end if;

  -- A student's own request or part.
  if private.my_role() is distinct from 'student' then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if not private.mobile_money_enabled(v_school) then
    raise exception 'mobile_money_off' using errcode = '55000';
  end if;
  v_with_fee := (select sc.fees_paid_by = 'student' from public.schools sc where sc.id = v_school)
    and (select st.student_fee_allowed from private.payment_settings st);

  if p_purpose = 'subscription' then
    select * into v_sub from public.subscriptions s where s.id = p_target and s.student_id = v_uid and s.school_id = v_school;
    if not found then
      raise exception 'not_found' using errcode = 'P0002';
    end if;
    if v_sub.status <> 'pending' or v_sub.amount_xaf is null then
      raise exception 'not_payable' using errcode = '55000';
    end if;
    if exists (select 1 from public.semesters m where m.id = v_sub.semester_id and m.end_date < v_today)
       or (v_sub.period_end is not null and v_sub.period_end < v_today) then
      raise exception 'period_ended' using errcode = '55000';
    end if;
    if v_sub.payment_mode = 'installments' then
      return query select v_school, i.amount_xaf, true, v_with_fee, 'subscription:' || v_sub.id::text
        from public.subscription_installments i where i.subscription_id = v_sub.id and i.seq = 1;
      if not found then
        raise exception 'not_payable' using errcode = '55000';
      end if;
      return;
    end if;
    return query select v_school, v_sub.amount_xaf, true, v_with_fee, 'subscription:' || v_sub.id::text;
    return;
  end if;

  -- A later part of an approved subscription, not paid yet and not waiting on a receipt.
  select * into v_part from public.subscription_installments i where i.id = p_target and i.student_id = v_uid and i.school_id = v_school;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if v_part.seq = 1 or v_part.status not in ('due', 'rejected') or v_part.amount_xaf <= 0
     or not exists (select 1 from public.subscriptions s where s.id = v_part.subscription_id and s.status = 'approved') then
    raise exception 'not_payable' using errcode = '55000';
  end if;
  return query select v_school, v_part.amount_xaf, true, v_with_fee, 'installment:' || v_part.id::text;
end;
$$;
revoke execute on function private.payment_item(text, uuid) from public;

-- What the caller would pay, before paying: one line per operator (or the one asked for). The fee is null for an
-- operator whose rates are not set yet; the app shows it as unavailable.
create function public.payment_quote(p_purpose text, p_target uuid, p_provider text default null)
returns table (provider text, amount_xaf integer, fee_xaf integer, total_xaf integer, currency text)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_item record;
begin
  if p_provider is not null and p_provider not in ('MTN_MOMO_CMR', 'ORANGE_CMR') then
    raise exception 'bad_provider' using errcode = '22023';
  end if;
  select * into v_item from private.payment_item(p_purpose, p_target);
  return query
  select x.p, v_item.amount_xaf, f.fee, v_item.amount_xaf + f.fee, 'XAF'::text
  from unnest(array['MTN_MOMO_CMR', 'ORANGE_CMR']) as x(p)
  cross join lateral (select case when v_item.with_fee then private.service_fee(x.p, v_item.amount_xaf, v_item.with_payout)
                                  else 0 * private.service_fee(x.p, v_item.amount_xaf, v_item.with_payout) end as fee) f
  where p_provider is null or x.p = p_provider
  order by x.p;
end;
$$;
revoke execute on function public.payment_quote(text, uuid, text) from public, anon;
grant execute on function public.payment_quote(text, uuid, text) to authenticated;

-- ---------------------------------------------------------------- opening a payment
-- Called by the `payments` Edge Function with the caller's session, before it calls pawaPay. Writes the payment first,
-- so whatever happens next it can be found and finished. The number is a Cameroonian mobile number in international
-- form without the plus (2376XXXXXXXX). Refusals as payment_item, plus 55000 payment_in_progress or fees_not_set (the
-- operator's rates are not entered yet) and 54000 too_many_attempts.
create function public.start_payment(p_purpose text, p_target uuid, p_provider text, p_phone text)
returns table (id uuid, amount_xaf integer, fee_xaf integer, total_xaf integer, currency text, provider text)
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_item record;
  v_settings private.payment_settings;
  v_fee integer;
  v_cost integer;
  v_row public.payments;
begin
  if p_provider is null or p_provider not in ('MTN_MOMO_CMR', 'ORANGE_CMR') then
    raise exception 'bad_provider' using errcode = '22023';
  end if;
  if p_phone is null or p_phone !~ '^2376[0-9]{8}$' then
    raise exception 'bad_phone' using errcode = '22023';
  end if;
  select * into v_settings from private.payment_settings;
  if (select count(*) from public.payments p where p.paid_by = v_uid and p.created_at > now() - interval '1 hour') >= v_settings.max_starts_per_hour then
    raise exception 'too_many_attempts' using errcode = '54000';
  end if;
  select * into v_item from private.payment_item(p_purpose, p_target);
  v_fee := private.service_fee(p_provider, v_item.amount_xaf, v_item.with_payout);
  if not v_item.with_fee then
    v_fee := 0 * v_fee;
  end if;
  v_cost := private.transfer_cost(p_provider, 'deposit', v_item.amount_xaf + coalesce(v_fee, 0))
    + case when v_item.with_payout then private.transfer_cost(p_provider, 'payout', v_item.amount_xaf) else 0 end;
  if v_fee is null or v_cost is null then
    raise exception 'fees_not_set' using errcode = '55000';
  end if;

  begin
    insert into public.payments (school_id, paid_by, purpose, subscription_id, installment_id, invoice_id, item_key,
                                 amount_xaf, fee_xaf, est_cost_xaf, school_pays_costs, provider, payer_masked)
    values (v_item.school_id, v_uid, p_purpose,
            case when p_purpose = 'subscription' then p_target
                 when p_purpose = 'installment' then (select i.subscription_id from public.subscription_installments i where i.id = p_target) end,
            case when p_purpose = 'installment' then p_target end,
            case when p_purpose = 'invoice' then p_target end,
            v_item.item_key, v_item.amount_xaf, v_fee, v_cost,
            v_item.with_payout and not v_item.with_fee,
            p_provider, left(p_phone, 4) || '*****' || right(p_phone, 3))
    returning * into v_row;
  exception when unique_violation then
    raise exception 'payment_in_progress' using errcode = '55000';
  end;

  return query select v_row.id, v_row.amount_xaf, v_row.fee_xaf, v_row.total_xaf, v_row.currency, v_row.provider;
end;
$$;
revoke execute on function public.start_payment(text, uuid, text, text) from public, anon;
grant execute on function public.start_payment(text, uuid, text, text) to authenticated;

-- ---------------------------------------------------------------- settling a payment
-- A refund BusIn owes because it could not apply a completed payment: the whole amount, fee included, sent by the
-- refunds worker. The school's share comes back out of its ledger at once.
create function private.refund_unapplied(p_payment public.payments, p_reason text) returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_refund uuid;
begin
  insert into public.refunds (school_id, payment_id, student_id, kind, reason, amount_xaf, fee_xaf, status)
  values (p_payment.school_id, p_payment.id, p_payment.paid_by, 'system', p_reason, p_payment.amount_xaf, p_payment.fee_xaf, 'queued')
  returning id into v_refund;
  -- Taken from the payment's own credit: still on hold, the two cancel out there; already available, at once.
  if p_payment.purpose <> 'invoice' then
    insert into public.school_ledger (school_id, kind, amount_xaf, available_at, refund_id, payment_id)
    select p_payment.school_id, 'refund', -p_payment.amount_xaf, greatest(now(), coalesce(max(l.available_at), now())), v_refund, p_payment.id
    from public.school_ledger l where l.payment_id = p_payment.id and l.kind = 'payment';
    -- BusIn's error: the school does not pay for moving the money either.
    insert into public.school_ledger (school_id, kind, amount_xaf, available_at, payment_id, note)
    select l.school_id, 'reversal', -l.amount_xaf, l.available_at, p_payment.id, 'transaction_fee'
    from public.school_ledger l where l.payment_id = p_payment.id and l.kind = 'transaction_fee';
  end if;
  update public.payments set outcome = 'refunded' where id = p_payment.id;
end;
$$;
revoke execute on function private.refund_unapplied(public.payments, text) from public;

-- Applies a completed payment to what it paid for, once. When the item can no longer take it, refunds it.
create function private.apply_payment(p_payment public.payments) returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_settings private.payment_settings;
  v_sub public.subscriptions;
  v_part public.subscription_installments;
  v_today date := private.school_today(p_payment.school_id);
begin
  select * into v_settings from private.payment_settings;

  if p_payment.purpose = 'invoice' then
    insert into public.school_ledger (school_id, kind, amount_xaf, payment_id, invoice_id)
    values (p_payment.school_id, 'invoice_payment', p_payment.amount_xaf, p_payment.id, p_payment.invoice_id);
    update public.busin_invoices set status = 'paid', paid_at = now() where id = p_payment.invoice_id and status = 'open';
    if not found then
      -- Paid twice, or voided meanwhile: the credit stays with the school, as money it no longer owes.
      null;
    end if;
    update public.payments set outcome = 'applied' where id = p_payment.id;
    return;
  end if;

  -- The school's share, on hold for the set days, less what moving it costs when the school bears that.
  insert into public.school_ledger (school_id, kind, amount_xaf, available_at, payment_id)
  values (p_payment.school_id, 'payment', p_payment.amount_xaf, now() + make_interval(days => v_settings.hold_days), p_payment.id);
  if p_payment.school_pays_costs and p_payment.est_cost_xaf > 0 then
    insert into public.school_ledger (school_id, kind, amount_xaf, available_at, payment_id)
    values (p_payment.school_id, 'transaction_fee', -p_payment.est_cost_xaf, now() + make_interval(days => v_settings.hold_days), p_payment.id);
  end if;

  if p_payment.purpose = 'subscription' then
    select * into v_sub from public.subscriptions where id = p_payment.subscription_id for update;
    if v_sub.status <> 'pending' then
      perform private.refund_unapplied(p_payment, 'not_pending');
      return;
    end if;
    if exists (select 1 from public.semesters m where m.id = v_sub.semester_id and m.end_date < v_today)
       or (v_sub.period_end is not null and v_sub.period_end < v_today) then
      perform private.refund_unapplied(p_payment, 'period_ended');
      return;
    end if;
    if private.student_is_suspended(v_sub.student_id) then
      perform private.refund_unapplied(p_payment, 'account_suspended');
      return;
    end if;
    update public.subscriptions
    set status = 'approved', review_note = null, reviewed_by = null, reviewed_at = now()
    where id = v_sub.id;
  else
    select * into v_part from public.subscription_installments where id = p_payment.installment_id for update;
    if v_part.status not in ('due', 'rejected')
       or not exists (select 1 from public.subscriptions s where s.id = v_part.subscription_id and s.status = 'approved') then
      perform private.refund_unapplied(p_payment, 'not_payable');
      return;
    end if;
    update public.subscription_installments
    set status = 'paid', review_note = null, reviewed_by = null, reviewed_at = now()
    where id = v_part.id;
    insert into public.installment_receipts (school_id, subscription_id, installment_id, student_id, seq, proof_path,
                                             decision, decided_at, payment_id)
    values (v_part.school_id, v_part.subscription_id, v_part.id, v_part.student_id, v_part.seq, null, 'paid', now(), p_payment.id);
  end if;
  update public.payments set outcome = 'applied' where id = p_payment.id;
end;
$$;
revoke execute on function private.apply_payment(public.payments) from public;

-- Every result pawaPay gives for a payment comes here: its callback, the reconciler's check, or the check after a
-- timeout. Statuses as pawaPay names them: ACCEPTED, PROCESSING, IN_RECONCILIATION, COMPLETED, FAILED, REJECTED,
-- DUPLICATE_IGNORED, and NOT_FOUND when pawaPay has no such payment. Safe to call any number of times: a payment already
-- final does not change, except a failed one pawaPay later reports completed (the money was taken, so it is honoured).
-- Returns the payment's status after the call, and whether it changed; null for an unknown payment.
create function public.settle_payment(
  p_id uuid,
  p_status text,
  p_amount text default null,
  p_currency text default null,
  p_provider_txn text default null,
  p_failure_code text default null,
  p_failure_message text default null
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_pay public.payments;
  v_new text;
  v_status text := upper(btrim(coalesce(p_status, '')));
begin
  select * into v_pay from public.payments where id = p_id for update;
  if not found then
    return null;
  end if;
  update public.payments set checks = least(checks + 1, 32000), last_checked_at = now() where id = p_id;

  if v_pay.status = 'completed'
     or (v_pay.status = 'failed' and v_status <> 'COMPLETED')
     or (v_pay.status = 'needs_attention') then
    return jsonb_build_object('status', v_pay.status, 'changed', false);
  end if;

  v_new := case v_status
    when 'ACCEPTED' then case when v_pay.status = 'initiated' then 'accepted' end
    when 'DUPLICATE_IGNORED' then null
    when 'PROCESSING' then 'processing'
    when 'IN_RECONCILIATION' then 'in_reconciliation'
    when 'COMPLETED' then 'completed'
    when 'FAILED' then 'failed'
    when 'REJECTED' then 'failed'
    -- pawaPay never received it: failed once it is old enough that it never will.
    when 'NOT_FOUND' then case when v_pay.created_at < now() - interval '15 minutes' then 'failed' end
    else 'needs_attention'
  end;

  if v_new = 'completed' and (
       (p_amount is not null and (p_amount !~ '^[0-9]+(\.0+)?$' or p_amount::numeric <> v_pay.total_xaf))
       or (p_currency is not null and upper(p_currency) <> v_pay.currency)) then
    v_new := 'needs_attention';
  end if;

  if v_new is null or v_new = v_pay.status then
    return jsonb_build_object('status', v_pay.status, 'changed', false);
  end if;

  if v_new = 'completed' then
    update public.payments
    set status = 'completed', completed_at = now(), updated_at = now(),
        provider_txn = coalesce(left(p_provider_txn, 100), provider_txn),
        failure_code = null, failure_message = null,
        receipt_no = coalesce(receipt_no, private.next_receipt_no('BI'))
    where id = p_id
    returning * into v_pay;
    perform private.apply_payment(v_pay);
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    values (v_pay.school_id, v_pay.paid_by, 'payment_completed', v_pay.id);
  elsif v_new = 'failed' then
    update public.payments
    set status = 'failed', updated_at = now(),
        failure_code = left(coalesce(nullif(btrim(p_failure_code), ''), case when v_status = 'NOT_FOUND' then 'NOT_FOUND' else 'UNKNOWN' end), 64),
        failure_message = left(p_failure_message, 300)
    where id = p_id;
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    values (v_pay.school_id, v_pay.paid_by, 'payment_failed', v_pay.id);
  else
    update public.payments
    set status = v_new, updated_at = now(),
        failure_code = case when v_new = 'needs_attention' then left(coalesce(nullif(v_status, ''), 'UNKNOWN'), 64) else failure_code end
    where id = p_id;
  end if;
  return jsonb_build_object('status', v_new, 'changed', true);
end;
$$;
revoke execute on function public.settle_payment(uuid, text, text, text, text, text, text) from public, anon, authenticated;
grant execute on function public.settle_payment(uuid, text, text, text, text, text, text) to service_role;

-- The open payments the reconciler checks with pawaPay: older than two minutes, the least recently checked first.
create function public.payments_to_check(p_limit integer default 50)
returns table (id uuid, status text, created_at timestamptz)
language sql stable security definer
set search_path = ''
as $$
  select p.id, p.status, p.created_at
  from public.payments p
  where p.status in ('initiated', 'accepted', 'processing', 'in_reconciliation')
    and p.created_at < now() - interval '2 minutes'
    and (p.last_checked_at is null or p.last_checked_at < now() - interval '2 minutes')
  order by p.last_checked_at nulls first, p.created_at
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
$$;
revoke execute on function public.payments_to_check(integer) from public, anon, authenticated;
grant execute on function public.payments_to_check(integer) to service_role;

-- ---------------------------------------------------------------- account deletion waits for open payments
create or replace function private.deletion_blocker(p_user uuid)
returns text
language sql stable security definer
set search_path = ''
as $$
  select case
    when exists (select 1 from public.profiles p where p.id = p_user and p.role = 'admin' and p.status = 'verified'
                 and p.school_id is not null
                 and not exists (select 1 from public.profiles a where a.school_id = p.school_id and a.role = 'admin'
                                 and a.status = 'verified' and a.id <> p.id and a.deletion_due_at is null)) then 'last_admin'
    when exists (select 1 from public.trips t where t.status = 'active' and (t.driver_id = p_user or t.assistant_id = p_user)) then 'active_trip'
    when exists (select 1 from public.payments x where x.paid_by = p_user
                 and x.status in ('initiated', 'accepted', 'processing', 'in_reconciliation', 'needs_attention'))
      or exists (select 1 from public.refunds r where r.student_id = p_user
                 and r.status in ('queued', 'accepted', 'processing', 'in_reconciliation', 'needs_attention')) then 'payment_in_progress'
  end;
$$;

-- ---------------------------------------------------------------- paying by receipt after all
-- A request made to pay by mobile money whose payment did not go through: the student sends a receipt for it instead,
-- and it waits for the school like any other. Refusals: 42501 not a student, P0002 not theirs, 55000 not pending or a
-- payment in progress, 22023 proof_required or proof_missing.
create function public.attach_subscription_proof(p_subscription uuid, p_path text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_sub public.subscriptions;
begin
  if private.my_role() is distinct from 'student' then
    raise exception 'Students only' using errcode = '42501';
  end if;
  select * into v_sub from public.subscriptions where id = p_subscription and student_id = v_uid and school_id = v_school for update;
  if not found then
    raise exception 'Subscription not found' using errcode = 'P0002';
  end if;
  if v_sub.status <> 'pending' then
    raise exception 'not_pending' using errcode = '55000';
  end if;
  if private.has_open_payment(v_sub.id, null) then
    raise exception 'payment_in_progress' using errcode = '55000';
  end if;
  if p_path is null or p_path not like v_school::text || '/' || v_uid::text || '/%' then
    raise exception 'proof_required' using errcode = '22023';
  end if;
  if not exists (select 1 from storage.objects o where o.bucket_id = 'proofs' and o.name = p_path) then
    raise exception 'proof_missing' using errcode = '22023';
  end if;
  update public.subscriptions set proof_path = p_path, payment_method = 'receipt', updated_at = now() where id = v_sub.id;
end;
$$;
revoke execute on function public.attach_subscription_proof(uuid, text) from public, anon;
grant execute on function public.attach_subscription_proof(uuid, text) to authenticated;
