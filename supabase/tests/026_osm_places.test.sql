begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into public.schools (id, name, timezone) values ('10000000-0000-4000-8000-000000000001', 'School A', 'UTC'), ('10000000-0000-4000-8000-000000000002', 'School B', 'UTC');
insert into public.school_domains (domain, school_id) values ('a.edu', '10000000-0000-4000-8000-000000000001'), ('b.edu', '10000000-0000-4000-8000-000000000002');
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data) values
  ('a1000000-0000-4000-8000-000000000001', 's@a.edu', '{"provider":"google"}', '{}'),
  ('a1000000-0000-4000-8000-000000000002', 'q@a.edu', '{"provider":"google"}', '{}'),
  ('b1000000-0000-4000-8000-000000000001', 's@b.edu', '{"provider":"google"}', '{}');
insert into public.stops (school_id, name, location) values
  ('10000000-0000-4000-8000-000000000001', 'Stop', extensions.st_point(11.5, 3.86)::extensions.geography);

select is(private.place_key('  Éssos - Mvog’Ada  '), 'essos mvog ada', 'keys ignore case, accents, hyphens and apostrophes');

select is(public.import_places('10000000-0000-4000-8000-000000000001', $$[
  {"osm_id": "r1", "name": "Bastos", "kind": "area", "lat": 3.894, "lng": 11.511},
  {"osm_id": "r2", "name": "Éssos", "kind": "area", "lat": 3.876, "lng": 11.543},
  {"osm_id": "w1", "name": "Rue de Bastos", "kind": "street", "lat": 3.890, "lng": 11.510},
  {"osm_id": "n1", "name": "Mendong", "kind": "village", "lat": 3.785, "lng": 11.627},
  {"osm_id": "n2", "name": "Mendong", "kind": "area", "lat": 3.835, "lng": 11.473},
  {"osm_id": "n3", "name": "", "kind": "area", "lat": 3.8, "lng": 11.4},
  {"osm_id": "n4", "name": "Bad kind", "kind": "river", "lat": 3.8, "lng": 11.4}
]$$::jsonb), 5, 'an import keeps the named places of known kinds');
select is(public.import_places('10000000-0000-4000-8000-000000000002', '[{"osm_id": "r1", "name": "Bastos B", "kind": "area", "lat": 3.9, "lng": 11.5}]'), 1, 'each school has its own places');
select is(public.import_places('10000000-0000-4000-8000-000000000001', $$[
  {"osm_id": "r1", "name": "Bastos", "kind": "area", "lat": 3.894, "lng": 11.511},
  {"osm_id": "r2", "name": "Éssos", "kind": "area", "lat": 3.876, "lng": 11.543},
  {"osm_id": "w1", "name": "Rue de Bastos", "kind": "street", "lat": 3.890, "lng": 11.510},
  {"osm_id": "n1", "name": "Mendong", "kind": "village", "lat": 3.785, "lng": 11.627},
  {"osm_id": "n2", "name": "Mendong", "kind": "area", "lat": 3.835, "lng": 11.473}
]$$::jsonb), 5, 'a new import replaces the school''s places');
select is((select count(*)::int from public.places where school_id = '10000000-0000-4000-8000-000000000002'), 1, 'and leaves other schools alone');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select string_agg(label || ':' || kind, ', ') from public.search_places('bastos')), 'Bastos:area, Rue de Bastos:street', 'names starting with the text come first');
select is((select label from public.search_places('essos')), 'Éssos', 'without the accent');
select is((select lng from public.search_places('mendong') limit 1), 11.473::double precision, 'the area before the village of the same name');
select is((select count(*)::int from public.search_places('b')), 0, 'one letter searches nothing');
select throws_ok($$select public.import_places('10000000-0000-4000-8000-000000000001', '[]')$$, '42501', null, 'students cannot import');
select throws_ok('select * from public.places', '42501', null, 'the table itself is closed');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"b1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select string_agg(label, ',') from public.search_places('bastos')), 'Bastos B', 'only the caller''s school');
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"a1000000-0000-4000-8000-000000000002","role":"authenticated"}';
do $$ begin for i in 1..60 loop perform public.search_places('bastos'); end loop; end $$;
select throws_ok($$select * from public.search_places('bastos')$$, 'PT429', 'too_many_searches', 'the 61st search in a minute is refused');
reset role;

select * from finish();
rollback;
