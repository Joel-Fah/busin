-- Follow-ups from building the school portal (ADR 0029).
-- 1. pawaPay's failure message is for BusIn's team: payers and school administrators read the failure code only.
-- 2. An administrator can preview the other choice of who pays the fees before saving it (price_breakdown).
-- 3. The school's summary gives the hold, the smallest payout and the time of the next payouts, so the portal follows
--    the platform's settings instead of copies of them.

revoke select on public.payments from authenticated;
grant select (id, school_id, paid_by, purpose, subscription_id, installment_id, invoice_id, amount_xaf, fee_xaf, total_xaf,
              currency, provider, payer_masked, status, failure_code, provider_txn, receipt_no,
              outcome, created_at, updated_at, completed_at)
  on public.payments to authenticated;

drop function public.price_breakdown(integer);

create function public.price_breakdown(p_price integer default null, p_fees_paid_by text default null)
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
  v_who text;
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
  -- An administrator may also try the other choice of who pays the fees before saving it.
  v_who := case when p_fees_paid_by in ('student', 'school') and private.is_admin() then p_fees_paid_by else v_school.fees_paid_by end;
  select * into v_settings from private.payment_settings;
  v_charge := private.busin_charge_for(v_school.id, coalesce(v_school.billing_period, 'semester'));
  v_amount := v_price + case when v_who = 'student' then v_charge else 0 end;
  method := 'receipt'; student_pays := v_amount; busin_charge := v_charge; transaction_cost := 0; school_receives := v_amount - v_charge;
  return next;
  if not private.mobile_money_enabled(v_school.id) then
    return;
  end if;
  v_with_fee := v_who = 'student' and v_settings.student_fee_allowed;
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
revoke execute on function public.price_breakdown(integer, text) from public, anon;
grant execute on function public.price_breakdown(integer, text) to authenticated;

create or replace function public.admin_payment_summary(p_months integer default 6)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_zone text;
  v_from date;
  v_months integer := least(greatest(coalesce(p_months, 6), 1), 24);
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  select timezone into v_zone from public.schools where id = v_school;
  v_from := (date_trunc('month', now() at time zone v_zone) - make_interval(months => v_months - 1))::date;

  return jsonb_build_object(
    'balance', (select to_jsonb(b) from private.school_balance(v_school) b),
    -- The platform's rules the page explains: the hold, the smallest payout, and when the next payouts are made (each
    -- Monday at 06:00 UTC, private.plan_payouts).
    'hold_days', (select s.hold_days from private.payment_settings s),
    'payout_min_xaf', (select s.payout_min_xaf from private.payment_settings s),
    'next_payout_at', (date_trunc('week', now() at time zone 'UTC') + interval '6 hours'
                       + case when now() at time zone 'UTC' >= date_trunc('week', now() at time zone 'UTC') + interval '6 hours'
                              then interval '7 days' else interval '0' end) at time zone 'UTC',
    'fees_paid_by', (select s.fees_paid_by from public.schools s where s.id = v_school),
    'mobile_money', private.mobile_money_enabled(v_school),
    'months', coalesce((
      with months as (
        select generate_series(v_from, date_trunc('month', now() at time zone v_zone)::date, interval '1 month')::date as month
      ),
      momo as (
        select date_trunc('month', p.completed_at at time zone v_zone)::date as month, sum(p.amount_xaf) as xaf
        from public.payments p
        where p.school_id = v_school and p.status = 'completed' and p.outcome = 'applied' and p.purpose <> 'invoice'
          and p.completed_at >= v_from
        group by 1
      ),
      receipts as (
        -- Requests approved on a receipt: the whole price, or part 1 when paid in installments.
        select date_trunc('month', s.reviewed_at at time zone v_zone)::date as month,
               sum(case when s.payment_mode = 'installments' then coalesce(i.amount_xaf, 0) else s.amount_xaf end) as xaf
        from public.subscriptions s
        left join public.subscription_installments i on i.subscription_id = s.id and i.seq = 1
        where s.school_id = v_school and s.payment_method = 'receipt' and s.reviewed_by is not null
          and s.status in ('approved', 'revoked', 'expired') and s.reviewed_at >= v_from and s.amount_xaf is not null
        group by 1
        union all
        -- Later parts the school marked paid on a receipt or at the office.
        select date_trunc('month', r.decided_at at time zone v_zone)::date, sum(i.amount_xaf)
        from public.installment_receipts r
        join public.subscription_installments i on i.id = r.installment_id
        where r.school_id = v_school and r.decision = 'paid' and r.payment_id is null and r.decided_at >= v_from
        group by 1
      ),
      ledger as (
        select date_trunc('month', l.created_at at time zone v_zone)::date as month,
               sum(-l.amount_xaf) filter (where l.kind in ('refund', 'refund_fee')) - coalesce(sum(l.amount_xaf) filter (where l.kind = 'refund_reversal'), 0) as refunds,
               sum(-l.amount_xaf) filter (where l.kind = 'charge') as charges,
               sum(-l.amount_xaf) filter (where l.kind = 'payout') - coalesce(sum(l.amount_xaf) filter (where l.kind = 'payout_reversal'), 0) as payouts,
               sum(-l.amount_xaf) filter (where l.kind = 'transaction_fee') as transfer_costs
        from public.school_ledger l
        where l.school_id = v_school and l.created_at >= v_from
        group by 1
      )
      select jsonb_agg(jsonb_build_object(
        'month', m.month,
        'mobile_money', coalesce((select sum(x.xaf) from momo x where x.month = m.month), 0),
        'receipts', coalesce((select sum(x.xaf) from receipts x where x.month = m.month), 0),
        'refunds', coalesce(l.refunds, 0),
        'charges', coalesce(l.charges, 0),
        'payouts', coalesce(l.payouts, 0),
        'transfer_costs', coalesce(l.transfer_costs, 0)
      ) order by m.month)
      from months m left join ledger l on l.month = m.month
    ), '[]'::jsonb),
    'payout_account', (
      select jsonb_build_object('provider', a.provider, 'phone_masked', left(a.phone, 4) || '*****' || right(a.phone, 3),
                                'account_name', a.account_name, 'usable_from', a.usable_from)
      from public.school_payout_accounts a where a.school_id = v_school and a.status = 'active'
    ),
    'refunds_waiting', (select count(*) from public.refunds r where r.school_id = v_school and r.status = 'requested'),
    'open_invoice', (
      select jsonb_build_object('id', i.id, 'number', i.number, 'amount_xaf', i.amount_xaf, 'due_date', i.due_date)
      from public.busin_invoices i where i.school_id = v_school and i.status = 'open' order by i.issued_at desc limit 1
    )
  );
end;
$$;
revoke execute on function public.admin_payment_summary(integer) from public, anon;
grant execute on function public.admin_payment_summary(integer) to authenticated;
