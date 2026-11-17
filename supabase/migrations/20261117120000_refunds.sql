-- Refunds (ADR 0029, point 6). A student asks for one with a reason; the school's administrator approves it (all or part
-- of the school's price) or declines it with a reason; the school can also refund on its own. BusIn refunds in full,
-- fee included, a payment it could not apply (already in the payments migration). One refund per payment: pawaPay
-- refuses a second one for a deposit already refunded.
--
-- Money: approving takes the amount from the school's balance at once (from the payment's own credit while that is on
-- hold); when pawaPay completes it, what sending it cost is taken too (the school decided it). A refund that fails is
-- put back. A system refund that fails is set aside for the platform instead: that money is not the school's.

-- ---------------------------------------------------------------- one refund per payment
drop index public.refunds_one_open_per_payment;
create unique index refunds_one_per_payment on public.refunds (payment_id) where status not in ('declined', 'failed');

alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'subscription_revoked', 'subscription_restored', 'school_notice', 'bus_near_stop',
                  'crew_assigned', 'installment_paid', 'installment_rejected', 'installment_due', 'trip_still_running',
                  'payment_completed', 'payment_failed', 'refund_completed', 'refund_failed', 'refund_declined'));

-- (The list keeps 'trip_still_running' from the trip reminders built on dev, so whichever migration runs last keeps
-- both.)

-- Takes an approved refund's amount from the school's balance: from the payment's credit while it is on hold.
create function private.reserve_refund(p_refund public.refunds) returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.school_ledger (school_id, kind, amount_xaf, available_at, refund_id, payment_id)
  select p_refund.school_id, 'refund', -p_refund.amount_xaf, greatest(now(), coalesce(max(l.available_at), now())), p_refund.id, p_refund.payment_id
  from public.school_ledger l where l.payment_id = p_refund.payment_id and l.kind = 'payment';
end;
$$;
revoke execute on function private.reserve_refund(public.refunds) from public;

