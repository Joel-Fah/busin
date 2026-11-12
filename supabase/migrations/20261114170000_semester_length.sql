-- A semester has a sensible length and a year that matches its dates (owner fixes list: one in the portal ran from
-- 4 February 2021 to 4 April 2026). It lasts at least 7 and at most 366 days, and its year is the year it starts or ends
-- in (a fall semester of 2026 may end in January 2027). Only people using the API are held to it, and only for what they
-- change, so an old row can still be edited for other reasons.

create or replace function private.check_semester_dates() returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_dates_changed boolean := tg_op = 'INSERT' or new.start_date is distinct from old.start_date or new.end_date is distinct from old.end_date;
begin
  if current_user <> 'authenticated' then
    return new;
  end if;
  if v_dates_changed and new.end_date < private.school_today(new.school_id) then
    raise exception 'semester_in_past' using errcode = '22023';
  end if;
  if v_dates_changed and (new.end_date - new.start_date < 7 or new.end_date - new.start_date > 366) then
    raise exception 'semester_length' using errcode = '22023';
  end if;
  if (v_dates_changed or tg_op = 'INSERT' or new.year is distinct from old.year)
     and new.year not between extract(year from new.start_date)::int and extract(year from new.end_date)::int then
    raise exception 'semester_year' using errcode = '22023';
  end if;
  return new;
end;
$$;

drop trigger semesters_no_past on public.semesters;
create trigger semesters_no_past before insert or update of start_date, end_date, year on public.semesters
  for each row execute function private.check_semester_dates();
