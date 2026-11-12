-- Core multi-tenant tables. Every tenant-owned table carries school_id.
-- Composite (id, school_id) keys let child rows prove they belong to the same
-- school as the rows they reference.

create table public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 120),
  short_name text check (char_length(short_name) between 1 and 20),
  timezone text not null default 'Africa/Douala',
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now()
);

-- One domain belongs to at most one school; sign-up matches against this.
create table public.school_domains (
  domain text primary key check (domain = lower(domain) and domain !~ '[@\s]'),
  school_id uuid not null references public.schools (id) on delete cascade,
  created_at timestamptz not null default now()
);
create index school_domains_school_id_idx on public.school_domains (school_id);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  school_id uuid not null references public.schools (id),
  email text not null,
  full_name text not null default '',
  avatar_url text,
  phone text,
  role public.user_role not null default 'student',
  status public.account_status not null default 'verified',
  matricule text,
  department text,
  program text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, school_id)
);
create index profiles_school_role_idx on public.profiles (school_id, role);

create table public.semesters (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  name public.semester_name not null,
  year int not null check (year between 2000 and 2100),
  start_date date not null,
  end_date date not null,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  check (end_date > start_date),
  unique (school_id, name, year),
  unique (id, school_id)
);

create table public.stops (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  name text not null check (char_length(name) between 1 and 120),
  location extensions.geography(Point, 4326) not null,
  photo_path text,
  active boolean not null default true,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id, name),
  unique (id, school_id)
);
create index stops_location_idx on public.stops using gist (location);

create table public.buses (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  plate text not null check (char_length(plate) between 1 and 20),
  capacity int not null check (capacity > 0),
  in_service boolean not null default true,
  created_at timestamptz not null default now(),
  unique (school_id, plate),
  unique (id, school_id)
);

create table public.trips (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  bus_id uuid not null,
  driver_id uuid,
  direction public.trip_direction not null,
  status public.trip_status not null default 'scheduled',
  scheduled_start timestamptz not null,
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (bus_id, school_id) references public.buses (id, school_id),
  foreign key (driver_id, school_id) references public.profiles (id, school_id),
  check (ended_at is null or started_at is not null),
  unique (id, school_id)
);
create index trips_school_start_idx on public.trips (school_id, scheduled_start desc);
create index trips_bus_idx on public.trips (bus_id);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  student_id uuid not null,
  semester_id uuid not null,
  stop_id uuid not null,
  status public.subscription_status not null default 'pending',
  proof_path text,
  review_note text check (char_length(review_note) <= 500),
  reviewed_by uuid references public.profiles (id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (student_id, school_id) references public.profiles (id, school_id),
  foreign key (semester_id, school_id) references public.semesters (id, school_id),
  foreign key (stop_id, school_id) references public.stops (id, school_id),
  unique (id, school_id)
);
-- A student has at most one live request per semester; a rejected one can be resubmitted.
create unique index subscriptions_one_live_per_semester
  on public.subscriptions (student_id, semester_id)
  where status in ('pending', 'approved');
create index subscriptions_school_status_idx on public.subscriptions (school_id, status);
create index subscriptions_student_idx on public.subscriptions (student_id);

create table public.scans (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  trip_id uuid not null,
  student_id uuid not null,
  subscription_id uuid not null,
  stop_id uuid,
  scanned_by uuid not null,
  scanned_at timestamptz not null default now(),
  location extensions.geography(Point, 4326),
  accuracy_m real check (accuracy_m is null or accuracy_m >= 0),
  foreign key (trip_id, school_id) references public.trips (id, school_id),
  foreign key (student_id, school_id) references public.profiles (id, school_id),
  foreign key (subscription_id, school_id) references public.subscriptions (id, school_id),
  foreign key (stop_id, school_id) references public.stops (id, school_id),
  foreign key (scanned_by, school_id) references public.profiles (id, school_id),
  -- A repeat scan of the same student on the same trip is the same boarding.
  unique (trip_id, student_id)
);
create index scans_school_time_idx on public.scans (school_id, scanned_at desc);
create index scans_student_idx on public.scans (student_id, scanned_at desc);
create index scans_scanner_idx on public.scans (scanned_by, scanned_at desc);
create index scans_location_idx on public.scans using gist (location);

-- Latest position per bus. One row per bus, overwritten.
create table public.live_positions (
  bus_id uuid primary key,
  school_id uuid not null,
  trip_id uuid,
  location extensions.geography(Point, 4326) not null,
  speed_mps real check (speed_mps is null or speed_mps >= 0),
  heading_deg real check (heading_deg is null or heading_deg between 0 and 360),
  accuracy_m real check (accuracy_m is null or accuracy_m >= 0),
  source text not null default 'phone' check (source in ('phone', 'staff', 'device', 'scan')),
  recorded_at timestamptz not null default now(),
  foreign key (bus_id, school_id) references public.buses (id, school_id),
  foreign key (trip_id, school_id) references public.trips (id, school_id)
);
create index live_positions_school_idx on public.live_positions (school_id);

create table public.audit_log (
  id bigint generated always as identity primary key,
  school_id uuid not null references public.schools (id),
  actor_id uuid references public.profiles (id),
  action text not null,
  target_type text not null,
  target_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index audit_log_school_time_idx on public.audit_log (school_id, created_at desc);

-- Keep updated_at honest and server-controlled.
create function private.touch_updated_at() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_touch before update on public.profiles
  for each row execute function private.touch_updated_at();
create trigger stops_touch before update on public.stops
  for each row execute function private.touch_updated_at();
create trigger subscriptions_touch before update on public.subscriptions
  for each row execute function private.touch_updated_at();
