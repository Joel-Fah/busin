-- A subscription the school gives back after revoking it is told as such ("restored"), no longer as a new approval.
-- Same rules as the other subscription notifications: the kind and the subscription id, never the reason.

alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'subscription_revoked', 'subscription_restored', 'school_notice', 'bus_near_stop', 'crew_assigned'));

create or replace function private.notify_subscription_decision() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_kind text;
begin
  if old.status = 'pending' and new.status in ('approved', 'rejected') then
    v_kind := 'subscription_' || new.status::text;
  elsif old.status = 'revoked' and new.status = 'approved' then
    v_kind := 'subscription_restored';
  elsif old.status = 'approved' and new.status = 'revoked' then
    v_kind := 'subscription_revoked';
  end if;
  if v_kind is not null then
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    values (new.school_id, new.student_id, v_kind, new.id);
  end if;
  return new;
end;
$$;
