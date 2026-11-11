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
delete from auth.users where email like 'demo.%@ictuniversity.edu.cm';

-- ---------------------------------------------------------------- people
-- 1 admin, 5 drivers (staff) and 400 students, enough to read the Insights properly. The sign-up trigger creates
-- each profile.
create temp table demo_people on commit drop as
select
  case when n = 0 then 'admin' when n < 0 then 'staff' else 'student' end as role,
  n,
  ('de10' || lpad(abs(n)::text, 4, '0') || case when n < 0 then '-1000' when n = 0 then '-2000' else '-0000' end || '-4000-8000-000000000000')::uuid as id,
  case when n = 0 then 'demo.admin@ictuniversity.edu.cm'
       when n < 0 then 'demo.driver' || abs(n) || '@ictuniversity.edu.cm'
       else 'demo.student' || lpad(n::text, greatest(2, length(n::text)), '0') || '@ictuniversity.edu.cm' end as email,
  (array['Amina','Brice','Carine','Daniel','Estelle','Fabrice','Grace','Herve','Ines','Junior','Karelle','Landry','Mireille',
         'Nadine','Olivier','Prisca','Quentin','Rosine','Serge','Tatiana','Ulrich','Vanessa','Wilfried','Yvan','Zita'])[1 + (abs(n) * 3) % 25] as first_name,
  (array['Mbarga','Fotso','Nkeng','Tchamba','Onana','Ngono','Essomba','Kamga','Atangana','Mvondo','Tagne','Nguemo','Abena','Owona',
         'Ekani','Djoumessi','Ndongo'])[1 + (abs(n) * 7) % 17] as last_name
from generate_series(-5, 400) as n;

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

