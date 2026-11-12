-- Scan verification and recording.
--
-- This is an internal function in the private schema, which the API does not
-- expose. The rotating QR migration adds the public wrapper that turns a
-- scanned code into a student id and calls this, so a plain student id can
-- never be submitted from a client.
--
-- Staff-facing outcomes (unknown student, suspended, no subscription) are
-- returned as data. Authorization problems (not staff, wrong school, trip not
-- active) raise errors.

create function private.record_scan(
  p_trip_id uuid,
  p_student_id uuid,
  p_stop_id uuid default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_accuracy real default null
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_trip public.trips;
  v_student public.profiles;
  v_sub uuid;
  v_scan uuid;
  v_point extensions.geography;
begin
  if not private.is_staff() then
    raise exception 'Staff access required' using errcode = '42501';
  end if;

  if (p_lat is null) <> (p_lng is null) then
    raise exception 'Latitude and longitude must be given together' using errcode = '22023';
  end if;
  if p_lat is not null then
    if p_lat not between -90 and 90 or p_lng not between -180 and 180 then
      raise exception 'Coordinates are out of range' using errcode = '22023';
    end if;
    v_point := extensions.st_point(p_lng, p_lat)::extensions.geography;
  end if;

  select * into v_trip from public.trips where id = p_trip_id and school_id = v_school;
  if not found then
    raise exception 'Trip not found' using errcode = 'P0002';
  end if;
  if v_trip.status <> 'active' then
    raise exception 'The trip is not active' using errcode = '55000';
  end if;

  if p_stop_id is not null then
    perform 1 from public.stops
    where id = p_stop_id and school_id = v_school and active;
    if not found then
      raise exception 'Stop not found' using errcode = 'P0002';
    end if;
  end if;

  select * into v_student from public.profiles
  where id = p_student_id and school_id = v_school;
  if not found or v_student.role <> 'student' then
    return jsonb_build_object('valid', false, 'reason', 'student_not_found');
  end if;
  if v_student.status <> 'verified' then
    return jsonb_build_object('valid', false, 'reason', 'account_not_verified');
  end if;

  -- An approved subscription whose semester includes today in the school's timezone.
  select s.id into v_sub
  from public.subscriptions s
  join public.semesters sem on sem.id = s.semester_id and sem.school_id = s.school_id
  join public.schools sc on sc.id = s.school_id
  where s.student_id = p_student_id
    and s.school_id = v_school
    and s.status = 'approved'
    and (now() at time zone sc.timezone)::date between sem.start_date and sem.end_date
  limit 1;
  if v_sub is null then
    return jsonb_build_object('valid', false, 'reason', 'no_active_subscription');
  end if;

  insert into public.scans (
    school_id, trip_id, student_id, subscription_id, stop_id, scanned_by, location, accuracy_m
  ) values (
    v_school, p_trip_id, p_student_id, v_sub, p_stop_id, v_actor, v_point, p_accuracy
  )
  on conflict (trip_id, student_id) do nothing
  returning id into v_scan;

  return jsonb_build_object(
    'valid', true,
    'duplicate', v_scan is null,
    'scan_id', v_scan,
    'student', jsonb_build_object(
      'full_name', v_student.full_name,
      'avatar_url', v_student.avatar_url,
      'matricule', v_student.matricule
    )
  );
end;
$$;

revoke execute on function
  private.record_scan(uuid, uuid, uuid, double precision, double precision, real)
  from public;
