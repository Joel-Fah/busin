-- Trips that end by themselves (owner, 2026-11-27, issue #575). Until now a trip left running got two reminders (an hour
-- apart) and then ran on until the school's midnight, with the phone still sharing. Now it also ends:
--   reminded   an hour after its second reminder, if it is still overdue (silent or long), field trips included;
--   at_campus  15 minutes after a trip going to school reached the campus (the crew was offered to end it on arrival).
-- The crew is told (trip_auto_ended) and the end is in the audit log, as the midnight safety net (end_stale_trips) does,
-- which stays. A phone still sharing stops by itself: its next position is refused as the trip is not running.

alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'subscription_revoked', 'subscription_restored', 'school_notice', 'bus_near_stop',
                  'crew_assigned', 'installment_paid', 'installment_rejected', 'installment_due', 'trip_still_running',
                  'payment_completed', 'payment_failed', 'refund_completed', 'refund_failed', 'refund_declined',
                  'trip_started', 'bus_at_stop', 'bus_left_stop', 'bus_at_campus', 'trip_at_campus', 'trip_auto_ended'));

-- How long after the second reminder, and how long at the campus, before the trip ends.
create function private.auto_end_after_reminders() returns interval language sql immutable as $$ select interval '1 hour' $$;
create function private.auto_end_at_campus() returns interval language sql immutable as $$ select interval '15 minutes' $$;
revoke execute on function private.auto_end_after_reminders(), private.auto_end_at_campus() from public;

-- Ends the running trips that are due, tells their crew and records why. Returns how many it ended.
create function private.end_overdue_trips() returns integer
language plpgsql security definer
set search_path = ''
as $$
declare
  v_due record;
  v_trip public.trips;
  v_count integer := 0;
begin
  for v_due in
    -- One reason per trip: the campus first (it is the expected end of a trip to school).
    select distinct on (d.id) d.id, d.reason
    from (
      select t.id, 'at_campus' as reason, 1 as rank
      from public.trips t
      join private.trip_campus_arrivals a on a.trip_id = t.id
      where t.status = 'active' and t.direction = 'inbound' and a.arrived_at <= now() - private.auto_end_at_campus()
      union all
      select t.id, 'reminded', 2
      from public.trips t
      join private.trip_reminders r on r.trip_id = t.id
      where t.status = 'active' and r.sent >= 2 and r.last_sent_at <= now() - private.auto_end_after_reminders()
        and private.trip_overdue_reason(t) in ('silent', 'long')
    ) d
    order by d.id, d.rank
  loop
    update public.trips t set status = 'completed', ended_at = now()
    where t.id = v_due.id and t.status = 'active'
    returning * into v_trip;
    if not found then
      continue;
    end if;
    perform private.write_audit(v_trip.school_id, null, 'trip.auto_ended', 'trip', v_trip.id, jsonb_build_object('reason', v_due.reason));
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    select distinct v_trip.school_id, u.user_id, 'trip_auto_ended', v_trip.id
    from (values (v_trip.driver_id), (v_trip.assistant_id), (v_trip.started_by)) as u (user_id)
    where u.user_id is not null;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;
revoke execute on function private.end_overdue_trips() from public;

-- Every ten minutes, a few minutes after the reminders.
select cron.schedule('busin-end-overdue-trips', '3-59/10 * * * *', $$select private.end_overdue_trips()$$);
