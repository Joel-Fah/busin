# Phase 5: insights

Goal: turn collected data into decisions for staff.

## Scope
- Nightly aggregates with `pg_cron`.
- Density heatmap and per-stop boardings in the admin portal.
- Built in this order (agreed with the owner, 2026-11-11):
  1. **Stop load map.** One circle per stop sized and coloured by load: boardings per departure against the seats on the bus (needs the stop of each scan from phase 4); until then, approved subscribers against the school's total seats.
  2. **Proximity per stop.** From the students' areas (ADR 0013): per stop, the median straight-line distance and bands (under 500 m, 0.5 to 1 km, 1 to 2 km, over 2 km) and the share living over 1 km; on the map, "desire lines" from a zone to a stop, as thick as the number of students. Distances are "about" (areas are rounded to 500 m; walks are longer than straight lines).
  3. **Students nearer another stop.** "12 students at A live nearer to B": actionable at once (tell them about B).
  4. **Stop suggestions.** Short sentences with the number behind them ("a stop near Carrefour Obili would bring 23 students within 500 m"; "X and Y are 350 m apart and share 9 students"; "Z has had no rider for 6 weeks"), from an explainable facility-location pass over the zones weighted by students. Candidate points are named places from the OpenStreetMap `places` table (crossroads, markets, schools, streets), so a suggestion is always a real, named spot. Combined with real boarding positions once phase 4 records them.
- **Privacy rules for all of these:** every figure, line or zone is shown only when at least 5 students with an area are behind it (as `admin_area_counts`), medians and bands rather than exact averages, no student point ever drawn, and "Not enough students yet" below the threshold. Each view says how many subscribers it is based on ("41 of 120"), since the area is optional.
- **Limits stated on the page:** suggestions do not know whether a bus can reach the spot (road width, one-way streets, route order); the admin decides and nothing changes by itself.
- To raise coverage before this: a dismissible card on the pass screen ("Help your school place stops near you"), could ship with phase 4.
- Pickup point suggestions: choose a small set of stop locations that covers the most students within walking distance (maximum coverage / facility location over boarding and home-area data), compared against the current fixed stops.
- Route optimization in a separate solver service (OR-Tools), planned for the fleet available that day (1 or 2 buses).
- Optional weekly summary written by a language model from aggregates only.

## Exit criteria
- Density map and suggestions render for real pilot data.
- Route suggestions are checked against the solver's constraints, not accepted from model output.

## Depends on
Phases 2 to 4 and enough collected scans.
