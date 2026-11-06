-- Following a bus live is part of what a subscription gives. A student sees live positions only while they have an
-- approved subscription that covers today (in the school's timezone); staff, drivers and admins always see their
-- school's buses. This is enforced here, in the database, so it also applies to Realtime; the apps only mirror it.

create function private.can_follow_buses() returns boolean
language sql stable security definer
set search_path = ''
as $$
  select private.my_school_id() is not null
    and (
      private.is_staff()
      or private.active_subscription_id((select auth.uid()), private.my_school_id()) is not null
    )
$$;

revoke execute on function private.can_follow_buses() from public;
grant execute on function private.can_follow_buses() to authenticated;

drop policy live_positions_select on public.live_positions;
create policy live_positions_select on public.live_positions for select to authenticated
  using (school_id = (select private.my_school_id()) and (select private.can_follow_buses()));

-- The same answer for the apps, so a student without a subscription is told so instead of seeing an empty map.
create function public.can_follow_buses() returns boolean
language sql stable security invoker
set search_path = ''
as $$
  select private.can_follow_buses()
$$;

revoke execute on function public.can_follow_buses() from public, anon;
grant execute on function public.can_follow_buses() to authenticated;
