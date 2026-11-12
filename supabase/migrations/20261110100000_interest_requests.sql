-- Requests sent from the public landing page: a school asking to join, or a visitor asking to be told when the app is
-- out on Android or iOS. Not owned by any school (the sender is not a user yet), so the table has no school_id.
--
-- The table is closed: RLS is on and forced with no policies, and no client role has any privilege on it. The only way
-- in is public.submit_interest, which validates every field, ignores spam caught by a hidden field, and refuses floods
-- (per address and overall, per hour). The owner reads the rows in Supabase Studio until an inbox exists.

create table public.interest_requests (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('school', 'notify_android', 'notify_ios')),
  name text check (name is null or char_length(name) between 1 and 80),
  organisation text check (organisation is null or char_length(organisation) between 1 and 120),
  email text not null check (char_length(email) between 3 and 254),
  message text check (message is null or char_length(message) <= 1000),
  locale text not null default 'en' check (locale in ('en', 'fr')),
  created_at timestamptz not null default now()
);

create index interest_requests_email_created_idx on public.interest_requests (email, created_at desc);
create index interest_requests_created_idx on public.interest_requests (created_at desc);

alter table public.interest_requests enable row level security;
alter table public.interest_requests force row level security;
revoke all on public.interest_requests from public, anon, authenticated;

comment on table public.interest_requests is 'Requests from the public landing page (school wants to join, notify me on Android or iOS). Written only through submit_interest; read in Studio.';

-- Returns 'stored' or 'already' (the same address asked for the same thing in the last 30 days). A filled hidden field
-- returns 'stored' without storing, so a bot learns nothing. Errors: 22023 for an invalid field, 54000 for too many.
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

  if p_kind is null or p_kind not in ('school', 'notify_android', 'notify_ios') then
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

revoke all on function public.submit_interest(text, text, text, text, text, text, text) from public;
grant execute on function public.submit_interest(text, text, text, text, text, text, text) to anon, authenticated;

comment on function public.submit_interest(text, text, text, text, text, text, text) is 'The landing page form: validates, drops spam caught by the hidden field, caps per address and overall per hour, stores one row.';
