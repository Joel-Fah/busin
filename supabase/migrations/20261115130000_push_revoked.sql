-- A student is told when their subscription is revoked, not only the next time they open the app (issue #386). Like the
-- other subscription notifications it carries the kind and the subscription id, never the reason: the app shows that.
-- Getting it back already sends one, as an approval.

alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'subscription_revoked', 'school_notice', 'bus_near_stop', 'crew_assigned'));

create or replace function private.notify_subscription_decision() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if (old.status = 'pending' and new.status in ('approved', 'rejected'))
     or (old.status = 'revoked' and new.status = 'approved')
     or (old.status = 'approved' and new.status = 'revoked') then
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    values (new.school_id, new.student_id, 'subscription_' || new.status::text, new.id);
  end if;
  return new;
end;
$$;
