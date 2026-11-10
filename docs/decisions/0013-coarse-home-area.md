# 0013: A coarse home area, given by the student

Status: accepted, 2026-11-11 (the owner chose this in the ideas round). Narrows the rule "location only in the ops app"
of the [busin-security skill](../../.claude/skills/busin-security/SKILL.md) for one case, and updates the privacy policy.

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
5. **Search through the server.** The app never talks to Mapbox. The `places-search` Edge Function checks the caller
   (verified student), counts their searches (20 a minute, 200 a day), biases results to the area around the school's
   stops, and returns only a label and a point. Mapbox receives the search text, never who typed it. Mapbox is already
   the approved map vendor ([ADR 0008](0008-map-provider.md)).
6. **Never tracked.** No background location, no repeated readings, no location in any other screen.

## Consequences
- The privacy policy (EN and FR) says what is kept, why, who sees it and how to remove it.
- The security skill rule becomes: location in the ops app when scanning or driving, and in the student app only for
  "My area", once, approximate, after an explanation.
- A new dependency in the student app: `geolocator`.
- Mapbox's terms limit storing results of its standard (temporary) geocoding. The app stores only a snapped grid cell
  and a short label. Before going live, the owner confirms this with Mapbox or turns on permanent geocoding in the
  function (a billing setting).
