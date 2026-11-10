-- A student's app hears its own boardings while it is open, to say "on board" the moment the code is scanned. Realtime
-- applies Row Level Security (a student reads only their own scans), and the app listens to its newest scan only.
alter publication supabase_realtime add table public.scans;
