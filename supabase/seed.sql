-- Local development data only. Applied by `npx supabase db reset`.
-- Never run against a hosted project. Users are created by signing in with Google;
-- promote a local account to admin with the SQL shown in docs/guides/local-setup.md.

insert into public.schools (id, name, short_name, timezone)
values ('00000000-0000-4000-8000-000000000001', 'ICT University', 'ICTU', 'Africa/Douala');

insert into public.school_domains (domain, school_id)
values ('ictuniversity.edu.cm', '00000000-0000-4000-8000-000000000001');

insert into public.semesters (id, school_id, name, year, start_date, end_date)
values (
  '00000000-0000-4000-8000-000000000011',
  '00000000-0000-4000-8000-000000000001',
  'fall', 2026, '2026-09-07', '2027-01-29'
);

-- ICT University's bus route, in order from the first pickup to the campus (positions from OpenStreetMap; Poste
-- Centrale and Olezoa approximate). The same stops serve every app and the demo data.
insert into public.stops (id, school_id, name, location)
values
  ('00000000-0000-4000-8000-000000000021', '00000000-0000-4000-8000-000000000001',
   'Shell Nsimeyong', extensions.st_point(11.49596, 3.83990)::extensions.geography),
  ('00000000-0000-4000-8000-000000000022', '00000000-0000-4000-8000-000000000001',
   'Carrefour Vogt', extensions.st_point(11.50139, 3.84426)::extensions.geography),
  ('00000000-0000-4000-8000-000000000023', '00000000-0000-4000-8000-000000000001',
   'Olezoa', extensions.st_point(11.51470, 3.84720)::extensions.geography),
  ('00000000-0000-4000-8000-000000000024', '00000000-0000-4000-8000-000000000001',
   'Poste Centrale', extensions.st_point(11.51640, 3.86690)::extensions.geography),
  ('00000000-0000-4000-8000-000000000025', '00000000-0000-4000-8000-000000000001',
   'Bata Nlongkak', extensions.st_point(11.52241, 3.88911)::extensions.geography),
  ('00000000-0000-4000-8000-000000000026', '00000000-0000-4000-8000-000000000001',
   'Carrefour du Palais (Etoudi)', extensions.st_point(11.52404, 3.91562)::extensions.geography);

-- Where the route ends, and the route itself (ADR 0017).
update public.schools
set campus_location = extensions.st_point(11.51669, 3.95293)::extensions.geography, campus_name = 'ICT-U Campus',
  -- Billing (ADR 0022): per semester, in installments if the student wants.
  billing_period = 'semester', price_xaf = 30000, installment_plan = '40-30-30'
where id = '00000000-0000-4000-8000-000000000001';
insert into public.routes (id, school_id, name)
values ('00000000-0000-4000-8000-000000000041', '00000000-0000-4000-8000-000000000001', 'Main route');
insert into public.route_stops (route_id, stop_id, school_id, position)
select '00000000-0000-4000-8000-000000000041', ('00000000-0000-4000-8000-0000000000' || (20 + n))::uuid,
       '00000000-0000-4000-8000-000000000001', n - 1
from generate_series(1, 6) as n;

insert into public.buses (id, school_id, plate, capacity, in_service)
values
  ('00000000-0000-4000-8000-000000000031', '00000000-0000-4000-8000-000000000001', 'DEV-001', 50, true),
  ('00000000-0000-4000-8000-000000000032', '00000000-0000-4000-8000-000000000001', 'DEV-002', 50, true);
