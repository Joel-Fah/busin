-- Faculties, their departments and the degree levels ("program") of a school. The school admin manages them;
-- students pick theirs on their profile. Per school, never hard-coded.

create table public.faculties (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 2 and 120),
  code text check (code is null or char_length(code) between 1 and 12),
  created_at timestamptz not null default now(),
  unique (id, school_id),
  unique (school_id, name)
);

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  faculty_id uuid not null,
  name text not null check (char_length(btrim(name)) between 2 and 120),
  code text check (code is null or char_length(code) between 1 and 12),
  created_at timestamptz not null default now(),
  unique (id, school_id),
  unique (faculty_id, name),
  foreign key (faculty_id, school_id) references public.faculties (id, school_id) on delete restrict
);
create index departments_faculty_idx on public.departments (faculty_id);

create table public.programs (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 2 and 120),
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (id, school_id),
  unique (school_id, name)
);

-- The profile points at the chosen rows. The text columns stay as a readable copy kept in step by triggers, so
-- everything that already reads them (the portal, exports) keeps working.
alter table public.profiles
  add column department_id uuid,
  add column program_id uuid,
  add foreign key (department_id, school_id) references public.departments (id, school_id) on delete set null (department_id),
  add foreign key (program_id, school_id) references public.programs (id, school_id) on delete set null (program_id);

create function private.sync_profile_academic_names() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or new.department_id is distinct from old.department_id then
    new.department := (select d.name from public.departments d where d.id = new.department_id);
  end if;
  if tg_op = 'INSERT' or new.program_id is distinct from old.program_id then
    new.program := (select p.name from public.programs p where p.id = new.program_id);
  end if;
  return new;
end;
$$;

-- Legacy rows keep their text until the person picks again; only a real change of the reference rewrites it.
create trigger profiles_sync_academic_names
  before insert or update of department_id, program_id on public.profiles
  for each row execute function private.sync_profile_academic_names();

create function private.propagate_department_name() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.profiles set department = new.name where department_id = new.id;
  return null;
end;
$$;
create trigger departments_propagate_name
  after update of name on public.departments
  for each row when (old.name is distinct from new.name)
  execute function private.propagate_department_name();

create function private.propagate_program_name() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.profiles set program = new.name where program_id = new.id;
  return null;
end;
$$;
create trigger programs_propagate_name
  after update of name on public.programs
  for each row when (old.name is distinct from new.name)
  execute function private.propagate_program_name();

alter table public.faculties enable row level security;
alter table public.departments enable row level security;
alter table public.programs enable row level security;
alter table public.faculties force row level security;
alter table public.departments force row level security;
alter table public.programs force row level security;

grant select, insert, delete on public.faculties, public.departments, public.programs to authenticated;
grant update (name, code) on public.faculties to authenticated;
grant update (name, code, faculty_id) on public.departments to authenticated;
grant update (name, sort_order) on public.programs to authenticated;

-- A student chooses from the lists; the free text can no longer be written by clients.
revoke update (department, program) on public.profiles from authenticated;
grant update (department_id, program_id) on public.profiles to authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['faculties', 'departments', 'programs'] loop
    execute format('create policy %I on public.%I for select to authenticated using (school_id = (select private.my_school_id()))', t || '_select', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (school_id = (select private.my_school_id()) and (select private.is_admin()))', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using (school_id = (select private.my_school_id()) and (select private.is_admin())) with check (school_id = (select private.my_school_id()) and (select private.is_admin()))', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using (school_id = (select private.my_school_id()) and (select private.is_admin()))', t || '_delete', t);
  end loop;
end $$;
