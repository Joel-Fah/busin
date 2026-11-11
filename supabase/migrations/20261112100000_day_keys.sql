-- Day keys (ADR 0014): boarding codes that a staff phone can check without a connection.
--
-- A student's code is now made from a key valid for one school day, derived from their secret:
--   day_key = HMAC-SHA256(key = secret, message = "busin-day:" || school-local date YYYY-MM-DD)
--   code    = busin2.<student uuid>.<window>.<mac>,  mac = first 20 hex of HMAC-SHA256(day_key, "<uuid>:<window>")
-- The date is the school-local date of the window's start. Each morning staff phones download the day keys of the
-- school's riders (staff_day_keys), check codes on the spot even offline, and queue the scans; on sync the server
-- checks them again, against the time they were scanned. busin1 codes are no longer accepted (nothing was released).
--
-- A lost staff phone exposes one day of keys for one school, never the students' secrets. A student who is revoked
-- or suspended drops out of the next download, and the server refuses them on sync.

-- Queued scans carry the phone's own id for the scan, so sending it twice records it once.
alter table public.scans add column client_id uuid;
create unique index scans_client_id_idx on public.scans (client_id) where client_id is not null;

create function private.qr_day_key(p_secret bytea, p_date date) returns bytea
language sql immutable
set search_path = ''
as $$
  select extensions.hmac(convert_to('busin-day:' || to_char(p_date, 'YYYY-MM-DD'), 'UTF8'), p_secret, 'sha256')
$$;

-- The school-local date of a window's start.
create function private.qr_window_date(p_window bigint, p_zone text) returns date
language sql immutable
set search_path = ''
as $$
  select (to_timestamp(p_window * 30) at time zone p_zone)::date
$$;

-- The approved subscription covering a given day at the school.
create function private.subscription_on(p_student uuid, p_school uuid, p_day date) returns uuid
language sql stable security definer
set search_path = ''
as $$
  select s.id
  from public.subscriptions s
  join public.semesters sem on sem.id = s.semester_id and sem.school_id = s.school_id
  where s.student_id = p_student
    and s.school_id = p_school
    and s.status = 'approved'
    and p_day between sem.start_date and sem.end_date
  limit 1
$$;

revoke execute on function private.qr_day_key(bytea, date), private.qr_window_date(bigint, text),
  private.subscription_on(uuid, uuid, date) from public;

-- The scan itself, now also for scans that were made offline and arrive later. A queued scan carries the time it was
-- made and the phone's id for it; it is checked against that time, may arrive after the trip ended, and is recorded
-- once whatever happens on the way.
drop function public.record_qr_scan(uuid, text, uuid, double precision, double precision, real);
drop function private.record_scan(uuid, uuid, uuid, double precision, double precision, real);

