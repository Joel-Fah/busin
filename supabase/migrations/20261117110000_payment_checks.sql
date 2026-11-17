-- The payment reconciler (ADR 0029). Every two minutes, when a mobile money payment has been open for more than two
-- minutes, pg_cron calls the payments-reconcile Edge Function with a shared secret; it asks pawaPay each payment's
-- status and settles it. Like the push and deletion schedulers (ADR 0010, 0028): where the function lives and its
-- secret are project settings in Vault (payments_reconcile_url, payments_reconcile_secret); a project without them
-- (local development) does nothing.

create function private.dispatch_payment_checks()
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
revoke execute on function private.dispatch_payment_checks() from public;

select cron.schedule('busin-check-payments', '*/2 * * * *', $$select private.dispatch_payment_checks()$$);
