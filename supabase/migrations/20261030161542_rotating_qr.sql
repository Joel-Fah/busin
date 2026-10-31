-- Rotating QR code.
--
-- Code format:  busin1.<student uuid>.<window>.<mac>
--   window = floor(unix seconds / 30)
--   mac    = first 20 hex characters of HMAC-SHA256(key = student secret,
--            message = "<student uuid>:<window>")
-- The student device holds its secret (fetched once through get_my_qr_secret, kept in secure
-- storage) and shows a fresh code every 30 seconds. Staff submit the scanned code to
-- record_qr_scan, which recomputes the mac from the secret stored here. A photographed
-- code is accepted for at most about a minute. The old plain-id QR is refused.
-- Format reference and test vector: docs/guides/qr-code-format.md.

-- Per-student secrets. Never readable through the API; only the functions below touch it.
create table private.qr_secrets (
  student_id uuid primary key references public.profiles (id) on delete cascade,
  secret bytea not null check (octet_length(secret) = 32),
  created_at timestamptz not null default now(),
  rotated_at timestamptz
);
alter table private.qr_secrets enable row level security;
alter table private.qr_secrets force row level security;
revoke all on private.qr_secrets from public, anon, authenticated;

create function private.qr_window(p_at timestamptz) returns bigint
language sql immutable
set search_path = ''
as $$
  select floor(extract(epoch from p_at) / 30)::bigint
$$;

create function private.qr_mac(p_secret bytea, p_student uuid, p_window bigint) returns text
language sql immutable
set search_path = ''
as $$
  select left(
    encode(
      extensions.hmac(convert_to(p_student::text || ':' || p_window::text, 'UTF8'), p_secret, 'sha256'),
      'hex'
    ),
    20
  )
$$;

-- The approved subscription that covers today in the school's timezone, if any.
create function private.active_subscription_id(p_student uuid, p_school uuid) returns uuid
language sql stable security definer
set search_path = ''
as $$
  select s.id
  from public.subscriptions s
  join public.semesters sem on sem.id = s.semester_id and sem.school_id = s.school_id
  join public.schools sc on sc.id = s.school_id
  where s.student_id = p_student
    and s.school_id = p_school
    and s.status = 'approved'
    and (now() at time zone sc.timezone)::date between sem.start_date and sem.end_date
  limit 1
$$;

revoke execute on function
  private.qr_window(timestamptz),
  private.qr_mac(bytea, uuid, bigint),
  private.active_subscription_id(uuid, uuid)
  from public;

-- record_scan now shares the subscription check above (same behaviour as before).
create or replace function private.record_scan(
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

  v_sub := private.active_subscription_id(p_student_id, v_school);
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

-- A student fetches their secret once and keeps it in secure storage. Only a verified
-- student with an active subscription gets one.
create function public.get_my_qr_secret() returns text
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_secret bytea;
begin
  if private.my_role() is distinct from 'student' then
    raise exception 'Only students have a boarding code' using errcode = '42501';
  end if;
  if private.active_subscription_id(v_uid, v_school) is null then
    raise exception 'No active subscription' using errcode = '42501';
  end if;

  insert into private.qr_secrets (student_id, secret)
  values (v_uid, extensions.gen_random_bytes(32))
  on conflict (student_id) do nothing;

  select secret into v_secret from private.qr_secrets where student_id = v_uid;
  return encode(v_secret, 'base64');
end;
$$;

-- Replace the secret, for example after losing a phone. Codes made with the old secret stop working.
create function public.rotate_my_qr_secret() returns text
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_secret bytea := extensions.gen_random_bytes(32);
begin
  if private.my_role() is distinct from 'student' then
    raise exception 'Only students have a boarding code' using errcode = '42501';
  end if;
  if private.active_subscription_id(v_uid, v_school) is null then
    raise exception 'No active subscription' using errcode = '42501';
  end if;

  insert into private.qr_secrets (student_id, secret)
  values (v_uid, v_secret)
  on conflict (student_id) do update set secret = excluded.secret, rotated_at = now();

  perform private.write_audit(v_school, v_uid, 'qr.secret_rotated', 'profile', v_uid);
  return encode(v_secret, 'base64');
end;
$$;

-- Staff submit a scanned code. The code must be well formed, recent and signed with the
-- student's secret before the scan is verified and recorded.
create function public.record_qr_scan(
  p_trip_id uuid,
  p_code text,
  p_stop_id uuid default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_accuracy real default null
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_parts text[];
  v_student uuid;
  v_window bigint;
  v_secret bytea;
  v_current bigint := private.qr_window(now());
  v_expected text;
begin
  if not private.is_staff() then
    raise exception 'Staff access required' using errcode = '42501';
  end if;

  if p_code is null or char_length(p_code) > 120 then
    return jsonb_build_object('valid', false, 'reason', 'invalid_code');
  end if;
  v_parts := string_to_array(p_code, '.');
  if array_length(v_parts, 1) is distinct from 4
     or v_parts[1] <> 'busin1'
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

  v_expected := private.qr_mac(v_secret, v_student, v_window);
  -- Compare hashes of both values so the comparison time does not depend on where they differ.
  if extensions.digest(v_expected, 'sha256') <> extensions.digest(v_parts[4], 'sha256') then
    return jsonb_build_object('valid', false, 'reason', 'invalid_code');
  end if;

  return private.record_scan(p_trip_id, v_student, p_stop_id, p_lat, p_lng, p_accuracy);
end;
$$;

revoke execute on function
  public.get_my_qr_secret(),
  public.rotate_my_qr_secret(),
  public.record_qr_scan(uuid, text, uuid, double precision, double precision, real)
  from public, anon;
grant execute on function
  public.get_my_qr_secret(),
  public.rotate_my_qr_secret(),
  public.record_qr_scan(uuid, text, uuid, double precision, double precision, real)
  to authenticated;