create function private.record_scan(
  p_trip_id uuid,
  p_student_id uuid,
  p_stop_id uuid default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_accuracy real default null,
  p_scanned_at timestamptz default null,
  p_client_id uuid default null
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_at timestamptz := coalesce(p_scanned_at, now());
  v_zone text;
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
  if p_scanned_at is null then
    -- Scanned now: the trip must be running.
    if v_trip.status <> 'active' then
      raise exception 'The trip is not active' using errcode = '55000';
    end if;
  else
    -- Scanned earlier: the trip must have been running then (five minutes of slack for phone clocks).
    if v_trip.started_at is null
       or v_at < v_trip.started_at - interval '5 minutes'
       or (v_trip.ended_at is not null and v_at > v_trip.ended_at + interval '5 minutes') then
      raise exception 'The trip was not running at that time' using errcode = '55000';
    end if;
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

  select sc.timezone into v_zone from public.schools sc where sc.id = v_school;
  v_sub := private.subscription_on(p_student_id, v_school, (v_at at time zone v_zone)::date);
  if v_sub is null then
    return jsonb_build_object('valid', false, 'reason', 'no_active_subscription');
  end if;

  insert into public.scans (
    school_id, trip_id, student_id, subscription_id, stop_id, scanned_by, scanned_at, location, accuracy_m, client_id
  ) values (
    v_school, p_trip_id, p_student_id, v_sub, p_stop_id, v_actor, v_at, v_point, p_accuracy, p_client_id
  )
  on conflict do nothing
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

revoke execute on function private.record_scan(uuid, uuid, uuid, double precision, double precision, real, timestamptz, uuid) from public;

create function public.record_qr_scan(
  p_trip_id uuid,
  p_code text,
  p_stop_id uuid default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_accuracy real default null,
  p_scanned_at timestamptz default null,
  p_client_id uuid default null
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_parts text[];
  v_student uuid;
  v_window bigint;
  v_secret bytea;
  v_zone text;
  v_current bigint;
  v_expected text;
begin
  if not private.is_staff() then
    raise exception 'Staff access required' using errcode = '42501';
  end if;

  -- A queued scan may be a day old at most, and never from the future (two minutes of slack for phone clocks).
  if p_scanned_at is not null and (p_scanned_at > now() + interval '2 minutes' or p_scanned_at < now() - interval '24 hours') then
    raise exception 'invalid_scan_time' using errcode = '22023';
  end if;
  v_current := private.qr_window(coalesce(p_scanned_at, now()));

  if p_code is null or char_length(p_code) > 120 then
    return jsonb_build_object('valid', false, 'reason', 'invalid_code');
  end if;
  v_parts := string_to_array(p_code, '.');
  if array_length(v_parts, 1) is distinct from 4
     or v_parts[1] <> 'busin2'
     or v_parts[2] !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     or v_parts[3] !~ '^[0-9]{1,12}$'
     or v_parts[4] !~ '^[0-9a-f]{20}$' then
    return jsonb_build_object('valid', false, 'reason', 'invalid_code');
  end if;

  v_student := v_parts[2]::uuid;
  v_window := v_parts[3]::bigint;

  -- One window of tolerance either side for clock differences between phones.
  if v_window < v_current - 1 then
    return jsonb_build_object('valid', false, 'reason', 'expired_code');
  end if;
  if v_window > v_current + 1 then
    return jsonb_build_object('valid', false, 'reason', 'invalid_code');
  end if;

  select secret into v_secret from private.qr_secrets where student_id = v_student;
  if v_secret is null then
    return jsonb_build_object('valid', false, 'reason', 'invalid_code');
  end if;
  select sc.timezone into v_zone from public.schools sc where sc.id = private.my_school_id();

  v_expected := private.qr_mac(private.qr_day_key(v_secret, private.qr_window_date(v_window, coalesce(v_zone, 'UTC'))), v_student, v_window);
  -- Compare hashes of both values so the comparison time does not depend on where they differ.
  if extensions.digest(v_expected, 'sha256') <> extensions.digest(v_parts[4], 'sha256') then
    return jsonb_build_object('valid', false, 'reason', 'invalid_code');
  end if;

  return private.record_scan(p_trip_id, v_student, p_stop_id, p_lat, p_lng, p_accuracy, p_scanned_at, p_client_id);
end;
$$;

revoke execute on function public.record_qr_scan(uuid, text, uuid, double precision, double precision, real, timestamptz, uuid) from public, anon;
grant execute on function public.record_qr_scan(uuid, text, uuid, double precision, double precision, real, timestamptz, uuid) to authenticated;

-- Today's riders for a staff phone: every verified student of the school with an approved subscription covering
-- today, with their day key, so the phone can check codes offline. The name, photo, matricule and stop are what the
-- result card at the door shows. Each download is audited. Students who never opened their code have no secret yet,
-- and so no code to show; they are left out.
create function public.staff_day_keys()
returns table (student_id uuid, day_key text, full_name text, avatar_url text, matricule text, stop_id uuid, day date)
language plpgsql security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
  v_zone text;
  v_today date;
begin
  if not private.is_staff() then
    raise exception 'Staff access required' using errcode = '42501';
  end if;
  select sc.timezone into v_zone from public.schools sc where sc.id = v_school;
  v_today := (now() at time zone coalesce(v_zone, 'UTC'))::date;

  perform private.write_audit(v_school, (select auth.uid()), 'day_keys.downloaded', 'school', v_school,
    jsonb_build_object('day', v_today));

  return query
  select p.id, encode(private.qr_day_key(q.secret, v_today), 'base64'), p.full_name, p.avatar_url, p.matricule, s.stop_id, v_today
  from public.profiles p
  join private.qr_secrets q on q.student_id = p.id
  join public.subscriptions s on s.id = private.subscription_on(p.id, v_school, v_today)
  where p.school_id = v_school and p.role = 'student' and p.status = 'verified'
  order by p.full_name;
end;
$$;

revoke execute on function public.staff_day_keys() from public, anon;
grant execute on function public.staff_day_keys() to authenticated;
