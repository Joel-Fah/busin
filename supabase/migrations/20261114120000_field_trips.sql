-- Field trips (ADR 0020): when an administrator missed scheduling a trip, a staff member can start one from the ops app.
-- They give the bus, the direction and whether they are the driver or the assistant; they are assigned at once, and the
-- other crew member can be picked and is told. The trip is marked as started in the field, and by whom. A switch on the
-- school turns the whole thing off.

alter table public.trips add column origin text not null default 'scheduled' check (origin in ('scheduled', 'field'));
-- Who made the trip when it was not scheduled by an administrator. Null for scheduled trips.
alter table public.trips add column created_by uuid references public.profiles (id) on delete set null;
create index trips_field_idx on public.trips (school_id, created_at desc) where origin = 'field';

alter table public.schools add column allow_field_trips boolean not null default true;

-- A staff member told they are on a trip's crew.
alter table private.notification_outbox drop constraint notification_outbox_kind_check;
alter table private.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('subscription_approved', 'subscription_rejected', 'school_notice', 'bus_near_stop', 'crew_assigned'));

-- The school's switch. Administrators only; audited.
create function public.admin_set_field_trips(p_allowed boolean)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Administrators only' using errcode = '42501';
  end if;
  if p_allowed is null then
    raise exception 'invalid_value' using errcode = '22023';
  end if;
  update public.schools set allow_field_trips = p_allowed where id = private.my_school_id();
  perform private.write_audit(private.my_school_id(), (select auth.uid()), 'school.field_trips', 'school', private.my_school_id(),
    jsonb_build_object('allowed', p_allowed));
end;
$$;

-- What the ops app needs to start a trip that is not on the list, in one call: whether the school allows it, the buses
-- in service that are not on a trip right now, and the verified staff who could be on the crew (names only). At most
-- 200 of each. Staff of the school only.
create function public.field_trip_options()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_allowed boolean;
begin
  if not private.is_staff() then
    raise exception 'Staff access required' using errcode = '42501';
  end if;
  select s.allow_field_trips into v_allowed from public.schools s where s.id = v_school;
  if not coalesce(v_allowed, false) then
    return jsonb_build_object('allowed', false, 'buses', '[]'::jsonb, 'staff', '[]'::jsonb);
  end if;
  return jsonb_build_object(
    'allowed', true,
    'buses', coalesce((
      select jsonb_agg(jsonb_build_object('id', b.id, 'plate', b.plate, 'name', b.name) order by b.plate)
      from (
        select b.id, b.plate, b.name from public.buses b
        where b.school_id = v_school and b.in_service
          and not exists (select 1 from public.trips t where t.bus_id = b.id and t.status = 'active')
        order by b.plate limit 200
      ) b
    ), '[]'::jsonb),
    'staff', coalesce((
      select jsonb_agg(jsonb_build_object('id', p.id, 'name', coalesce(nullif(p.full_name, ''), p.email)) order by coalesce(nullif(p.full_name, ''), p.email))
      from (
        select p.id, p.full_name, p.email from public.profiles p
        where p.school_id = v_school and p.role = 'staff' and p.status = 'verified' and p.id <> (select auth.uid())
        order by coalesce(nullif(p.full_name, ''), p.email) limit 200
      ) p
    ), '[]'::jsonb)
  );
end;
$$;

-- Starts a trip nobody scheduled. [p_role] is what the caller is on this trip, 'driver' or 'assistant'; [p_other_id] is
-- the other crew member, if any (the driver when the caller is the assistant, the assistant when they are the driver).
-- The trip is running at once, so the caller can scan and share the position straight away. Refused when: the school has
-- the switch off; the bus is out of service or already on a trip; a scheduled trip exists today for this bus and
-- direction (start that one instead); or the caller has already started 5 today.
create function public.start_field_trip(
  p_bus_id uuid,
  p_direction public.trip_direction,
  p_role text,
  p_other_id uuid default null
)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_me uuid := (select auth.uid());
  v_zone text;
  v_allowed boolean;
  v_in_service boolean;
  v_today date;
  v_trip uuid;
begin
  if not private.is_staff() then
    raise exception 'Staff access required' using errcode = '42501';
  end if;
  select s.timezone, s.allow_field_trips into v_zone, v_allowed from public.schools s where s.id = v_school;
  if not coalesce(v_allowed, false) then
    raise exception 'field_trips_off' using errcode = '42501';
  end if;
  if p_role is null or p_role not in ('driver', 'assistant') or p_direction is null then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  v_today := (now() at time zone v_zone)::date;

  select b.in_service into v_in_service from public.buses b where b.id = p_bus_id and b.school_id = v_school;
  if not found then
    raise exception 'Bus not found' using errcode = 'P0002';
  end if;
  if not v_in_service then
    raise exception 'bus_out_of_service' using errcode = '55000';
  end if;
  if exists (select 1 from public.trips t where t.bus_id = p_bus_id and t.status = 'active') then
    raise exception 'bus_busy' using errcode = '55000';
  end if;
  if exists (
    select 1 from public.trips t
    where t.bus_id = p_bus_id and t.direction = p_direction and t.status = 'scheduled'
      and (t.scheduled_start at time zone v_zone)::date = v_today
  ) then
    raise exception 'use_scheduled_trip' using errcode = '55000';
  end if;
  if (
    select count(*) from public.trips t
    where t.created_by = v_me and t.origin = 'field' and (t.created_at at time zone v_zone)::date = v_today
  ) >= 5 then
    raise exception 'too_many_field_trips' using errcode = 'PT429';
  end if;

  if p_other_id is not null then
    if p_other_id = v_me or not exists (
      select 1 from public.profiles p
      where p.id = p_other_id and p.school_id = v_school and p.role = 'staff' and p.status = 'verified'
    ) then
      raise exception 'invalid_crew' using errcode = '22023';
    end if;
  end if;

  insert into public.trips (school_id, bus_id, driver_id, assistant_id, direction, status, scheduled_start, started_at, started_by, origin, created_by)
  values (
    v_school, p_bus_id,
    case when p_role = 'driver' then v_me else p_other_id end,
    case when p_role = 'assistant' then v_me else p_other_id end,
    p_direction, 'active', now(), now(), v_me, 'field', v_me
  )
  returning id into v_trip;

  perform private.write_audit(v_school, v_me, 'trip.started_in_field', 'trip', v_trip,
    jsonb_build_object('role', p_role, 'other', p_other_id));
  if p_other_id is not null then
    insert into private.notification_outbox (school_id, user_id, kind, ref_id) values (v_school, p_other_id, 'crew_assigned', v_trip);
  end if;
  return v_trip;
end;
$$;

revoke execute on function public.admin_set_field_trips(boolean), public.field_trip_options(),
  public.start_field_trip(uuid, public.trip_direction, text, uuid) from public, anon;
grant execute on function public.admin_set_field_trips(boolean), public.field_trip_options(),
  public.start_field_trip(uuid, public.trip_direction, text, uuid) to authenticated;
