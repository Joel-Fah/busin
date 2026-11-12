-- Names unique ignoring case and spaces, and stops not too close (owner fixes list).
--   * "Computer Science", "computer science", " COMPUTER   SCIENCE " are one faculty, department, program, stop or bus
--     plate. The name is stored cleaned (trimmed, runs of spaces collapsed; a plate also in capitals), and a unique index
--     on the lower-cased form refuses a second one. Names that already clash are renamed first, with " (2)", " (3)".
--   * A stop within 25 metres of another active stop of the school is refused for people using the API: it is the same
--     place. The portal warns earlier, under 200 metres, and lets the administrator go on.

-- A name as it is stored: trimmed, with every run of spaces and line breaks made one space.
create function private.clean_name(p_name text) returns text
language sql immutable
set search_path = ''
as $$
  select btrim(regexp_replace(p_name, '\s+', ' ', 'g'))
$$;
-- Used by the indexes below, so signed-in people need to be able to call it.
grant execute on function private.clean_name(text) to authenticated;

-- ---------------------------------------------------------------- clean what is there, then rename what still clashes
update public.faculties set name = private.clean_name(name) where name is distinct from private.clean_name(name);
update public.departments set name = private.clean_name(name) where name is distinct from private.clean_name(name);
update public.programs set name = private.clean_name(name) where name is distinct from private.clean_name(name);
update public.stops set name = private.clean_name(name) where name is distinct from private.clean_name(name);
update public.buses set plate = upper(private.clean_name(plate)) where plate is distinct from upper(private.clean_name(plate));

do $$
declare
  r record;
begin
  -- Each later row of a clashing set gets " (2)", " (3)" after its name.
  for r in
    select t.id, t.name, row_number() over (partition by t.school_id, lower(t.name) order by t.created_at, t.id) as n from public.faculties t
  loop if r.n > 1 then update public.faculties set name = r.name || ' (' || r.n || ')' where id = r.id; end if; end loop;
  for r in
    select t.id, t.name, row_number() over (partition by t.faculty_id, lower(t.name) order by t.created_at, t.id) as n from public.departments t
  loop if r.n > 1 then update public.departments set name = r.name || ' (' || r.n || ')' where id = r.id; end if; end loop;
  for r in
    select t.id, t.name, row_number() over (partition by t.school_id, lower(t.name) order by t.created_at, t.id) as n from public.programs t
  loop if r.n > 1 then update public.programs set name = r.name || ' (' || r.n || ')' where id = r.id; end if; end loop;
  for r in
    select t.id, t.name, row_number() over (partition by t.school_id, lower(t.name) order by t.created_at, t.id) as n from public.stops t
  loop if r.n > 1 then update public.stops set name = r.name || ' (' || r.n || ')' where id = r.id; end if; end loop;
  for r in
    select t.id, t.plate, row_number() over (partition by t.school_id, lower(t.plate) order by t.created_at, t.id) as n from public.buses t
  loop if r.n > 1 then update public.buses set plate = r.plate || ' (' || r.n || ')' where id = r.id; end if; end loop;
end;
$$;

-- ---------------------------------------------------------------- stored cleaned
create function private.store_clean_name() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  new.name := private.clean_name(new.name);
  return new;
end;
$$;
create function private.store_clean_plate() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  new.plate := upper(private.clean_name(new.plate));
  return new;
end;
$$;
revoke execute on function private.store_clean_name(), private.store_clean_plate() from public;

create trigger faculties_clean_name before insert or update of name on public.faculties for each row execute function private.store_clean_name();
create trigger departments_clean_name before insert or update of name on public.departments for each row execute function private.store_clean_name();
create trigger programs_clean_name before insert or update of name on public.programs for each row execute function private.store_clean_name();
create trigger stops_clean_name before insert or update of name on public.stops for each row execute function private.store_clean_name();
create trigger buses_clean_plate before insert or update of plate on public.buses for each row execute function private.store_clean_plate();

-- ---------------------------------------------------------------- unique ignoring case
create unique index faculties_school_name_ci_key on public.faculties (school_id, lower(private.clean_name(name)));
create unique index departments_faculty_name_ci_key on public.departments (faculty_id, lower(private.clean_name(name)));
create unique index programs_school_name_ci_key on public.programs (school_id, lower(private.clean_name(name)));
create unique index stops_school_name_ci_key on public.stops (school_id, lower(private.clean_name(name)));
create unique index buses_school_plate_ci_key on public.buses (school_id, lower(private.clean_name(plate)));

-- ---------------------------------------------------------------- stops not too close
create function private.check_stop_distance() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Runs as the administrator (they can read the school's stops). Only people using the API are held to it; seeds and
  -- fixtures load their own stops.
  if current_user <> 'authenticated' then
    return new;
  end if;
  if tg_op = 'UPDATE' and new.location is not distinct from old.location then
    return new;
  end if;
  if exists (
    select 1 from public.stops s
    where s.school_id = new.school_id and s.id <> new.id and s.active
      and extensions.st_dwithin(s.location, new.location, 25)
  ) then
    raise exception 'stop_too_close' using errcode = '22023';
  end if;
  return new;
end;
$$;
revoke execute on function private.check_stop_distance() from public;
grant execute on function private.check_stop_distance() to authenticated;
create trigger stops_not_too_close before insert or update of location on public.stops
  for each row execute function private.check_stop_distance();
