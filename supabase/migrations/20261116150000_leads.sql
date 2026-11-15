-- Leads from the landing page in the platform console (ADR 0027, slice 5): the requests of schools that want BusIn and of
-- people who asked to be told when the apps are out, until now read in Studio. Each gets a status (new, contacted,
-- converted, dismissed), a note and, once converted, the school it became. The people sent their email to be contacted,
-- so the console shows it.

alter table public.interest_requests
  add column status text not null default 'new' check (status in ('new', 'contacted', 'converted', 'dismissed')),
  add column handled_at timestamptz,
  add column note text check (note is null or char_length(note) <= 500),
  add column school_id uuid references public.schools (id) on delete set null;

create index interest_requests_kind_status_idx on public.interest_requests (kind, status, created_at desc);

-- One page of leads, newest first, with the total for the pager. Filters: kind ('school' or 'notify') and status.
create function public.platform_leads(p_kind text default null, p_status text default null, p_limit int default 20, p_offset int default 0)
returns table (
  id uuid, kind text, name text, organisation text, email text, message text, locale text, created_at timestamptz,
  status text, handled_at timestamptz, note text, school_id uuid, school_name text, total bigint
)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  return query
  select r.id, r.kind, r.name, r.organisation, r.email, r.message, r.locale, r.created_at,
         r.status, r.handled_at, r.note, r.school_id, s.name, count(*) over ()
  from public.interest_requests r
  left join public.schools s on s.id = r.school_id
  where (p_kind is null or r.kind = p_kind) and (p_status is null or r.status = p_status)
  order by r.created_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 100) offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

-- How many leads of each kind and status, for the tabs and "Needs you".
create function public.platform_lead_counts()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_object_agg(k, n) from (
      select r.kind || ':' || r.status as k, count(*) as n from public.interest_requests r group by r.kind, r.status
    ) x), '{}'::jsonb);
end;
$$;

-- One lead, for "create the school" from it (the form is prefilled from it).
create function public.platform_lead(p_lead_id uuid)
returns table (id uuid, kind text, name text, organisation text, email text, status text)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  return query select r.id, r.kind, r.name, r.organisation, r.email, r.status from public.interest_requests r where r.id = p_lead_id;
end;
$$;

-- Sets a lead's status and note (null keeps the note, '' clears it). Converted can name the school it became.
-- Refusals: 42501, P0002 no_lead, 22023 bad_status or note_too_long or no_school.
create function public.platform_update_lead(p_lead_id uuid, p_status text, p_note text default null, p_school_id uuid default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_note text := btrim(coalesce(p_note, ''));
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  if p_status is null or p_status not in ('new', 'contacted', 'converted', 'dismissed') then
    raise exception 'bad_status' using errcode = '22023';
  end if;
  if char_length(v_note) > 500 then
    raise exception 'note_too_long' using errcode = '22023';
  end if;
  if p_school_id is not null and not exists (select 1 from public.schools where id = p_school_id) then
    raise exception 'no_school' using errcode = '22023';
  end if;
  update public.interest_requests
  set status = p_status,
      handled_at = case when p_status = 'new' then null else now() end,
      note = case when p_note is null then note else nullif(v_note, '') end,
      school_id = case when p_status = 'converted' then coalesce(p_school_id, school_id) else school_id end
  where id = p_lead_id;
  if not found then
    raise exception 'no_lead' using errcode = 'P0002';
  end if;
  perform private.write_platform_audit('lead.' || p_status, p_school_id, 'lead', p_lead_id, '{}'::jsonb);
end;
$$;

revoke execute on function public.platform_leads(text, text, int, int), public.platform_lead_counts(), public.platform_lead(uuid),
  public.platform_update_lead(uuid, text, text, uuid) from public, anon;
grant execute on function public.platform_leads(text, text, int, int), public.platform_lead_counts(), public.platform_lead(uuid),
  public.platform_update_lead(uuid, text, text, uuid) to authenticated;
