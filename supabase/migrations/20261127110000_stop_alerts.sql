-- Stop alerts (issue #557, owner's device test). On top of "bus near my stop":
--   trip_started   a trip going to school started: riders of the day, at most one per student per school day;
--   bus_at_stop    the bus is at the student's stop, and bus_left_stop when it leaves it: students of that stop who
--                  are not on a bus yet;
--   bus_at_campus  the bus reached the campus: students on board (scanned on this trip);
--   trip_at_campus the crew is told the bus is at the campus, with an End trip button (as trip_still_running).
-- All for trips going to school, and only to students covered today (approved, the semester or period running, a
-- verified account, today one of their riding days). Two settings: trip_started_on, stop_alerts_on (at, left, campus).
-- The texts stay generic (no stop, bus or time goes through Firebase); the app names the stop.

alter table public.notification_preferences
  add column trip_started_on boolean not null default true,
  add column stop_alerts_on boolean not null default true;

drop function public.my_notification_preferences();
create function public.my_notification_preferences()
returns table (riding_days smallint, morning_on boolean, morning_time time, evening_on boolean, evening_time time,
               bus_near_on boolean, bus_near_minutes smallint, boarding_messages_on boolean, trip_started_on boolean,
               stop_alerts_on boolean)
language sql stable security definer
set search_path = ''
as $$
  select coalesce(n.riding_days, 31::smallint), coalesce(n.morning_on, true), coalesce(n.morning_time, '06:30'::time),
         coalesce(n.evening_on, false), coalesce(n.evening_time, '16:30'::time), coalesce(n.bus_near_on, true),
         coalesce(n.bus_near_minutes, 5::smallint), coalesce(n.boarding_messages_on, true), coalesce(n.trip_started_on, true),
         coalesce(n.stop_alerts_on, true)
  from (select (select auth.uid()) as uid) me
  left join public.notification_preferences n on n.user_id = me.uid
$$;
revoke execute on function public.my_notification_preferences() from public, anon;
grant execute on function public.my_notification_preferences() to authenticated;

-- The two new settings default to on, so an app that does not send them yet keeps them as they are.
drop function public.set_notification_preferences(smallint, boolean, time, boolean, time, boolean, smallint, boolean);
create function public.set_notification_preferences(
  p_riding_days smallint,
  p_morning_on boolean,
  p_morning_time time,
  p_evening_on boolean,
  p_evening_time time,
  p_bus_near_on boolean,
  p_bus_near_minutes smallint,
  p_boarding_messages_on boolean,
  p_trip_started_on boolean default null,
  p_stop_alerts_on boolean default null
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
    evening_time, bus_near_on, bus_near_minutes, boarding_messages_on, trip_started_on, stop_alerts_on, updated_at)
  values (v_uid, v_school, p_riding_days, p_morning_on, p_morning_time, p_evening_on, p_evening_time, p_bus_near_on,
    p_bus_near_minutes, p_boarding_messages_on, coalesce(p_trip_started_on, true), coalesce(p_stop_alerts_on, true), now())
  on conflict (user_id) do update set
    school_id = excluded.school_id, riding_days = excluded.riding_days, morning_on = excluded.morning_on,
    morning_time = excluded.morning_time, evening_on = excluded.evening_on, evening_time = excluded.evening_time,
    bus_near_on = excluded.bus_near_on, bus_near_minutes = excluded.bus_near_minutes,
    boarding_messages_on = excluded.boarding_messages_on,
    trip_started_on = coalesce(p_trip_started_on, n.trip_started_on),
    stop_alerts_on = coalesce(p_stop_alerts_on, n.stop_alerts_on),
    updated_at = now();
end;
$$;
revoke execute on function public.set_notification_preferences(smallint, boolean, time, boolean, time, boolean, smallint, boolean, boolean, boolean) from public, anon;
grant execute on function public.set_notification_preferences(smallint, boolean, time, boolean, time, boolean, smallint, boolean, boolean, boolean) to authenticated;

-- Every kind the outbox takes: the earlier ones (trips, payments) and the new ones.
alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'subscription_revoked', 'subscription_restored', 'school_notice', 'bus_near_stop',
                  'crew_assigned', 'installment_paid', 'installment_rejected', 'installment_due', 'trip_still_running',
                  'payment_completed', 'payment_failed', 'refund_completed', 'refund_failed', 'refund_declined',
                  'trip_started', 'bus_at_stop', 'bus_left_stop', 'bus_at_campus', 'trip_at_campus'));

