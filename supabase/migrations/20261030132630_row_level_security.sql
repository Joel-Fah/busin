-- Row Level Security for every table, plus explicit minimal grants.
-- anon gets nothing. authenticated gets only what is listed here, and RLS
-- decides which rows. Role, status and school_id are never writable by clients.

alter table public.schools enable row level security;
alter table public.school_domains enable row level security;
alter table public.profiles enable row level security;
alter table public.semesters enable row level security;
alter table public.stops enable row level security;
alter table public.buses enable row level security;
alter table public.trips enable row level security;
alter table public.subscriptions enable row level security;
alter table public.scans enable row level security;
alter table public.live_positions enable row level security;
alter table public.audit_log enable row level security;

alter table public.schools force row level security;
alter table public.school_domains force row level security;
alter table public.profiles force row level security;
alter table public.semesters force row level security;
alter table public.stops force row level security;
alter table public.buses force row level security;
alter table public.trips force row level security;
alter table public.subscriptions force row level security;
alter table public.scans force row level security;
alter table public.live_positions force row level security;
alter table public.audit_log force row level security;

revoke all on all tables in schema public from anon, authenticated;

-- created_by is filled by the server, not the client.
alter table public.semesters alter column created_by set default auth.uid();
alter table public.stops alter column created_by set default auth.uid();

-- schools: members read their own school; admins edit display fields only.
grant select on public.schools to authenticated;
grant update (name, short_name, timezone) on public.schools to authenticated;
create policy schools_select on public.schools for select to authenticated
  using (id = (select private.my_school_id()));
create policy schools_update on public.schools for update to authenticated
  using (id = (select private.my_school_id()) and (select private.is_admin()))
  with check (id = (select private.my_school_id()) and (select private.is_admin()));

-- school_domains: admins read; changes go through functions later.
grant select on public.school_domains to authenticated;
create policy school_domains_select on public.school_domains for select to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

-- profiles: a user reads and edits their own; admins read their school.
grant select on public.profiles to authenticated;
grant update (full_name, phone, avatar_url, matricule, department, program)
  on public.profiles to authenticated;
create policy profiles_select on public.profiles for select to authenticated
  using (
    id = (select auth.uid())
    or (school_id = (select private.my_school_id()) and (select private.is_admin()))
  );
create policy profiles_update on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()) and (select private.my_school_id()) is not null);

-- Reference data: everyone in the school reads, admins write.
grant select, insert, delete on public.semesters, public.stops, public.buses, public.trips
  to authenticated;
grant update (name, year, start_date, end_date) on public.semesters to authenticated;
grant update (name, location, photo_path, active) on public.stops to authenticated;
grant update (plate, capacity, in_service) on public.buses to authenticated;
grant update (bus_id, driver_id, direction, scheduled_start) on public.trips to authenticated;

create policy semesters_select on public.semesters for select to authenticated
  using (school_id = (select private.my_school_id()));
create policy semesters_insert on public.semesters for insert to authenticated
  with check (
    school_id = (select private.my_school_id()) and (select private.is_admin())
    and created_by = (select auth.uid())
  );
create policy semesters_update on public.semesters for update to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()))
  with check (school_id = (select private.my_school_id()) and (select private.is_admin()));
create policy semesters_delete on public.semesters for delete to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

create policy stops_select on public.stops for select to authenticated
  using (school_id = (select private.my_school_id()));
create policy stops_insert on public.stops for insert to authenticated
  with check (
    school_id = (select private.my_school_id()) and (select private.is_admin())
    and created_by = (select auth.uid())
  );
create policy stops_update on public.stops for update to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()))
  with check (school_id = (select private.my_school_id()) and (select private.is_admin()));
create policy stops_delete on public.stops for delete to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

create policy buses_select on public.buses for select to authenticated
  using (school_id = (select private.my_school_id()));
create policy buses_insert on public.buses for insert to authenticated
  with check (school_id = (select private.my_school_id()) and (select private.is_admin()));
create policy buses_update on public.buses for update to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()))
  with check (school_id = (select private.my_school_id()) and (select private.is_admin()));
create policy buses_delete on public.buses for delete to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

create policy trips_select on public.trips for select to authenticated
  using (school_id = (select private.my_school_id()));
create policy trips_insert on public.trips for insert to authenticated
  with check (school_id = (select private.my_school_id()) and (select private.is_admin()));
create policy trips_update on public.trips for update to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()))
  with check (school_id = (select private.my_school_id()) and (select private.is_admin()));
create policy trips_delete on public.trips for delete to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

-- subscriptions: a student creates pending requests for themselves and reads
-- their own; admins read their school. Review decisions come from functions.
grant select on public.subscriptions to authenticated;
grant insert (school_id, student_id, semester_id, stop_id, proof_path)
  on public.subscriptions to authenticated;
create policy subscriptions_select on public.subscriptions for select to authenticated
  using (
    student_id = (select auth.uid())
    or (school_id = (select private.my_school_id()) and (select private.is_admin()))
  );
create policy subscriptions_insert on public.subscriptions for insert to authenticated
  with check (
    student_id = (select auth.uid())
    and school_id = (select private.my_school_id())
    and (select private.my_role()) = 'student'
    and (
      proof_path is null
      or proof_path like (school_id::text || '/' || student_id::text || '/%')
    )
  );

-- scans, live positions and the audit log are read-only for clients.
-- Writes come from functions that verify the caller and the data.
grant select on public.scans, public.live_positions, public.audit_log to authenticated;

create policy scans_select on public.scans for select to authenticated
  using (
    student_id = (select auth.uid())
    or (school_id = (select private.my_school_id()) and (select private.is_admin()))
    or (
      school_id = (select private.my_school_id())
      and (select private.is_staff())
      and scanned_by = (select auth.uid())
    )
  );

create policy live_positions_select on public.live_positions for select to authenticated
  using (school_id = (select private.my_school_id()));

create policy audit_log_select on public.audit_log for select to authenticated
  using (school_id = (select private.my_school_id()) and (select private.is_admin()));

-- Students follow their bus live through Realtime; RLS applies to it.
alter publication supabase_realtime add table public.live_positions;
