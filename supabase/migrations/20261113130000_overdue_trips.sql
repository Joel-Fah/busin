-- Trips that run too long (owner request, 2026-11-11). A trip nobody ends keeps "running": students see a bus that is
-- not moving and staff phones may keep sharing. Admins already may end any running trip of their school (end_trip);
-- this adds what draws their attention to one, and a safety net that ends trips left running from an earlier day.

-- Why a running trip is overdue, or null: 'earlier_day' (it started on an earlier school day), 'silent' (it reported
-- a position but none for 30 minutes), 'long' (it started more than 3 hours ago). The first that applies.
create function private.trip_overdue_reason(p_trip public.trips)
returns text
language sql stable security definer
set search_path = ''
as $$
  select case
    when p_trip.status <> 'active' or p_trip.started_at is null then null
    when (p_trip.started_at at time zone sc.timezone)::date < (now() at time zone sc.timezone)::date then 'earlier_day'
    when lp.recorded_at is not null and lp.recorded_at < now() - interval '30 minutes' then 'silent'
    when p_trip.started_at < now() - interval '3 hours' then 'long'
  end
  from public.schools sc
  left join public.live_positions lp on lp.bus_id = p_trip.bus_id and lp.trip_id = p_trip.id
  where sc.id = p_trip.school_id;
$$;
revoke execute on function private.trip_overdue_reason(public.trips) from public;

-- The admin's overdue trips: why, when it started, and when the bus last reported (null if never). Oldest first.
create function public.admin_overdue_trips()
returns table (trip_id uuid, reason text, started_at timestamptz, last_position_at timestamptz)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  return query
  select o.id, o.reason, o.started_at, lp.recorded_at
  from (
    select t.id, t.bus_id, t.started_at, private.trip_overdue_reason(t) as reason
    from public.trips t
    where t.school_id = private.my_school_id() and t.status = 'active'
  ) o
  left join public.live_positions lp on lp.bus_id = o.bus_id and lp.trip_id = o.id
  where o.reason is not null
  order by o.started_at
  limit 100;
end;
$$;

revoke execute on function public.admin_overdue_trips() from public, anon;
grant execute on function public.admin_overdue_trips() to authenticated;

-- Ends every trip still running from an earlier school day, in each school's own time zone, and records it. Returns how
-- many it ended.
create function private.end_stale_trips()
returns int
language plpgsql security definer
set search_path = ''
as $$
declare
  v_trip record;
  v_count int := 0;
begin
  for v_trip in
    update public.trips t set status = 'completed', ended_at = now()
    from public.schools sc
    where sc.id = t.school_id and t.status = 'active' and t.started_at is not null
      and (t.started_at at time zone sc.timezone)::date < (now() at time zone sc.timezone)::date
    returning t.id, t.school_id
  loop
    perform private.write_audit(v_trip.school_id, null, 'trip.auto_ended', 'trip', v_trip.id, '{"reason":"earlier_day"}'::jsonb);
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;
revoke execute on function private.end_stale_trips() from public;

-- Hourly, so each school's trips end soon after its own midnight.
select cron.schedule('busin-end-stale-trips', '5 * * * *', $$select private.end_stale_trips()$$);
