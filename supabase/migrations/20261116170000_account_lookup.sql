-- Account lookup in the platform console (ADR 0027, slice 7): where one account stands, found by its exact email, for
-- support without SQL by hand. Read only. Each lookup is in the platform audit (the account found, never the email
-- typed), and a platform admin makes at most 30 lookups an hour, so the console cannot be used to browse people.

create function public.platform_lookup_account(p_email text)
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

revoke execute on function public.platform_lookup_account(text) from public, anon;
grant execute on function public.platform_lookup_account(text) to authenticated;
