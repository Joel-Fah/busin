begin;
create extension if not exists pgtap with schema extensions;
select plan(2);

select ok(
  exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'subscriptions'),
  'subscriptions is published to Realtime');
select ok(
  (select relrowsecurity and relforcerowsecurity from pg_class where oid = 'public.subscriptions'::regclass),
  'and its Row Level Security is on, so Realtime only delivers a student their own row');

select * from finish();
rollback;
