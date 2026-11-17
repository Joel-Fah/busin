-- Trips left running, in steps (owner, 2026-11-17). The portal already flags a running trip as overdue when its bus has
-- been silent for 30 minutes or it started more than 3 hours ago (private.trip_overdue_reason), and trips from an earlier
-- school day end by themselves (private.end_stale_trips); nobody on the trip was told. Now whoever runs it (the driver,
-- the assistant and whoever started it) gets a push with an End trip action when it becomes overdue, and a second one
-- an hour later if it still runs. Two at most; the end of the school day still ends it.

-- How many reminders each running trip got, and when the last one went.
create table private.trip_reminders (
  trip_id uuid primary key references public.trips (id) on delete cascade,
  sent smallint not null,
  last_sent_at timestamptz not null
);
revoke all on private.trip_reminders from public, anon, authenticated;

-- The kinds of notification, with this one. The list also names the payment kinds of ADR 0029 (built on its own branch),
-- so whichever of the two migrations runs last keeps both.
alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'subscription_revoked', 'subscription_restored', 'school_notice', 'bus_near_stop',
                  'crew_assigned', 'installment_paid', 'installment_rejected', 'installment_due', 'trip_still_running',
                  'payment_completed', 'payment_failed', 'refund_completed', 'refund_failed', 'refund_declined'));

-- Queues the reminders that are due: running trips overdue for being silent or long (not the ones from an earlier day,
-- which end by themselves), with fewer than two reminders and none in the last hour. Returns how many trips were
-- reminded.
create function private.remind_running_trips() returns integer
language plpgsql security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  with due as (
    select t.id
    from public.trips t
    left join private.trip_reminders r on r.trip_id = t.id
    where t.status = 'active'
      and private.trip_overdue_reason(t) in ('silent', 'long')
      and coalesce(r.sent, 0) < 2
      and (r.last_sent_at is null or r.last_sent_at < now() - interval '1 hour')
  ),
  marked as (
    insert into private.trip_reminders (trip_id, sent, last_sent_at)
    select d.id, 1, now() from due d
    on conflict (trip_id) do update set sent = private.trip_reminders.sent + 1, last_sent_at = now()
    returning trip_id
  ),
  queued as (
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    select distinct t.school_id, u.user_id, 'trip_still_running', t.id
    from marked m
    join public.trips t on t.id = m.trip_id
    cross join lateral (values (t.driver_id), (t.assistant_id), (t.started_by)) as u (user_id)
    where u.user_id is not null
    returning ref_id
  )
  select count(*) into v_count from marked;
  return v_count;
end;
$$;
revoke execute on function private.remind_running_trips() from public;

-- Every ten minutes.
select cron.schedule('busin-remind-running-trips', '*/10 * * * *', $$select private.remind_running_trips()$$);
