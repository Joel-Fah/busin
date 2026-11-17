-- School health for the platform console (ADR 0027, slice 2): signals computed from data that already exists, each
-- with a level (0 OK, 1 Watch, 2 Needs help, 3 Critical), so a platform admin can see which school struggles and why.
-- Thresholds live in a table so they can be tuned without code. A nightly job keeps one record per school per day, to
-- see whether a school improves (for example after the platform reached out).

create table private.health_rules (
  signal text primary key,
  area text not null check (area in ('waiting', 'conversion', 'profile', 'setup', 'operations', 'engagement')),
  -- 'above': a higher value is worse (days waiting); 'below': a lower value is worse (share of trips scanned).
  direction text not null check (direction in ('above', 'below')),
  watch numeric not null,
  needs_help numeric not null,
  critical numeric not null,
  -- How much the signal counts in the school's score (1 to 3).
  weight smallint not null check (weight between 1 and 3),
  -- Setup-type signals are capped at Watch during a new school's first 14 days.
  grace boolean not null,
  position smallint not null unique,
  check (case direction when 'above' then watch <= needs_help and needs_help <= critical
                        else watch >= needs_help and needs_help >= critical end)
);
alter table private.health_rules enable row level security;
alter table private.health_rules force row level security;
revoke all on private.health_rules from public, anon, authenticated;

insert into private.health_rules (signal, area, direction, watch, needs_help, critical, weight, grace, position) values
  ('answer_time_days',        'waiting',    'above',   2,   4,   7, 3, false, 1),
  ('oldest_pending_days',     'waiting',    'above',   3,   7,  14, 3, false, 2),
  ('oldest_request_days',     'waiting',    'above',   3,   7,  14, 2, false, 3),
  ('oldest_receipt_days',     'waiting',    'above',   3,   7,  14, 2, false, 4),
  ('answered_48h_pct',        'conversion', 'below',  80,  60,  40, 2, false, 5),
  ('approval_rate_pct',       'conversion', 'below',  80,  60,  40, 1, false, 6),
  ('profile_missing',         'profile',    'above',   0,   2,   4, 1, true,  7),
  ('setup_missing',           'setup',      'above',   0,   1,   2, 3, true,  8),
  ('semester_days_left',      'setup',      'below',  14,   7,   0, 2, true,  9),
  ('scanned_trips_pct',       'operations', 'below',  80,  50,  20, 2, true, 10),
  ('tracked_trips_pct',       'operations', 'below',  80,  50,  20, 1, true, 11),
  ('cancelled_pct',           'operations', 'above',  10,  25,  50, 1, true, 12),
  ('admin_idle_days',         'engagement', 'above',   7,  14,  30, 2, true, 13),
  ('new_students_change_pct', 'engagement', 'below', -30, -50, -99, 1, true, 14);

comment on table private.health_rules is 'Thresholds of the school health signals (ADR 0027). A value strictly beyond a threshold reaches its level.';

-- ---------------------------------------------------------------- the signals
-- Each signal's value for one school (null when it does not apply: too few cases to judge, or nothing to measure), its
-- level, and its rule. Shares and rates need at least 3 trips or 5 requests, so one bad day does not flag a small school.
create function private.school_signals(p_school uuid)
returns table (signal text, area text, value numeric, level smallint, weight smallint, direction text, watch numeric, needs_help numeric, critical numeric, graced boolean, detail jsonb)
language plpgsql stable security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_school public.schools;
  v_today date;
  v_values jsonb;
  v_missing text[];
  v_details jsonb := '{}'::jsonb;
  v_n int;
  v_m int;
  v_end date;
  v_cur int;
  v_prev int;
