begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

insert into public.schools (id, name) values ('10000000-0000-4000-8000-000000000001', 'School A'), ('10000000-0000-4000-8000-000000000002', 'School B');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data) values
  ('a3000000-0000-4000-8000-000000000001', 'admin@a.edu', '{"provider":"google"}'),
  ('a2000000-0000-4000-8000-000000000001', 'staff@a.edu', '{"provider":"google"}'),
  ('a1000000-0000-4000-8000-000000000001', 'student@a.edu', '{"provider":"google"}'),
  ('b3000000-0000-4000-8000-000000000001', 'admin@b.edu', '{"provider":"google"}'),
  ('b1000000-0000-4000-8000-000000000001', 'student@b.edu', '{"provider":"google"}');
update public.profiles set role = 'admin' where id in ('a3000000-0000-4000-8000-000000000001', 'b3000000-0000-4000-8000-000000000001');
update public.profiles set role = 'staff' where id = 'a2000000-0000-4000-8000-000000000001';

-- An account with no school yet: School A accepts other emails for a moment.
update public.schools set accepts_open_signup = true where id = '10000000-0000-4000-8000-000000000001';
insert into auth.users (id, email, raw_app_meta_data) values ('c1000000-0000-4000-8000-000000000001', 'waiting@elsewhere.org', '{"provider":"google"}');
update public.schools set accepts_open_signup = false where id = '10000000-0000-4000-8000-000000000001';

-- ---------------------------------------------------------------- inviting
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.admin_invite_staff('  Driver.New@Gmail.com ', 'staff'), 'invited', 'a new email waits for its first sign-in');
select is(public.admin_invite_staff('student@a.edu', 'staff'), 'applied', 'an account of the school gets the role at once');
select is(public.admin_invite_staff('waiting@elsewhere.org', 'staff'), 'applied', 'so does an account with no school yet');
select throws_ok($$select public.admin_invite_staff('student@b.edu', 'staff')$$, '55000', 'other_school', 'an account of another school is not taken');
select throws_ok($$select public.admin_invite_staff('admin@a.edu', 'staff')$$, '42501', null, 'not the admin''s own account');
select throws_ok($$select public.admin_invite_staff('not an email', 'staff')$$, '22023', 'invalid_email', 'the email is checked');
select throws_ok($$select public.admin_invite_staff('x@y.org', 'student')$$, '22023', 'invalid_role', 'only staff or admin');
select is(public.admin_invite_staff('late@gmail.com', 'admin'), 'invited', 'another invite');
select is(public.admin_invite_staff('late@gmail.com', 'staff'), 'invited', 'inviting again renews it');
select is((select role::text from public.staff_invites where email = 'late@gmail.com'), 'staff', 'with the new role');
select is((select count(*)::int from public.staff_invites), 2, 'the admin sees the school''s open invites');
reset role;

select is((select school_id::text || ':' || role::text || ':' || status::text from public.profiles where email = 'waiting@elsewhere.org'),
  '10000000-0000-4000-8000-000000000001:staff:verified', 'the account without a school joined, verified, as staff');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_invite_staff('late@gmail.com', 'staff')$$, '55000', 'other_school', 'another school cannot take over an open invite');
select is((select count(*)::int from public.staff_invites), 0, 'nor see it');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a2000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.admin_invite_staff('y@z.org', 'staff')$$, '42501', null, 'staff cannot invite');
select is((select count(*)::int from public.staff_invites), 0, 'nor see the invites');
reset role;

-- ---------------------------------------------------------------- signing up
insert into auth.users (id, email, raw_app_meta_data) values ('d1000000-0000-4000-8000-000000000001', 'driver.new@gmail.com', '{"provider":"google"}');
select is((select school_id::text || ':' || role::text || ':' || status::text from public.profiles where id = 'd1000000-0000-4000-8000-000000000001'),
  '10000000-0000-4000-8000-000000000001:staff:verified', 'an invited email joins the school as staff, whatever its domain');
select is((select count(*)::int from public.staff_invites where email = 'driver.new@gmail.com'), 0, 'the invite is used up');
select is((select count(*)::int from public.audit_log where action in ('invite.created', 'invite.applied', 'invite.accepted') and school_id = '10000000-0000-4000-8000-000000000001'), 6, 'every step is audited');

-- An expired invite is ignored: the school email falls back to a plain student.
insert into public.staff_invites (email, school_id, role, expires_at) values ('expired@a.edu', '10000000-0000-4000-8000-000000000001', 'staff', now() - interval '1 day');
insert into auth.users (id, email, raw_app_meta_data) values ('d1000000-0000-4000-8000-000000000002', 'expired@a.edu', '{"provider":"google"}');
select is((select role::text from public.profiles where id = 'd1000000-0000-4000-8000-000000000002'), 'student', 'an expired invite gives no role');

-- ---------------------------------------------------------------- cancelling
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select public.admin_cancel_invite('late@gmail.com');
reset role;
select is((select count(*)::int from public.staff_invites where email = 'late@gmail.com'), 1, 'another school cannot cancel it');
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a3000000-0000-4000-8000-000000000001","role":"authenticated"}';
select public.admin_cancel_invite('LATE@gmail.com');
reset role;
select is((select count(*)::int from public.staff_invites where email = 'late@gmail.com'), 0, 'the school''s admin can');

select * from finish();
rollback;
