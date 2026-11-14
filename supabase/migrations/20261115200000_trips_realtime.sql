-- The ops app hears while it is open that a trip was put on a staff member's crew (an administrator assigning or
-- moving a scheduled trip, or a colleague starting one in the field with them), so the Trips tab can show a dot.
-- Realtime applies Row Level Security (staff receive only their own trips, `trips_select`), and the app listens only for
-- changes, filtered to the trips where it is the driver or the assistant: no rows are loaded by the listener.
alter publication supabase_realtime add table public.trips;
