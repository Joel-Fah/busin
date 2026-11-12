-- No semesters or trips in the past (owner fixes list). A semester is refused when its last day is before today, and a
-- trip when it starts before now, both in the school's own timezone. Only a changed date is checked, so an old row can
-- still be edited for other reasons. Only people using the API are held to it (the writing role is `authenticated`):
-- seeds, the demo data, the service role and fixtures load history on purpose. The two checks run as the caller, so the
-- role they see is the real one.

-- A school's calendar day today, in its own timezone (the server's date is UTC).
create function private.school_today(p_school uuid) returns date
language sql stable security definer
set search_path = ''
as $$
  select (now() at time zone s.timezone)::date from public.schools s where s.id = p_school
$$;
-- Callable by signed-in users because the checks below run as them; it gives nothing away but a school's date.
grant execute on function private.school_today(uuid) to authenticated;

create function private.check_semester_dates() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user <> 'authenticated' then
    return new;
  end if;
  if (tg_op = 'INSERT' or new.start_date is distinct from old.start_date or new.end_date is distinct from old.end_date)
     and new.end_date < private.school_today(new.school_id) then
    raise exception 'semester_in_past' using errcode = '22023';
  end if;
  return new;
end;
$$;
revoke execute on function private.check_semester_dates() from public;
create trigger semesters_no_past before insert or update of start_date, end_date on public.semesters
  for each row execute function private.check_semester_dates();

create function private.check_trip_start() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user <> 'authenticated' then
    return new;
  end if;
  -- To the minute: a trip scheduled for this very minute is not in the past (a field trip starts now).
  if (tg_op = 'INSERT' or new.scheduled_start is distinct from old.scheduled_start)
     and new.scheduled_start < date_trunc('minute', now()) then
    raise exception 'trip_start_in_past' using errcode = '22023';
  end if;
  return new;
end;
$$;
revoke execute on function private.check_trip_start() from public;
create trigger trips_no_past before insert or update of scheduled_start on public.trips
  for each row execute function private.check_trip_start();

-- The school's day is only as good as its timezone, which is free text an administrator can change.
create function private.is_valid_timezone(p_zone text) returns boolean
language sql stable
set search_path = ''
as $$
  select exists (select 1 from pg_catalog.pg_timezone_names n where n.name = p_zone)
$$;
grant execute on function private.is_valid_timezone(text) to authenticated;
alter table public.schools add constraint schools_timezone_valid check (private.is_valid_timezone(timezone));

-- Two places counted a "day" by the server's date. They use the school's.
create or replace function private.stop_subscribers(p_school uuid)
returns table (student_id uuid, stop_id uuid, area extensions.geography)
language sql stable security definer
set search_path = ''
as $$
  select distinct on (s.student_id) s.student_id, s.stop_id, a.area
  from public.subscriptions s
  join public.semesters m on m.id = s.semester_id and m.school_id = s.school_id
  join public.profiles p on p.id = s.student_id and p.status = 'verified'
  left join public.student_areas a on a.user_id = s.student_id and a.school_id = s.school_id
  where s.school_id = p_school and s.status = 'approved' and m.end_date >= private.school_today(p_school)
  order by s.student_id, m.end_date desc;
$$;

create or replace function private.notify_semester_dates() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if (old.start_date, old.end_date) is distinct from (new.start_date, new.end_date)
     and greatest(old.end_date, new.end_date) >= private.school_today(new.school_id) then
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    select distinct s.school_id, s.student_id, 'school_notice', new.id
    from public.subscriptions s
    where s.semester_id = new.id and s.status in ('pending', 'approved');
  end if;
  return new;
end;
$$;
