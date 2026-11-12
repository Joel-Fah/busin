begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin1@a.edu', '{"provider":"google"}'),
  ('a3000000-0000-4000-8000-000000000002', 'admin2@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff1@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000002', 'staff2@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'stu1@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000002', 'stu2@a.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'a3000000-0000-4000-8000-000000000002');
update public.profiles set role = 'staff' where id in ('a2000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000002');

insert into public.semesters (id, school_id, name, year, start_date, end_date) values
  ('c1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'fall', 2026, current_date - 30, current_date + 30);
insert into public.stops (id, school_id, name, location) values
  ('d1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Stop A', extensions.st_point(11.5, 3.85)::extensions.geography);
insert into public.subscriptions (id, school_id, student_id, semester_id, stop_id, proof_path) values
  ('11000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000001/p.jpg'),
  ('11000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001/a1000000-0000-4000-8000-000000000002/p.jpg');
insert into public.buses (id, school_id, plate, capacity) values ('e1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'A-1', 50);
insert into public.trips (id, school_id, bus_id, direction, scheduled_start) values
  ('f1000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'inbound', now() + interval '1 day');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';

-- ---------------------------------------------------------------- roles: staff and administrator are one family, students another
select lives_ok($$select public.admin_set_user_role('a2000000-0000-4000-8000-000000000001', 'admin')$$, 'staff can become an administrator');
select lives_ok($$select public.admin_set_user_role('a2000000-0000-4000-8000-000000000001', 'staff')$$, 'and back');
select throws_ok($$select public.admin_set_user_role('a1000000-0000-4000-8000-000000000001', 'staff')$$, '22023', 'role_family', 'a student cannot become staff');
select throws_ok($$select public.admin_set_user_role('a1000000-0000-4000-8000-000000000001', 'admin')$$, '22023', 'role_family', 'nor an administrator');
select throws_ok($$select public.admin_set_user_role('a2000000-0000-4000-8000-000000000001', 'student')$$, '22023', 'role_family', 'staff cannot become a student');
select throws_ok($$select public.admin_set_user_role('a3000000-0000-4000-8000-000000000002', 'student')$$, '22023', 'role_family', 'nor an administrator');
select lives_ok($$select public.admin_set_user_role('a1000000-0000-4000-8000-000000000001', 'student')$$, 'a student staying a student is no change and no problem');

-- ---------------------------------------------------------------- the last administrator
select lives_ok($$select public.admin_set_user_role('a3000000-0000-4000-8000-000000000002', 'staff')$$, 'an administrator can be demoted while another remains');
select throws_ok($$select public.admin_set_user_role('a3000000-0000-4000-8000-000000000001', 'staff')$$, '42501', null, 'one cannot demote oneself');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.admin_set_user_role('a3000000-0000-4000-8000-000000000001', 'staff')$$, '42501', 'Admin access required', 'a demoted administrator has no more admin power');
reset role;
update public.profiles set role = 'admin' where id = 'a3000000-0000-4000-8000-000000000002';
update public.profiles set status = 'suspended' where id = 'a3000000-0000-4000-8000-000000000002';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
-- Only one verified administrator is left (the other is suspended).
select throws_ok($$select public.admin_invite_staff('admin1@a.edu', 'staff')$$, '42501', null, 'the last administrator cannot be demoted by an invite either (it would be themselves)');
reset role;
update public.profiles set status = 'verified' where id = 'a3000000-0000-4000-8000-000000000002';

-- ---------------------------------------------------------------- status: suspend, restore, nothing else
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.admin_set_user_status('a2000000-0000-4000-8000-000000000002', 'suspended')$$, 'an account can be suspended');
select throws_ok($$select public.admin_set_user_status('a2000000-0000-4000-8000-000000000002', 'pending')$$, '55000', 'invalid_transition', 'a suspended account can only be restored, not made pending');
select throws_ok($$select public.admin_set_user_status('a2000000-0000-4000-8000-000000000002', 'suspended')$$, '55000', 'invalid_transition', 'nor suspended twice');
select throws_ok($$select public.admin_set_user_status('a1000000-0000-4000-8000-000000000001', 'pending')$$, '55000', 'invalid_transition', 'a verified account cannot be made pending');

-- ---------------------------------------------------------------- nothing is done to a suspended account
select throws_ok($$select public.admin_set_user_role('a2000000-0000-4000-8000-000000000002', 'admin')$$, '55000', 'account_not_active', 'its role cannot be changed');
select throws_ok($$select public.admin_invite_staff('staff2@a.edu', 'admin')$$, '55000', 'account_not_active', 'nor can it be invited into another role');
select throws_ok($$select public.admin_invite_staff('stu2@a.edu', 'staff')$$, '55000', 'student_account', 'an invite never turns a student into staff');

-- ---------------------------------------------------------------- a suspended student's subscriptions are frozen
reset role;
update public.profiles set status = 'suspended' where id = 'a1000000-0000-4000-8000-000000000002';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000002', 'approved')$$, '55000', 'account_suspended', 'a suspended student''s request cannot be approved');
select throws_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000002', 'rejected', 'This account is on hold')$$, '55000', 'account_suspended', 'nor rejected');
select lives_ok($$select public.admin_set_user_status('a1000000-0000-4000-8000-000000000002', 'verified')$$, 'restoring the account frees it');
select lives_ok($$select public.admin_review_subscription('11000000-0000-4000-8000-000000000002', 'approved')$$, 'and then the request can be reviewed');
reset role;
update public.profiles set status = 'suspended' where id = 'a1000000-0000-4000-8000-000000000002';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_revoke_subscription('11000000-0000-4000-8000-000000000002', 'Payment was reversed')$$, '55000', 'account_suspended', 'an approved subscription of a suspended student cannot be revoked until restored');

-- ---------------------------------------------------------------- the last administrator cannot be suspended
reset role;
update public.profiles set role = 'staff' where id = 'a3000000-0000-4000-8000-000000000002';
update public.profiles set status = 'verified' where id = 'a3000000-0000-4000-8000-000000000002';
update public.profiles set role = 'admin' where id = 'a2000000-0000-4000-8000-000000000001';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.admin_set_user_status('a2000000-0000-4000-8000-000000000001', 'suspended')$$, 'an administrator can be suspended while another remains');
select lives_ok($$select public.admin_set_user_status('a2000000-0000-4000-8000-000000000001', 'verified')$$, 'and a suspended administrator can be restored');
reset role;

-- ---------------------------------------------------------------- trip crew must be verified staff
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
reset role;
update public.profiles set role = 'staff' where id = 'a3000000-0000-4000-8000-000000000002';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$update public.trips set driver_id = 'a1000000-0000-4000-8000-000000000001' where id = 'f1000000-0000-4000-8000-000000000001'$$, '22023', 'crew_not_staff', 'a student cannot be a trip''s driver');
select throws_ok($$update public.trips set assistant_id = 'a2000000-0000-4000-8000-000000000002' where id = 'f1000000-0000-4000-8000-000000000001'$$, '22023', 'crew_not_staff', 'nor can a suspended staff member be its assistant');
select lives_ok($$update public.trips set driver_id = 'a3000000-0000-4000-8000-000000000002' where id = 'f1000000-0000-4000-8000-000000000001'$$, 'a verified staff member can');
reset role;

select * from finish();
rollback;
