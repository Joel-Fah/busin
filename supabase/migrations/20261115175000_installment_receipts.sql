-- Every receipt a student sends for a part stays (ADR 0022). A part keeps only its latest proof; this table keeps them
-- all, each with the school's decision, so the subscription's history shows what was paid and when. Part 1 is the
-- request's own proof and is already in the history. Written by the database only; never edited or deleted by a person.

create table public.installment_receipts (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  subscription_id uuid not null,
  installment_id uuid not null references public.subscription_installments (id) on delete cascade,
  student_id uuid not null,
  seq smallint not null check (seq between 1 and 4),
  -- Null when an administrator marked the part paid without a receipt (paid at the office).
  proof_path text,
  sent_at timestamptz not null default now(),
  decision text check (decision in ('paid', 'rejected')),
  note text check (note is null or char_length(note) <= 500),
  decided_at timestamptz,
  decided_by uuid references public.profiles (id) on delete set null,
  foreign key (subscription_id, school_id) references public.subscriptions (id, school_id) on delete cascade
);
create index installment_receipts_subscription_idx on public.installment_receipts (subscription_id, sent_at);
create index installment_receipts_student_idx on public.installment_receipts (student_id);

alter table public.installment_receipts enable row level security;
alter table public.installment_receipts force row level security;
revoke all on public.installment_receipts from anon, authenticated;
grant select on public.installment_receipts to authenticated;
create policy installment_receipts_select on public.installment_receipts for select to authenticated
  using (
    school_id = (select private.my_school_id())
    and ((select private.is_admin()) or student_id = (select auth.uid()))
  );

-- Proofs already sent for later parts, kept as their first receipt.
insert into public.installment_receipts (school_id, subscription_id, installment_id, student_id, seq, proof_path, sent_at, decision, note, decided_at, decided_by)
select i.school_id, i.subscription_id, i.id, i.student_id, i.seq, i.proof_path, coalesce(i.submitted_at, i.created_at),
       case when i.status in ('paid', 'rejected') then i.status end, i.review_note, i.reviewed_at, i.reviewed_by
from public.subscription_installments i
where i.seq > 1 and (i.proof_path is not null or i.status = 'paid');

-- Sending a proof keeps it as a receipt.
create or replace function public.submit_installment_proof(p_installment uuid, p_path text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_part public.subscription_installments;
  v_sub_status public.subscription_status;
begin
  if private.my_role() is distinct from 'student' then
    raise exception 'Students only' using errcode = '42501';
  end if;
  select * into v_part from public.subscription_installments
  where id = p_installment and student_id = v_uid and school_id = v_school
  for update;
  if not found then
    raise exception 'Installment not found' using errcode = 'P0002';
  end if;
  select s.status into v_sub_status from public.subscriptions s where s.id = v_part.subscription_id;
  if v_part.seq = 1 or v_part.status not in ('due', 'rejected') or v_sub_status not in ('pending', 'approved') then
    raise exception 'installment_not_open' using errcode = '55000';
  end if;
  if p_path is null or p_path not like v_school::text || '/' || v_uid::text || '/%' then
    raise exception 'proof_required' using errcode = '22023';
  end if;
  if not exists (select 1 from storage.objects o where o.bucket_id = 'proofs' and o.name = p_path) then
    raise exception 'proof_missing' using errcode = '22023';
  end if;
  update public.subscription_installments
  set status = 'submitted', proof_path = p_path, submitted_at = now(), review_note = null, reviewed_by = null, reviewed_at = null
  where id = p_installment;
  insert into public.installment_receipts (school_id, subscription_id, installment_id, student_id, seq, proof_path)
  values (v_part.school_id, v_part.subscription_id, v_part.id, v_part.student_id, v_part.seq, p_path);
end;
$$;

-- Deciding a part writes the decision on its latest receipt; a part paid without one gets a receipt without a proof.
create or replace function public.admin_review_installment(p_installment uuid, p_decision text, p_note text default null)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_part public.subscription_installments;
  v_note text;
  v_receipt uuid;
begin
  if not private.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  if p_decision is null or p_decision not in ('paid', 'rejected') then
    raise exception 'Decision must be paid or rejected' using errcode = '22023';
  end if;
  v_note := private.clean_reason(p_note, p_decision = 'rejected');
  select * into v_part from public.subscription_installments where id = p_installment and school_id = v_school for update;
  if not found then
    raise exception 'Installment not found' using errcode = 'P0002';
  end if;
  -- Part 1 is decided with the request itself.
  if v_part.seq = 1 or v_part.status = 'paid' or (p_decision = 'rejected' and v_part.status <> 'submitted') then
    raise exception 'installment_not_open' using errcode = '55000';
  end if;
  update public.subscription_installments
  set status = p_decision, review_note = v_note, reviewed_by = v_actor, reviewed_at = now()
  where id = p_installment;

  select r.id into v_receipt from public.installment_receipts r
  where r.installment_id = p_installment and r.decision is null
  order by r.sent_at desc limit 1;
  if v_receipt is not null then
    update public.installment_receipts set decision = p_decision, note = v_note, decided_at = now(), decided_by = v_actor where id = v_receipt;
  else
    insert into public.installment_receipts (school_id, subscription_id, installment_id, student_id, seq, proof_path, decision, note, decided_at, decided_by)
    values (v_part.school_id, v_part.subscription_id, v_part.id, v_part.student_id, v_part.seq, null, p_decision, v_note, now(), v_actor);
  end if;

  perform private.write_audit(v_school, v_actor, 'installment.' || p_decision, 'subscription', v_part.subscription_id,
    jsonb_build_object('student_id', v_part.student_id, 'seq', v_part.seq));
  insert into private.notification_outbox (school_id, user_id, kind, ref_id)
  values (v_school, v_part.student_id, 'installment_' || p_decision, v_part.subscription_id);
end;
$$;
