-- Buses can have a name. Where a bus is shown, its name is used when it has one, otherwise its plate. Two buses of the
-- same school cannot share a name (letter case ignored); buses of different schools can.

alter table public.buses add column name text check (name is null or char_length(btrim(name)) between 1 and 40);

create unique index buses_school_name_key on public.buses (school_id, lower(btrim(name))) where name is not null;

grant update (name) on public.buses to authenticated;

comment on column public.buses.name is 'What the school calls the bus. Optional; shown instead of the plate when set. Unique per school, ignoring case.';
