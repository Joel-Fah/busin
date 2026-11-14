begin;
create extension if not exists pgtap with schema extensions;
select plan(2);

-- The ops app hears about trips put on its crew while it is open (Realtime applies the trips' Row Level Security).
select ok(exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'trips'),
  'trips are published to Realtime');
select ok((select relrowsecurity from pg_class where oid = 'public.trips'::regclass), 'and keep Row Level Security, which Realtime applies');

select * from finish();
rollback;
