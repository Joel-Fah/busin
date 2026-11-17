-- Usage, costs and system health for the platform console (ADR 0027, slice 6): the sizes and counts that free plans
-- limit (database, file storage, active accounts, map directions), the scheduled jobs and their failures, push
-- notifications sent and failing, the phones registered for push, and running trips whose bus has gone quiet. Counts and
-- sizes only; the limits themselves are set in the console, so a plan change needs no migration.

create function public.platform_system_health()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_month timestamptz := date_trunc('month', now());
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'database_bytes', pg_catalog.pg_database_size(pg_catalog.current_database()),

    'storage', coalesce((
      select jsonb_agg(jsonb_build_object('bucket', b.bucket_id, 'bytes', b.bytes, 'files', b.files) order by b.bytes desc)
      from (
        select o.bucket_id, sum(coalesce((o.metadata ->> 'size')::bigint, 0)) as bytes, count(*) as files
        from storage.objects o group by o.bucket_id
      ) b), '[]'::jsonb),

    'accounts', jsonb_build_object(
      'total', (select count(*) from auth.users),
      'active_30d', (select count(*) from auth.users u where u.last_sign_in_at > now() - interval '30 days')),

    'usage', jsonb_build_object(
      'directions_month', (select count(*) from private.route_directions_usage r where r.at >= v_month),
      'place_searches_month', (select count(*) from private.place_search_usage p where p.at >= v_month),
      'directions_days', coalesce((
        select jsonb_agg(jsonb_build_object('day', d.day, 'n', d.n) order by d.day)
        from (select (r.at at time zone 'UTC')::date as day, count(*) as n from private.route_directions_usage r
              where r.at > now() - interval '30 days' group by 1) d), '[]'::jsonb),
      'searches_days', coalesce((
        select jsonb_agg(jsonb_build_object('day', d.day, 'n', d.n) order by d.day)
        from (select (p.at at time zone 'UTC')::date as day, count(*) as n from private.place_search_usage p
              where p.at > now() - interval '30 days' group by 1) d), '[]'::jsonb)),

    -- A push is failed after 5 attempts without being sent (the dispatcher stops there).
    'push', jsonb_build_object(
      'sent_7d', (select count(*) from private.notification_outbox o where o.sent_at > now() - interval '7 days'),
      'failed_7d', (select count(*) from private.notification_outbox o where o.sent_at is null and o.attempts >= 5 and o.created_at > now() - interval '7 days'),
      'waiting', (select count(*) from private.notification_outbox o where o.sent_at is null and o.attempts < 5),
      'oldest_waiting_at', (select min(o.created_at) from private.notification_outbox o where o.sent_at is null and o.attempts < 5),
      'last_error', (select o.last_error from private.notification_outbox o where o.last_error is not null order by o.created_at desc limit 1)),

    'devices', jsonb_build_object(
      'android', (select count(*) from public.device_tokens t where t.platform = 'android'),
      'ios', (select count(*) from public.device_tokens t where t.platform = 'ios'),
      'web', (select count(*) from public.device_tokens t where t.platform = 'web'),
      'stale_30d', (select count(*) from public.device_tokens t where t.last_seen_at < now() - interval '30 days')),

    -- Each scheduled job: when it last ran, how it went, and its failures over 7 days.
    'jobs', coalesce((
      select jsonb_agg(jsonb_build_object(
        'name', j.jobname, 'schedule', j.schedule, 'active', j.active,
        'last_run_at', last.start_time, 'last_status', last.status,
        'failures_7d', (select count(*) from cron.job_run_details d where d.jobid = j.jobid and d.status = 'failed' and d.start_time > now() - interval '7 days'),
        'last_error', (select left(d.return_message, 200) from cron.job_run_details d where d.jobid = j.jobid and d.status = 'failed' order by d.start_time desc limit 1)
      ) order by j.jobname)
      from cron.job j
      left join lateral (
        select d.start_time, d.status from cron.job_run_details d where d.jobid = j.jobid order by d.start_time desc limit 1
      ) last on true), '[]'::jsonb),

    -- Running trips whose bus sent no position for 15 minutes (the driver's phone may be off or offline).
    'quiet_trips', coalesce((
      select jsonb_agg(jsonb_build_object('school', q.school, 'school_id', q.school_id, 'started_at', q.started_at, 'last_position_at', q.last_at) order by q.started_at)
      from (
        select s.name as school, s.id as school_id, t.started_at,
               (select max(p.recorded_at) from public.trip_positions p where p.trip_id = t.id) as last_at
        from public.trips t join public.schools s on s.id = t.school_id
        where t.status = 'active' and t.started_at < now() - interval '15 minutes'
      ) q
      where q.last_at is null or q.last_at < now() - interval '15 minutes'), '[]'::jsonb)
  );
end;
$$;

revoke execute on function public.platform_system_health() from public, anon;
grant execute on function public.platform_system_health() to authenticated;
