-- Reaching out to a school from the platform console (ADR 0027, slice 3): the school's contacts (each view audited), an
-- in-portal notice its administrators see and can dismiss, and an outreach log with snooze and follow-ups, so a school
-- is not reminded twice for the same thing and the platform sees whether it helped.

-- ---------------------------------------------------------------- notices in a school's portal
create table public.school_notices (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 600),
  -- A page of the school portal the notice leads to (for example /subscriptions), never another site (no "//host").
  link_path text check (link_path is null or (char_length(link_path) <= 80 and link_path ~ '^/([a-z0-9?=&-][a-z0-9/?=&-]*)?$')),
  signals text[] not null default '{}',
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users (id),
  expires_at timestamptz not null default now() + interval '30 days',
  dismissed_at timestamptz,
  dismissed_by uuid references public.profiles (id) on delete set null
);
create index school_notices_school_idx on public.school_notices (school_id, created_at desc) where dismissed_at is null;
alter table public.school_notices enable row level security;
alter table public.school_notices force row level security;
revoke all on public.school_notices from public, anon, authenticated;
-- A school's administrators read their own school's notices; nobody writes them directly.
grant select (id, school_id, body, link_path, created_at, expires_at, dismissed_at) on public.school_notices to authenticated;
create policy school_notices_admin_read on public.school_notices for select to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

comment on table public.school_notices is 'Reminders from the BusIn platform to a school''s administrators (ADR 0027). Written only by platform_send_notice.';

-- An administrator of the school dismisses a notice (it stays in the platform''s log).
create function public.dismiss_school_notice(p_notice_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  update public.school_notices
  set dismissed_at = now(), dismissed_by = (select auth.uid())
  where id = p_notice_id and school_id = private.my_school_id() and dismissed_at is null;
  if not found then
    raise exception 'no_notice' using errcode = 'P0002';
  end if;
end;
$$;
revoke execute on function public.dismiss_school_notice(uuid) from public, anon;
grant execute on function public.dismiss_school_notice(uuid) to authenticated;

-- ---------------------------------------------------------------- the outreach log
create table public.platform_outreach (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  signals text[] not null default '{}',
  channel text not null check (channel in ('email', 'whatsapp', 'call', 'notice', 'meeting', 'other')),
  note text check (note is null or char_length(note) <= 1000),
  -- Until then the signals are marked as handled, so the school is not reminded again for them.
  snooze_until date,
  follow_up_on date,
  follow_up_done_at timestamptz,
  notice_id uuid references public.school_notices (id) on delete set null,
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users (id)
);
create index platform_outreach_school_idx on public.platform_outreach (school_id, created_at desc);
create index platform_outreach_follow_up_idx on public.platform_outreach (follow_up_on) where follow_up_done_at is null and follow_up_on is not null;
alter table public.platform_outreach enable row level security;
alter table public.platform_outreach force row level security;
revoke all on public.platform_outreach from public, anon, authenticated;

comment on table public.platform_outreach is 'Each contact the platform made with a school, about which signals (ADR 0027). Read only through platform functions.';

-- Only signals the console knows, without repeats.
create function private.clean_signals(p_signals text[])
returns text[]
language sql stable security definer
set search_path = ''
as $$
  select coalesce(array_agg(distinct s order by s), '{}')
  from unnest(coalesce(p_signals, '{}')) s
  where s in (select r.signal from private.health_rules r);
$$;
revoke execute on function private.clean_signals(text[]) from public;

-- Records one contact. Refusals: 42501 not a platform admin, P0002 unknown school, 22023 bad channel, note, snooze or date.
create function public.platform_log_outreach(
  p_school_id uuid,
  p_channel text,
  p_signals text[] default '{}',
  p_note text default null,
  p_snooze_days int default 0,
  p_follow_up_on date default null
) returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.schools where id = p_school_id) then
    raise exception 'no_school' using errcode = 'P0002';
  end if;
  if p_channel is null or p_channel not in ('email', 'whatsapp', 'call', 'notice', 'meeting', 'other') then
    raise exception 'bad_channel' using errcode = '22023';
  end if;
  if v_note is not null and char_length(v_note) > 1000 then
    raise exception 'note_too_long' using errcode = '22023';
  end if;
  if coalesce(p_snooze_days, 0) not between 0 and 60 then
    raise exception 'bad_snooze' using errcode = '22023';
  end if;
  if p_follow_up_on is not null and (p_follow_up_on < current_date or p_follow_up_on > current_date + 180) then
    raise exception 'bad_follow_up' using errcode = '22023';
  end if;

  insert into public.platform_outreach (school_id, signals, channel, note, snooze_until, follow_up_on, created_by)
  values (p_school_id, private.clean_signals(p_signals), p_channel, v_note,
          case when coalesce(p_snooze_days, 0) > 0 then current_date + p_snooze_days end, p_follow_up_on, (select auth.uid()))
  returning id into v_id;
  perform private.write_platform_audit('outreach.logged', p_school_id, 'outreach', v_id,
    jsonb_build_object('channel', p_channel, 'signals', private.clean_signals(p_signals)));
  return v_id;
