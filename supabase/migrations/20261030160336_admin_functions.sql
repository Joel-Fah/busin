-- Privileged actions as functions. Clients cannot write these fields directly
-- (see the grants in the row level security migration), so every change here
-- is authorized against the live profile and recorded in the audit log.

create function private.write_audit(
  p_school uuid,
  p_actor uuid,
  p_action text,
  p_target_type text,
  p_target uuid,
  p_details jsonb default '{}'::jsonb
) returns void
language sql security definer
set search_path = ''
as $$
  insert into public.audit_log (school_id, actor_id, action, target_type, target_id, details)
  values (p_school, p_actor, p_action, p_target_type, p_target, coalesce(p_details, '{}'::jsonb))
$$;
revoke execute on function private.write_audit(uuid, uuid, text, text, uuid, jsonb) from public;

-- Approve or reject a pending subscription.
create function public.admin_review_subscription(
  p_subscription_id uuid,
  p_decision text,
  p_note text default null
) returns void
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
  if p_decision is null or p_decision not in ('approved', 'rejected') then
    raise exception 'Decision must be approved or rejected' using errcode = '22023';
  end if;
  if p_decision = 'rejected' and v_note is null then
    raise exception 'A reason is required to reject a subscription' using errcode = '22023';
  end if;
  if v_note is not null and char_length(v_note) > 500 then
    raise exception 'The note is too long (500 characters at most)' using errcode = '22023';
  end if;

  select * into v_sub
  from public.subscriptions
  where id = p_subscription_id and school_id = v_school
  for update;
  if not found then
    raise exception 'Subscription not found' using errcode = 'P0002';
  end if;
  if v_sub.status <> 'pending' then
    raise exception 'Only pending subscriptions can be reviewed' using errcode = '55000';
  end if;

  update public.subscriptions
  set status = p_decision::public.subscription_status,
      review_note = v_note,
      reviewed_by = v_actor,
      reviewed_at = now()
  where id = p_subscription_id;

  perform private.write_audit(
    v_school, v_actor, 'subscription.' || p_decision, 'subscription', p_subscription_id,
    jsonb_build_object('student_id', v_sub.student_id)
  );
end;
$$;

-- Change a user's role. Admins cannot change their own role, so a school always keeps an admin.
create function public.admin_set_user_role(p_user_id uuid, p_role public.user_role)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_old public.user_role;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if p_user_id = v_actor then
    raise exception 'You cannot change your own role' using errcode = '42501';
  end if;
  if p_role is null then
    raise exception 'A role is required' using errcode = '22023';
  end if;

  select role into v_old
  from public.profiles
  where id = p_user_id and school_id = v_school
  for update;
  if not found then
    raise exception 'User not found' using errcode = 'P0002';
  end if;

  update public.profiles set role = p_role where id = p_user_id;

  perform private.write_audit(
    v_school, v_actor, 'user.role_changed', 'profile', p_user_id,
    jsonb_build_object('from', v_old, 'to', p_role)
  );
end;
$$;

-- Suspend, restore or mark a user pending. Admins cannot change their own status.
create function public.admin_set_user_status(p_user_id uuid, p_status public.account_status)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_old public.account_status;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if p_user_id = v_actor then
    raise exception 'You cannot change your own status' using errcode = '42501';
  end if;
  if p_status is null then
    raise exception 'A status is required' using errcode = '22023';
  end if;

  select status into v_old
  from public.profiles
  where id = p_user_id and school_id = v_school
  for update;
  if not found then
    raise exception 'User not found' using errcode = 'P0002';
  end if;

  update public.profiles set status = p_status where id = p_user_id;

  perform private.write_audit(
    v_school, v_actor, 'user.status_changed', 'profile', p_user_id,
    jsonb_build_object('from', v_old, 'to', p_status)
  );
end;
$$;

revoke execute on function
  public.admin_review_subscription(uuid, text, text),
  public.admin_set_user_role(uuid, public.user_role),
  public.admin_set_user_status(uuid, public.account_status)
  from public, anon;
grant execute on function
  public.admin_review_subscription(uuid, text, text),
  public.admin_set_user_role(uuid, public.user_role),
  public.admin_set_user_status(uuid, public.account_status)
  to authenticated;
