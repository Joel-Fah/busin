-- Follow-ups from building the console's payment pages (ADR 0029).
-- 1. Every call through the API loads the safeupdate extension, which refuses an UPDATE or DELETE without a WHERE. The
--    settings change updated its single row without one, so it failed through the console (pgTAP connects directly and
--    did not see it). Fixed here; test 069 loads safeupdate and goes through every payment function that writes.
-- 2. BusIn's wallet movements can be listed and one entered by mistake removed.
-- 3. The platform confirms a payout number only for a school with a single administrator: two administrators confirm
--    each other's. The alerts give the number of administrators.

create or replace function public.platform_set_payment_settings(p_settings jsonb)
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
      updated_at = now(), updated_by = (select auth.uid())
    -- The one row (its key is true). A WHERE is required: the API loads safeupdate, which refuses an UPDATE without one.
    where s.id;
  exception when check_violation or numeric_value_out_of_range or invalid_text_representation then
    raise exception 'bad_setting' using errcode = '22023';
  end;
  perform private.write_platform_audit('payments.settings', null, null, null, p_settings);
end;
$$;
revoke execute on function public.platform_set_payment_settings(jsonb) from public, anon;
grant execute on function public.platform_set_payment_settings(jsonb) to authenticated;

create function public.platform_wallet_movements(p_limit integer default 50)
returns table (id uuid, kind text, amount_xaf integer, note text, happened_at timestamptz)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  return query select m.id, m.kind, m.amount_xaf, m.note, m.happened_at
    from private.wallet_movements m order by m.happened_at desc
    limit least(greatest(coalesce(p_limit, 50), 1), 200);
end;
$$;
revoke execute on function public.platform_wallet_movements(integer) from public, anon;
grant execute on function public.platform_wallet_movements(integer) to authenticated;

create function public.platform_delete_wallet_movement(p_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_row private.wallet_movements;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  delete from private.wallet_movements where id = p_id returning * into v_row;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  perform private.write_platform_audit('payments.wallet_movement_deleted', null, null, null,
    jsonb_build_object('kind', v_row.kind, 'amount', v_row.amount_xaf));
end;
$$;
revoke execute on function public.platform_delete_wallet_movement(uuid) from public, anon;
grant execute on function public.platform_delete_wallet_movement(uuid) to authenticated;

-- The school's verified administrators, other than any deletion already scheduled.
create function private.school_admin_count(p_school uuid) returns integer
language sql stable security definer
set search_path = ''
as $$
  select count(*)::integer from public.profiles p
  where p.school_id = p_school and p.role = 'admin' and p.status = 'verified' and p.deletion_due_at is null
$$;
revoke execute on function private.school_admin_count(uuid) from public;

-- Refusals: 42501, P0002 not_found, 55000 not_proposed or two_admins (the school's administrators confirm it).
create or replace function public.platform_confirm_payout_account(p_account uuid)
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
  if private.school_admin_count(v_account.school_id) > 1 then
    raise exception 'two_admins' using errcode = '55000';
  end if;
  perform private.confirm_payout_account(v_account, (select auth.uid()));
  perform private.write_platform_audit('payout_account.confirmed', v_account.school_id, 'payout_account', p_account);
end;
$$;

drop function public.platform_payment_alerts();
create function public.platform_payment_alerts()
returns table (kind text, id uuid, school_id uuid, school_name text, amount_xaf integer, status text, code text, at timestamptz, admins integer)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admins only' using errcode = '42501';
  end if;
  return query
  select x.kind, x.id, x.school_id, x.school_name, x.amount_xaf, x.status, x.code, x.at, private.school_admin_count(x.school_id)
  from (
    select 'payment'::text as kind, p.id, p.school_id, s.name as school_name, p.total_xaf as amount_xaf, p.status, p.failure_code as code, p.updated_at as at
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
  order by x.at desc
  limit 200;
end;
$$;
revoke execute on function public.platform_payment_alerts() from public, anon;
grant execute on function public.platform_payment_alerts() to authenticated;
