begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

insert into public.schools (id, name) values
  ('10000000-0000-4000-8000-000000000001', 'School A'),
  ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values
  ('a.edu', '10000000-0000-4000-8000-000000000001'),
  ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'stu@b.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';
update public.profiles set role = 'admin' where id in
  ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');

-- Existing files, created by the database owner.
insert into storage.objects (bucket_id, name) values
  ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/receipt.jpg'),
  ('proofs', '10000000-0000-4000-8000-000000000002/b1000000-0000-4000-8000-000000000001/receipt.jpg'),
  ('stops', '10000000-0000-4000-8000-000000000001/stop.jpg');

-- Bucket configuration.
select is(
  (select count(*)::int from storage.buckets where id in ('proofs', 'stops') and public = false),
  2, 'both buckets are private');
select is(
  (select file_size_limit from storage.buckets where id = 'proofs'),
  5242880::bigint, 'proofs have a 5 MiB size cap');
select is(
  (select allowed_mime_types from storage.buckets where id = 'proofs'),
  array['image/jpeg', 'image/png', 'image/webp'], 'only image types are accepted');

-- ---------------------------------------------------------------- student 1
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';

select lives_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/proof.jpg')$$,
  'student can upload into their own folder');
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('proofs', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/proof.jpg')$$,
  '42501', null, 'student cannot upload into another student folder');
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('proofs', '10000000-0000-4000-8000-000000000002/a1000000-0000-4000-8000-000000000001/proof.jpg')$$,
  '42501', null, 'student cannot upload into another school folder');
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('proofs', 'proof-at-root.jpg')$$,
  '42501', null, 'student cannot upload outside the school and user folders');
select is(
  (select count(*)::int from storage.objects where bucket_id = 'proofs'),
  1, 'student sees only their own proof');
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('stops', '10000000-0000-4000-8000-000000000001/new.jpg')$$,
  '42501', null, 'student cannot upload a stop photo');
select is(
  (select count(*)::int from storage.objects where bucket_id = 'stops'),
  1, 'student reads stop photos of their school');

-- A student cannot rename evidence. Deletes are made through the Storage API, which has no
-- delete policy for proofs, so they are refused there; SQL deletes are blocked by Storage itself.
update storage.objects set name = name || '.x'
  where bucket_id = 'proofs' and (storage.foldername(name))[2] = 'a1000000-0000-4000-8000-000000000001';
-- ---------------------------------------------------------------- staff
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is(
  (select count(*)::int from storage.objects where bucket_id = 'proofs'),
  0, 'staff cannot read payment proofs');

-- ---------------------------------------------------------------- admin A
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is(
  (select count(*)::int from storage.objects where bucket_id = 'proofs'),
  2, 'admin reads proofs of their school only');
select lives_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('stops', '10000000-0000-4000-8000-000000000001/admin.jpg')$$,
  'admin can upload a stop photo for their school');
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('stops', '10000000-0000-4000-8000-000000000002/admin.jpg')$$,
  '42501', null, 'admin cannot upload a stop photo for another school');

-- ---------------------------------------------------------------- student of school B
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is(
  (select count(*)::int from storage.objects where bucket_id = 'stops'),
  0, 'another school cannot read stop photos');

-- ---------------------------------------------------------------- anon
reset role;
set local role anon;
set local "request.jwt.claims" = '{"role":"anon"}';

select is(
  (select count(*)::int from storage.objects),
  0, 'anonymous callers see no files');

-- ---------------------------------------------------------------- owner view after the student attempts
reset role;
select is(
  (select count(*)::int from storage.objects
    where bucket_id = 'proofs'
      and name = '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/proof.jpg'),
  1, 'the proof keeps its name: clients cannot rename files');

select * from finish();
rollback;
