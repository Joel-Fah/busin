-- Revoking an approved subscription: an admin ends it early, with a reason the student can read. The student's boarding
-- code stops being accepted at the next scan (scans check for an approved subscription every time), and they may ask
-- again. A new status keeps it apart from "rejected" (never approved) and "expired" (ran its course).
alter type public.subscription_status add value if not exists 'revoked';

create function public.admin_revoke_subscription(p_subscription_id uuid, p_note text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_sub public.subscriptions;
  v_note text := nullif(btrim(p_note), '');
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if v_note is null then
    raise exception 'A reason is required to revoke a subscription' using errcode = '22023';
  end if;
  if char_length(v_note) > 500 then
    raise exception 'The note is too long (500 characters at most)' using errcode = '22023';
  end if;

  select * into v_sub
  from public.subscriptions
  where id = p_subscription_id and school_id = v_school
  for update;
  if not found then
    raise exception 'Subscription not found' using errcode = 'P0002';
  end if;
  if v_sub.status <> 'approved' then
    raise exception 'Only approved subscriptions can be revoked' using errcode = '55000';
  end if;

  update public.subscriptions
  set status = 'revoked',
      review_note = v_note,
      reviewed_by = v_actor,
      reviewed_at = now()
  where id = p_subscription_id;

  perform private.write_audit(
    v_school, v_actor, 'subscription.revoked', 'subscription', p_subscription_id,
    jsonb_build_object('student_id', v_sub.student_id, 'approved_by', v_sub.reviewed_by)
  );
end;
$$;

revoke execute on function public.admin_revoke_subscription(uuid, text) from public, anon;
grant execute on function public.admin_revoke_subscription(uuid, text) to authenticated;
