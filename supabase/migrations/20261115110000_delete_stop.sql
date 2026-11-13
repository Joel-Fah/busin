-- Deleting a stop (owner request, 2026-11-13).
--
-- A stop can be deleted only while nothing on record points at it: no subscription in any state and no boarding. Then
-- it is a mistake or a duplicate, and it goes, together with its place in the bus routes and its load summaries (those
-- follow it by cascade). A stop that was used stays, so past subscriptions and boardings keep their stop; turning it
-- off (active = false) hides it from students instead. Deleting goes through one function that checks and audits it:
-- the direct delete grant is withdrawn.

revoke delete on public.stops from authenticated;

-- How many records of any time use each stop of the caller's school (administrators only). A stop missing from the
-- answer has none, so it can be deleted.
create or replace function public.admin_stop_history()
returns table (stop_id uuid, subscriptions int, boardings int)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_school uuid := private.my_school_id();
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  return query
  with subs as (
    select s.stop_id, count(*)::int as n from public.subscriptions s where s.school_id = v_school group by s.stop_id
  ),
  boards as (
    select c.stop_id, count(*)::int as n from public.scans c where c.school_id = v_school and c.stop_id is not null group by c.stop_id
  )
  select coalesce(subs.stop_id, boards.stop_id), coalesce(subs.n, 0), coalesce(boards.n, 0)
  from subs full join boards on boards.stop_id = subs.stop_id;
end;
$$;
revoke execute on function public.admin_stop_history() from public, anon;
grant execute on function public.admin_stop_history() to authenticated;

-- Deletes a stop nothing uses. Refuses with stop_in_use otherwise.
create or replace function public.admin_delete_stop(p_stop_id uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_stop public.stops;
  v_actor uuid := (select auth.uid());
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  select * into v_stop from public.stops where id = p_stop_id and school_id = private.my_school_id() for update;
  if not found then
    raise exception 'Stop not found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.subscriptions s where s.stop_id = v_stop.id)
     or exists (select 1 from public.scans c where c.stop_id = v_stop.id) then
    raise exception 'stop_in_use' using errcode = '55000';
  end if;

  delete from public.stops where id = v_stop.id;
  perform private.write_audit(v_stop.school_id, v_actor, 'stop.deleted', 'stop', v_stop.id, jsonb_build_object('name', v_stop.name));
end;
$$;
revoke execute on function public.admin_delete_stop(uuid) from public, anon;
grant execute on function public.admin_delete_stop(uuid) to authenticated;