-- A completed payment that can still be refunded by the school or on a student's request: applied (not already being
-- refunded by BusIn), paid to the school (not BusIn's invoice), with no refund that is not declined or failed.
create function private.refundable(p_payment public.payments) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select p_payment.status = 'completed' and p_payment.outcome = 'applied' and p_payment.purpose in ('subscription', 'installment')
    and not exists (select 1 from public.refunds r where r.payment_id = p_payment.id and r.status not in ('declined', 'failed'))
$$;
revoke execute on function private.refundable(public.payments) from public;

-- ---------------------------------------------------------------- the student asks
-- Refusals: 42501 not a student, P0002 not their payment, 55000 not_refundable, 22023 reason_required, reason_too_short (under 10 characters) or reason_too_long.
create function public.request_refund(p_payment uuid, p_reason text)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_pay public.payments;
  v_reason text;
  v_id uuid;
begin
  if private.my_role() is distinct from 'student' then
    raise exception 'Students only' using errcode = '42501';
  end if;
  v_reason := private.clean_reason(p_reason, true);
  select * into v_pay from public.payments where id = p_payment and paid_by = v_uid and school_id = private.my_school_id() for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if not private.refundable(v_pay) then
    raise exception 'not_refundable' using errcode = '55000';
  end if;
  insert into public.refunds (school_id, payment_id, student_id, kind, reason, amount_xaf, status, requested_by)
  values (v_pay.school_id, v_pay.id, v_uid, 'student', v_reason, v_pay.amount_xaf, 'requested', v_uid)
  returning id into v_id;
  perform private.write_audit(v_pay.school_id, v_uid, 'refund.requested', 'payment', v_pay.id, jsonb_build_object('refund_id', v_id));
  return v_id;
end;
$$;
revoke execute on function public.request_refund(uuid, text) from public, anon;
grant execute on function public.request_refund(uuid, text) to authenticated;

-- ---------------------------------------------------------------- the school decides
-- Approves (all of the school's price, or part of it with p_amount) or declines (a reason is required). Refusals: 42501
-- not an administrator, P0002 not found, 55000 not_requested, 22023 bad_amount or a missing reason.
create function public.admin_decide_refund(p_refund uuid, p_approve boolean, p_amount integer default null, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_refund public.refunds;
  v_max integer;
  v_note text;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if p_approve is null then
    raise exception 'bad_decision' using errcode = '22023';
  end if;
  v_note := private.clean_reason(p_note, not p_approve);
  select * into v_refund from public.refunds where id = p_refund and school_id = v_school for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if v_refund.status <> 'requested' then
    raise exception 'not_requested' using errcode = '55000';
  end if;

  if not p_approve then
    update public.refunds
    set status = 'declined', decided_by = v_actor, decided_at = now(), decision_note = v_note, updated_at = now()
    where id = p_refund;
    insert into private.notification_outbox (school_id, user_id, kind, ref_id) values (v_school, v_refund.student_id, 'refund_declined', v_refund.payment_id);
    perform private.write_audit(v_school, v_actor, 'refund.declined', 'payment', v_refund.payment_id, jsonb_build_object('refund_id', p_refund));
    return;
  end if;

  select p.amount_xaf into v_max from public.payments p where p.id = v_refund.payment_id;
  if p_amount is not null and (p_amount < 1 or p_amount > v_max) then
    raise exception 'bad_amount' using errcode = '22023';
  end if;
  update public.refunds
  set status = 'queued', amount_xaf = coalesce(p_amount, v_max), decided_by = v_actor, decided_at = now(), decision_note = v_note, updated_at = now()
  where id = p_refund
  returning * into v_refund;
  perform private.reserve_refund(v_refund);
  perform private.write_audit(v_school, v_actor, 'refund.approved', 'payment', v_refund.payment_id,
    jsonb_build_object('refund_id', p_refund, 'amount', v_refund.amount_xaf));
end;
$$;
revoke execute on function public.admin_decide_refund(uuid, boolean, integer, text) from public, anon;
grant execute on function public.admin_decide_refund(uuid, boolean, integer, text) to authenticated;

-- The school refunds a payment on its own (for example when it revokes the subscription). Refusals as above, plus
-- 55000 not_refundable.
create function public.admin_refund_payment(p_payment uuid, p_amount integer, p_reason text)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_pay public.payments;
  v_reason text;
  v_refund public.refunds;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  v_reason := private.clean_reason(p_reason, true);
  select * into v_pay from public.payments where id = p_payment and school_id = v_school for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if not private.refundable(v_pay) then
    raise exception 'not_refundable' using errcode = '55000';
  end if;
  if p_amount is null or p_amount < 1 or p_amount > v_pay.amount_xaf then
    raise exception 'bad_amount' using errcode = '22023';
  end if;
  insert into public.refunds (school_id, payment_id, student_id, kind, reason, amount_xaf, status, requested_by, decided_by, decided_at)
  values (v_school, v_pay.id, v_pay.paid_by, 'school', v_reason, p_amount, 'queued', v_actor, v_actor, now())
  returning * into v_refund;
  perform private.reserve_refund(v_refund);
  perform private.write_audit(v_school, v_actor, 'refund.sent', 'payment', v_pay.id, jsonb_build_object('refund_id', v_refund.id, 'amount', p_amount));
  return v_refund.id;
end;
$$;
revoke execute on function public.admin_refund_payment(uuid, integer, text) from public, anon;
grant execute on function public.admin_refund_payment(uuid, integer, text) to authenticated;

-- ---------------------------------------------------------------- sending, and the result
-- What the reconciler does with refunds: send those queued, and ask pawaPay about those it has accepted for more than two
-- minutes. Each with its deposit (the payment) and amount.
create function public.refunds_to_send(p_limit integer default 50)
returns table (id uuid, payment_id uuid, total_xaf integer, currency text, action text)
language sql stable security definer
set search_path = ''
as $$
  select r.id, r.payment_id, r.total_xaf, p.currency, case when r.status = 'queued' then 'send' else 'check' end
  from public.refunds r
  join public.payments p on p.id = r.payment_id
  where r.status = 'queued'
     or (r.status in ('accepted', 'processing', 'in_reconciliation') and r.updated_at < now() - interval '2 minutes')
  order by r.updated_at
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
$$;
revoke execute on function public.refunds_to_send(integer) from public, anon, authenticated;
grant execute on function public.refunds_to_send(integer) to service_role;

-- Every result pawaPay gives for a refund, as for payments (settle_payment): applied once, final states do not change.
-- On completion the student gets a numbered receipt, the school pays what sending it cost (unless it was BusIn's
-- refund), and a refund of a request's whole price ends the subscription. A refund that fails is put back in the
-- school's balance; BusIn's own refund that fails is set aside for the platform.
create function public.settle_refund(
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
  v_refund public.refunds;
  v_pay public.payments;
  v_status text := upper(btrim(coalesce(p_status, '')));
  v_new text;
  v_cost integer;
begin
  select * into v_refund from public.refunds where id = p_id for update;
  if not found then
    return null;
  end if;
  if v_refund.status in ('completed', 'failed', 'declined', 'requested', 'needs_attention') then
    return jsonb_build_object('status', v_refund.status, 'changed', false);
  end if;
  select * into v_pay from public.payments where id = v_refund.payment_id;

  v_new := case v_status
    when 'ACCEPTED' then case when v_refund.status = 'queued' then 'accepted' end
    when 'DUPLICATE_IGNORED' then case when v_refund.status = 'queued' then 'accepted' end
    when 'PROCESSING' then 'processing'
    when 'IN_RECONCILIATION' then 'in_reconciliation'
    when 'COMPLETED' then 'completed'
    when 'FAILED' then 'failed'
    when 'REJECTED' then 'failed'
    -- Never sent yet: it stays queued. Sent, and unknown to pawaPay after 15 minutes: failed.
    when 'NOT_FOUND' then case when v_refund.status <> 'queued' and v_refund.updated_at < now() - interval '15 minutes' then 'failed' end
    else 'needs_attention'
  end;
  if v_new = 'completed' and (
       (p_amount is not null and (p_amount !~ '^[0-9]+(\.0+)?$' or p_amount::numeric <> v_refund.total_xaf))
       or (p_currency is not null and upper(p_currency) <> v_pay.currency)) then
    v_new := 'needs_attention';
  end if;
  -- BusIn's own refund is never put back in the school's balance: the platform looks at it.
  if v_new = 'failed' and v_refund.kind = 'system' then
    v_new := 'needs_attention';
  end if;
  if v_new is null or v_new = v_refund.status then
    return jsonb_build_object('status', v_refund.status, 'changed', false);
  end if;

  if v_new = 'completed' then
    update public.refunds
    set status = 'completed', completed_at = now(), updated_at = now(), failure_code = null,
        provider_txn = coalesce(left(p_provider_txn, 100), provider_txn),
        receipt_no = coalesce(receipt_no, private.next_receipt_no('BR'))
    where id = p_id
    returning * into v_refund;
    if v_refund.kind <> 'system' then
      v_cost := coalesce(private.transfer_cost(v_pay.provider, 'refund', v_refund.total_xaf), 0);
      if v_cost > 0 then
        insert into public.school_ledger (school_id, kind, amount_xaf, refund_id, payment_id)
        values (v_refund.school_id, 'refund_fee', -v_cost, v_refund.id, v_pay.id);
      end if;
    end if;
    -- The whole price of a request given back: the subscription ends.
    if v_pay.purpose = 'subscription' and v_refund.amount_xaf >= v_pay.amount_xaf then
      update public.subscriptions
      set status = 'revoked', review_note = 'Refunded (' || v_refund.receipt_no || ')', reviewed_by = null, reviewed_at = now()
      where id = v_pay.subscription_id and status = 'approved';
    end if;
    insert into private.notification_outbox (school_id, user_id, kind, ref_id) values (v_refund.school_id, v_refund.student_id, 'refund_completed', v_pay.id);
  elsif v_new = 'failed' then
    update public.refunds
    set status = 'failed', updated_at = now(), failure_code = left(coalesce(nullif(btrim(p_failure_code), ''), case when v_status = 'NOT_FOUND' then 'NOT_FOUND' else 'UNKNOWN' end), 64)
    where id = p_id;
    insert into public.school_ledger (school_id, kind, amount_xaf, available_at, refund_id, payment_id)
    select l.school_id, 'refund_reversal', -l.amount_xaf, now(), p_id, v_pay.id
    from public.school_ledger l where l.refund_id = p_id and l.kind = 'refund';
    insert into private.notification_outbox (school_id, user_id, kind, ref_id) values (v_refund.school_id, v_refund.student_id, 'refund_failed', v_pay.id);
  else
    update public.refunds
    set status = v_new, updated_at = now(),
        failure_code = case when v_new = 'needs_attention' then left(coalesce(nullif(btrim(p_failure_code), ''), nullif(v_status, ''), 'UNKNOWN'), 64) else failure_code end
    where id = p_id;
  end if;
  return jsonb_build_object('status', v_new, 'changed', true);
end;
$$;
revoke execute on function public.settle_refund(uuid, text, text, text, text, text) from public, anon, authenticated;
grant execute on function public.settle_refund(uuid, text, text, text, text, text) to service_role;

-- The reconciler is also called when a refund waits to be sent or checked.
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
