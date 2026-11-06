-- A student's app can follow its own subscription live (approved, rejected, revoked) while it is open. Realtime applies
-- Row Level Security, so a student only ever receives their own row; the app also filters to that row.
alter publication supabase_realtime add table public.subscriptions;
