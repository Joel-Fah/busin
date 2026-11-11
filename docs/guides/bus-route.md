# The bus route

How a school's route works and how to set up road drawing ([ADR 0017](../decisions/0017-bus-route.md)).

## What it is

- The **campus** is where every route ends. An admin sets it on the Stops page.
- The **route** is the school's active stops in the order the bus picks students up, from the first pickup to the
  campus. One route per school for now.
- The portal draws it **along real roads** with Mapbox Directions, through the `route-directions` Edge Function, and
  stores the road with each leg's distance and time. Changing the order, moving a stop or the campus makes it out of date
  until it is drawn again. Without a token the portal draws straight lines between stops.

## Set up road drawing (owner)

1. In the Mapbox account, create a token for this use only (Account, Tokens, Create a token). The default public scopes
   are enough for Directions. Do not add a URL restriction: it is used from the server, not from a browser.
2. Locally: copy `supabase/functions/.env.example` to `supabase/functions/.env` and put the token in
   `MAPBOX_DIRECTIONS_TOKEN`. `npm run backend:start` now starts the Edge Functions runtime too (it used to be left
   out, so the route stayed straight). If drawing still says it is not set up, run `npx supabase functions serve` in
   a terminal and keep it open: it reads `supabase/functions/.env` directly.
4. On the Stops page, open Bus route and press "Draw along roads". The road is stored; it stays until the stops, their
   order or the campus change.
3. Hosted project (later): `supabase secrets set MAPBOX_DIRECTIONS_TOKEN=...`.

The token never reaches a browser or an app. Each school can draw at most 30 routes an hour and 300 a day.
