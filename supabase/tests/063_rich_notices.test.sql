begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

-- Rich text in the platform's notices to a school (ADR 0027, reaching out): a JSON document beside the plain text.

insert into public.schools (id, name) values
  ('c0000000-0000-4000-8000-0000000000a1', 'School A'),
  ('c0000000-0000-4000-8000-0000000000b2', 'School B');
insert into public.school_domains (domain, school_id) values ('ra.edu', 'c0000000-0000-4000-8000-0000000000a1'), ('rb.edu', 'c0000000-0000-4000-8000-0000000000b2');
insert into auth.users (id, email, raw_app_meta_data) values
  ('c1000000-0000-4000-8000-0000000000a1', 'admin@ra.edu', '{"provider":"google"}'),
  ('c1000000-0000-4000-8000-0000000000b1', 'admin@rb.edu', '{"provider":"google"}'),
  ('c1000000-0000-4000-8000-0000000000f1', 'owner@gmail.com', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('c1000000-0000-4000-8000-0000000000a1', 'c1000000-0000-4000-8000-0000000000b1');
insert into private.platform_admins (user_id, note) values ('c1000000-0000-4000-8000-0000000000f1', 'test');

select has_column('public', 'school_notices', 'body_doc', 'notices have a document column');
select col_type_is('public', 'school_notices', 'body_doc', 'jsonb', 'which is jsonb');
select col_is_null('public', 'school_notices', 'body_doc', 'and optional, so plain-text notices stay valid');
select ok(has_column_privilege('authenticated', 'public.school_notices', 'body_doc', 'select'), 'signed-in users may select it (the row policy decides which rows)');
select ok(not has_function_privilege('anon', 'public.platform_send_notice(uuid, text, text, text[], int, date, jsonb)', 'execute'), 'anon cannot send a notice');

set local role authenticated;

-- ---------------------------------------------------------------- only the platform sends
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select public.platform_send_notice('c0000000-0000-4000-8000-0000000000a1', 'Hi', p_body_doc => '{"type":"doc","content":[]}')$$,
  '42501', null, 'a school admin cannot send a rich notice');

-- ---------------------------------------------------------------- the platform admin
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select throws_ok($$select public.platform_send_notice('c0000000-0000-4000-8000-0000000000a1', 'Hi', p_body_doc => '[1, 2]')$$,
  '22023', 'bad_body', 'a document that is not an object is refused');
select throws_ok($$select public.platform_send_notice('c0000000-0000-4000-8000-0000000000a1', 'Hi', p_body_doc => '{"type":"paragraph","content":[]}')$$,
  '22023', 'bad_body', 'a document of another type is refused');
select throws_ok($$select public.platform_send_notice('c0000000-0000-4000-8000-0000000000a1', 'Hi', p_body_doc => '{"type":"doc","content":"text"}')$$,
  '22023', 'bad_body', 'a document whose content is not an array is refused');
select throws_ok(
  format($$select public.platform_send_notice('c0000000-0000-4000-8000-0000000000a1', 'Hi', p_body_doc => %L::jsonb)$$,
    jsonb_build_object('type', 'doc', 'content', jsonb_build_array(jsonb_build_object('type', 'paragraph', 'content',
      jsonb_build_array(jsonb_build_object('type', 'text', 'text', repeat('x', 33000))))))::text),
  '22023', 'bad_body', 'an oversize document is refused');
select throws_ok($$select public.platform_send_notice('c0000000-0000-4000-8000-0000000000a1', '  ', p_body_doc => '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Hi"}]}]}')$$,
  '22023', 'bad_body', 'the plain text stays required beside a document');
select throws_ok($$select public.platform_send_notice('c0000000-0000-4000-8000-0000000000a1', repeat('x', 4001))$$,
  '22023', 'bad_body', 'the plain text is at most 4000 characters');

select lives_ok($$select public.platform_send_notice('c0000000-0000-4000-8000-0000000000a1', 'Students wait.' || chr(10) || '- Review them' || repeat('.', 1200),
  '/subscriptions', '{}', 0, null,
  '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Students wait.","marks":[{"type":"bold"}]}]},{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"Review them"}]}]}]}]}')$$,
  'a notice longer than 600 characters is sent with its document');
select is(
  (select char_length(l->>'note') from public.platform_school_outreach('c0000000-0000-4000-8000-0000000000a1') x, jsonb_array_elements(x->'log') l limit 1),
  1000, 'the outreach log keeps its beginning, within the note limit');

-- ---------------------------------------------------------------- the school's administrators
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select is((select body_doc->'content'->0->'content'->0->'marks'->0->>'type' from public.school_notices where school_id = 'c0000000-0000-4000-8000-0000000000a1'),
  'bold', 'the school''s admin reads the document');
set local "request.jwt.claims" = '{"sub":"c1000000-0000-4000-8000-0000000000b1","role":"authenticated"}';
select is((select count(*)::int from public.school_notices where body_doc is not null), 0, 'another school''s admin does not');

select * from finish();
rollback;