-- Where a running trip has been: each stop it reached (and when it left), and the campus. One row each, so every alert
-- goes once per trip. Gone with the trip.
create table private.trip_stop_visits (
  trip_id uuid not null references public.trips (id) on delete cascade,
  stop_id uuid not null references public.stops (id) on delete cascade,
  arrived_at timestamptz not null default now(),
  left_at timestamptz,
  primary key (trip_id, stop_id)
);
create table private.trip_campus_arrivals (
  trip_id uuid primary key references public.trips (id) on delete cascade,
  arrived_at timestamptz not null default now()
);
-- "A trip started" at most once per student and school day, however many buses start.
create table private.trip_started_sent (
  user_id uuid not null references public.profiles (id) on delete cascade,
  day date not null,
  primary key (user_id, day)
);
alter table private.trip_stop_visits enable row level security;
alter table private.trip_stop_visits force row level security;
alter table private.trip_campus_arrivals enable row level security;
alter table private.trip_campus_arrivals force row level security;
alter table private.trip_started_sent enable row level security;
alter table private.trip_started_sent force row level security;
revoke all on private.trip_stop_visits, private.trip_campus_arrivals, private.trip_started_sent from public, anon, authenticated;

-- Within this of a stop the bus is at it; it has left once further than the second (the student app uses the same).
create function private.at_stop_m() returns double precision language sql immutable as $$ select 80::double precision $$;
create function private.left_stop_m() returns double precision language sql immutable as $$ select 150::double precision $$;
-- The campus is a bigger place: arrived within this.
create function private.at_campus_m() returns double precision language sql immutable as $$ select 150::double precision $$;

-- Students of a school covered today, as "bus near my stop" counts them: approved, the period running today, a verified
-- account, today one of their riding days. With their stop and their settings.
create function private.riders_today(p_school uuid)
returns table (student_id uuid, stop_id uuid, trip_started_on boolean, stop_alerts_on boolean)
language sql stable security definer
set search_path = ''
as $$
  with day as (
    select (now() at time zone sc.timezone)::date as today from public.schools sc where sc.id = p_school
  )
  select s.student_id, s.stop_id, coalesce(n.trip_started_on, true), coalesce(n.stop_alerts_on, true)
  from day
  join public.subscriptions s on s.school_id = p_school and s.status = 'approved'
  join public.semesters se on se.id = s.semester_id
    and day.today between coalesce(s.period_start, se.start_date) and coalesce(s.period_end, se.end_date)
  join public.profiles p on p.id = s.student_id and p.status = 'verified'
  left join public.notification_preferences n on n.user_id = s.student_id
  where (coalesce(n.riding_days, 31) & (1 << (extract(isodow from day.today)::int - 1))) <> 0
$$;
revoke execute on function private.riders_today(uuid) from public;

-- On a bus right now: scanned on a trip that is still running.
create function private.on_board_now(p_student uuid) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (select 1 from public.scans s join public.trips t on t.id = s.trip_id where s.student_id = p_student and t.status = 'active')
$$;
revoke execute on function private.on_board_now(uuid) from public;

