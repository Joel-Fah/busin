-- Rich text in the notices the platform sends to a school's portal (ADR 0027, reaching out). The console's editor
-- produces a JSON document (never HTML); it is stored as it was checked by the server action, beside its plain text.
-- `body` stays the plain text (the outreach log, lists, anywhere text is needed) and is still required; `body_doc` is
-- optional, so the notices sent before keep only their text and show as they always did. The portal draws the document
-- with its own whitelist renderer.

-- ---------------------------------------------------------------- the document beside the text
alter table public.school_notices add column body_doc jsonb;

-- The plain text of a formatted notice is longer than the old 600 characters (lists, headings): 4000 at most.
alter table public.school_notices drop constraint school_notices_body_check;
alter table public.school_notices add constraint school_notices_body_check check (char_length(btrim(body)) between 1 and 4000);

-- A document is an object of type "doc" with an array of content, at most 32000 bytes in its text form. What it may
-- hold (nodes, marks, links) is checked by the server action and again by the renderer, which draws nothing else.
alter table public.school_notices add constraint school_notices_body_doc_check check (
  body_doc is null or (
    jsonb_typeof(body_doc) = 'object'
    and body_doc->>'type' = 'doc'
    and jsonb_typeof(body_doc->'content') = 'array'
    and octet_length(body_doc::text) <= 32000
  )
);

-- The school's administrators read it like the other columns (the row policy is unchanged).
grant select (body_doc) on public.school_notices to authenticated;

comment on column public.school_notices.body is 'The notice as plain text (1 to 4000 characters). Always set; the only text of notices sent before rich text.';
comment on column public.school_notices.body_doc is 'The notice as a rich text document from the console''s editor (JSON, never HTML), or null for a plain-text notice.';

-- ---------------------------------------------------------------- sending one
-- Same checks, audit and outreach log as before, plus the optional document. Refusals: 42501 not a platform admin,
-- P0002 unknown or switched-off school, 22023 bad_body (text missing or too long, document not a "doc" object or too
-- big) or bad_link.
drop function public.platform_send_notice(uuid, text, text, text[], int, date);
create function public.platform_send_notice(
  p_school_id uuid,
  p_body text,
  p_link_path text default null,
  p_signals text[] default '{}',
  p_snooze_days int default 7,
  p_follow_up_on date default null,
  p_body_doc jsonb default null
) returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_body text := btrim(coalesce(p_body, ''));
  v_note text;
  v_notice uuid;
  v_outreach uuid;
begin
  if not private.is_platform_admin() then
    raise exception 'Platform admin access required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.schools where id = p_school_id and status = 'active') then
    raise exception 'no_school' using errcode = 'P0002';
  end if;
  if char_length(v_body) not between 1 and 4000 then
    raise exception 'bad_body' using errcode = '22023';
  end if;
  if p_body_doc is not null and (
    jsonb_typeof(p_body_doc) <> 'object'
    or p_body_doc->>'type' is distinct from 'doc'
    or jsonb_typeof(p_body_doc->'content') is distinct from 'array'
    or octet_length(p_body_doc::text) > 32000
  ) then
    raise exception 'bad_body' using errcode = '22023';
  end if;
  if p_link_path is not null and (char_length(p_link_path) > 80 or p_link_path !~ '^/([a-z0-9?=&-][a-z0-9/?=&-]*)?$') then
    raise exception 'bad_link' using errcode = '22023';
  end if;

  insert into public.school_notices (school_id, body, body_doc, link_path, signals, created_by)
  values (p_school_id, v_body, p_body_doc, p_link_path, private.clean_signals(p_signals), (select auth.uid()))
  returning id into v_notice;
  -- The outreach log keeps notes to 1000 characters: a longer notice is logged by its beginning.
  v_note := case when char_length(v_body) > 1000 then left(v_body, 997) || '...' else v_body end;
  v_outreach := public.platform_log_outreach(p_school_id, 'notice', p_signals, v_note, p_snooze_days, p_follow_up_on);
  update public.platform_outreach set notice_id = v_notice where id = v_outreach;
  return v_notice;
end;
$$;

revoke execute on function public.platform_send_notice(uuid, text, text, text[], int, date, jsonb) from public, anon;
grant execute on function public.platform_send_notice(uuid, text, text, text[], int, date, jsonb) to authenticated;