end;
$$;

-- Sends a notice to the school's administrators and logs it as an outreach (channel "notice").
create function public.platform_send_notice(
  p_school_id uuid,
  p_body text,
  p_link_path text default null,
  p_signals text[] default '{}',
  p_snooze_days int default 7,
  p_follow_up_on date default null
) returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_body text := btrim(coalesce(p_body, ''));
  v_notice uuid;
  v_outreach uuid;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.schools where id = p_school_id and status = 'active') then
    raise exception 'no_school' using errcode = 'P0002';
  end if;
  if char_length(v_body) not between 1 and 600 then
    raise exception 'bad_body' using errcode = '22023';
  end if;
  if p_link_path is not null and (char_length(p_link_path) > 80 or p_link_path !~ '^/([a-z0-9?=&-][a-z0-9/?=&-]*)?$') then
    raise exception 'bad_link' using errcode = '22023';
  end if;

  insert into public.school_notices (school_id, body, link_path, signals, created_by)
  values (p_school_id, v_body, p_link_path, private.clean_signals(p_signals), (select auth.uid()))
  returning id into v_notice;
  v_outreach := public.platform_log_outreach(p_school_id, 'notice', p_signals, v_body, p_snooze_days, p_follow_up_on);
  update public.platform_outreach set notice_id = v_notice where id = v_outreach;
  return v_notice;
end;
$$;

-- Marks a follow-up as done.
create function public.platform_complete_follow_up(p_outreach_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_school uuid;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  update public.platform_outreach set follow_up_done_at = now()
  where id = p_outreach_id and follow_up_on is not null and follow_up_done_at is null
  returning school_id into v_school;
  if not found then
    raise exception 'no_follow_up' using errcode = 'P0002';
  end if;
  perform private.write_platform_audit('outreach.follow_up_done', v_school, 'outreach', p_outreach_id, '{}'::jsonb);
end;
$$;

-- ---------------------------------------------------------------- reading
-- The people to contact at a school: its own contact details and its administrators. These are the school's
-- representatives, so they are shown, and each view is in the platform audit.
create function public.platform_school_contacts(p_school_id uuid)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_school public.schools;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  select * into v_school from public.schools where id = p_school_id;
  if not found then
    return null;
  end if;
  perform private.write_platform_audit('school.contacts_viewed', p_school_id, 'school', p_school_id, '{}'::jsonb);
  return jsonb_build_object(
    'email', v_school.contact_email,
    'phone', v_school.phone,
    'phone_secondary', v_school.phone_secondary,
    'admins', coalesce((
      select jsonb_agg(jsonb_build_object('name', p.full_name, 'email', p.email, 'phone', p.phone) order by p.full_name)
      from (select * from public.profiles p where p.school_id = p_school_id and p.role = 'admin' and p.status = 'verified' limit 20) p
    ), '[]'::jsonb));
end;
$$;

-- The school's outreach history (newest first, at most 50) with its notices' state, and the signals snoozed today.
create function public.platform_school_outreach(p_school_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'log', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', o.id, 'channel', o.channel, 'signals', o.signals, 'note', o.note, 'snooze_until', o.snooze_until,
        'follow_up_on', o.follow_up_on, 'follow_up_done_at', o.follow_up_done_at, 'created_at', o.created_at,
        'notice_dismissed_at', n.dismissed_at) order by o.created_at desc)
      from (select * from public.platform_outreach where school_id = p_school_id order by created_at desc limit 50) o
      left join public.school_notices n on n.id = o.notice_id), '[]'::jsonb),
    'snoozed', private.snoozed_signals(p_school_id));
