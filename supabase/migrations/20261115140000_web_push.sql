-- Push on the web (ADR 0021): the student web app registers its browser's FCM token with the platform 'web', and the
-- sender gives web tokens a webpush message (supabase/functions/_shared/push.ts). Nothing else changes: the same rules
-- (verified accounts only, ten registrations a person, a token follows its device).

alter table public.device_tokens drop constraint device_tokens_platform_check;
alter table public.device_tokens add constraint device_tokens_platform_check check (platform in ('android', 'ios', 'web'));

create or replace function public.register_device_token(p_token text, p_platform text, p_locale text default 'en')
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
  if p_platform is null or p_platform not in ('android', 'ios', 'web') then
    raise exception 'The platform must be android, ios or web' using errcode = '22023';
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
