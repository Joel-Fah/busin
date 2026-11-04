-- Boardings per calendar day, for the overview chart.
--
-- Days are cut in the school's own timezone, and days with no boardings are returned as zero so the chart
-- has no gaps. It runs as the caller, so Row Level Security limits the rows to the admin's school, and it
-- refuses anyone else. At most 90 days, so the answer stays small.

create function public.admin_boardings_by_day(p_days int default 14)
returns table (day date, boardings int)
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_tz text;
  v_days int := least(greatest(coalesce(p_days, 14), 1), 90);
  v_today date;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;

  select s.timezone into v_tz from public.schools s where s.id = private.my_school_id();
  v_tz := coalesce(v_tz, 'UTC');
  v_today := (now() at time zone v_tz)::date;

  return query
  select d.day::date, coalesce(c.n, 0)::int
  from generate_series(v_today - (v_days - 1), v_today, interval '1 day') as d(day)
  left join (
    select (sc.scanned_at at time zone v_tz)::date as day, count(*) as n
    from public.scans sc
    where sc.scanned_at >= ((v_today - (v_days - 1))::timestamp at time zone v_tz)
    group by 1
  ) c on c.day = d.day::date
  order by d.day;
end;
$$;

revoke execute on function public.admin_boardings_by_day(int) from public, anon;
grant execute on function public.admin_boardings_by_day(int) to authenticated;
