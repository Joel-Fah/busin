begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 'ok@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2030, current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.buses (id, school_id, plate, capacity) values
  ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50);
-- A trip that ran from an hour ago until ten minutes ago: the phone was offline for all of it.
insert into public.trips (id, school_id, bus_id, direction, status, scheduled_start, started_at, ended_at) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001',
   'inbound', 'completed', now() - interval '1 hour', now() - interval '1 hour', now() - interval '10 minutes');
insert into public.subscriptions (school_id, student_id, semester_id, stop_id, status) values
  ('10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001',
   'd1000000-0000-4000-8000-000000000001', 'approved');
insert into private.qr_secrets (student_id, secret) values ('a1000000-0000-4000-8000-000000000001', decode(repeat('33', 32), 'hex'));

-- The code the student showed half an hour ago, and the time and id the staff phone kept with it.
create temp table queued (name text primary key, code text, at timestamptz);
grant all on queued to public;
insert into queued
select 'then', 'busin2.a1000000-0000-4000-8000-000000000001.' || w || '.' ||
  private.qr_mac(private.qr_day_key(q.secret, private.qr_window_date(w, 'Africa/Douala')), q.student_id, w), at
from private.qr_secrets q, lateral (select now() - interval '30 minutes' as at) t, lateral (select private.qr_window(t.at) as w) x
where q.student_id = 'a1000000-0000-4000-8000-000000000001';
insert into queued
select n, 'busin2.a1000000-0000-4000-8000-000000000001.' || w || '.' ||
  private.qr_mac(private.qr_day_key(q.secret, private.qr_window_date(w, 'Africa/Douala')), q.student_id, w), at
from private.qr_secrets q,
  (values ('early', now() - interval '2 hours'), ('now', now())) v(n, at),
  lateral (select private.qr_window(v.at) as w) x
where q.student_id = 'a1000000-0000-4000-8000-000000000001';

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from queued where name = 'then'), 'd1000000-0000-4000-8000-000000000001',
     3.85, 11.5, 12, (select at from queued where name = 'then'), '99999999-0000-4000-8000-000000000001')) ->> 'valid',
  'true', 'a scan made offline is accepted later, checked against the time it was made, after the trip ended');
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from queued where name = 'then'), 'd1000000-0000-4000-8000-000000000001',
     3.85, 11.5, 12, (select at from queued where name = 'then'), '99999999-0000-4000-8000-000000000001')) ->> 'duplicate',
  'true', 'sending it again records nothing new');
reset role;
select is((select count(*)::int from public.scans where trip_id = 'f1000000-0000-4000-8000-000000000001'), 1, 'one boarding');
select is((select scanned_at from public.scans where trip_id = 'f1000000-0000-4000-8000-000000000001'), (select at from queued where name = 'then'), 'it keeps the time it was made');
select is((select client_id from public.scans where trip_id = 'f1000000-0000-4000-8000-000000000001'), '99999999-0000-4000-8000-000000000001'::uuid, 'and the phone''s id for it');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(
  (public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from queued where name = 'then'), null, null, null, null, now() - interval '5 minutes')) ->> 'reason',
  'expired_code', 'the code is checked against the scan time: one made half an hour before it has expired');
select throws_ok(
  $$select public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from queued where name = 'early'), null, null, null, null, (select at from queued where name = 'early'))$$,
  '55000', 'The trip was not running at that time', 'a scan from before the trip started is refused');
select throws_ok(
  $$select public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from queued where name = 'then'), null, null, null, null, now() + interval '10 minutes')$$,
  '22023', 'invalid_scan_time', 'a scan time in the future is refused');
select throws_ok(
  $$select public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from queued where name = 'then'), null, null, null, null, now() - interval '25 hours')$$,
  '22023', 'invalid_scan_time', 'a scan more than a day old is refused');
select throws_ok(
  $$select public.record_qr_scan('f1000000-0000-4000-8000-000000000001', (select code from queued where name = 'now'))$$,
  '55000', 'The trip is not active', 'a live scan still needs a running trip');

reset role;
select * from finish();
rollback;
