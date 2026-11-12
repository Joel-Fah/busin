-- Bus near my stop. When a bus on an inbound trip that is under way reports its position (ops driver mode, phase 4),
-- every student waiting for it is told once: an approved subscription for a semester running today, "bus near my stop"
-- on (the default), today one of their riding days, not yet scanned on this trip, and their stop within the distance
-- the bus covers in their chosen minutes. The distance uses the reported speed, or a town pace when the phone gives
-- none, and is kept between 300 m (a bus crawling in traffic) and 15 km.
-- One push per trip and student (private.bus_near_sent). The text is generic: no stop, bus or time goes through Firebase.

alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'school_notice', 'bus_near_stop'));

create table private.bus_near_sent (
  trip_id uuid not null references public.trips (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  sent_at timestamptz not null default now(),
  primary key (trip_id, user_id)
);
alter table private.bus_near_sent enable row level security;
alter table private.bus_near_sent force row level security;
revoke all on private.bus_near_sent from public, anon, authenticated;

-- Town pace when the phone reports no speed: about 20 km/h.
create function private.bus_near_reach_m(p_speed_mps real, p_minutes int) returns double precision
language sql immutable set search_path = ''
as $$
  select least(15000, greatest(300, coalesce(nullif(p_speed_mps, 0), 5.5) * 60 * p_minutes))::double precision;
$$;

create function private.notify_bus_near_stop() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_zone text;
  v_today date;
  v_dow int;
begin
  if new.trip_id is null then return new; end if;
  if not exists (
    select 1 from public.trips t
    where t.id = new.trip_id and t.school_id = new.school_id and t.status = 'active' and t.direction = 'inbound'
  ) then
    return new;
  end if;

  select sc.timezone into v_zone from public.schools sc where sc.id = new.school_id;
  v_today := (now() at time zone v_zone)::date;
  v_dow := extract(isodow from v_today)::int - 1;

  with waiting as (
    select s.student_id, s.school_id
    from public.subscriptions s
    join public.semesters se on se.id = s.semester_id and v_today between se.start_date and se.end_date
    join public.stops st on st.id = s.stop_id
    join public.profiles p on p.id = s.student_id and p.status = 'verified'
    left join public.notification_preferences n on n.user_id = s.student_id
    where s.school_id = new.school_id
      and s.status = 'approved'
      and coalesce(n.bus_near_on, true)
      and (coalesce(n.riding_days, 31) & (1 << v_dow)) <> 0
      and extensions.st_dwithin(st.location, new.location, private.bus_near_reach_m(new.speed_mps, coalesce(n.bus_near_minutes, 5)))
      and not exists (select 1 from public.scans x where x.trip_id = new.trip_id and x.student_id = s.student_id)
  ),
  fresh as (
    insert into private.bus_near_sent (trip_id, user_id)
    select new.trip_id, w.student_id from waiting w
    on conflict do nothing
    returning user_id
  )
  insert into private.notification_outbox (school_id, user_id, kind, ref_id)
  select new.school_id, f.user_id, 'bus_near_stop', new.trip_id from fresh f;

  return new;
end;
$$;

revoke execute on function private.notify_bus_near_stop(), private.bus_near_reach_m(real, int) from public;

create trigger live_positions_bus_near_stop
  after insert or update of location on public.live_positions
  for each row execute function private.notify_bus_near_stop();
