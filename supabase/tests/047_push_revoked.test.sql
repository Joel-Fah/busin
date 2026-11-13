begin;
create extension if not exists pgtap with schema extensions;
select plan(6);
delete from private.notification_outbox;

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values ('a1000000-0000-4000-8000-000000000001', 'stu@a.edu', '{"provider":"google"}');
insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2090, '2090-09-01', '2091-01-31');
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, status) values
  ('51000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'approved');

update public.subscriptions set status = 'revoked' where id = '51000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox), 1, 'revoking an approved subscription queues one notification');
select is((select kind from private.notification_outbox), 'subscription_revoked', 'as a revocation');
select is((select user_id from private.notification_outbox), 'a1000000-0000-4000-8000-000000000001'::uuid, 'for its student');
select is((select ref_id from private.notification_outbox), '51000000-0000-4000-8000-000000000001'::uuid, 'about that subscription');

update public.subscriptions set status = 'approved' where id = '51000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox where kind = 'subscription_approved'), 1, 'getting it back still queues an approval');

update public.subscriptions set status = 'expired' where id = '51000000-0000-4000-8000-000000000001';
update public.subscriptions set status = 'revoked' where id = '51000000-0000-4000-8000-000000000001';
select is((select count(*)::int from private.notification_outbox), 2, 'revoking one that had already expired queues nothing');

select * from finish();
rollback;
