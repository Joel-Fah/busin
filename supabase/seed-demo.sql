-- Demo data for LOCAL development only. Run it with: npm run seed:demo
--
-- It is not part of `supabase db reset` (config.toml loads only seed.sql), and it only ever touches demo rows:
-- accounts whose email starts with demo. and rows whose id starts with de. Running it again replaces them, and
-- moves the trips to the current dates. Never run it against a hosted project.
--
-- Variables from the caller: :demo_password (given to the admin, a driver and a student so they can sign in).

select setseed(0.42);

-- ---------------------------------------------------------------- remove the previous demo rows
delete from public.scans
where trip_id in (select id from public.trips where bus_id::text like 'de%')
   or student_id in (select id from auth.users where email like 'demo.%@ictuniversity.edu.cm');
delete from public.subscriptions
where student_id in (select id from auth.users where email like 'demo.%@ictuniversity.edu.cm');
delete from public.live_positions where bus_id::text like 'de%';
delete from public.trips where bus_id::text like 'de%';
delete from public.buses where id::text like 'de%';
delete from public.stops where id::text like 'de%';
delete from auth.users where email like 'demo.%@ictuniversity.edu.cm';

-- ---------------------------------------------------------------- people
-- 1 admin, 5 drivers (staff) and 60 students. The sign-up trigger creates each profile.
create temp table demo_people on commit drop as
select
  case when n = 0 then 'admin' when n < 0 then 'staff' else 'student' end as role,
  n,
  ('de10' || lpad(abs(n)::text, 4, '0') || case when n < 0 then '-1000' when n = 0 then '-2000' else '-0000' end || '-4000-8000-000000000000')::uuid as id,
  case when n = 0 then 'demo.admin@ictuniversity.edu.cm'
       when n < 0 then 'demo.driver' || abs(n) || '@ictuniversity.edu.cm'
       else 'demo.student' || lpad(n::text, 2, '0') || '@ictuniversity.edu.cm' end as email,
  (array['Amina','Brice','Carine','Daniel','Estelle','Fabrice','Grace','Herve','Ines','Junior','Karelle','Landry','Mireille',
         'Nadine','Olivier','Prisca','Quentin','Rosine','Serge','Tatiana','Ulrich','Vanessa','Wilfried','Yvan','Zita'])[1 + (abs(n) * 3) % 25] as first_name,
  (array['Mbarga','Fotso','Nkeng','Tchamba','Onana','Ngono','Essomba','Kamga','Atangana','Mvondo','Tagne','Nguemo','Abena','Owona',
         'Ekani','Djoumessi','Ndongo'])[1 + (abs(n) * 7) % 17] as last_name
from generate_series(-5, 60) as n;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
select
  '00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated', email,
  extensions.crypt(:'demo_password', extensions.gen_salt('bf')), now(),
  '{"provider":"google","providers":["google"]}',
  jsonb_build_object('full_name', first_name || ' ' || last_name),
  now() - (random() * interval '120 days'), now(), '', '', '', ''
from demo_people;

insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), id, id::text, 'google', jsonb_build_object('sub', id::text, 'email', email), now(), now(), now()
from demo_people;

update public.profiles p
set role = d.role::public.user_role,
    full_name = d.first_name || ' ' || d.last_name,
    status = case
      when d.role <> 'student' then 'verified'
      when d.n % 17 = 0 then 'suspended'
      when d.n % 13 = 0 then 'pending'
      else 'verified' end::public.account_status,
    phone = '+2376' || lpad((70000000 + abs(d.n) * 137911 % 29999999)::text, 8, '0'),
    matricule = case when d.role = 'student' then 'ICTU2026' || lpad(d.n::text, 4, '0') end,
    department = case when d.role = 'student'
      then (array['Computer Science','Software Engineering','Networks and Telecoms','Business Administration'])[1 + d.n % 4] end,
    program = case when d.role = 'student' then (array['BSc','BSc','BSc','MSc'])[1 + d.n % 4] end
from demo_people d
where p.id = d.id;

