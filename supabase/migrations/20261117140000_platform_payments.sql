-- The platform's side of payments (ADR 0029, with the console of ADR 0027): the settings (pawaPay's share, VAT,
-- operator rates, the margin for rounding, the hold, the payout minimum, BusIn's charge per paying student, whether a
-- fee on top is allowed), each school's switch and terms, monthly infrastructure costs, BusIn's money month by month
-- with its real margin, and the check that pawaPay's wallet holds what the books say. Every change is in the platform
-- audit. Platform admins only, read live (ADR 0005).

-- ---------------------------------------------------------------- settings
create function public.platform_payment_settings()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  return (select to_jsonb(s) - 'id' from private.payment_settings s)
    || jsonb_build_object('rates', coalesce((
         select jsonb_agg(jsonb_build_object('provider', r.provider, 'operation', r.operation, 'mmo_percent', r.mmo_percent, 'mmo_fixed_xaf', r.mmo_fixed_xaf)
                          order by r.provider, r.operation)
         from private.provider_rates r), '[]'::jsonb));
end;
$$;
revoke execute on function public.platform_payment_settings() from public, anon;
grant execute on function public.platform_payment_settings() to authenticated;

-- Changes the given settings only (a key left out keeps its value). Refusals: 42501, 22023 bad_setting (an unknown key
-- or a value out of range, checked by the table).
create function public.platform_set_payment_settings(p_settings jsonb)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_allowed text[] := array['pawapay_percent', 'pawapay_vat_percent', 'fee_buffer_percent', 'fee_min_xaf', 'student_fee_allowed', 'hold_days',
                            'payout_min_xaf', 'charge_semester_xaf', 'charge_month_xaf', 'max_starts_per_hour'];
  v_key text;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  if p_settings is null or jsonb_typeof(p_settings) <> 'object' then
    raise exception 'bad_setting' using errcode = '22023';
  end if;
  for v_key in select jsonb_object_keys(p_settings) loop
    if not v_key = any (v_allowed) or jsonb_typeof(p_settings -> v_key) not in ('number', 'boolean') then
      raise exception 'bad_setting' using errcode = '22023';
    end if;
  end loop;
  begin
    update private.payment_settings s set
      pawapay_percent = coalesce((p_settings ->> 'pawapay_percent')::numeric, s.pawapay_percent),
      pawapay_vat_percent = coalesce((p_settings ->> 'pawapay_vat_percent')::numeric, s.pawapay_vat_percent),
      fee_buffer_percent = coalesce((p_settings ->> 'fee_buffer_percent')::numeric, s.fee_buffer_percent),
      fee_min_xaf = coalesce((p_settings ->> 'fee_min_xaf')::integer, s.fee_min_xaf),
      student_fee_allowed = coalesce((p_settings ->> 'student_fee_allowed')::boolean, s.student_fee_allowed),
      hold_days = coalesce((p_settings ->> 'hold_days')::smallint, s.hold_days),
      payout_min_xaf = coalesce((p_settings ->> 'payout_min_xaf')::integer, s.payout_min_xaf),
      charge_semester_xaf = coalesce((p_settings ->> 'charge_semester_xaf')::integer, s.charge_semester_xaf),
      charge_month_xaf = coalesce((p_settings ->> 'charge_month_xaf')::integer, s.charge_month_xaf),
      max_starts_per_hour = coalesce((p_settings ->> 'max_starts_per_hour')::smallint, s.max_starts_per_hour),
      updated_at = now(), updated_by = (select auth.uid());
  exception when check_violation or numeric_value_out_of_range or invalid_text_representation then
    raise exception 'bad_setting' using errcode = '22023';
  end;
  perform private.write_platform_audit('payments.settings', null, null, null, p_settings);
end;
$$;
revoke execute on function public.platform_set_payment_settings(jsonb) from public, anon;
grant execute on function public.platform_set_payment_settings(jsonb) to authenticated;

-- One operator's share for a kind of transaction (null: not set, which stops payments with it).
create function public.platform_set_provider_rate(p_provider text, p_operation text, p_percent numeric, p_fixed_xaf integer default 0)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  if p_percent is not null and (p_percent < 0 or p_percent > 20) or coalesce(p_fixed_xaf, 0) < 0 then
    raise exception 'bad_setting' using errcode = '22023';
  end if;
  update private.provider_rates
  set mmo_percent = p_percent, mmo_fixed_xaf = coalesce(p_fixed_xaf, 0), updated_at = now()
  where provider = p_provider and operation = p_operation;
  if not found then
    raise exception 'bad_setting' using errcode = '22023';
  end if;
  perform private.write_platform_audit('payments.rate', null, null, null,
    jsonb_build_object('provider', p_provider, 'operation', p_operation, 'percent', p_percent, 'fixed', p_fixed_xaf));