begin
  select * into v_school from public.schools where id = p_school;
  if not found or v_school.status <> 'active' then
    return;
  end if;
  v_today := private.school_today(p_school);
  v_values := '{}'::jsonb;

  -- Waiting: how long students wait for an answer.
  v_values := v_values || jsonb_build_object('answer_time_days', (
    select round((percentile_cont(0.5) within group (order by extract(epoch from s.reviewed_at - s.created_at)) / 86400)::numeric, 1)
    from public.subscriptions s
    where s.school_id = p_school and s.status in ('approved', 'rejected') and s.reviewed_at > now() - interval '30 days'));
  v_values := v_values || jsonb_build_object('oldest_pending_days', (
    select round((extract(epoch from now() - min(s.created_at)) / 86400)::numeric, 1)
    from public.subscriptions s where s.school_id = p_school and s.status = 'pending' and s.proof_path is not null));
  v_values := v_values || jsonb_build_object('oldest_request_days', (
    select round((extract(epoch from now() - min(t.at)) / 86400)::numeric, 1)
    from (
      select p.join_requested_at as at from public.profiles p where p.school_id = p_school and p.status = 'pending' and p.join_requested_at is not null
      union all
      select p.staff_requested_at from public.profiles p where p.staff_request_school = p_school and p.staff_requested_at is not null
    ) t));
  v_values := v_values || jsonb_build_object('oldest_receipt_days', (
    select round((extract(epoch from now() - min(r.sent_at)) / 86400)::numeric, 1)
    from public.installment_receipts r where r.school_id = p_school and r.decision is null and r.proof_path is not null));

  -- Conversion: answered within two days, and approved, over the last 30 days.
  select count(*), count(*) filter (where s.reviewed_at is not null and s.reviewed_at <= s.created_at + interval '48 hours')
  into v_n, v_m
  from public.subscriptions s
  where s.school_id = p_school and s.proof_path is not null
    and s.created_at > now() - interval '30 days' and s.created_at < now() - interval '48 hours';
  v_values := v_values || jsonb_build_object('answered_48h_pct', case when v_n >= 5 then round(100.0 * v_m / v_n) end);

  select count(*), count(*) filter (where s.status = 'approved') into v_n, v_m
  from public.subscriptions s
  where s.school_id = p_school and s.status in ('approved', 'rejected') and s.reviewed_at > now() - interval '30 days';
  v_values := v_values || jsonb_build_object('approval_rate_pct', case when v_n >= 5 then round(100.0 * v_m / v_n) end);

  -- Profile: what students see about the school. The detail names what is missing, so outreach can say it.
  v_missing := array_remove(array[
    case when v_school.logo_path is null then 'logo' end,
    case when nullif(btrim(coalesce(v_school.about, '')), '') is null then 'about' end,
    case when v_school.contact_email is null then 'contact_email' end,
    case when v_school.phone is null then 'phone' end,
    case when v_school.address is null then 'address' end,
    case when v_school.website is null then 'website' end,
    case when v_school.campus_location is null then 'campus' end], null);
  v_values := v_values || jsonb_build_object('profile_missing', cardinality(v_missing));
  v_details := v_details || jsonb_build_object('profile_missing', to_jsonb(v_missing));

  -- Setup: what the school needs to run.
  v_missing := array_remove(array[
    case when not exists (select 1 from public.school_domains d where d.school_id = p_school) and not v_school.accepts_open_signup then 'domain' end,
    case when v_school.price_xaf is null then 'billing' end,
    case when not exists (select 1 from public.semesters m where m.school_id = p_school and v_today between m.start_date and m.end_date) then 'semester' end,
    case when not exists (select 1 from public.stops x where x.school_id = p_school) then 'stops' end,
    case when not exists (select 1 from public.routes r where r.school_id = p_school and r.geometry is not null) then 'route' end,
    case when not exists (select 1 from public.buses b where b.school_id = p_school) then 'buses' end,
    case when not exists (select 1 from public.profiles p where p.school_id = p_school and p.role = 'staff' and p.status = 'verified') then 'staff' end], null);
  v_values := v_values || jsonb_build_object('setup_missing', cardinality(v_missing));
  v_details := v_details || jsonb_build_object('setup_missing', to_jsonb(v_missing));

  -- Days until the last planned semester ends; -1 once it ended with nothing after it; null with no semester at all.
  select max(m.end_date) into v_end from public.semesters m where m.school_id = p_school;
  v_values := v_values || jsonb_build_object('semester_days_left',
    case when v_end is null then null when v_end < v_today then -1 else v_end - v_today end);

  -- Operations, over the last 14 days.
  select count(*),
         count(*) filter (where exists (select 1 from public.scans x where x.trip_id = t.id))
  into v_n, v_m
  from public.trips t where t.school_id = p_school and t.status = 'completed' and t.started_at > now() - interval '14 days';
  v_values := v_values || jsonb_build_object('scanned_trips_pct', case when v_n >= 3 then round(100.0 * v_m / v_n) end);

  select count(*) filter (where exists (select 1 from public.trip_positions x where x.trip_id = t.id)) into v_m
  from public.trips t where t.school_id = p_school and t.status = 'completed' and t.started_at > now() - interval '14 days';
  v_values := v_values || jsonb_build_object('tracked_trips_pct', case when v_n >= 3 then round(100.0 * v_m / v_n) end);

  select count(*), count(*) filter (where t.status = 'cancelled') into v_n, v_m
  from public.trips t
  where t.school_id = p_school and t.status in ('completed', 'cancelled')
    and t.scheduled_start > now() - interval '14 days' and t.scheduled_start <= now();
  v_values := v_values || jsonb_build_object('cancelled_pct', case when v_n >= 3 then round(100.0 * v_m / v_n) end);

  -- Engagement: the last thing an administrator did, and new students against the 30 days before.
  v_values := v_values || jsonb_build_object('admin_idle_days', (
    select floor(extract(epoch from now() - coalesce(max(a.created_at), v_school.created_at)) / 86400)
    from public.audit_log a join public.profiles p on p.id = a.actor_id and p.role = 'admin'
    where a.school_id = p_school));

  select count(*) filter (where p.created_at > now() - interval '30 days'),
         count(*) filter (where p.created_at <= now() - interval '30 days' and p.created_at > now() - interval '60 days')
  into v_cur, v_prev
  from public.profiles p where p.school_id = p_school and p.role = 'student';
  v_values := v_values || jsonb_build_object('new_students_change_pct',
    case when v_prev >= 5 then round(100.0 * (v_cur - v_prev) / v_prev) end);

  return query
  with valued as (
    select r.*, (v_values ->> r.signal)::numeric as v,
           (r.grace and v_school.created_at > now() - interval '14 days') as in_grace
    from private.health_rules r
  ),
  leveled as (
    select valued.*,
      (case
         when v is null then 0
         when direction = 'above' then case when v > critical then 3 when v > needs_help then 2 when v > watch then 1 else 0 end
         else case when v < critical then 3 when v < needs_help then 2 when v < watch then 1 else 0 end
       end)::smallint as raw_level
    from valued
  )
  select l.signal, l.area, l.v, (case when l.in_grace then least(l.raw_level, 1) else l.raw_level end)::smallint,
         l.weight, l.direction, l.watch, l.needs_help, l.critical, (l.in_grace and l.raw_level > 1), v_details -> l.signal
  from leveled l
  order by l.position;