end;
$$;

-- For each signal snoozed today: until when, and when the school was last contacted about it.
create function private.snoozed_signals(p_school uuid)
returns jsonb
language sql stable security definer
set search_path = ''
as $$
  select coalesce(jsonb_object_agg(x.signal, jsonb_build_object('until', x.until, 'contacted_at', x.contacted_at)), '{}'::jsonb)
  from (
    select s as signal, max(o.snooze_until) as until, max(o.created_at) as contacted_at
    from public.platform_outreach o, unnest(o.signals) s
    where o.school_id = p_school and o.snooze_until >= current_date
    group by s
  ) x;
$$;
revoke execute on function private.snoozed_signals(uuid) from public;

-- Follow-ups due today or earlier, across schools, oldest first (for "Needs you").
create function public.platform_follow_ups()
returns table (id uuid, school_id uuid, school_name text, channel text, note text, follow_up_on date, created_at timestamptz)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  return query
  select o.id, o.school_id, s.name, o.channel, o.note, o.follow_up_on, o.created_at
  from public.platform_outreach o join public.schools s on s.id = o.school_id
  where o.follow_up_on is not null and o.follow_up_done_at is null and o.follow_up_on <= current_date
  order by o.follow_up_on, o.created_at
  limit 100;
end;
$$;

-- The schools list now says which signals are snoozed and when the school was last contacted.
drop function public.platform_schools();
create function public.platform_schools()
returns table (
  id uuid, name text, short_name text, logo_path text, status text, created_at timestamptz,
  students bigint, staff bigint, level smallint, score smallint, reasons jsonb, last_admin_action_at timestamptz,
  snoozed jsonb, last_outreach_at timestamptz
)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  return query
  select s.id, s.name, s.short_name, s.logo_path, s.status, s.created_at,
    (select count(*) from public.profiles p where p.school_id = s.id and p.role = 'student' and p.status = 'verified'),
    (select count(*) from public.profiles p where p.school_id = s.id and p.role = 'staff' and p.status = 'verified'),
    h.level, h.score,
    coalesce((
      select jsonb_agg(x order by (x->>'level')::int desc, (x->>'weight')::int desc)
      from jsonb_array_elements(h.signals) x where (x->>'level')::int > 0
    ), '[]'::jsonb),
    (select max(a.created_at) from public.audit_log a join public.profiles p on p.id = a.actor_id and p.role = 'admin' where a.school_id = s.id),
    private.snoozed_signals(s.id),
    (select max(o.created_at) from public.platform_outreach o where o.school_id = s.id)
  from public.schools s
  left join lateral private.school_health(s.id) h on true
  order by h.level desc nulls last, h.score asc nulls last, s.name
  limit 500;
end;
$$;

revoke execute on function public.platform_log_outreach(uuid, text, text[], text, int, date),
  public.platform_send_notice(uuid, text, text, text[], int, date), public.platform_complete_follow_up(uuid),
  public.platform_school_contacts(uuid), public.platform_school_outreach(uuid), public.platform_follow_ups(),
  public.platform_schools() from public, anon;
grant execute on function public.platform_log_outreach(uuid, text, text[], text, int, date),
  public.platform_send_notice(uuid, text, text, text[], int, date), public.platform_complete_follow_up(uuid),
  public.platform_school_contacts(uuid), public.platform_school_outreach(uuid), public.platform_follow_ups(),
  public.platform_schools() to authenticated;
