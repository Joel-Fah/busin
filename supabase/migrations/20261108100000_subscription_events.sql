-- Every operation on a subscription is kept: requested, approved, rejected, revoked, reinstated. The database writes the
-- events itself (triggers, in the same transaction as the change), so the history cannot be missed or edited by a client.
-- The student reads their own, an admin reads their school's. A reinstated subscription is the same subscription with a
-- new operation, not a new request.

create table public.subscription_events (
  id bigint generated always as identity primary key,
  school_id uuid not null references public.schools (id) on delete cascade,
  subscription_id uuid not null,
  student_id uuid not null,
  action text not null check (action in ('requested', 'approved', 'rejected', 'revoked', 'reinstated')),
  -- Who did it: the student for a request, an admin for a decision.
  actor_id uuid references public.profiles (id) on delete set null,
  note text check (note is null or char_length(note) <= 500),
  created_at timestamptz not null default now(),
  foreign key (subscription_id, school_id) references public.subscriptions (id, school_id) on delete cascade
);
create index subscription_events_subscription_idx on public.subscription_events (subscription_id, created_at);
create index subscription_events_student_idx on public.subscription_events (student_id, created_at);

alter table public.subscription_events enable row level security;
alter table public.subscription_events force row level security;
revoke all on public.subscription_events from anon, authenticated;
grant select on public.subscription_events to authenticated;
create policy subscription_events_select on public.subscription_events for select to authenticated
  using (
    school_id = (select private.my_school_id())
    and ((select private.is_admin()) or student_id = (select auth.uid()))
  );

create function private.log_subscription_event() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_action text;
begin
  if tg_op = 'INSERT' then
    insert into public.subscription_events (school_id, subscription_id, student_id, action, actor_id)
    values (new.school_id, new.id, new.student_id, 'requested', new.student_id);
    return new;
  end if;

  v_action := case
    when old.status = 'pending' and new.status = 'approved' then 'approved'
    when old.status = 'pending' and new.status = 'rejected' then 'rejected'
    when old.status = 'approved' and new.status = 'revoked' then 'revoked'
    when old.status = 'revoked' and new.status = 'approved' then 'reinstated'
  end;
  if v_action is not null then
    insert into public.subscription_events (school_id, subscription_id, student_id, action, actor_id, note)
    values (new.school_id, new.id, new.student_id, v_action, new.reviewed_by, new.review_note);
  end if;
  return new;
end;
$$;

create trigger subscriptions_log_request after insert on public.subscriptions
  for each row execute function private.log_subscription_event();
create trigger subscriptions_log_decision after update of status on public.subscriptions
  for each row execute function private.log_subscription_event();

-- What happened before this migration: the request, and the decision the subscription stands at now.
insert into public.subscription_events (school_id, subscription_id, student_id, action, actor_id, created_at)
select school_id, id, student_id, 'requested', student_id, created_at from public.subscriptions;

insert into public.subscription_events (school_id, subscription_id, student_id, action, actor_id, note, created_at)
select school_id, id, student_id, status::text, reviewed_by, review_note, coalesce(reviewed_at, updated_at)
from public.subscriptions
where status in ('approved', 'rejected', 'revoked');

-- An admin gives a revoked subscription back. It becomes approved again and the student is told.
create function public.admin_reinstate_subscription(p_subscription_id uuid, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_sub public.subscriptions;
  v_note text := nullif(btrim(p_note), '');
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if v_note is not null and char_length(v_note) > 500 then
    raise exception 'The note is too long (500 characters at most)' using errcode = '22023';
  end if;

  select * into v_sub
  from public.subscriptions
  where id = p_subscription_id and school_id = v_school
  for update;
  if not found then
    raise exception 'Subscription not found' using errcode = 'P0002';
  end if;
  if v_sub.status <> 'revoked' then
    raise exception 'Only revoked subscriptions can be reinstated' using errcode = '55000';
  end if;
  -- One live subscription per student and semester: a newer request has to be dealt with first.
  if exists (
    select 1 from public.subscriptions s
    where s.student_id = v_sub.student_id and s.semester_id = v_sub.semester_id
      and s.id <> v_sub.id and s.status in ('pending', 'approved')
  ) then
    raise exception 'The student already has a live subscription for this semester' using errcode = '55000';
  end if;

  update public.subscriptions
  set status = 'approved',
      review_note = v_note,
      reviewed_by = v_actor,
      reviewed_at = now()
  where id = p_subscription_id;

  perform private.write_audit(
    v_school, v_actor, 'subscription.reinstated', 'subscription', p_subscription_id,
    jsonb_build_object('student_id', v_sub.student_id)
  );
end;
$$;

revoke execute on function public.admin_reinstate_subscription(uuid, text) from public, anon;
grant execute on function public.admin_reinstate_subscription(uuid, text) to authenticated;

-- Getting a subscription back is good news worth a notification, like an approval.
create or replace function private.notify_subscription_decision() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if (old.status = 'pending' and new.status in ('approved', 'rejected'))
     or (old.status = 'revoked' and new.status = 'approved') then
    insert into private.notification_outbox (school_id, user_id, kind, ref_id)
    values (new.school_id, new.student_id, 'subscription_' || new.status::text, new.id);
  end if;
  return new;
end;
$$;
