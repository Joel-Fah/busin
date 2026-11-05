-- Push notifications: who to notify, what happened, and the functions the sender uses.
--
-- Design: docs/decisions/0010-push-notifications.md. In short:
--   * a phone registers its FCM token through register_device_token (a user never writes the table directly);
--   * a status change a student cares about writes one row to private.notification_outbox, in the same transaction;
--   * the send-push Edge Function (service role only) claims pending rows, sends them through FCM and reports back.
-- The outbox carries a kind and a reference id, never text or personal data. The sender builds the wording
-- in the language the phone registered with, so nothing personal passes through Firebase beyond the ids.

-- ---------------------------------------------------------------------------- device tokens

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  user_id uuid not null,
  token text not null check (char_length(token) between 20 and 4096),
  platform text not null check (platform in ('android', 'ios')),
  locale text not null default 'en' check (locale in ('en', 'fr')),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  foreign key (user_id, school_id) references public.profiles (id, school_id) on delete cascade,
  -- A token belongs to one phone installation, so to one user at a time.
  unique (token)
);
create index device_tokens_user_idx on public.device_tokens (user_id, last_seen_at desc);

alter table public.device_tokens enable row level security;
alter table public.device_tokens force row level security;

-- A user may see their own registrations (for a "signed in on these devices" screen later). Nothing else:
-- every change goes through the functions below, which also handle a phone changing hands.
grant select on public.device_tokens to authenticated;
create policy device_tokens_select on public.device_tokens for select to authenticated
  using (user_id = (select auth.uid()));

-- Register or refresh this phone's token for the signed-in user. If the same token was registered by someone
-- else (a shared or handed-over phone), it moves to the current user: a token follows the installation.
create function public.register_device_token(p_token text, p_platform text, p_locale text default 'en')
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
begin
  if v_uid is null or v_school is null then
    raise exception 'Sign in first' using errcode = '42501';
  end if;
  if (select status from public.profiles where id = v_uid) is distinct from 'verified' then
    raise exception 'Only a verified account can receive notifications' using errcode = '42501';
  end if;
  if p_token is null or char_length(p_token) not between 20 and 4096 then
    raise exception 'That does not look like a device token' using errcode = '22023';
  end if;
  if p_platform is null or p_platform not in ('android', 'ios') then
    raise exception 'The platform must be android or ios' using errcode = '22023';
  end if;
  if p_locale is null or p_locale not in ('en', 'fr') then
    raise exception 'The language must be en or fr' using errcode = '22023';
  end if;

  insert into public.device_tokens (school_id, user_id, token, platform, locale)
  values (v_school, v_uid, p_token, p_platform, p_locale)
  on conflict (token) do update
    set school_id = excluded.school_id,
        user_id = excluded.user_id,
        platform = excluded.platform,
        locale = excluded.locale,
        last_seen_at = now();

  -- Keep the ten most recently seen registrations per user, so reinstalls do not pile up.
  delete from public.device_tokens
  where user_id = v_uid
    and id in (
      select id from public.device_tokens
      where user_id = v_uid
      order by last_seen_at desc, created_at desc
      offset 10
    );
end;
$$;

-- Forget this phone's token, on sign-out. Only the owner's own registration is removed.
create function public.unregister_device_token(p_token text)
returns void
language sql security definer
set search_path = ''
as $$
  delete from public.device_tokens where token = p_token and user_id = (select auth.uid());
$$;

revoke execute on function public.register_device_token(text, text, text) from public, anon;
revoke execute on function public.unregister_device_token(text) from public, anon;
grant execute on function public.register_device_token(text, text, text) to authenticated;
grant execute on function public.unregister_device_token(text) to authenticated;

-- ---------------------------------------------------------------------------- outbox

create table private.notification_outbox (
  id bigint generated always as identity primary key,
  school_id uuid not null references public.schools (id),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('subscription_approved', 'subscription_rejected')),
  -- The record the notification is about (the subscription), for the app to open.
  ref_id uuid,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  attempts int not null default 0,
  last_error text check (char_length(last_error) <= 300)
);
alter table private.notification_outbox enable row level security;
alter table private.notification_outbox force row level security;
revoke all on private.notification_outbox from public, anon, authenticated;
create index notification_outbox_pending_idx on private.notification_outbox (id) where sent_at is null;

-- A decision on a subscription tells the student. Fires in the same transaction as the decision, so a
-- notification exists exactly when the decision does.
create function private.notify_subscription_decision() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if old.status = 'pending' and new.status in ('approved', 'rejected') then
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    values (new.school_id, new.student_id, 'subscription_' || new.status::text, new.id);
  end if;
  return new;
end;
$$;

create trigger subscriptions_notify_decision
  after update of status on public.subscriptions
  for each row execute function private.notify_subscription_decision();

-- ---------------------------------------------------------------------------- sender functions (service role only)

-- Take up to p_limit pending notifications, with the tokens to send each to. Rows are locked while claimed
-- and counted as an attempt, so two senders never send the same one and a failing one stops after five tries.
create function public.claim_notifications(p_limit int default 50)
returns table (id bigint, kind text, ref_id uuid, tokens jsonb)
language plpgsql security definer
set search_path = ''
as $$
begin
  return query
  with claimed as (
    select o.id
    from private.notification_outbox o
    where o.sent_at is null and o.attempts < 5
    order by o.id
    limit least(greatest(coalesce(p_limit, 50), 1), 200)
    for update skip locked
  ), bumped as (
    update private.notification_outbox o
    set attempts = o.attempts + 1
    from claimed c
    where o.id = c.id
    returning o.id, o.kind, o.ref_id, o.user_id
  )
  select b.id, b.kind, b.ref_id,
    coalesce(
      (select jsonb_agg(jsonb_build_object('token', t.token, 'platform', t.platform, 'locale', t.locale) order by t.last_seen_at desc)
       from public.device_tokens t where t.user_id = b.user_id),
      '[]'::jsonb
    )
  from bumped b
  order by b.id;
end;
$$;

-- Record the outcome. No error means it was sent (or there was nobody to send to).
create function public.complete_notification(p_id bigint, p_error text default null)
returns void
language sql security definer
set search_path = ''
as $$
  update private.notification_outbox
  set sent_at = case when p_error is null then now() else null end,
      last_error = left(p_error, 300)
  where id = p_id;
$$;

-- FCM says a token is dead (app uninstalled): forget it.
create function public.drop_device_token(p_token text)
returns void
language sql security definer
set search_path = ''
as $$
  delete from public.device_tokens where token = p_token;
$$;

revoke execute on function public.claim_notifications(int) from public, anon, authenticated;
revoke execute on function public.complete_notification(bigint, text) from public, anon, authenticated;
revoke execute on function public.drop_device_token(text) from public, anon, authenticated;
grant execute on function public.claim_notifications(int) to service_role;
grant execute on function public.complete_notification(bigint, text) to service_role;
grant execute on function public.drop_device_token(text) to service_role;
