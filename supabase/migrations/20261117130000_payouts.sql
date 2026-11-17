-- Paying schools out, and invoicing what they owe (ADR 0029, point 5). A school registers the mobile money number it is
-- paid on: one administrator proposes it, another confirms it (or the platform, for a school with one administrator);
-- a number that replaces another is used only after 7 days, so a stolen account cannot redirect the money at once.
-- Every Monday morning the available balance of each school, above the minimum, becomes a payout to that number; the
-- reconciler sends it to pawaPay and follows it like a payment. On the first of each month a school whose balance is
-- negative (BusIn's charges with nothing to take them from) gets an invoice, paid from the portal by mobile money.

-- ---------------------------------------------------------------- the payout number
-- Refusals: 42501 not an administrator, 22023 bad_provider, bad_phone or bad_name.
create function public.admin_propose_payout_account(p_provider text, p_phone text, p_account_name text)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_phone text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  v_name text := nullif(btrim(regexp_replace(coalesce(p_account_name, ''), '\s+', ' ', 'g')), '');
  v_id uuid;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if p_provider is null or p_provider not in ('MTN_MOMO_CMR', 'ORANGE_CMR') then
    raise exception 'bad_provider' using errcode = '22023';
  end if;
  if char_length(v_phone) = 9 then
    v_phone := '237' || v_phone;
  end if;
  if v_phone !~ '^2376[0-9]{8}$' then
    raise exception 'bad_phone' using errcode = '22023';
  end if;
  if v_name is null or char_length(v_name) not between 2 and 120 then
    raise exception 'bad_name' using errcode = '22023';
  end if;
  -- A new proposal replaces one still waiting.
  update public.school_payout_accounts set status = 'declined' where school_id = v_school and status = 'proposed';
  insert into public.school_payout_accounts (school_id, provider, phone, account_name, proposed_by)
  values (v_school, p_provider, v_phone, v_name, v_actor)
  returning id into v_id;
  perform private.write_audit(v_school, v_actor, 'payout_account.proposed', 'school', v_school,
    jsonb_build_object('provider', p_provider, 'phone_end', right(v_phone, 3)));
  return v_id;
end;
$$;
revoke execute on function public.admin_propose_payout_account(text, text, text) from public, anon;
grant execute on function public.admin_propose_payout_account(text, text, text) to authenticated;

-- Makes a proposed number the school's payout number. Used at once for a first number, after 7 days for a replacement.
create function private.confirm_payout_account(p_account public.school_payout_accounts, p_actor uuid) returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_replaces boolean;
begin
  select exists (select 1 from public.school_payout_accounts a where a.school_id = p_account.school_id and a.status = 'active') into v_replaces;
  update public.school_payout_accounts set status = 'retired', retired_at = now() where school_id = p_account.school_id and status = 'active';
  update public.school_payout_accounts
  set status = 'active', confirmed_by = p_actor, confirmed_at = now(),
      usable_from = case when v_replaces then now() + interval '7 days' else now() end
  where id = p_account.id;
end;
$$;
revoke execute on function private.confirm_payout_account(public.school_payout_accounts, uuid) from public;

-- Another administrator of the school confirms it. Refusals: 42501, P0002 not_found, 55000 not_proposed or same_admin.
create function public.admin_confirm_payout_account(p_account uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_account public.school_payout_accounts;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  select * into v_account from public.school_payout_accounts where id = p_account and school_id = v_school for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if v_account.status <> 'proposed' then
    raise exception 'not_proposed' using errcode = '55000';
  end if;
  if v_account.proposed_by = v_actor then
    raise exception 'same_admin' using errcode = '55000';
  end if;
  perform private.confirm_payout_account(v_account, v_actor);
  perform private.write_audit(v_school, v_actor, 'payout_account.confirmed', 'school', v_school, jsonb_build_object('account_id', p_account));
end;
$$;
revoke execute on function public.admin_confirm_payout_account(uuid) from public, anon;
grant execute on function public.admin_confirm_payout_account(uuid) to authenticated;

-- An administrator withdraws or refuses a proposed number.
create function public.admin_decline_payout_account(p_account uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  update public.school_payout_accounts set status = 'declined' where id = p_account and school_id = v_school and status = 'proposed';
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  perform private.write_audit(v_school, v_actor, 'payout_account.declined', 'school', v_school, jsonb_build_object('account_id', p_account));
end;
$$;
revoke execute on function public.admin_decline_payout_account(uuid) from public, anon;
grant execute on function public.admin_decline_payout_account(uuid) to authenticated;

-- The platform confirms for a school with a single administrator, after checking with the school (ADR 0027 outreach).
create function public.platform_confirm_payout_account(p_account uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_account public.school_payout_accounts;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  select * into v_account from public.school_payout_accounts where id = p_account for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if v_account.status <> 'proposed' then
    raise exception 'not_proposed' using errcode = '55000';
  end if;
  perform private.confirm_payout_account(v_account, (select auth.uid()));
  perform private.write_platform_audit('payout_account.confirmed', v_account.school_id, 'payout_account', p_account);
end;
$$;
revoke execute on function public.platform_confirm_payout_account(uuid) from public, anon;
grant execute on function public.platform_confirm_payout_account(uuid) to authenticated;

-- ---------------------------------------------------------------- weekly payouts
-- Creates this week's payouts: each school with a confirmed number in use and an available balance at or above the
-- minimum, and no payout still going, is paid all of it. The amount leaves the balance at once (a failure puts it
-- back). An open invoice whose debt has since been covered by payments is voided. Returns the number of payouts.
create function private.plan_payouts() returns integer
language plpgsql security definer
set search_path = ''
as $$
declare
  v_min integer := (select s.payout_min_xaf from private.payment_settings s);
  v_count integer := 0;
  r record;
  v_payout uuid;
begin
  update public.busin_invoices i set status = 'void'
  where i.status = 'open' and (select b.owed_xaf from private.school_balance(i.school_id) b) = 0;

  for r in
    select a.school_id, a.id as account_id, a.provider, a.phone, b.available_xaf
    from public.school_payout_accounts a
    cross join lateral private.school_balance(a.school_id) b
    where a.status = 'active' and a.usable_from <= now()
      and b.available_xaf >= greatest(v_min, 1)
      and not exists (select 1 from public.payouts p where p.school_id = a.school_id
                      and p.status in ('queued', 'accepted', 'processing', 'in_reconciliation', 'needs_attention'))
  loop
    insert into public.payouts (school_id, account_id, amount_xaf, provider, phone_masked)
    values (r.school_id, r.account_id, r.available_xaf, r.provider, left(r.phone, 4) || '*****' || right(r.phone, 3))
    returning id into v_payout;
    insert into public.school_ledger (school_id, kind, amount_xaf, payout_id) values (r.school_id, 'payout', -r.available_xaf, v_payout);
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;
revoke execute on function private.plan_payouts() from public;

-- Monday 06:00 UTC, 07:00 in Douala.
select cron.schedule('busin-plan-payouts', '0 6 * * 1', $$select private.plan_payouts()$$);

-- What the reconciler does with payouts: send those queued (with the full number, which only the server reads), and ask
-- pawaPay about those sent more than two minutes ago.
create function public.payouts_to_send(p_limit integer default 50)
returns table (id uuid, amount_xaf integer, provider text, phone text, action text)
language sql stable security definer
set search_path = ''
as $$
  select p.id, p.amount_xaf, p.provider, a.phone, case when p.status = 'queued' then 'send' else 'check' end
  from public.payouts p
  join public.school_payout_accounts a on a.id = p.account_id
  where p.status = 'queued'
     or (p.status in ('accepted', 'processing', 'in_reconciliation') and p.updated_at < now() - interval '2 minutes')
  order by p.updated_at
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
$$;
revoke execute on function public.payouts_to_send(integer) from public, anon, authenticated;
grant execute on function public.payouts_to_send(integer) to service_role;

-- Every result pawaPay gives for a payout, applied once (as settle_payment). A payout that fails is put back in the
-- school's balance and is tried again with next week's.
create function public.settle_payout(
  p_id uuid,
  p_status text,
  p_amount text default null,
  p_currency text default null,
  p_provider_txn text default null,
  p_failure_code text default null
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_payout public.payouts;
  v_status text := upper(btrim(coalesce(p_status, '')));
  v_new text;
begin
  select * into v_payout from public.payouts where id = p_id for update;
  if not found then
    return null;
  end if;
  if v_payout.status in ('completed', 'failed', 'needs_attention') then
    return jsonb_build_object('status', v_payout.status, 'changed', false);
  end if;
  v_new := case v_status
    when 'ACCEPTED' then case when v_payout.status = 'queued' then 'accepted' end
    when 'DUPLICATE_IGNORED' then case when v_payout.status = 'queued' then 'accepted' end
    when 'ENQUEUED' then 'processing'
    when 'PROCESSING' then 'processing'
    when 'IN_RECONCILIATION' then 'in_reconciliation'
    when 'COMPLETED' then 'completed'
    when 'FAILED' then 'failed'
    when 'REJECTED' then 'failed'
    when 'NOT_FOUND' then case when v_payout.status <> 'queued' and v_payout.updated_at < now() - interval '15 minutes' then 'failed' end
    else 'needs_attention'
  end;
  if v_new = 'completed' and (
       (p_amount is not null and (p_amount !~ '^[0-9]+(\.0+)?$' or p_amount::numeric <> v_payout.amount_xaf))
       or (p_currency is not null and upper(p_currency) <> 'XAF')) then
    v_new := 'needs_attention';
  end if;
  if v_new is null or v_new = v_payout.status then
    return jsonb_build_object('status', v_payout.status, 'changed', false);
  end if;

  if v_new = 'completed' then
    update public.payouts
    set status = 'completed', completed_at = now(), updated_at = now(), failure_code = null,
        provider_txn = coalesce(left(p_provider_txn, 100), provider_txn)
    where id = p_id;
  elsif v_new = 'failed' then
    update public.payouts
    set status = 'failed', updated_at = now(),
        failure_code = left(coalesce(nullif(btrim(p_failure_code), ''), case when v_status = 'NOT_FOUND' then 'NOT_FOUND' else 'UNKNOWN' end), 64)
    where id = p_id;
    insert into public.school_ledger (school_id, kind, amount_xaf, payout_id) values (v_payout.school_id, 'payout_reversal', v_payout.amount_xaf, p_id);
  else
    update public.payouts
    set status = v_new, updated_at = now(),
        failure_code = case when v_new = 'needs_attention' then left(coalesce(nullif(btrim(p_failure_code), ''), nullif(v_status, ''), 'UNKNOWN'), 64) else failure_code end
    where id = p_id;
  end if;
  return jsonb_build_object('status', v_new, 'changed', true);
end;
$$;
revoke execute on function public.settle_payout(uuid, text, text, text, text, text) from public, anon, authenticated;
grant execute on function public.settle_payout(uuid, text, text, text, text, text) to service_role;

-- ---------------------------------------------------------------- monthly invoices
-- On the first of the month, a school that owes BusIn (a negative balance) and has no open invoice gets one for what it
-- owes, due in 14 days. Returns the number issued.
create function private.issue_invoices(p_month date default null) returns integer
language plpgsql security definer
set search_path = ''
as $$
declare
  v_month date := date_trunc('month', coalesce(p_month, (now() at time zone 'UTC')::date))::date;
  v_count integer := 0;
  r record;
begin
  for r in
    select s.id as school_id, b.owed_xaf
    from public.schools s
    cross join lateral private.school_balance(s.id) b
    where b.owed_xaf > 0
      and not exists (select 1 from public.busin_invoices i where i.school_id = s.id and (i.status = 'open' or i.month = v_month))
  loop
    insert into public.busin_invoices (school_id, number, month, amount_xaf, due_date)
    values (r.school_id, private.next_receipt_no('BF'), v_month, r.owed_xaf, v_month + 14);
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;
revoke execute on function private.issue_invoices(date) from public;

-- The 1st at 07:00 UTC.
select cron.schedule('busin-issue-invoices', '0 7 1 * *', $$select private.issue_invoices()$$);

-- ---------------------------------------------------------------- what the school sees
-- The school's payments at a glance: its balance, what it collected (by mobile money and by approved receipts),
-- refunds, BusIn's charges and payouts, month by month for the last p_months months (school time), its payout number,
-- refunds waiting for a decision, and an open invoice.
create function public.admin_payment_summary(p_months integer default 6)
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

-- ---------------------------------------------------------------- the reconciler also sends payouts
create or replace function private.dispatch_payment_checks()
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  if not exists (
    select 1 from public.payments p
    where p.status in ('initiated', 'accepted', 'processing', 'in_reconciliation')
      and p.created_at < now() - interval '2 minutes'
  ) and not exists (
    select 1 from public.refunds r
    where r.status = 'queued'
       or (r.status in ('accepted', 'processing', 'in_reconciliation') and r.updated_at < now() - interval '2 minutes')
  ) and not exists (
    select 1 from public.payouts o
    where o.status = 'queued'
       or (o.status in ('accepted', 'processing', 'in_reconciliation') and o.updated_at < now() - interval '2 minutes')
  ) then
    return;
  end if;
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'payments_reconcile_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'payments_reconcile_secret';
  if coalesce(v_url, '') = '' or coalesce(v_secret, '') = '' then
    return;
  end if;
  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-reconcile-secret', v_secret),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
end;
$$;
