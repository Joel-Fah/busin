-- The platform console (ADR 0027): who may open it, its audit log, and its first page (platform totals and schools).
--
-- A platform admin is not a fourth role: a profile's role is a role inside one school. Platform admins are a short list
-- of accounts in the private schema, added by the owner with SQL only (never from an app). Every platform_* function
-- checks the list first and returns aggregates (counts per school), not people; reading one account comes later as an
-- audited lookup. No existing policy changes: a platform admin reads nothing new directly.

create table private.platform_admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  added_at timestamptz not null default now(),
  -- Who added the row and why, in words (for example "owner, 2026-11-16"): rows are added by SQL, not by an account.
  note text not null check (char_length(note) between 1 and 200)
);
alter table private.platform_admins enable row level security;
alter table private.platform_admins force row level security;
revoke all on private.platform_admins from public, anon, authenticated;

comment on table private.platform_admins is 'Accounts that may open the platform console (ADR 0027). Added by the owner with SQL only.';

-- Whether the caller is a platform admin, read live (as ADR 0005 does for roles), so removing a row applies at once.
create function private.is_platform_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (select 1 from private.platform_admins a where a.user_id = (select auth.uid()));
$$;
revoke execute on function private.is_platform_admin() from public;

-- For the portal's guard: true or false, never an error, so a page can answer "not found" to everyone else.
create function public.am_platform_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select private.is_platform_admin();
$$;
revoke execute on function public.am_platform_admin() from public, anon;
grant execute on function public.am_platform_admin() to authenticated;

-- What platform admins did: lookups, schools created or switched off, leads handled, notices sent. A school may be
-- involved or not (a lead has none), so this is not audit_log, whose school is required.
create table public.platform_audit (
  id bigint generated always as identity primary key,
  actor_id uuid not null references auth.users (id),
  action text not null check (char_length(action) between 1 and 80),
  school_id uuid references public.schools (id) on delete set null,
  target_type text check (char_length(target_type) <= 40),
  target_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index platform_audit_created_idx on public.platform_audit (created_at desc);
create index platform_audit_actor_idx on public.platform_audit (actor_id, created_at desc);
create index platform_audit_school_idx on public.platform_audit (school_id, created_at desc) where school_id is not null;
alter table public.platform_audit enable row level security;
alter table public.platform_audit force row level security;
revoke all on public.platform_audit from public, anon, authenticated;

comment on table public.platform_audit is 'Actions of platform admins (ADR 0027). Written only by platform functions; never read by schools.';

create function private.write_platform_audit(
  p_action text,
  p_school uuid default null,
  p_target_type text default null,
  p_target uuid default null,
  p_details jsonb default '{}'::jsonb
) returns void
language sql security definer
set search_path = ''
as $$
  insert into public.platform_audit (actor_id, action, school_id, target_type, target_id, details)
  values ((select auth.uid()), p_action, p_school, p_target_type, p_target, coalesce(p_details, '{}'::jsonb));
$$;
revoke execute on function private.write_platform_audit(text, uuid, text, uuid, jsonb) from public;

-- ---------------------------------------------------------------- the overview
-- Platform totals, then one row per school (at most 500), all counts. "Today" is each school's own date. A bus is live
-- when its running trip sent a position in the last two minutes. Refuses everyone but a platform admin (42501).
create function public.platform_overview()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_totals jsonb;
  v_schools jsonb;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'schools_active', (select count(*) from public.schools where status = 'active'),
    'schools_inactive', (select count(*) from public.schools where status <> 'active'),
    'students', (select count(*) from public.profiles where role = 'student' and status = 'verified'),
    'staff', (select count(*) from public.profiles where role = 'staff' and status = 'verified'),
    'admins', (select count(*) from public.profiles where role = 'admin' and status = 'verified'),
    'pending_accounts', (select count(*) from public.profiles where status = 'pending'),
    'suspended_accounts', (select count(*) from public.profiles where status = 'suspended'),
    'new_accounts_7d', (select count(*) from public.profiles where created_at > now() - interval '7 days'),
    'new_accounts_30d', (select count(*) from public.profiles where created_at > now() - interval '30 days'),
    'subscriptions_pending', (select count(*) from public.subscriptions s join public.semesters m on m.id = s.semester_id
                               where s.status = 'pending' and private.school_today(s.school_id) between m.start_date and m.end_date),
    'subscriptions_approved', (select count(*) from public.subscriptions s join public.semesters m on m.id = s.semester_id
                                where s.status = 'approved' and private.school_today(s.school_id) between m.start_date and m.end_date),
    'subscriptions_rejected', (select count(*) from public.subscriptions s join public.semesters m on m.id = s.semester_id
                                where s.status = 'rejected' and private.school_today(s.school_id) between m.start_date and m.end_date),
    'trips_today_scheduled', (select count(*) from public.trips t join public.schools sc on sc.id = t.school_id
                               where t.status = 'scheduled' and (t.scheduled_start at time zone sc.timezone)::date = private.school_today(t.school_id)),
    'trips_today_active', (select count(*) from public.trips t where t.status = 'active'),
    'trips_today_completed', (select count(*) from public.trips t join public.schools sc on sc.id = t.school_id
                               where t.status = 'completed' and (t.scheduled_start at time zone sc.timezone)::date = private.school_today(t.school_id)),
    'trips_today_cancelled', (select count(*) from public.trips t join public.schools sc on sc.id = t.school_id
                               where t.status = 'cancelled' and (t.scheduled_start at time zone sc.timezone)::date = private.school_today(t.school_id)),
    'scans_today', (select count(*) from public.scans x join public.schools sc on sc.id = x.school_id
                     where x.scanned_at > now() - interval '2 days'
                       and (x.scanned_at at time zone sc.timezone)::date = private.school_today(x.school_id)),
    'buses_live', (select count(*) from public.live_positions p join public.trips t on t.id = p.trip_id
                    where t.status = 'active' and p.recorded_at > now() - interval '2 minutes')
  ) into v_totals;

  select coalesce(jsonb_agg(school_row order by school_row->>'name'), '[]'::jsonb) into v_schools
  from (
    select jsonb_build_object(
      'id', s.id,
      'name', s.name,
      'short_name', s.short_name,
      'logo_path', s.logo_path,
      'status', s.status,
      'created_at', s.created_at,
      'students', (select count(*) from public.profiles p where p.school_id = s.id and p.role = 'student' and p.status = 'verified'),
      'staff', (select count(*) from public.profiles p where p.school_id = s.id and p.role = 'staff' and p.status = 'verified'),
      'admins', (select count(*) from public.profiles p where p.school_id = s.id and p.role = 'admin' and p.status = 'verified'),
      'waiting_to_join', (select count(*) from public.profiles p where p.school_id = s.id and p.status = 'pending' and p.join_requested_at is not null),
      'subscriptions_pending', (select count(*) from public.subscriptions x where x.school_id = s.id and x.status = 'pending'),
      'trips_active', (select count(*) from public.trips t where t.school_id = s.id and t.status = 'active'),
      'last_admin_action_at', (select max(a.created_at) from public.audit_log a where a.school_id = s.id)
    ) as school_row
    from public.schools s
    order by s.name
    limit 500
  ) listed;

  return jsonb_build_object('totals', v_totals, 'schools', v_schools);
end;
$$;
revoke execute on function public.platform_overview() from public, anon;
grant execute on function public.platform_overview() to authenticated;
