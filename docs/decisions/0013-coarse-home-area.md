# 0013: A coarse home area, given by the student

Status: accepted, 2026-11-11 (the owner chose this in the ideas round). Narrows the rule "location only in the ops app"
of the [busin-security skill](../../.claude/skills/busin-security/SKILL.md) for one case, and updates the privacy policy.
Amended by [ADR 0016](0016-show-me-on-my-bus.md) (2026-11-11): the student app may also read a precise position on My bus, when the student asks, kept on the phone.

## Context
Schools want to place stops and plan routes where students live (phase 5). Today the student app never reads the
phone's location, and a typed address is not reliable. The owner wants students to be able to say where they live,
once, without being tracked.

## Decision
1. **Optional and asked for.** "My area" sits in the profile. It is never asked during setup and nothing depends on it.
2. **Two ways in.** "Are you home right now?" If yes, the app explains what it reads and asks for **approximate
   location** only (Android `ACCESS_COARSE_LOCATION`, iOS reduced accuracy), and reads it **once**. If no, the student
   searches a place and picks a result; "Not seeing your street?" leaves a note to do it later at home.
3. **Coarse on the server.** `set_my_area` snaps the point to a grid of about 500 m before it is stored
   (`student_areas`, one row per student). The exact point is never stored and never returned. The app rounds it too.
4. **Who sees what.** The student reads, changes and deletes their own area. Nobody else reads a row: administrators
   only get `admin_area_counts()`, the grid cells of their school with at least 5 students, for planning.
5. **Search on our own copy of OpenStreetMap** (revised the same day, after testing: Mapbox's geocoding knew few
   Yaounde neighbourhoods, OpenStreetMap knows them). `tools/import-places.mjs` imports the named places around a
   school's stops (neighbourhoods, villages, streets, landmarks) from the public Overpass service into `places`, when a
   school starts or its stops move. `search_places` searches them in Postgres (ignoring case, accents and hyphens,
   nearest to the school first) for verified members of that school, 60 searches a minute and 600 a day. Nothing leaves
   our server at search time, there is no per-search cost, and no third party sees what students type. The data is
   (c) OpenStreetMap contributors under the ODbL: the app credits it under the results.
6. **Never tracked.** No background location, no repeated readings, no location in any other screen.

## Consequences
- The privacy policy (EN and FR) says what is kept, why, who sees it and how to remove it.
- The security skill rule becomes: location in the ops app when scanning or driving, and in the student app only for
  "My area", once, approximate, after an explanation.
- A new dependency in the student app: `geolocator`.
- No Mapbox call and no Mapbox token for place search (the first version's `places-search` Edge Function was removed).
- Each school's places must be imported once (`npm run places:import -- <school id>`), and again when its stops move.
  Against a hosted project that is the owner's call. The places table is internal and never published, so the ODbL
  share-alike terms for public databases do not apply; the credit does.