end;
$$;
revoke execute on function private.school_signals(uuid) from public;

-- The school's level (its worst signal) and score: 100 when every measured signal is OK, 0 when every one is Critical,
-- weighted. Null level for a school that is switched off.
create function private.school_health(p_school uuid)
returns table (level smallint, score smallint, signals jsonb)
language sql stable security definer
set search_path = ''
as $$
  select
    max(s.level)::smallint,
    coalesce(100 - round(100.0 * sum(s.weight * s.level) filter (where s.value is not null)
                          / nullif(sum(s.weight * 3) filter (where s.value is not null), 0)), 100)::smallint,
    coalesce(jsonb_agg(jsonb_build_object(
      'signal', s.signal, 'area', s.area, 'value', s.value, 'level', s.level, 'weight', s.weight,
      'direction', s.direction, 'watch', s.watch, 'needs_help', s.needs_help, 'critical', s.critical, 'graced', s.graced,
      'detail', s.detail)), '[]'::jsonb)
  from private.school_signals(p_school) s
  having count(*) > 0;
$$;
revoke execute on function private.school_health(uuid) from public;

-- ---------------------------------------------------------------- the nightly record
create table public.school_health_daily (
  school_id uuid not null references public.schools (id) on delete cascade,
  day date not null,
  level smallint not null check (level between 0 and 3),
  score smallint not null check (score between 0 and 100),
  -- Each signal's value and level that day: {"answer_time_days": {"value": 3.5, "level": 1}, ...}
  signals jsonb not null default '{}'::jsonb,
  primary key (school_id, day)
);
alter table public.school_health_daily enable row level security;
alter table public.school_health_daily force row level security;
revoke all on public.school_health_daily from public, anon, authenticated;

