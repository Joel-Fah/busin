-- Account deletion (ADR 0028, owner's decisions of 2026-11-16).
--
-- A person asks to delete their account from any app (or the platform schedules it for someone who lost access). It
-- happens 7 days later unless they cancel. Then a nightly job erases what identifies them: their name, email, phone,
-- picture, matricule, home area, devices, preferences, requests and their payment proof files. The school keeps its
-- records without a name (subscriptions and payments, boardings, trips they drove, the audit log), so its accounting and
-- statistics stay right. The profile stays as an empty "Deleted account" row those records point to, and the sign-in
-- account is soft-deleted (Supabase keeps a hashed id only), so the same Google account can start afresh later.

alter table public.profiles
  add column deletion_requested_at timestamptz,
  add column deletion_due_at timestamptz,
  add column deletion_by text check (deletion_by in ('self', 'platform')),
  add column deleted_at timestamptz,
  add constraint profiles_deletion_pair check ((deletion_requested_at is null) = (deletion_due_at is null));

create index profiles_deletion_due_idx on public.profiles (deletion_due_at) where deletion_due_at is not null;

comment on column public.profiles.deleted_at is 'When the account was erased (ADR 0028). The row stays, empty, so the school''s records keep pointing to it.';

-- Why a deletion cannot start now: the last administrator of a school (hand it over first), or someone on a running
-- trip (finish it first). Null when it can.
create function private.deletion_blocker(p_user uuid)
returns text
language sql stable security definer
set search_path = ''
as $$
  select case
    when exists (select 1 from public.profiles p where p.id = p_user and p.role = 'admin' and p.status = 'verified'
                 and p.school_id is not null
                 and not exists (select 1 from public.profiles a where a.school_id = p.school_id and a.role = 'admin'
                                 and a.status = 'verified' and a.id <> p.id and a.deletion_due_at is null)) then 'last_admin'
    when exists (select 1 from public.trips t where t.status = 'active' and (t.driver_id = p_user or t.assistant_id = p_user)) then 'active_trip'
  end;
$$;
revoke execute on function private.deletion_blocker(uuid) from public;

-- The caller's own deletion: null when none is scheduled.
create function public.my_account_deletion()
returns table (requested_at timestamptz, due_at timestamptz, requested_by text)
language sql stable security definer
set search_path = ''
as $$
  select p.deletion_requested_at, p.deletion_due_at, p.deletion_by
  from public.profiles p where p.id = (select auth.uid()) and p.deletion_due_at is not null;
$$;

-- Schedules the caller's deletion in 7 days. Refusals: 42501 not signed in, 55000 last_admin or active_trip.
-- Asking again keeps the first date.
create function public.request_account_deletion()
returns timestamptz
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_profile public.profiles;
  v_blocker text;
begin
  select * into v_profile from public.profiles where id = v_uid and deleted_at is null for update;
  if not found then
    raise exception 'not_signed_in' using errcode = '42501';
  end if;
  if v_profile.deletion_due_at is not null then
    return v_profile.deletion_due_at;
  end if;
  v_blocker := private.deletion_blocker(v_uid);
  if v_blocker is not null then
    raise exception '%', v_blocker using errcode = '55000';
  end if;
  update public.profiles
  set deletion_requested_at = now(), deletion_due_at = now() + interval '7 days', deletion_by = 'self'
  where id = v_uid
  returning deletion_due_at into v_profile.deletion_due_at;
  if v_profile.school_id is not null then
    perform private.write_audit(v_profile.school_id, v_uid, 'account.deletion_requested', 'profile', v_uid, '{}'::jsonb);
  end if;
  return v_profile.deletion_due_at;
end;
$$;

-- Cancels the caller's scheduled deletion (any time before it happens).
create function public.cancel_account_deletion()
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid;
begin
  update public.profiles set deletion_requested_at = null, deletion_due_at = null, deletion_by = null
  where id = v_uid and deletion_due_at is not null and deleted_at is null
  returning school_id into v_school;
  if found and v_school is not null then
    perform private.write_audit(v_school, v_uid, 'account.deletion_cancelled', 'profile', v_uid, '{}'::jsonb);
  end if;
end;
$$;

-- The platform schedules (or cancels) the deletion of someone who cannot sign in any more, after confirming with them.
-- Same guards and the same 7 days. Refusals: 42501, P0002 no_account, 55000 last_admin or active_trip.
create function public.platform_schedule_deletion(p_user_id uuid, p_schedule boolean)
returns timestamptz
language plpgsql security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
  v_blocker text;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  select * into v_profile from public.profiles where id = p_user_id and deleted_at is null for update;
  if not found then
    raise exception 'no_account' using errcode = 'P0002';
  end if;
  if not coalesce(p_schedule, false) then
    update public.profiles set deletion_requested_at = null, deletion_due_at = null, deletion_by = null where id = p_user_id;
    perform private.write_platform_audit('account.deletion_cancelled', v_profile.school_id, 'profile', p_user_id, '{}'::jsonb);
    return null;
  end if;
  if v_profile.deletion_due_at is not null then
    return v_profile.deletion_due_at;
  end if;
  v_blocker := private.deletion_blocker(p_user_id);
  if v_blocker is not null then
    raise exception '%', v_blocker using errcode = '55000';
  end if;
  update public.profiles
  set deletion_requested_at = now(), deletion_due_at = now() + interval '7 days', deletion_by = 'platform'
  where id = p_user_id
  returning deletion_due_at into v_profile.deletion_due_at;
  perform private.write_platform_audit('account.deletion_scheduled', v_profile.school_id, 'profile', p_user_id, '{}'::jsonb);
  return v_profile.deletion_due_at;
end;
$$;

-- ---------------------------------------------------------------- the nightly erasure (service role only)
-- The accounts due now, each with its payment proof files (proofs/{school}/{user}/...), at most 50 a run. The Edge
-- Function deletes the files through the Storage API, then calls erase_account, then soft-deletes the sign-in account.
-- A deletion whose blocker appeared since (became the last admin, started a trip) waits for the next run.
create function public.due_account_deletions()
returns table (user_id uuid, files text[])
language sql stable security definer
set search_path = ''
as $$
  select p.id,
         coalesce((select array_agg(o.name) from storage.objects o
                   where o.bucket_id = 'proofs' and split_part(o.name, '/', 2) = p.id::text), '{}')
  from public.profiles p
  where p.deletion_due_at <= now() and p.deleted_at is null and private.deletion_blocker(p.id) is null
  order by p.deletion_due_at
  limit 50;
$$;

-- Erases what identifies a person and keeps the school's records under an empty profile. Idempotent.
create function public.erase_account(p_user_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
begin
  select * into v_profile from public.profiles where id = p_user_id for update;
  if not found or v_profile.deleted_at is not null then
    return;
  end if;

  delete from public.student_areas where user_id = p_user_id;
  delete from public.device_tokens where user_id = p_user_id;
  delete from public.notification_preferences where user_id = p_user_id;
  delete from private.qr_secrets where student_id = p_user_id;
  delete from private.bus_near_sent where user_id = p_user_id;
  delete from private.notification_outbox where user_id = p_user_id;
  delete from private.place_search_usage where user_id = p_user_id;
  delete from public.trip_position_leases where holder = p_user_id;
  delete from public.staff_invites where email = v_profile.email;
  delete from private.platform_admins where user_id = p_user_id;
  -- The proof files are gone (deleted through Storage first): the records no longer point to them.
  update public.subscriptions set proof_path = null where student_id = p_user_id and proof_path is not null;
  update public.installment_receipts set proof_path = null where student_id = p_user_id and proof_path is not null;

  update public.profiles
  set full_name = 'Deleted account', email = 'deleted-' || p_user_id || '@deleted.invalid', avatar_url = null, phone = null,
      matricule = null, department = null, program = null, status = 'suspended',
      join_requested_at = null, join_declined_at = null, join_declined_school = null, join_decline_note = null,
      staff_requested_at = null, staff_request_school = null, staff_declined_at = null, staff_declined_school = null,
      staff_decline_note = null, deletion_requested_at = null, deletion_due_at = null, deleted_at = now()
  where id = p_user_id;

  if v_profile.school_id is not null then
    perform private.write_audit(v_profile.school_id, null, 'account.erased', 'profile', p_user_id,
      jsonb_build_object('by', coalesce(v_profile.deletion_by, 'self')));
  end if;
end;
$$;

-- Calls the delete-accounts Edge Function at night when something is due. Like the push scheduler (ADR 0010): where the
-- function lives and its secret are project settings in Vault (deletions_url, deletions_secret); a project without
-- them (local development) does nothing, and `npm run dev:erase` runs the same steps by hand.
create function private.dispatch_deletions()
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'deletions_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'deletions_secret';
  if coalesce(v_url, '') = '' or coalesce(v_secret, '') = '' then
    return;
  end if;
  if not exists (select 1 from public.profiles where deletion_due_at <= now() and deleted_at is null) then
    return;
  end if;
  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-deletions-secret', v_secret),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
end;
$$;
revoke execute on function private.dispatch_deletions() from public;

select cron.schedule('busin-erase-accounts', '40 2 * * *', $$select private.dispatch_deletions()$$);

revoke execute on function public.my_account_deletion(), public.request_account_deletion(), public.cancel_account_deletion(),
  public.platform_schedule_deletion(uuid, boolean) from public, anon;
grant execute on function public.my_account_deletion(), public.request_account_deletion(), public.cancel_account_deletion(),
  public.platform_schedule_deletion(uuid, boolean) to authenticated;
revoke execute on function public.due_account_deletions(), public.erase_account(uuid) from public, anon, authenticated;
grant execute on function public.due_account_deletions(), public.erase_account(uuid) to service_role;

-- ---------------------------------------------------------------- asking without being able to sign in
-- The public deletion page (/delete-account) lets someone who lost access ask by email: a 'deletion' lead the platform
-- confirms with them by email before scheduling it from Lookup. Same checks and limits as the landing's other requests.
alter table public.interest_requests drop constraint interest_requests_kind_check;
alter table public.interest_requests add constraint interest_requests_kind_check check (kind in ('school', 'notify', 'deletion'));

create or replace function public.submit_interest(
  p_kind text,
  p_email text,
  p_name text default null,
  p_organisation text default null,
  p_message text default null,
  p_locale text default 'en',
  p_trap text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_name text := nullif(btrim(coalesce(p_name, '')), '');
  v_org text := nullif(btrim(coalesce(p_organisation, '')), '');
  v_message text := nullif(btrim(coalesce(p_message, '')), '');
  v_locale text := coalesce(nullif(btrim(p_locale), ''), 'en');
begin
  if nullif(btrim(coalesce(p_trap, '')), '') is not null then
    return 'stored';
  end if;

  if p_kind is null or p_kind not in ('school', 'notify', 'deletion') then
    raise exception 'Unknown request kind' using errcode = '22023';
  end if;
  if char_length(v_email) > 254 or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]{2,}$' then
    raise exception 'Invalid email' using errcode = '22023';
  end if;
  if v_name is not null and char_length(v_name) > 80 then
    raise exception 'Name too long' using errcode = '22023';
  end if;
  if v_org is not null and char_length(v_org) > 120 then
    raise exception 'Organisation too long' using errcode = '22023';
  end if;
  if v_message is not null and char_length(v_message) > 1000 then
    raise exception 'Message too long' using errcode = '22023';
  end if;
  if p_kind = 'school' and (v_name is null or v_org is null) then
    raise exception 'A school request needs a name and a school' using errcode = '22023';
  end if;
  if v_locale not in ('en', 'fr') then
    v_locale := 'en';
  end if;

  if (select count(*) from public.interest_requests where email = v_email and created_at > now() - interval '1 hour') >= 3 then
    raise exception 'Too many requests' using errcode = '54000';
  end if;
  if (select count(*) from public.interest_requests where created_at > now() - interval '1 hour') >= 200 then
    raise exception 'Too many requests' using errcode = '54000';
  end if;

  if exists (
    select 1 from public.interest_requests
    where email = v_email and kind = p_kind and created_at > now() - interval '30 days'
  ) then
    return 'already';
  end if;

  insert into public.interest_requests (kind, name, organisation, email, message, locale)
  values (p_kind, v_name, v_org, v_email, v_message, v_locale);
  return 'stored';
end;
$$;

-- Lookup shows a scheduled deletion (and who asked for it).
create or replace function public.platform_lookup_account(p_email text)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_profile public.profiles;
  v_user auth.users;
  v_invite public.staff_invites;
  v_result jsonb;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' or char_length(v_email) > 254 then
    raise exception 'invalid_email' using errcode = '22023';
  end if;
  if (select count(*) from public.platform_audit a
      where a.actor_id = v_actor and a.action = 'account.lookup' and a.created_at > now() - interval '1 hour') >= 30 then
    raise exception 'too_many' using errcode = '54000';
  end if;

  select * into v_profile from public.profiles where email = v_email;
  select * into v_invite from public.staff_invites where email = v_email and expires_at > now();

  if v_profile.id is not null then
    select * into v_user from auth.users where id = v_profile.id;
    v_result := jsonb_build_object(
      'found', true,
      'id', v_profile.id,
      'email', v_profile.email,
      'full_name', v_profile.full_name,
      'avatar_url', v_profile.avatar_url,
      'role', v_profile.role,
      'status', v_profile.status,
      'school_id', v_profile.school_id,
      'school_name', (select s.name from public.schools s where s.id = v_profile.school_id),
      'created_at', v_profile.created_at,
      'last_sign_in_at', v_user.last_sign_in_at,
      'provider', v_user.raw_app_meta_data ->> 'provider',
      'join_requested_at', v_profile.join_requested_at,
      'join_declined_at', v_profile.join_declined_at,
      'staff_requested_at', v_profile.staff_requested_at,
      'staff_request_school', (select s.name from public.schools s where s.id = v_profile.staff_request_school),
      'staff_declined_at', v_profile.staff_declined_at,
      'deletion_due_at', v_profile.deletion_due_at,
      'deletion_by', v_profile.deletion_by,
      'platform_admin', exists (select 1 from private.platform_admins a where a.user_id = v_profile.id),
      'subscriptions', coalesce((
        select jsonb_object_agg(x.status, x.n) from (
          select s.status, count(*) as n from public.subscriptions s where s.student_id = v_profile.id group by s.status
        ) x), '{}'::jsonb),
      'devices', (select count(*) from public.device_tokens t where t.user_id = v_profile.id)
    );
  else
    v_result := jsonb_build_object('found', false);
  end if;

  if v_invite.email is not null then
    v_result := v_result || jsonb_build_object('invite', jsonb_build_object(
      'school_id', v_invite.school_id,
      'school_name', (select s.name from public.schools s where s.id = v_invite.school_id),
      'role', v_invite.role,
      'expires_at', v_invite.expires_at));
  end if;

  perform private.write_platform_audit('account.lookup', v_profile.school_id, case when v_profile.id is null then null else 'profile' end, v_profile.id,
    jsonb_build_object('found', v_profile.id is not null));
  return v_result;
end;
$$;
