begin;
create extension if not exists pgtap with schema extensions;
select plan(27);

-- Account deletion (ADR 0028).

insert into public.schools (id, name) values ('a7000000-0000-4000-8000-0000000000a1', 'Erase School');
insert into public.school_domains (domain, school_id) values ('erase.edu', 'a7000000-0000-4000-8000-0000000000a1');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a7100000-0000-4000-8000-0000000000a1', 'admin@erase.edu', '{"provider":"google"}'),
  ('a7100000-0000-4000-8000-0000000000a2', 'stu@erase.edu', '{"provider":"google"}'),
  ('a7100000-0000-4000-8000-0000000000a3', 'driver@erase.edu', '{"provider":"google"}'),
  ('a7100000-0000-4000-8000-0000000000f1', 'platform@erase.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id = 'a7100000-0000-4000-8000-0000000000a1';
update public.profiles set role = 'staff' where id = 'a7100000-0000-4000-8000-0000000000a3';
update public.profiles set phone = '+237677000123', matricule = 'M-1' where id = 'a7100000-0000-4000-8000-0000000000a2';
insert into private.platform_admins (user_id, note) values ('a7100000-0000-4000-8000-0000000000f1', 'test');

-- The student's history: a subscription with its proof file, a boarding, a home area, a device.
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('a7200000-0000-4000-8000-0000000000a1', 'a7000000-0000-4000-8000-0000000000a1', 'fall', 2093, current_date - 30, current_date + 60);
insert into public.stops (id, school_id, name, location) values
  ('a7300000-0000-4000-8000-0000000000a1', 'a7000000-0000-4000-8000-0000000000a1', 'Gate', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into storage.objects (bucket_id, name, owner_id) values
  ('proofs', 'a7000000-0000-4000-8000-0000000000a1/a7100000-0000-4000-8000-0000000000a2/proof.jpg', 'a7100000-0000-4000-8000-0000000000a2');
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, proof_path, status) values
  ('a7400000-0000-4000-8000-0000000000a1', 'a7000000-0000-4000-8000-0000000000a1', 'a7100000-0000-4000-8000-0000000000a2',
   'a7200000-0000-4000-8000-0000000000a1', 'a7300000-0000-4000-8000-0000000000a1',
   'a7000000-0000-4000-8000-0000000000a1/a7100000-0000-4000-8000-0000000000a2/proof.jpg', 'approved');
insert into public.buses (id, school_id, plate, capacity) values ('a7500000-0000-4000-8000-0000000000a1', 'a7000000-0000-4000-8000-0000000000a1', 'ER-1', 40);
insert into public.trips (id, school_id, bus_id, driver_id, direction, status, scheduled_start, started_at) values
  ('a7600000-0000-4000-8000-0000000000a1', 'a7000000-0000-4000-8000-0000000000a1', 'a7500000-0000-4000-8000-0000000000a1',
   'a7100000-0000-4000-8000-0000000000a3', 'inbound', 'active', now() - interval '10 minutes', now() - interval '10 minutes');
insert into public.scans (school_id, trip_id, student_id, subscription_id, scanned_by) values
  ('a7000000-0000-4000-8000-0000000000a1', 'a7600000-0000-4000-8000-0000000000a1', 'a7100000-0000-4000-8000-0000000000a2',
   'a7400000-0000-4000-8000-0000000000a1', 'a7100000-0000-4000-8000-0000000000a3');
insert into public.device_tokens (school_id, user_id, token, platform) values
  ('a7000000-0000-4000-8000-0000000000a1', 'a7100000-0000-4000-8000-0000000000a2', repeat('t', 40), 'android');

set local role authenticated;

-- ---------------------------------------------------------------- asking and cancelling
set local "request.jwt.claims" = '{"sub":"a7100000-0000-4000-8000-0000000000a2","role":"authenticated"}';
select is((select count(*)::int from public.my_account_deletion()), 0, 'nothing is scheduled at first');
select ok(public.request_account_deletion() between now() + interval '7 days' - interval '1 minute' and now() + interval '7 days' + interval '1 minute',
  'asking schedules the deletion in 7 days');
select is((select requested_by from public.my_account_deletion()), 'self', 'by the person');
select lives_ok($$select public.cancel_account_deletion()$$, 'it can be cancelled');
select is((select count(*)::int from public.my_account_deletion()), 0, 'and nothing is scheduled any more');
select lives_ok($$select public.request_account_deletion()$$, 'it is asked again');
select throws_ok($$update public.profiles set deletion_due_at = now() where id = 'a7100000-0000-4000-8000-0000000000a2'$$, '42501', null,
  'the date cannot be moved by hand');

set local "request.jwt.claims" = '{"sub":"a7100000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select public.request_account_deletion()$$, '55000', 'last_admin', 'the last administrator of a school hands it over first');
set local "request.jwt.claims" = '{"sub":"a7100000-0000-4000-8000-0000000000a3","role":"authenticated"}';
select throws_ok($$select public.request_account_deletion()$$, '55000', 'active_trip', 'someone on a running trip finishes it first');

-- ---------------------------------------------------------------- the platform, for someone who lost access
set local "request.jwt.claims" = '{"sub":"a7100000-0000-4000-8000-0000000000a1","role":"authenticated"}';
select throws_ok($$select public.platform_schedule_deletion('a7100000-0000-4000-8000-0000000000a2', true)$$, '42501', null, 'a school admin cannot schedule a deletion');
set local "request.jwt.claims" = '{"sub":"a7100000-0000-4000-8000-0000000000f1","role":"authenticated"}';
select is(public.platform_lookup_account('stu@erase.edu') ->> 'deletion_by', 'self', 'Lookup shows the scheduled deletion and who asked');
select lives_ok($$select public.platform_schedule_deletion('a7100000-0000-4000-8000-0000000000a2', false)$$, 'the platform can cancel it');
select ok(public.platform_schedule_deletion('a7100000-0000-4000-8000-0000000000a2', true) is not null, 'and schedule it again');
select is(public.platform_lookup_account('stu@erase.edu') ->> 'deletion_by', 'platform', 'now by the platform');

-- ---------------------------------------------------------------- the nightly erasure
select throws_ok($$select * from public.due_account_deletions()$$, '42501', null, 'only the service role lists the accounts due');
select throws_ok($$select public.erase_account('a7100000-0000-4000-8000-0000000000a2')$$, '42501', null, 'and erases them');

reset role;
update public.profiles set deletion_due_at = now() - interval '1 minute' where id = 'a7100000-0000-4000-8000-0000000000a2';
set local role service_role;
select is((select files from public.due_account_deletions() where user_id = 'a7100000-0000-4000-8000-0000000000a2'),
  array['a7000000-0000-4000-8000-0000000000a1/a7100000-0000-4000-8000-0000000000a2/proof.jpg'], 'a due account comes with its proof files');
select lives_ok($$select public.erase_account('a7100000-0000-4000-8000-0000000000a2')$$, 'the account is erased');
reset role;

select is((select full_name || ' / ' || email from public.profiles where id = 'a7100000-0000-4000-8000-0000000000a2'),
  'Deleted account / deleted-a7100000-0000-4000-8000-0000000000a2@deleted.invalid', 'the name and email are gone');
select ok((select phone is null and matricule is null and status = 'suspended' and deleted_at is not null and deletion_due_at is null
           from public.profiles where id = 'a7100000-0000-4000-8000-0000000000a2'), 'so are the phone and matricule, and the account is closed');
select is((select count(*)::int from public.device_tokens where user_id = 'a7100000-0000-4000-8000-0000000000a2'), 0, 'its devices are removed');
select is((select status::text || ' ' || coalesce(proof_path, 'no proof') from public.subscriptions where id = 'a7400000-0000-4000-8000-0000000000a1'),
  'approved no proof', 'the school keeps the subscription, without the proof');
select is((select count(*)::int from public.scans where student_id = 'a7100000-0000-4000-8000-0000000000a2'), 1, 'and the boarding');
select ok(exists (select 1 from public.audit_log where target_id = 'a7100000-0000-4000-8000-0000000000a2' and action = 'account.erased'), 'the erasure is in the school''s log');
select lives_ok($$select public.erase_account('a7100000-0000-4000-8000-0000000000a2')$$, 'erasing again does nothing');
select is((select count(*)::int from public.due_account_deletions() where user_id = 'a7100000-0000-4000-8000-0000000000a2'), 0, 'and it is no longer due');

-- ---------------------------------------------------------------- asking from the public page
set local role anon;
select is(public.submit_interest('deletion', 'lost@example.org', null, null, 'I lost my Google account.'), 'stored', 'someone who lost access can ask from the public page');

select * from finish();
rollback;
