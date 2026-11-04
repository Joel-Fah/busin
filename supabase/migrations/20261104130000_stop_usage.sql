-- How many students use each stop.
--
-- Counts approved and pending subscriptions per stop, for semesters that have not ended. It runs as the
-- caller, so Row Level Security still limits the rows to the admin's school, and it refuses anyone else.
-- Stops nobody uses are not returned; the caller treats a missing stop as zero.

create function public.admin_stop_usage()
returns table (stop_id uuid, students int, pending int)
language plpgsql stable security invoker
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;

  return query
  select
    s.stop_id,
    (count(*) filter (where s.status = 'approved'))::int,
    (count(*) filter (where s.status = 'pending'))::int
  from public.subscriptions s
  join public.semesters m on m.id = s.semester_id and m.school_id = s.school_id
  where s.status in ('approved', 'pending')
    and m.end_date >= current_date
  group by s.stop_id;
end;
$$;

revoke execute on function public.admin_stop_usage() from public, anon;
grant execute on function public.admin_stop_usage() to authenticated;
