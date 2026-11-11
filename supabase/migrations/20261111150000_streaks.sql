-- Streaks, for students who opt in. Everything is worked out from scans, in the school's time zone, so a boarding
-- recorded late (the ops app's offline queue) corrects the streak by itself. Opting in also puts the student on their
-- school's leaderboard (the owner's decision); the app says so when they turn it on.
--
-- Each day of a semester, from the later of its start and the day the student opted in, is one of:
--   rode        the student was scanned that day
--   rest        not one of the student's riding days (notification preferences), and no scan
--   no_service  no trip was scheduled at the school that day (holiday, weekend without buses), and no scan
--   missed      a riding day with service, gone by without a scan
--   today       today, not scanned yet (it can still become rode)
--   future      still to come
-- The streak counts consecutive rode days; rest, no_service and today are skipped; only missed breaks it.

alter table public.profiles
  add column streak_opt_in boolean not null default false,
  add column streak_opt_in_at timestamptz;

-- The days of a semester for one student, with their state. Internal: callers check who may see what.
create function private.ride_days(p_user uuid, p_semester uuid)
returns table (day date, state text)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school uuid;
  v_zone text;
  v_start date;
  v_end date;
  v_from date;
  v_today date;
  v_mask int;
begin
  select s.school_id, sc.timezone, s.start_date, s.end_date into v_school, v_zone, v_start, v_end
  from public.semesters s join public.schools sc on sc.id = s.school_id
  where s.id = p_semester;
  if v_school is null then return; end if;

  select greatest(v_start, (p.streak_opt_in_at at time zone v_zone)::date) into v_from
  from public.profiles p where p.id = p_user and p.school_id = v_school and p.streak_opt_in;
  if v_from is null then return; end if;

  v_today := (now() at time zone v_zone)::date;
  select coalesce((select n.riding_days from public.notification_preferences n where n.user_id = p_user), 31) into v_mask;

  return query
  with days as (
    select g::date as d from generate_series(v_from, v_end, interval '1 day') g
  ),
  rode as (
    select distinct (sc.scanned_at at time zone v_zone)::date as d
    from public.scans sc
    where sc.student_id = p_user and sc.school_id = v_school
      and sc.scanned_at >= (v_from::timestamp at time zone v_zone) and sc.scanned_at < ((v_end + 1)::timestamp at time zone v_zone)
  ),
  service as (
    select distinct (t.scheduled_start at time zone v_zone)::date as d
    from public.trips t
    where t.school_id = v_school and t.status <> 'cancelled'
      and t.scheduled_start >= (v_from::timestamp at time zone v_zone) and t.scheduled_start < ((v_end + 1)::timestamp at time zone v_zone)
  )
  select days.d,
    case
      when exists (select 1 from rode r where r.d = days.d) then 'rode'
      when days.d > v_today then 'future'
      when days.d = v_today then 'today'
      when (v_mask & (1 << (extract(isodow from days.d)::int - 1))) = 0 then 'rest'
      when not exists (select 1 from service sv where sv.d = days.d) then 'no_service'
      else 'missed'
    end
  from days
  order by days.d;
end;
$$;

-- The current and best streaks and the number of rides, from ride_days.
create function private.streak_of(p_user uuid, p_semester uuid)
returns table (current_streak int, best_streak int, rides int)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_run int := 0;
  v_best int := 0;
  v_rides int := 0;
  v_any boolean := false;
  r record;
begin
  for r in select * from private.ride_days(p_user, p_semester) loop
    v_any := true;
    if r.state = 'rode' then
      v_run := v_run + 1;
      v_rides := v_rides + 1;
      v_best := greatest(v_best, v_run);
    elsif r.state = 'missed' then
      v_run := 0;
    end if;
  end loop;
  if v_any then
    return query select v_run, v_best, v_rides;
  end if;
end;
$$;

revoke execute on function private.ride_days(uuid, uuid), private.streak_of(uuid, uuid) from public;

-- Turning streaks on or off. Turning on starts counting today (an earlier opt-in date is kept when it is already on).
create function public.set_streak_opt_in(p_on boolean)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if private.my_school_id() is null or private.my_role() <> 'student' then
    raise exception 'Only a verified student can use streaks' using errcode = '42501';
  end if;
  update public.profiles
  set streak_opt_in = coalesce(p_on, false),
      streak_opt_in_at = case when coalesce(p_on, false) then coalesce(case when streak_opt_in then streak_opt_in_at end, now()) else null end
  where id = v_uid;
end;
$$;

-- The caller's own days and streak for a semester of their school (nothing when they have not opted in).
create function public.my_ride_days(p_semester_id uuid)
returns table (day date, state text)
language sql stable security definer
set search_path = ''
as $$
  select d.day, d.state from private.ride_days((select auth.uid()), p_semester_id) d
  where exists (select 1 from public.semesters s where s.id = p_semester_id and s.school_id = private.my_school_id());
$$;

create function public.my_streak(p_semester_id uuid)
returns table (current_streak int, best_streak int, rides int)
language sql stable security definer
set search_path = ''
as $$
  select s.current_streak, s.best_streak, s.rides from private.streak_of((select auth.uid()), p_semester_id) s
  where exists (select 1 from public.semesters x where x.id = p_semester_id and x.school_id = private.my_school_id());
$$;

revoke execute on function public.set_streak_opt_in(boolean), public.my_ride_days(uuid), public.my_streak(uuid) from public, anon;
grant execute on function public.set_streak_opt_in(boolean), public.my_ride_days(uuid), public.my_streak(uuid) to authenticated;
