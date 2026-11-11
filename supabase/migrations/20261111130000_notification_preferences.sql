-- What each student wants to be reminded of, and when. Morning and evening reminders are scheduled on the phone itself
-- (local notifications, nothing sent from here); "bus near my stop" is sent from the server later (phase 3 slice 10),
-- so the preferences live here where both can read them. School notices cannot be turned off: when an admin changes the
-- dates of a semester students are subscribed to, each of them is told.

create table public.notification_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  school_id uuid not null references public.schools (id) on delete cascade,
  -- Days the student rides, Monday = bit 0 ... Sunday = bit 6. Default Monday to Friday.
  riding_days smallint not null default 31 check (riding_days between 0 and 127),
  morning_on boolean not null default true,
  morning_time time not null default '06:30',
  evening_on boolean not null default false,
  evening_time time not null default '16:30',
  bus_near_on boolean not null default true,
  bus_near_minutes smallint not null default 5 check (bus_near_minutes between 1 and 30),
  boarding_messages_on boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.notification_preferences enable row level security;
alter table public.notification_preferences force row level security;
revoke all on public.notification_preferences from public, anon, authenticated;
grant select on public.notification_preferences to authenticated;

-- A student reads their own row. Writes go through the function below.
create policy notification_preferences_select on public.notification_preferences for select to authenticated
  using (user_id = (select auth.uid()));

-- The caller's preferences, with the defaults when they never saved any.
create function public.my_notification_preferences()
returns table (riding_days smallint, morning_on boolean, morning_time time, evening_on boolean, evening_time time,
               bus_near_on boolean, bus_near_minutes smallint, boarding_messages_on boolean)
language sql stable security definer
set search_path = ''
as $$
  select coalesce(n.riding_days, 31::smallint), coalesce(n.morning_on, true), coalesce(n.morning_time, '06:30'::time),
         coalesce(n.evening_on, false), coalesce(n.evening_time, '16:30'::time), coalesce(n.bus_near_on, true),
         coalesce(n.bus_near_minutes, 5::smallint), coalesce(n.boarding_messages_on, true)
  from (select (select auth.uid()) as uid) me
  left join public.notification_preferences n on n.user_id = me.uid
  where private.my_school_id() is not null;
$$;

-- Saves the caller's preferences (a verified account only).
create function public.set_notification_preferences(
  p_riding_days smallint,
  p_morning_on boolean,
  p_morning_time time,
  p_evening_on boolean,
  p_evening_time time,
  p_bus_near_on boolean,
  p_bus_near_minutes smallint,
  p_boarding_messages_on boolean
)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
begin
  if v_school is null then
    raise exception 'A verified account is required' using errcode = '42501';
  end if;
  insert into public.notification_preferences as n (user_id, school_id, riding_days, morning_on, morning_time, evening_on,
    evening_time, bus_near_on, bus_near_minutes, boarding_messages_on, updated_at)
  values (v_uid, v_school, p_riding_days, p_morning_on, p_morning_time, p_evening_on, p_evening_time, p_bus_near_on,
    p_bus_near_minutes, p_boarding_messages_on, now())
  on conflict (user_id) do update set
    school_id = excluded.school_id, riding_days = excluded.riding_days, morning_on = excluded.morning_on,
    morning_time = excluded.morning_time, evening_on = excluded.evening_on, evening_time = excluded.evening_time,
    bus_near_on = excluded.bus_near_on, bus_near_minutes = excluded.bus_near_minutes,
    boarding_messages_on = excluded.boarding_messages_on, updated_at = now();
end;
$$;

revoke execute on function public.my_notification_preferences(), public.set_notification_preferences(smallint, boolean, time, boolean, time, boolean, smallint, boolean) from public, anon;
grant execute on function public.my_notification_preferences(), public.set_notification_preferences(smallint, boolean, time, boolean, time, boolean, smallint, boolean) to authenticated;

-- ---------------------------------------------------------------------------- school notices (cannot be turned off)

alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'school_notice'));

-- When an admin moves the dates of a semester that has not ended, every student with a live request for it is told.
create function private.notify_semester_dates() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if (old.start_date, old.end_date) is distinct from (new.start_date, new.end_date) and greatest(old.end_date, new.end_date) >= current_date then
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    select distinct s.school_id, s.student_id, 'school_notice', new.id
    from public.subscriptions s
    where s.semester_id = new.id and s.status in ('pending', 'approved');
  end if;
  return new;
end;
$$;

create trigger semesters_notify_dates
  after update of start_date, end_date on public.semesters
  for each row execute function private.notify_semester_dates();
