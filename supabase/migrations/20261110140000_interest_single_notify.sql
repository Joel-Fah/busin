-- One "tell me when the app is out" request instead of one per platform: it is the same message whichever phone the
-- visitor has. Earlier rows of either platform become 'notify'. The function is the same apart from the kinds it accepts.

alter table public.interest_requests drop constraint interest_requests_kind_check;
update public.interest_requests set kind = 'notify' where kind in ('notify_android', 'notify_ios');
alter table public.interest_requests add constraint interest_requests_kind_check check (kind in ('school', 'notify'));

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

  if p_kind is null or p_kind not in ('school', 'notify') then
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