-- A trip going to school started: its riders of the day hear it once that day.
create function private.notify_trip_started() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_today date;
begin
  if new.status <> 'active' or new.direction <> 'inbound' or (tg_op = 'UPDATE' and old.status = 'active') then
    return new;
  end if;
  select (now() at time zone sc.timezone)::date into v_today from public.schools sc where sc.id = new.school_id;
  with fresh as (
    insert into private.trip_started_sent (user_id, day)
    select distinct r.student_id, v_today from private.riders_today(new.school_id) r where r.trip_started_on
    on conflict do nothing
    returning user_id
  )
  insert into private.notification_outbox (school_id, user_id, kind, ref_id)
  select new.school_id, f.user_id, 'trip_started', new.id from fresh f;
  return new;
end;
$$;
revoke execute on function private.notify_trip_started() from public;

create trigger trips_notify_started
  after insert or update of status on public.trips
  for each row execute function private.notify_trip_started();

-- Each new position of a bus on a trip going to school: the stops it reached, the stops it left, the campus.
create function private.track_trip_progress() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_trip public.trips;
  v_campus extensions.geography;
begin
  if new.trip_id is null then return new; end if;
  select * into v_trip from public.trips t
  where t.id = new.trip_id and t.school_id = new.school_id and t.status = 'active' and t.direction = 'inbound';
  if not found then return new; end if;

  -- Reached: students of that stop who are not on a bus yet (this one or another still running).
  with reached as (
    insert into private.trip_stop_visits (trip_id, stop_id)
    select new.trip_id, st.id from public.stops st
    where st.school_id = new.school_id and st.active
      and extensions.st_dwithin(st.location, new.location, private.at_stop_m())
    on conflict do nothing
    returning stop_id
  )
  insert into private.notification_outbox (school_id, user_id, kind, ref_id)
  select distinct new.school_id, r.student_id, 'bus_at_stop', new.trip_id
  from reached x
  join private.riders_today(new.school_id) r on r.stop_id = x.stop_id and r.stop_alerts_on
  where not private.on_board_now(r.student_id);

  -- Left: the same students, still not on a bus.
  with went as (
    update private.trip_stop_visits v set left_at = now()
    from public.stops st
    where v.trip_id = new.trip_id and v.left_at is null and st.id = v.stop_id
      and not extensions.st_dwithin(st.location, new.location, private.left_stop_m())
    returning v.stop_id
  )
  insert into private.notification_outbox (school_id, user_id, kind, ref_id)
  select distinct new.school_id, r.student_id, 'bus_left_stop', new.trip_id
  from went x
  join private.riders_today(new.school_id) r on r.stop_id = x.stop_id and r.stop_alerts_on
  where not private.on_board_now(r.student_id);

  -- The campus: a welcome to those on board, and the crew is offered to end the trip.
  select sc.campus_location into v_campus from public.schools sc where sc.id = new.school_id;
  if v_campus is not null and extensions.st_dwithin(v_campus, new.location, private.at_campus_m()) then
    insert into private.trip_campus_arrivals (trip_id) values (new.trip_id) on conflict do nothing;
    if found then
      insert into private.notification_outbox (school_id, user_id, kind, ref_id)
      select distinct new.school_id, s.student_id, 'bus_at_campus', new.trip_id
      from public.scans s
      left join public.notification_preferences n on n.user_id = s.student_id
      where s.trip_id = new.trip_id and s.student_id is not null and coalesce(n.stop_alerts_on, true);

      insert into private.notification_outbox (school_id, user_id, kind, ref_id)
      select distinct new.school_id, u.user_id, 'trip_at_campus', new.trip_id
      from (values (v_trip.driver_id), (v_trip.assistant_id), (v_trip.started_by)) as u (user_id)
      where u.user_id is not null;
    end if;
  end if;
  return new;
end;
$$;
revoke execute on function private.track_trip_progress(), private.at_stop_m(), private.left_stop_m(), private.at_campus_m() from public;

create trigger live_positions_track_trip_progress
  after insert or update of location on public.live_positions
  for each row execute function private.track_trip_progress();
