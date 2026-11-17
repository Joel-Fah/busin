-- Housekeeping (ADR 0010's promised follow-up): every night, small working tables lose the rows nobody needs any more,
-- so the database stays small on the free plan. Nothing a person or a school reads is touched: subscriptions, boardings,
-- trips and audit logs stay.
--
-- - Push notifications sent more than 30 days ago, and ones that failed (5 tries) more than 90 days ago.
-- - "Bus near my stop" markers older than 30 days (they only stop a second notice for the same trip).
-- - Place search and map directions counters older than 90 days (they only enforce limits and feed the Health page,
--   which shows this month and the last 30 days).

create function private.prune_old_rows()
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_sent int;
  v_failed int;
  v_near int;
  v_searches int;
  v_directions int;
begin
  delete from private.notification_outbox where sent_at < now() - interval '30 days';
  get diagnostics v_sent = row_count;
  delete from private.notification_outbox where sent_at is null and attempts >= 5 and created_at < now() - interval '90 days';
  get diagnostics v_failed = row_count;
  delete from private.bus_near_sent where sent_at < now() - interval '30 days';
  get diagnostics v_near = row_count;
  delete from private.place_search_usage where at < now() - interval '90 days';
  get diagnostics v_searches = row_count;
  delete from private.route_directions_usage where at < now() - interval '90 days';
  get diagnostics v_directions = row_count;
  return jsonb_build_object('push_sent', v_sent, 'push_failed', v_failed, 'bus_near', v_near, 'place_searches', v_searches, 'directions', v_directions);
end;
$$;
revoke execute on function private.prune_old_rows() from public;

select cron.schedule('busin-prune-old-rows', '10 3 * * *', $$select private.prune_old_rows()$$);