end;
$$;
revoke execute on function public.platform_set_provider_rate(text, text, numeric, integer) from public, anon;
grant execute on function public.platform_set_provider_rate(text, text, numeric, integer) to authenticated;

-- ---------------------------------------------------------------- each school
create function public.platform_school_payments(p_school uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  if not exists (select 1 from public.schools where id = p_school) then
    return null;
  end if;
  return jsonb_build_object(
    'terms', (select to_jsonb(t) - 'school_id' from private.school_payment_terms t where t.school_id = p_school),
    'fees_paid_by', (select s.fees_paid_by from public.schools s where s.id = p_school),
    'balance', (select to_jsonb(b) from private.school_balance(p_school) b),
    'payout_account', (select jsonb_build_object('id', a.id, 'status', a.status, 'provider', a.provider,
                                                 'phone_masked', left(a.phone, 4) || '*****' || right(a.phone, 3),
                                                 'account_name', a.account_name, 'usable_from', a.usable_from)
                       from public.school_payout_accounts a where a.school_id = p_school and a.status in ('active', 'proposed')
                       order by a.status = 'proposed' desc limit 1),
    'collected_30d', (select coalesce(sum(p.amount_xaf), 0) from public.payments p
                      where p.school_id = p_school and p.status = 'completed' and p.purpose <> 'invoice' and p.completed_at > now() - interval '30 days'),
    'open_issues', (select count(*) from public.payments p where p.school_id = p_school and p.status = 'needs_attention')
                 + (select count(*) from public.refunds r where r.school_id = p_school and r.status = 'needs_attention')
                 + (select count(*) from public.payouts o where o.school_id = p_school and o.status in ('needs_attention', 'failed'))
  );
end;
$$;
revoke execute on function public.platform_school_payments(uuid) from public, anon;
grant execute on function public.platform_school_payments(uuid) to authenticated;

-- Switches mobile money on or off for a school, sets the day BusIn's charges start (null: none yet) and the school's
-- own charges (null: the platform's). Refusals: 42501, P0002 no_school, 22023 bad_setting.
create function public.platform_set_school_payment_terms(
  p_school uuid,
  p_enabled boolean,
  p_charges_from date default null,
  p_charge_semester_xaf integer default null,
  p_charge_month_xaf integer default null
) returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  if not exists (select 1 from public.schools where id = p_school) then
    raise exception 'no_school' using errcode = 'P0002';
  end if;
  if p_enabled is null or coalesce(p_charge_semester_xaf, 0) < 0 or coalesce(p_charge_month_xaf, 0) < 0 then
    raise exception 'bad_setting' using errcode = '22023';
  end if;
  insert into private.school_payment_terms (school_id, enabled, charges_from, charge_semester_xaf, charge_month_xaf, updated_by)
  values (p_school, p_enabled, p_charges_from, p_charge_semester_xaf, p_charge_month_xaf, (select auth.uid()))
  on conflict (school_id) do update
    set enabled = excluded.enabled, charges_from = excluded.charges_from, charge_semester_xaf = excluded.charge_semester_xaf,
        charge_month_xaf = excluded.charge_month_xaf, updated_at = now(), updated_by = excluded.updated_by;
  perform private.write_platform_audit('payments.school_terms', p_school, 'school', p_school,
    jsonb_build_object('enabled', p_enabled, 'charges_from', p_charges_from, 'semester', p_charge_semester_xaf, 'month', p_charge_month_xaf));
end;
$$;
revoke execute on function public.platform_set_school_payment_terms(uuid, boolean, date, integer, integer) from public, anon;
grant execute on function public.platform_set_school_payment_terms(uuid, boolean, date, integer, integer) to authenticated;

-- ---------------------------------------------------------------- infrastructure costs
create function public.platform_infra_costs(p_from date default null)
returns table (id uuid, month date, label text, amount_xaf integer, note text, created_at timestamptz)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  return query select c.id, c.month, c.label, c.amount_xaf, c.note, c.created_at
    from private.infra_costs c
    where c.month >= coalesce(p_from, (date_trunc('month', now()) - interval '11 months')::date)
    order by c.month desc, c.label
    limit 500;
end;
$$;
revoke execute on function public.platform_infra_costs(date) from public, anon;
grant execute on function public.platform_infra_costs(date) to authenticated;

-- Refusals: 42501, 22023 bad_cost.
create function public.platform_add_infra_cost(p_month date, p_label text, p_amount_xaf integer, p_note text default null)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  begin
    insert into private.infra_costs (month, label, amount_xaf, note, created_by)
    values (date_trunc('month', p_month)::date, btrim(p_label), p_amount_xaf, nullif(btrim(coalesce(p_note, '')), ''), (select auth.uid()))
    returning id into v_id;
  exception when check_violation or not_null_violation then
    raise exception 'bad_cost' using errcode = '22023';
  end;
  perform private.write_platform_audit('payments.infra_cost_added', null, 'infra_cost', v_id,
    jsonb_build_object('month', p_month, 'label', p_label, 'amount', p_amount_xaf));
  return v_id;
end;
$$;
revoke execute on function public.platform_add_infra_cost(date, text, integer, text) from public, anon;
grant execute on function public.platform_add_infra_cost(date, text, integer, text) to authenticated;

create function public.platform_delete_infra_cost(p_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  delete from private.infra_costs where id = p_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  perform private.write_platform_audit('payments.infra_cost_deleted', null, 'infra_cost', p_id);
end;
$$;
revoke execute on function public.platform_delete_infra_cost(uuid) from public, anon;
grant execute on function public.platform_delete_infra_cost(uuid) to authenticated;

-- ---------------------------------------------------------------- the wallet against the books
-- BusIn's own movements of the pawaPay wallet, entered by the platform: money it took out (to its bank) or put in.
create table private.wallet_movements (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('withdrawal', 'top_up')),
  amount_xaf integer not null check (amount_xaf > 0),
  note text check (note is null or char_length(note) <= 300),
  happened_at timestamptz not null default now(),
  created_by uuid
);
revoke all on private.wallet_movements from public, anon, authenticated;

-- pawaPay's balance as read each day, with what the books said at that moment.
create table private.wallet_snapshots (
  id bigint generated always as identity primary key,
  taken_at timestamptz not null default now(),
  balance_xaf integer not null,
  book_xaf integer not null
);
revoke all on private.wallet_snapshots from public, anon, authenticated;

-- What the wallet should hold: every payment taken, less what pawaPay and the operators kept (estimated by the rates in
-- force), less refunds and payouts sent (and what sending them cost), less BusIn's withdrawals, plus its top-ups.
create function private.book_balance() returns integer
language sql stable security definer
set search_path = ''
as $$
  select (
    coalesce((select sum(p.total_xaf) from public.payments p where p.status = 'completed'), 0)
    - coalesce((select sum(coalesce(p.provider_fee_xaf, private.transfer_cost(p.provider, 'deposit', p.total_xaf), 0)) from public.payments p where p.status = 'completed'), 0)
    - coalesce((select sum(r.total_xaf + coalesce(private.transfer_cost(p.provider, 'refund', r.total_xaf), 0))
                from public.refunds r join public.payments p on p.id = r.payment_id where r.status = 'completed'), 0)
    - coalesce((select sum(o.amount_xaf + coalesce(private.transfer_cost(o.provider, 'payout', o.amount_xaf), 0)) from public.payouts o where o.status = 'completed'), 0)
    - coalesce((select sum(m.amount_xaf) from private.wallet_movements m where m.kind = 'withdrawal'), 0)
    + coalesce((select sum(m.amount_xaf) from private.wallet_movements m where m.kind = 'top_up'), 0)
  )::integer
$$;
revoke execute on function private.book_balance() from public;

-- Whether today's reading is due (one a day), for the reconciler.
create function public.wallet_snapshot_due() returns boolean
language sql stable security definer
set search_path = ''
as $$
  select not exists (select 1 from private.wallet_snapshots s where s.taken_at > now() - interval '23 hours')
$$;
revoke execute on function public.wallet_snapshot_due() from public, anon, authenticated;
grant execute on function public.wallet_snapshot_due() to service_role;

-- The reconciler records pawaPay's XAF balance for Cameroon.
create function public.record_wallet_balance(p_balance_xaf integer) returns void
language sql security definer
set search_path = ''
as $$
  insert into private.wallet_snapshots (balance_xaf, book_xaf) values (p_balance_xaf, private.book_balance())
$$;
revoke execute on function public.record_wallet_balance(integer) from public, anon, authenticated;
grant execute on function public.record_wallet_balance(integer) to service_role;

-- Refusals: 42501, 22023 bad_movement.
create function public.platform_add_wallet_movement(p_kind text, p_amount_xaf integer, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  begin
    insert into private.wallet_movements (kind, amount_xaf, note, created_by)
    values (p_kind, p_amount_xaf, nullif(btrim(coalesce(p_note, '')), ''), (select auth.uid()));
  exception when check_violation or not_null_violation then
    raise exception 'bad_movement' using errcode = '22023';
  end;
  perform private.write_platform_audit('payments.wallet_' || p_kind, null, null, null, jsonb_build_object('amount', p_amount_xaf));
end;
$$;
revoke execute on function public.platform_add_wallet_movement(text, integer, text) from public, anon;
grant execute on function public.platform_add_wallet_movement(text, integer, text) to authenticated;

-- ---------------------------------------------------------------- BusIn's money
-- Month by month for the last p_months months (UTC): what students paid, the schools' share, BusIn's fees (net of BusIn's
-- own refunds), its charges, the transfer costs it bore, refunds, payouts, infrastructure costs, and its margin. Then
-- the money held for schools against the wallet, what schools owe, the busiest schools, each operator's failure rate,
-- and what needs a look.
create function public.platform_payments_overview(p_months integer default 6)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_months integer := least(greatest(coalesce(p_months, 6), 1), 24);
  v_from date := (date_trunc('month', now()) - make_interval(months => least(greatest(coalesce(p_months, 6), 1), 24) - 1))::date;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'months', coalesce((
      with months as (
        select generate_series(v_from, date_trunc('month', now())::date, interval '1 month')::date as month
      ),
      paid as (
        select date_trunc('month', p.completed_at)::date as month,
               sum(p.total_xaf) filter (where p.purpose <> 'invoice') as volume,
               sum(p.amount_xaf) filter (where p.purpose <> 'invoice') as schools_share,
               sum(p.fee_xaf) as fees,
               sum(p.est_cost_xaf) as transfer_costs,
               sum(p.amount_xaf) filter (where p.purpose = 'invoice') as invoices_paid,
               count(*) as payments
        from public.payments p where p.status = 'completed' and p.completed_at >= v_from group by 1
      ),
      ledger as (
        select date_trunc('month', l.created_at)::date as month,
               sum(-l.amount_xaf) filter (where l.kind = 'charge') as charges,
               sum(-l.amount_xaf) filter (where l.kind = 'transaction_fee') as costs_from_schools,
               sum(-l.amount_xaf) filter (where l.kind = 'payout') - coalesce(sum(l.amount_xaf) filter (where l.kind = 'payout_reversal'), 0) as payouts
        from public.school_ledger l where l.created_at >= v_from group by 1
      ),
      refunded as (
        select date_trunc('month', r.completed_at)::date as month,
               sum(r.total_xaf) as refunds,
               sum(r.fee_xaf) filter (where r.kind = 'system') as fees_given_back,
               sum(coalesce(private.transfer_cost(p.provider, 'refund', r.total_xaf), 0)) filter (where r.kind = 'system') as system_refund_costs
        from public.refunds r join public.payments p on p.id = r.payment_id
        where r.status = 'completed' and r.completed_at >= v_from group by 1
      ),
      infra as (
        select c.month, sum(c.amount_xaf) as infra from private.infra_costs c where c.month >= v_from group by 1
      ),
      rows as (
        select m.month,
               coalesce(p.volume, 0) as volume, coalesce(p.schools_share, 0) as schools_share, coalesce(p.payments, 0) as payments,
               coalesce(p.fees, 0) - coalesce(f.fees_given_back, 0) as fees,
               coalesce(l.charges, 0) as charges,
               coalesce(p.transfer_costs, 0) + coalesce(f.system_refund_costs, 0) as transfer_costs,
               coalesce(l.costs_from_schools, 0) as costs_from_schools,
               coalesce(f.refunds, 0) as refunds, coalesce(l.payouts, 0) as payouts,
               coalesce(p.invoices_paid, 0) as invoices_paid, coalesce(i.infra, 0) as infra
        from months m
        left join paid p on p.month = m.month
        left join ledger l on l.month = m.month
        left join refunded f on f.month = m.month
        left join infra i on i.month = m.month
      )
      select jsonb_agg(jsonb_build_object(
        'month', r.month, 'volume', r.volume, 'schools_share', r.schools_share, 'payments', r.payments, 'fees', r.fees,
        'charges', r.charges, 'transfer_costs', r.transfer_costs, 'costs_from_schools', r.costs_from_schools,
        'refunds', r.refunds, 'payouts', r.payouts, 'invoices_paid', r.invoices_paid, 'infra', r.infra,
        -- What BusIn keeps: its fees and charges, plus what schools paid for transfers, less the transfers it paid for,
        -- less its infrastructure.
        'margin', r.fees + r.charges + r.costs_from_schools - r.transfer_costs - r.infra
      ) order by r.month)
      from rows r
    ), '[]'::jsonb),
    'held_for_schools', (select coalesce(sum(greatest(b.available_xaf + b.on_hold_xaf - b.owed_xaf, 0)), 0)
                         from public.schools s cross join lateral private.school_balance(s.id) b),
    'owed_by_schools', (select coalesce(sum(b.owed_xaf), 0) from public.schools s cross join lateral private.school_balance(s.id) b),
    'book_balance', private.book_balance(),
    'wallet', (select jsonb_build_object('balance_xaf', w.balance_xaf, 'book_xaf', w.book_xaf, 'taken_at', w.taken_at)
               from private.wallet_snapshots w order by w.taken_at desc limit 1),
    'top_schools', coalesce((
      select jsonb_agg(x order by x.volume desc) from (
        select s.id, s.name, sum(p.amount_xaf) as volume, count(*) as payments
        from public.payments p join public.schools s on s.id = p.school_id
        where p.status = 'completed' and p.purpose <> 'invoice' and p.completed_at >= v_from
        group by s.id, s.name order by sum(p.amount_xaf) desc limit 10
      ) x), '[]'::jsonb),
    'operators', coalesce((
      select jsonb_agg(jsonb_build_object('provider', p.provider, 'completed', p.completed, 'failed', p.failed,
                                          'failure_rate', case when p.completed + p.failed > 0 then round(p.failed::numeric / (p.completed + p.failed), 3) end,
                                          'top_failure', p.top_failure) order by p.provider)
      from (
        select x.provider, count(*) filter (where x.status = 'completed') as completed, count(*) filter (where x.status = 'failed') as failed,
               mode() within group (order by x.failure_code) filter (where x.status = 'failed') as top_failure
        from public.payments x where x.created_at > now() - interval '30 days' group by x.provider
      ) p), '[]'::jsonb),
    'attention', jsonb_build_object(
      'payments', (select count(*) from public.payments where status = 'needs_attention'),
      'refunds', (select count(*) from public.refunds where status = 'needs_attention'),
      'payouts_failed', (select count(*) from public.payouts where status in ('failed', 'needs_attention') and updated_at > now() - interval '14 days'),
      'payout_accounts_waiting', (select count(*) from public.school_payout_accounts where status = 'proposed')
    )
  );
end;
$$;
revoke execute on function public.platform_payments_overview(integer) from public, anon;
grant execute on function public.platform_payments_overview(integer) to authenticated;

-- What needs a look, item by item, newest first: payments, refunds and payouts set aside or failed, and payout numbers
-- waiting for a confirmation.
create function public.platform_payment_alerts()
returns table (kind text, id uuid, school_id uuid, school_name text, amount_xaf integer, status text, code text, at timestamptz)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  return query
  select * from (
    select 'payment'::text, p.id, p.school_id, s.name, p.total_xaf, p.status, p.failure_code, p.updated_at
    from public.payments p join public.schools s on s.id = p.school_id where p.status = 'needs_attention'
    union all
    select 'refund', r.id, r.school_id, s.name, r.total_xaf, r.status, r.failure_code, r.updated_at
    from public.refunds r join public.schools s on s.id = r.school_id where r.status = 'needs_attention'
    union all
    select 'payout', o.id, o.school_id, s.name, o.amount_xaf, o.status, o.failure_code, o.updated_at
    from public.payouts o join public.schools s on s.id = o.school_id
    where o.status in ('failed', 'needs_attention') and o.updated_at > now() - interval '14 days'
    union all
    select 'payout_account', a.id, a.school_id, s.name, null::integer, a.status, a.provider, a.proposed_at
    from public.school_payout_accounts a join public.schools s on s.id = a.school_id where a.status = 'proposed'
  ) x
  order by 8 desc
  limit 200;
end;
$$;
revoke execute on function public.platform_payment_alerts() from public, anon;
grant execute on function public.platform_payment_alerts() to authenticated;
