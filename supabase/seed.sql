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

-- Placeholder coordinates around Yaounde for map development; replace with real stops.
insert into public.stops (id, school_id, name, location)
values
  ('00000000-0000-4000-8000-000000000021', '00000000-0000-4000-8000-000000000001',
   'Sample stop A', extensions.st_point(11.5021, 3.8480)::extensions.geography),
  ('00000000-0000-4000-8000-000000000022', '00000000-0000-4000-8000-000000000001',
   'Sample stop B', extensions.st_point(11.4833, 3.8333)::extensions.geography);

insert into public.buses (id, school_id, plate, capacity, in_service)
values
  ('00000000-0000-4000-8000-000000000031', '00000000-0000-4000-8000-000000000001', 'DEV-001', 50, true),
  ('00000000-0000-4000-8000-000000000032', '00000000-0000-4000-8000-000000000001', 'DEV-002', 50, true);