-- ---------------------------------------------------------------- faculties, departments, degree levels
insert into public.faculties (id, school_id, name, code) values
  ('de600000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'Faculty of Information and Communication Technology', 'ICT'),
  ('de600000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', 'Faculty of Business and Management Sciences', 'BMS')
on conflict (id) do nothing;

insert into public.departments (id, school_id, faculty_id, name, code) values
  ('de400000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000001', 'Computer Science', 'CSC'),
  ('de400000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000001', 'Software Engineering', 'SEN'),
  ('de400000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000001', 'Cybersecurity', 'CYS'),
  ('de400000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000001', 'Information Systems and Networks', 'ISN'),
  ('de400000-0000-4000-8000-000000000005', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000001', 'Information and Communication Technology', 'ICT'),
  ('de400000-0000-4000-8000-000000000006', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000002', 'Accounting and Finance', 'ACF'),
  ('de400000-0000-4000-8000-000000000007', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000002', 'Marketing and Communication', 'MKC'),
  ('de400000-0000-4000-8000-000000000008', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000002', 'Human Resource Management', 'HRM'),
  ('de400000-0000-4000-8000-000000000009', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000002', 'Banking and Insurance', 'BNI'),
  ('de400000-0000-4000-8000-000000000010', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000002', 'Entrepreneurship and Innovation', 'ENI'),
  ('de400000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-000000000001', 'de600000-0000-4000-8000-000000000002', 'Logistics and Supply Chain Management', 'LSC')
on conflict (id) do nothing;

insert into public.programs (id, school_id, name, sort_order) values
  ('de500000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'Bachelor', 1),
  ('de500000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', 'Master', 2),
  ('de500000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000001', 'Doctorate', 3)
on conflict (id) do nothing;

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
    department_id = case when d.role = 'student'
      then ('de400000-0000-4000-8000-' || lpad((1 + d.n % 11)::text, 12, '0'))::uuid end,
    program_id = case when d.role = 'student'
      then ('de500000-0000-4000-8000-' || lpad((case when d.n % 4 = 3 then 2 else 1 end)::text, 12, '0'))::uuid end
from demo_people d
where p.id = d.id;

-- ---------------------------------------------------------------- stops: ICT University's route (as in seed.sql)
-- The same six stops every app uses, kept in step with seed.sql (put back if they were renamed or moved).
insert into public.stops (id, school_id, name, location, active)
select ('00000000-0000-4000-8000-0000000000' || (20 + i))::uuid, '00000000-0000-4000-8000-000000000001', name,
       extensions.st_point(lng, lat)::extensions.geography, true
from (values
  (1, 'Shell Nsimeyong',              11.49596, 3.83990),
  (2, 'Carrefour Vogt',               11.50139, 3.84426),
  (3, 'Olezoa',                       11.51470, 3.84720),
  (4, 'Poste Centrale',               11.51640, 3.86690),
  (5, 'Bata Nlongkak',                11.52241, 3.88911),
  (6, 'Carrefour du Palais (Etoudi)', 11.52404, 3.91562)
) as s(i, name, lng, lat)
on conflict (id) do update set name = excluded.name, location = excluded.location, active = true;

-- Earlier demo stops go. Anything still pointing at one (a test account's subscription or scans) moves to the nearest of
-- the six, so nothing is lost.
create temp table demo_old_stops on commit drop as
select o.id as old_id,
       (select r.id from public.stops r
        where r.school_id = o.school_id and r.id::text like '00000000-0000-4000-8000-00000000002%'
        order by extensions.st_distance(r.location, o.location) limit 1) as new_id
from public.stops o
where o.id::text like 'de%';
update public.subscriptions s set stop_id = d.new_id from demo_old_stops d where s.stop_id = d.old_id;
update public.scans s set stop_id = d.new_id from demo_old_stops d where s.stop_id = d.old_id;
delete from public.route_stops where stop_id in (select old_id from demo_old_stops);
delete from public.stops where id in (select old_id from demo_old_stops);

-- ---------------------------------------------------------------- buses
insert into public.buses (id, school_id, plate, capacity, in_service)
select ('de200000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid, '00000000-0000-4000-8000-000000000001', plate, capacity, in_service
from (values
  (1, 'DEMO-101', 70, true), (2, 'DEMO-102', 60, true), (3, 'DEMO-103', 50, true),
  (4, 'DEMO-104', 40, true), (5, 'DEMO-105', 30, true), (6, 'DEMO-106', 50, false)
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
-- Where each demo student boards, weighted the way a real route fills: Poste Centrale the busiest, Carrefour du Palais
-- the quietest. Stable for a student (from their number), so reruns tell the same story.
create temp table demo_stop on commit drop as
select d.n, ('00000000-0000-4000-8000-0000000000' || (20 + case
    when (d.n * 37) % 100 < 18 then 1   -- Shell Nsimeyong 18%
    when (d.n * 37) % 100 < 29 then 2   -- Carrefour Vogt 11%
    when (d.n * 37) % 100 < 46 then 3   -- Olezoa 17%
    when (d.n * 37) % 100 < 80 then 4   -- Poste Centrale 34%
    when (d.n * 37) % 100 < 93 then 5   -- Bata Nlongkak 13%
    else 6 end))::uuid as stop_id          -- Carrefour du Palais 7%
from demo_people d where d.role = 'student';

create temp table demo_semester on commit drop as
select id from public.semesters
where school_id = '00000000-0000-4000-8000-000000000001' and current_date between start_date and end_date
order by start_date desc limit 1;

-- Students 1 to 300 approved, 301 to 340 waiting, 341 to 352 rejected, the rest have not subscribed.
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status, review_note, reviewed_by, reviewed_at, created_at)
select
  '00000000-0000-4000-8000-000000000001', d.id, (select id from demo_semester),
  (select ds.stop_id from demo_stop ds where ds.n = d.n),
  case when d.n <= 300 then 'approved' when d.n <= 340 then 'pending' else 'rejected' end::public.subscription_status,
  case when d.n > 340 then 'The proof of payment was not readable. Please send it again.' end,
  case when d.n <> 0 and (d.n <= 300 or d.n > 340) then (select id from demo_people where role = 'admin') end,
  case when d.n <= 300 or d.n > 340 then now() - (random() * interval '20 days') end,
  now() - interval '25 days' + (random() * interval '20 days')
from demo_people d
where d.role = 'student' and d.n between 1 and 352;

-- Two hundred of them also rode last semester.
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status, reviewed_by, reviewed_at, created_at)
select '00000000-0000-4000-8000-000000000001', d.id, 'de100000-0000-4000-8000-000000000001',
       (select ds.stop_id from demo_stop ds where ds.n = d.n),
       'expired', (select id from demo_people where role = 'admin'), '2026-02-10', '2026-02-05'
from demo_people d
where d.role = 'student' and d.n between 1 and 200;

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
-- Each approved student rides one bus, the bigger buses carrying more of them, and boards about two in three of its
-- trips. Mornings (to campus) they board at their stop; afternoons (home) at the campus, so no stop is noted. A running
-- trip has the boardings that have happened so far.
insert into public.scans (school_id, trip_id, student_id, subscription_id, stop_id, scanned_by, scanned_at, location, accuracy_m)
select
  '00000000-0000-4000-8000-000000000001', t.id, d.id, sub.id, case when t.direction = 'inbound' then sub.stop_id end, t.driver_id,
  tr.started_at + (random() * least(interval '40 minutes', coalesce(now() - tr.started_at, interval '40 minutes'))),
  case when t.direction = 'inbound' then st.location else (select campus_location from public.schools where id = '00000000-0000-4000-8000-000000000001') end,
  round((5 + random() * 20)::numeric, 1)
from public.trips tr
join demo_trips t on t.id = tr.id
join demo_people d on d.role = 'student' and d.n between 1 and 300
  and (case when d.n % 20 < 7 then 1 when d.n % 20 < 13 then 2 when d.n % 20 < 17 then 3 else 4 end) = t.bus_index
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
where d.role = 'student' and d.n between 281 and 300;

-- ---------------------------------------------------------------- where students live (My area, ADR 0013)
-- Four in five approved students gave a coarse area. Most live within about a kilometre of their stop; three groups
-- tell a story for Insights:
--   * Carrefour du Palais students mostly live by Bata Nlongkak (they would be "nearer to another stop");
--   * a group of Olezoa and Poste Centrale students lives in Essos, about 1.3 km east of the route, far from every stop;
--   * a group of Shell Nsimeyong and Olezoa students lives in Ekounou, south-east, also far from every stop.
-- The last two are where stop suggestions appear.
insert into public.student_areas (user_id, school_id, area, label, source)
select x.student_id, '00000000-0000-4000-8000-000000000001',
  private.snap_area(x.lat, x.lng), x.label, 'search'
from (
  select sub.student_id, d.n, st.name as stop,
    case
      when st.name = 'Carrefour du Palais (Etoudi)' and d.n % 4 <> 0 then 3.8925 + (d.n % 3) * 0.002
      when st.name in ('Olezoa', 'Poste Centrale') and d.n % 6 = 0 then 3.8690 + (d.n % 2) * 0.0015
      when st.name in ('Shell Nsimeyong', 'Olezoa') and d.n % 7 = 0 then 3.8350 + (d.n % 2) * 0.0015
      else extensions.st_y(st.location::extensions.geometry) + (((d.n * 13) % 9) - 4) * 0.0020
    end as lat,
    case
      when st.name = 'Carrefour du Palais (Etoudi)' and d.n % 4 <> 0 then 11.5235 + (d.n % 2) * 0.002
      when st.name in ('Olezoa', 'Poste Centrale') and d.n % 6 = 0 then 11.5360 + (d.n % 3) * 0.0015
      when st.name in ('Shell Nsimeyong', 'Olezoa') and d.n % 7 = 0 then 11.5380 + (d.n % 3) * 0.0015
      else extensions.st_x(st.location::extensions.geometry) + (((d.n * 7) % 9) - 4) * 0.0020
    end as lng,
    case
      when st.name = 'Carrefour du Palais (Etoudi)' and d.n % 4 <> 0 then 'Nlongkak'
      when st.name in ('Olezoa', 'Poste Centrale') and d.n % 6 = 0 then 'Essos'
      when st.name in ('Shell Nsimeyong', 'Olezoa') and d.n % 7 = 0 then 'Ekounou'
      else 'Near ' || st.name
    end as label
  from public.subscriptions sub
  join demo_people d on d.id = sub.student_id and d.role = 'student'
  join public.semesters m on m.id = sub.semester_id and current_date between m.start_date and m.end_date
  join public.stops st on st.id = sub.stop_id
  where sub.status = 'approved' and d.n % 5 <> 0
) x
on conflict (user_id) do update set area = excluded.area, label = excluded.label, source = excluded.source, updated_at = now();

-- Counted at once, so Stop load shows the demo boardings without waiting for the night.
select private.refresh_stop_loads(null, '00000000-0000-4000-8000-000000000001');

-- ---------------------------------------------------------------- the bus route (ADR 0017)
-- ICT University's route, as in seed.sql: the six stops in order, then the campus. Drawn along roads when an admin
-- presses "Draw along roads" (Stops, Bus route).
update public.schools
set campus_location = extensions.st_point(11.51669, 3.95293)::extensions.geography, campus_name = 'ICT-U Campus'
where id = '00000000-0000-4000-8000-000000000001';
-- The route row is kept, so a road already drawn for these same stops stays current across reruns.
delete from public.routes where school_id = '00000000-0000-4000-8000-000000000001' and id <> '00000000-0000-4000-8000-000000000041';
insert into public.routes (id, school_id, name)
values ('00000000-0000-4000-8000-000000000041', '00000000-0000-4000-8000-000000000001', 'Main route')
on conflict (id) do nothing;
delete from public.route_stops where route_id = '00000000-0000-4000-8000-000000000041';
insert into public.route_stops (route_id, stop_id, school_id, position)
select '00000000-0000-4000-8000-000000000041', ('00000000-0000-4000-8000-0000000000' || (20 + n))::uuid,
       '00000000-0000-4000-8000-000000000001', n - 1
from generate_series(1, 6) as n;
