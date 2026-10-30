# Phase 5: insights

Goal: turn collected data into decisions for staff.

## Scope
- Nightly aggregates with `pg_cron`.
- Density heatmap and per-stop boardings in the admin portal.
- Pickup point suggestions: choose a small set of stop locations that covers the most students within walking distance (maximum coverage / facility location over boarding and home-area data), compared against the current fixed stops.
- Route optimization in a separate solver service (OR-Tools), planned for the fleet available that day (1 or 2 buses).
- Optional weekly summary written by a language model from aggregates only.

## Exit criteria
- Density map and suggestions render for real pilot data.
- Route suggestions are checked against the solver's constraints, not accepted from model output.

## Depends on
Phases 2 to 4 and enough collected scans.
