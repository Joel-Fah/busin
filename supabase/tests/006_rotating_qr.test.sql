begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'ok@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'other@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000003', 'nosub@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000004', 'susp@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2030,
   current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A',
   extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50);
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   'e1000000-0000-4000-8000-000000000001', 'inbound', 'active', now(), now());
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status)
select '10000000-0000-4000-8000-000000000001', s, 'c1000000-0000-4000-8000-000000000001',
       'd1000000-0000-4000-8000-000000000001', 'approved'
from unnest(array[
  'a1000000-0000-4000-8000-000000000001'::uuid,
  'a1000000-0000-4000-8000-000000000002'::uuid,
  'a1000000-0000-4000-8000-000000000004'::uuid]) as s;

-- Format and parity: the vector was computed with Node's crypto module, an independent
-- implementation, so the future Dart client can be checked against the same value.
select is(
  private.qr_mac(
    decode('000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f', 'hex'),
    'a1000000-0000-4000-8000-000000000001', 57000000),
  'c73e53d52fa5fb670e54', 'the code mac matches the independent test vector');
select is(
  private.qr_window('2030-01-01 00:00:29+00'::timestamptz) + 1,
  private.qr_window('2030-01-01 00:00:30+00'::timestamptz),
  'the window advances every 30 seconds');

-- ---------------------------------------------------------------- secrets
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000009","role":"authenticated"}';
select throws_ok($$select public.get_my_qr_secret()$$, '42501', null, 'an unknown caller gets no secret');

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.get_my_qr_secret()$$, '42501', 'No active subscription',
  'a student without an active subscription gets no secret');

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.get_my_qr_secret()$$, '42501', 'Only students have a boarding code',
  'staff do not have a boarding code');

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.get_my_qr_secret()$$, 'an eligible student can fetch their secret');
select is(length(decode(public.get_my_qr_secret(), 'base64')), 32, 'the secret is 32 bytes');
select is(public.get_my_qr_secret(), public.get_my_qr_secret(), 'the secret is stable between calls');
select throws_ok($$select secret from private.qr_secrets$$, '42501', null,
  'clients cannot read the secrets table');

-- ---------------------------------------------------------------- scanning
reset role;
-- Other students need a secret too; create them the way the function would.
insert into private.qr_secrets (student_id, secret) values
  ('a1000000-0000-4000-8000-000000000002', decode(repeat('11', 32), 'hex')),
  ('a1000000-0000-4000-8000-000000000004', decode(repeat('22', 32), 'hex'));

create temp table codes (name text primary key, code text);
grant all on codes to public;

insert into codes
select 'now', 'busin1.a1000000-0000-4000-8000-000000000001.' || private.qr_window(now()) || '.' ||
  private.qr_mac(q.secret, q.student_id, private.qr_window(now()))
from private.qr_secrets q where q.student_id = 'a1000000-0000-4000-8000-000000000001';

insert into codes
select 'prev', 'busin1.a1000000-0000-4000-8000-000000000002.' || (private.qr_window(now()) - 1) || '.' ||
  private.qr_mac(q.secret, q.student_id, private.qr_window(now()) - 1)
from private.qr_secrets q where q.student_id = 'a1000000-0000-4000-8000-000000000002';

insert into codes
select 'old', 'busin1.a1000000-0000-4000-8000-000000000002.' || (private.qr_window(now()) - 2) || '.' ||
  private.qr_mac(q.secret, q.student_id, private.qr_window(now()) - 2)
from private.qr_secrets q where q.student_id = 'a1000000-0000-4000-8000-000000000002';

insert into codes
select 'future', 'busin1.a1000000-0000-4000-8000-000000000002.' || (private.qr_window(now()) + 2) || '.' ||
  private.qr_mac(q.secret, q.student_id, private.qr_window(now()) + 2)
from private.qr_secrets q where q.student_id = 'a1000000-0000-4000-8000-000000000002';

insert into codes
select 'suspended', 'busin1.a1000000-0000-4000-8000-000000000004.' || private.qr_window(now()) || '.' ||
  private.qr_mac(q.secret, q.student_id, private.qr_window(now()))
from private.qr_secrets q where q.student_id = 'a1000000-0000-4000-8000-000000000004';
update public.profiles set status = 'suspended' where id = 'a1000000-0000-4000-8000-000000000004';

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from codes where name = 'now'))) ->> 'valid',
  'true', 'a current code is accepted');
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from codes where name = 'now'))) ->> 'duplicate',
  'true', 'the same code again is a duplicate, not a second boarding');
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from codes where name = 'prev'))) ->> 'valid',
  'true', 'the previous window is accepted for clock differences');
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from codes where name = 'old'))) ->> 'reason',
  'expired_code', 'a code two windows old has expired');
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from codes where name = 'future'))) ->> 'reason',
  'invalid_code', 'a code from the future is refused');
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001',
     regexp_replace((select code from codes where name = 'now'), '.$', 'x'))) ->> 'reason',
  'invalid_code', 'a tampered code is refused');
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001')) ->> 'reason',
  'invalid_code', 'the old plain-id QR is refused');
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', 'not a code')) ->> 'reason',
  'invalid_code', 'garbage is refused');
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from codes where name = 'suspended'))) ->> 'reason',
  'account_not_verified', 'a valid code for a suspended student is refused');
select is((select count(*)::int from public.scans), 2, 'only the two valid boardings were recorded');

-- ---------------------------------------------------------------- caller checks and rotation
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.record_qr_scan('f1000000-0000-4000-8000-000000000001', 'busin1.x.1.y')$$,
  '42501', 'Staff access required', 'a student cannot submit scans');

reset role;
create temp table old_secret as
  select encode(secret, 'base64') as secret from private.qr_secrets
  where student_id = 'a1000000-0000-4000-8000-000000000001';
grant all on old_secret to public;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select isnt(public.rotate_my_qr_secret(), (select secret from old_secret), 'rotating gives a new secret');

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from codes where name = 'now'))) ->> 'reason',
  'invalid_code', 'a code made with the old secret stops working after rotation');

reset role;
set local role anon;
set local "request.jwt.claims" = '{"role":"anon"}';
select throws_ok($$select public.get_my_qr_secret()$$, '42501', null, 'anonymous callers cannot fetch a secret');

reset role;
select * from finish();
rollback;