comment on table public.school_health_daily is 'One health record per active school per day (ADR 0027). Read only through platform functions.';

-- Records today's health for every active school (its own date) and keeps about 13 months.
create function private.record_school_health()
returns int
language plpgsql security definer
set search_path = ''
as $$
declare
  v_count int;
begin
  insert into public.school_health_daily (school_id, day, level, score, signals)
  select s.id, private.school_today(s.id), h.level, h.score,
         (select coalesce(jsonb_object_agg(x->>'signal', jsonb_build_object('value', x->'value', 'level', x->'level')), '{}'::jsonb)
          from jsonb_array_elements(h.signals) x)
  from public.schools s
  cross join lateral private.school_health(s.id) h
  where s.status = 'active'
  on conflict (school_id, day) do update set level = excluded.level, score = excluded.score, signals = excluded.signals;
  get diagnostics v_count = row_count;
  delete from public.school_health_daily where day < current_date - 400;
  return v_count;
end;
$$;
revoke execute on function private.record_school_health() from public;

select cron.schedule('busin-school-health', '20 2 * * *', $$select private.record_school_health()$$);

-- ---------------------------------------------------------------- what the console reads
-- Every school with its level, score and the signals that set it (worst first), most troubled first.
create function public.platform_schools()
returns table (
  id uuid, name text, short_name text, logo_path text, status text, created_at timestamptz,
  students bigint, staff bigint, level smallint, score smallint, reasons jsonb, last_admin_action_at timestamptz
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
    (select max(a.created_at) from public.audit_log a join public.profiles p on p.id = a.actor_id and p.role = 'admin' where a.school_id = s.id)
  from public.schools s
  left join lateral private.school_health(s.id) h on true
  order by h.level desc nulls last, h.score asc nulls last, s.name
  limit 500;
end;
$$;

-- One school in detail: who it is, its counts, every signal, its last 30 days of health and its administrators' recent
-- actions (the kind and the time only, never who or on whom). Null for an unknown school.
create function public.platform_school(p_school_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school public.schools;
  v_health record;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  select * into v_school from public.schools where id = p_school_id;
  if not found then
    return null;
  end if;
  select * into v_health from private.school_health(p_school_id);

  return jsonb_build_object(
    'school', jsonb_build_object(
      'id', v_school.id, 'name', v_school.name, 'short_name', v_school.short_name, 'logo_path', v_school.logo_path,
      'status', v_school.status, 'created_at', v_school.created_at, 'timezone', v_school.timezone,
      'city', v_school.city, 'country', v_school.country,
      'accepts_open_signup', v_school.accepts_open_signup, 'public_listing', v_school.public_listing,
      'domains', coalesce((select jsonb_agg(d.domain order by d.domain) from public.school_domains d where d.school_id = v_school.id), '[]'::jsonb)),
    'counts', jsonb_build_object(
      'students', (select count(*) from public.profiles p where p.school_id = v_school.id and p.role = 'student' and p.status = 'verified'),
      'staff', (select count(*) from public.profiles p where p.school_id = v_school.id and p.role = 'staff' and p.status = 'verified'),
      'admins', (select count(*) from public.profiles p where p.school_id = v_school.id and p.role = 'admin' and p.status = 'verified')),
    'level', v_health.level,
    'score', v_health.score,
    'signals', coalesce(v_health.signals, '[]'::jsonb),
    'history', coalesce((
      select jsonb_agg(jsonb_build_object('day', d.day, 'level', d.level, 'score', d.score) order by d.day)
      from public.school_health_daily d where d.school_id = v_school.id and d.day > current_date - 31), '[]'::jsonb),
    'admin_actions', coalesce((
      select jsonb_agg(jsonb_build_object('action', a.action, 'at', a.created_at) order by a.created_at desc)
      from (
        select a.action, a.created_at from public.audit_log a join public.profiles p on p.id = a.actor_id and p.role = 'admin'
        where a.school_id = v_school.id order by a.created_at desc limit 15
      ) a), '[]'::jsonb)
  );
end;
$$;

revoke execute on function public.platform_schools(), public.platform_school(uuid) from public, anon;
grant execute on function public.platform_schools(), public.platform_school(uuid) to authenticated;