-- ---------------------------------------------------------------- stops (approximate places around Yaounde)
insert into public.stops (id, school_id, name, location, active)
select ('de300000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid, '00000000-0000-4000-8000-000000000001', name,
       extensions.st_point(lng, lat)::extensions.geography, active
from (values
  (1, 'Mvan roundabout',        11.5290, 3.8150, true),
  (2, 'Mendong market',         11.4770, 3.8200, true),
  (3, 'Biyem-Assi terminal',    11.4890, 3.8280, true),
  (4, 'Melen junction',         11.5050, 3.8680, true),
  (5, 'Ekounou crossroads',     11.5380, 3.8350, true),
  (6, 'Nsimeyong carrefour',    11.5030, 3.8140, true),
  (7, 'Bastos embassy road',    11.5120, 3.8960, true),
  (8, 'Essos hospital',         11.5360, 3.8710, true),
  (9, 'Mvog-Ada church',        11.5210, 3.8420, true),
  (10, 'Nkolbisson bridge',     11.4640, 3.8650, true),
  (11, 'Etoudi palace road',    11.5200, 3.9030, true),
  (12, 'Old Odza junction',     11.5570, 3.8190, false)
) as s(i, name, lng, lat, active);

-- ---------------------------------------------------------------- buses
insert into public.buses (id, school_id, plate, capacity, in_service)
select ('de200000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid, '00000000-0000-4000-8000-000000000001', plate, capacity, in_service
from (values
  (1, 'DEMO-101', 60, true), (2, 'DEMO-102', 60, true), (3, 'DEMO-103', 50, true),
  (4, 'DEMO-104', 50, true), (5, 'DEMO-105', 30, true), (6, 'DEMO-106', 50, false)
) as b(i, plate, capacity, in_service);

-- ---------------------------------------------------------------- semesters: one finished, the current one, the next
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('de100000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'spring', 2026, '2026-02-02', '2026-06-26'),
  ('de100000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000001', 'spring', 2027, '2027-02-01', '2027-06-30')
on conflict do nothing;
-- If no semester covers today (a later date than the seed expected), add one that does.
insert into public.semesters (id, school_id, name, year, start_date, end_date)
select 'de100000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', 'summer',
       extract(year from current_date)::int, current_date - 30, current_date + 90
where not exists (
  select 1 from public.semesters
  where school_id = '00000000-0000-4000-8000-000000000001' and current_date between start_date and end_date
)
on conflict do nothing;

-- ---------------------------------------------------------------- subscriptions
create temp table demo_semester on commit drop as
select id from public.semesters
where school_id = '00000000-0000-4000-8000-000000000001' and current_date between start_date and end_date
order by start_date desc limit 1;

-- Students 1 to 40 approved, 41 to 50 waiting, 51 to 54 rejected, the rest have not subscribed. Most pick the
-- first few stops, so the counts differ from stop to stop.
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status, review_note, reviewed_by, reviewed_at, created_at)
select
  '00000000-0000-4000-8000-000000000001', d.id, (select id from demo_semester),
  ('de300000-0000-4000-8000-' || lpad((1 + floor(power(random(), 1.8) * 11))::int::text, 12, '0'))::uuid,
  case when d.n <= 40 then 'approved' when d.n <= 50 then 'pending' else 'rejected' end::public.subscription_status,
  case when d.n > 50 then 'The proof of payment was not readable. Please send it again.' end,
  case when d.n <> 0 and (d.n <= 40 or d.n > 50) then (select id from demo_people where role = 'admin') end,
  case when d.n <= 40 or d.n > 50 then now() - (random() * interval '20 days') end,
  now() - interval '25 days' + (random() * interval '20 days')
from demo_people d
where d.role = 'student' and d.n between 1 and 54;

-- Thirty of them also rode last semester.
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status, reviewed_by, reviewed_at, created_at)
select '00000000-0000-4000-8000-000000000001', d.id, 'de100000-0000-4000-8000-000000000001',
       ('de300000-0000-4000-8000-' || lpad((1 + floor(power(random(), 1.8) * 11))::int::text, 12, '0'))::uuid,
       'expired', (select id from demo_people where role = 'admin'), '2026-02-10', '2026-02-05'
from demo_people d
where d.role = 'student' and d.n between 1 and 30;

-- ---------------------------------------------------------------- trips: two weeks back, a few days ahead
-- Four buses run on weekdays: one trip to school in the morning and one home in the afternoon. Bus 5 is a spare
-- without a driver. Times are Douala wall-clock times.
create temp table demo_trips on commit drop as
select
  md5(d::text || b.i || dir)::uuid as id,
  ('de200000-0000-4000-8000-' || lpad(b.i::text, 12, '0'))::uuid as bus_id,
  case when b.i <= 4 and not (d >= current_date + 3 and b.i = 3) then (select id from demo_people where n = -b.i) end as driver_id,
  dir::public.trip_direction as direction,
  b.i as bus_index,
  d as day,
  ((d + case when dir = 'inbound' then time '06:30' else time '16:30' end + (b.i * interval '10 minutes'))::timestamp
     at time zone 'Africa/Douala') as scheduled_start
from (select generate_series(current_date - 14, current_date + 4, interval '1 day')::date as d) as g
cross join generate_series(1, 5) as b(i)
cross join (values ('inbound'), ('outbound')) as v(dir)
where extract(isodow from d) < 6 and (b.i <= 4 or dir = 'inbound');

insert into public.trips (id, school_id, bus_id, driver_id, direction, status, scheduled_start, started_at, ended_at, archived_at)
select
  id, '00000000-0000-4000-8000-000000000001', bus_id, driver_id, direction,
  s.status::public.trip_status,
  scheduled_start,
  case when s.status in ('completed', 'active') then scheduled_start + interval '2 minutes' end,
  case when s.status = 'completed' then scheduled_start + interval '50 minutes' end,
  -- Finished or cancelled trips from before last week were put away.
  case when s.status in ('completed', 'cancelled') and day < current_date - 7 then scheduled_start + interval '1 day' end
from (
  select t.*,
    case
      when day > current_date and bus_index = 2 and direction = 'inbound' and day = current_date + 1 then 'cancelled'
      when scheduled_start + interval '55 minutes' < now() and (hashtext(id::text) % 17) = 0 then 'cancelled'
      when scheduled_start + interval '55 minutes' < now() then 'completed'
      when scheduled_start <= now() then 'active'
      else 'scheduled' end as status
  from demo_trips t
) s(id, bus_id, driver_id, direction, bus_index, day, scheduled_start, status);

-- ---------------------------------------------------------------- boardings
-- Each approved student rides one bus (by number), and boards about two in three of its trips.
-- A running trip has the boardings that have happened so far.
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by, scanned_at, location, accuracy_m)
select
  '00000000-0000-4000-8000-000000000001', t.id, d.id, sub.id, sub.stop_id, t.driver_id,
  tr.started_at + (random() * least(interval '40 minutes', coalesce(now() - tr.started_at, interval '40 minutes'))),
  st.location, round((5 + random() * 20)::numeric, 1)
