-- Cancel and archive trips.
--
-- A trip is what boardings (scans) point to, so a trip is never deleted: a trip that has not started is
-- cancelled, and a trip that is finished or cancelled can be archived so it leaves the working list.
-- Both are audited functions, because clients cannot write a trip's status or archive mark directly.

alter table public.trips add column archived_at timestamptz;

-- Administrators could delete trips through the API (there was a delete grant and policy). Not any more.
drop policy trips_delete on public.trips;
revoke delete on public.trips from authenticated;

-- Cancel a trip that has not started. The reason is optional and is kept in the audit log.
create function public.admin_cancel_trip(p_trip_id uuid, p_reason text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_trip public.trips;
  v_reason text := nullif(btrim(p_reason), '');
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if v_reason is not null and char_length(v_reason) > 300 then
    raise exception 'The reason is too long (300 characters at most)' using errcode = '22023';
  end if;

  select * into v_trip
  from public.trips
  where id = p_trip_id and school_id = v_school
  for update;
  if not found then
    raise exception 'Trip not found' using errcode = 'P0002';
  end if;
  if v_trip.status <> 'scheduled' then
    raise exception 'Only a trip that has not started can be cancelled' using errcode = '55000';
  end if;

  update public.trips set status = 'cancelled' where id = p_trip_id;

  perform private.write_audit(
    v_school, v_actor, 'trip.cancelled', 'trip', p_trip_id,
    jsonb_build_object('bus_id', v_trip.bus_id, 'scheduled_start', v_trip.scheduled_start, 'reason', v_reason)
  );
end;
$$;

-- Archive a finished or cancelled trip, or bring an archived one back.
create function public.admin_set_trip_archived(p_trip_id uuid, p_archived boolean)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_trip public.trips;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if p_archived is null then
    raise exception 'Say whether to archive or restore' using errcode = '22023';
  end if;

  select * into v_trip
  from public.trips
  where id = p_trip_id and school_id = v_school
  for update;
  if not found then
    raise exception 'Trip not found' using errcode = 'P0002';
  end if;
  if p_archived and v_trip.status not in ('completed', 'cancelled') then
    raise exception 'Only a finished or cancelled trip can be archived' using errcode = '55000';
  end if;

  update public.trips
  set archived_at = case when p_archived then now() else null end
  where id = p_trip_id;

  perform private.write_audit(
    v_school, v_actor, case when p_archived then 'trip.archived' else 'trip.unarchived' end, 'trip', p_trip_id,
    jsonb_build_object('status', v_trip.status)
  );
end;
$$;

revoke execute on function
  public.admin_cancel_trip(uuid, text),
  public.admin_set_trip_archived(uuid, boolean)
  from public, anon;
grant execute on function
  public.admin_cancel_trip(uuid, text),
  public.admin_set_trip_archived(uuid, boolean)
  to authenticated;
