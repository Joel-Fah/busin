begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

-- Leads from the landing page in the platform console (ADR 0027, slice 5).

insert into public.schools (id, name) values ('d0000000-0000-4000-8000-0000000000a1', 'Lead School');
insert into public.school_domains (domain, school_id) values ('lead.edu', 'd0000000-0000-4000-8000-0000000000a1');
insert into auth.users (id, email, raw_app_meta_data) values
  ('d1000000-0000-4000-8000-0000000000a1', 'admin@lead.edu', '{"provider":"google"}'),
  ('d1000000-0000-4000-8000-0000000000f1', 'platform@lead.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'd1000000-0000-4000-8000-0000000000a1';
insert into private.platform_admins (user_id, note) values ('d1000000-0000-4000-8000-0000000000f1', 'test');
insert into public.interest_requests (id, kind, name, organisation, email, message, created_at) values
  ('d2000000-0000-4000-8000-0000000000a1', 'school', 'Ama', 'Test College', 'ama@college.example', 'We have 3 buses.', now() - interval '2 days'),
  ('d2000000-0000-4000-8000-0000000000a2', 'notify', null, null, 'fan@example.org', null, now() - interval '1 day'),
  ('d2000000-0000-4000-8000-0000000000a3', 'school', 'Ben', 'Other College', 'ben@other.example', null, now());

set local role authenticated;

set local "request.jwt.claims" = '{"sub":"d1000000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select * from public.platform_leads()$$, '42501', null, 'a school admin cannot read the leads');
select throws_ok($$select public.platform_update_lead('d2000000-0000-4000-8000-0000000000a1', 'dismissed')$$, '42501', null, 'nor change one');
select throws_ok($$select * from public.interest_requests$$, '42501', null, 'nor read the table');

set local "request.jwt.claims" = '{"sub":"d1000000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select ok((select count(*) from public.platform_leads('school') where id in ('d2000000-0000-4000-8000-0000000000a1', 'd2000000-0000-4000-8000-0000000000a3')) = 2,
  'the platform admin reads the school leads');
select is((select id from public.platform_leads('school') where id in ('d2000000-0000-4000-8000-0000000000a1', 'd2000000-0000-4000-8000-0000000000a3') limit 1),
  'd2000000-0000-4000-8000-0000000000a3'::uuid, 'newest first');
select ok((select bool_and(kind = 'notify') from public.platform_leads('notify')), 'the notify filter keeps notify leads only');
select ok((select total >= 2 from public.platform_leads('school', null, 1, 0) limit 1), 'the total counts every match, not just the page');
select ok((public.platform_lead_counts() ->> 'school:new')::int >= 2, 'counts by kind and status');

select throws_ok($$select public.platform_update_lead('d2000000-0000-4000-8000-0000000000a1', 'won')$$, '22023', 'bad_status', 'an unknown status is refused');
select throws_ok($$select public.platform_update_lead('d2000000-0000-4000-8000-000000000999', 'contacted')$$, 'P0002', 'no_lead', 'an unknown lead is refused');
select lives_ok($$select public.platform_update_lead('d2000000-0000-4000-8000-0000000000a1', 'contacted', 'Called Ama.')$$, 'a lead is marked contacted with a note');
select lives_ok($$select public.platform_update_lead('d2000000-0000-4000-8000-0000000000a1', 'converted', null, 'd0000000-0000-4000-8000-0000000000a1')$$,
  'then converted into a school, keeping the note');
select is((select note || ' / ' || school_name from public.platform_leads('school', 'converted') where id = 'd2000000-0000-4000-8000-0000000000a1'),
  'Called Ama. / Lead School', 'the note stays and the school is named');

reset role;
select is((select count(*)::int from public.platform_audit where target_id = 'd2000000-0000-4000-8000-0000000000a1'), 2, 'each change is in the platform audit');

select * from finish();
rollback;
