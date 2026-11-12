# 0017: The bus route, drawn along roads

Date: 2026-11-11. Status: accepted (owner, 2026-11-11). Builds on [ADR 0008](0008-map-provider.md) (routing was left for
later) and the phase 5 insights.

## Context

A school's stops are not a loose set: the bus leaves from its first pickup and goes stop after stop until the campus.
Insights and stop suggestions should read where students live against that route, and a suggested stop is only useful
if the route can take it in. Drawing a route along real streets needs a routing service.

## Decision

1. **Campus.** Each school has a campus point and name (`schools.campus_location`, `campus_name`), set by its admins.
2. **One route per school now.** `routes` and `route_stops` (stops in order, the route ends at the campus). The tables
   allow more routes per school later (another bus, another direction); the functions use the school's first route.
3. **Road routing: Mapbox Directions** (owner's choice, same account as the optional map provider). Called only from
   the `route-directions` Edge Function, never from a client, with a server-only token (`MAPBOX_DIRECTIONS_TOKEN`),
   driving profile, at most 25 waypoints per request (longer routes are split and joined).
4. **Stored, not recomputed.** The geometry, total distance and time, and each leg's distance and time (stop to stop,
   then to the campus) are stored on the route with a hash of the stops and campus; a changed order clears them. A
   preview mode returns a route for a suggestion (the route with a stop inserted) without storing it.
5. **Limits.** Admins only; at most 30 calls an hour and 300 a day per school. Without a token the portal draws straight
   segments between stops and says the road route is not drawn yet.
6. **Directions** are stop by stop: each leg's distance and time, no street turns (owner's choice).

## Consequences

- One new use of an existing vendor; requests are rare (a route changes when its stops do). Mapbox's free tier covers
  it many times over.
- Students and staff of the school may read its route (for the student app later); only admins change it.
- The route is the backbone of the Insights maps and graph, and of suggested routes.