from public.trips tr
join demo_trips t on t.id = tr.id
join demo_people d on d.role = 'student' and d.n between 1 and 40 and 1 + d.n % 4 = t.bus_index
join public.subscriptions sub on sub.student_id = d.id and sub.semester_id = (select id from demo_semester) and sub.status = 'approved'
join public.stops st on st.id = sub.stop_id
where tr.status in ('completed', 'active') and t.driver_id is not null and random() < 0.66;

-- ---------------------------------------------------------------- one trip that is always running
-- The weekday trips above are only "running" at their own hour, so this extra one keeps the Running tab and a
-- live trip with boardings on show at any time of day. It is on the spare bus, with the fifth driver.
insert into public.trips (id, school_id, bus_id, driver_id, direction, status, scheduled_start, started_at)
values (
  md5('demo-live-trip')::uuid, '00000000-0000-4000-8000-000000000001',
  'de200000-0000-4000-8000-000000000005', (select id from demo_people where n = -5),
  'outbound', 'active', now() - interval '12 minutes', now() - interval '10 minutes'
);
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by, scanned_at, location, accuracy_m)
select '00000000-0000-4000-8000-000000000001', md5('demo-live-trip')::uuid, d.id, sub.id, sub.stop_id,
       (select id from demo_people where n = -5), now() - (random() * interval '9 minutes'), st.location, 8
from demo_people d
join public.subscriptions sub on sub.student_id = d.id and sub.semester_id = (select id from demo_semester) and sub.status = 'approved'
join public.stops st on st.id = sub.stop_id
where d.role = 'student' and d.n between 33 and 40;
