-- Sending the push notifications (ADR 0010, option A).
--
-- Every minute the database calls the send-push Edge Function, which drains the outbox. Where the function lives and the
-- shared secret it checks are project settings, not code: they are read from Vault (names push_url and push_secret), so
-- this migration is the same for every project. A project without them (local development) does nothing: no call is
-- made and nothing fails. The call is fire and forget through pg_net; the function itself claims rows so two calls never
-- send the same notification.

create extension if not exists pg_net;

create or replace function private.dispatch_push()
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'push_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'push_secret';
  if coalesce(v_url, '') = '' or coalesce(v_secret, '') = '' then
    return;
  end if;
  -- Nothing to send: no call at all, so an idle school costs nothing.
  if not exists (select 1 from private.notification_outbox where sent_at is null and attempts < 5) then
    return;
  end if;
  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', v_secret),
    body := '{}'::jsonb,
    timeout_milliseconds := 20000
  );
end;
$$;
revoke execute on function private.dispatch_push() from public;

select cron.schedule('busin-send-push', '* * * * *', $$select private.dispatch_push()$$);
