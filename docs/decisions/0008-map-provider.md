# 0008: Map provider behind a provider-neutral component

Status: accepted, 2026-10-31. Amended 2026-11-04 (owner request, see [ADR 0009](0009-design-system.md)): the portal now uses Mapbox when a public token is configured, and keeps MapLibre with OpenFreeMap as the fallback and the free alternative.

## Context
The admin portal needs maps for placing stops now, and for density heatmaps, pickup suggestions and routes in Phase 5. The owner wants to start free and be able to move to Mapbox later without rewriting pages.

## Facts checked on 2026-10-31
| Option | Library | Licence | Cost |
|---|---|---|---|
| MapLibre GL JS 6.16 with OpenFreeMap tiles | `maplibre-gl` | BSD-3-Clause | No key. OpenFreeMap says it has no usage limits and is funded by donations; this comes from secondary sources, so confirm on openfreemap.org before relying on it for heavy traffic |
| Mapbox GL JS 3.x | `mapbox-gl` | Proprietary since v2 | Needs an access token. Third-party 2026 summaries report 50,000 free map loads a month, then per-load billing; confirm on mapbox.com/pricing |

OpenStreetMap's own tile servers are not a free production CDN, so they are not used.

## Decision
- Start with **MapLibre GL JS** and the **OpenFreeMap** style. No account, key or card.
- Pages and forms never import a map library. They use `components/map/MapView.tsx` with the props in `components/map/types.ts`: a centre, a zoom, a style address, optional fixed markers and an optional picker. Positions are plain latitude and longitude, the same as the database.
- All MapLibre code lives in `components/map/providers/maplibre.tsx`. `MapView.tsx` is the only place providers are registered.
- Settings come from environment variables and are validated in `lib/map/config.ts`: `MAP_PROVIDER`, `MAP_STYLE_URL`, `MAP_DEFAULT_LAT`, `MAP_DEFAULT_LNG`, `MAP_DEFAULT_ZOOM`. Invalid values fall back to safe defaults. None is a secret.

## How to move to Mapbox (or another provider)
1. Install `mapbox-gl` in `apps/admin_web`.
2. Create `components/map/providers/mapbox.tsx` with a default export that implements `MapViewProps`. Copy `maplibre.tsx` as the starting point: the two libraries have very similar APIs (map, marker, click events, bounds).
3. Add `"mapbox"` to `MAP_PROVIDERS` in `lib/map/config.ts`, and register the new component in `components/map/MapView.tsx`.
4. Put the Mapbox access token in a public environment variable and read it in the new provider file. A Mapbox public token is meant for browsers; restrict it to the portal's address in the Mapbox dashboard.
5. Set `MAP_PROVIDER=mapbox` and `MAP_STYLE_URL` to a Mapbox style address.
6. Run the existing browser tests; they intercept the style request, so point the interception at the new host.

Do not point MapLibre at Mapbox's tiles or styles: Mapbox's terms tie those to its own library.

## Not covered by the abstraction
- **Place search and address lookup** (geocoding), routing and distance matrices. They are separate services with their own cost and licence. Add a similar small interface when a page needs one. The route solver in Phase 5 runs on the server and does not depend on the map provider.
- **Heatmap layers** in Phase 5 will need a layer concept in the contract. Extend `MapViewProps` then; the DB and pages stay unchanged.

## Consequences
- Swapping provider touches three files plus configuration, not the pages.
- The abstraction is intentionally small. Features only one provider offers would need a deliberate extension of the contract.
- Self-hosting tiles (for example with Protomaps) later only changes `MAP_STYLE_URL`.

## Mapbox switch (2026-11-04)
- **Provider**: `components/map/providers/mapbox.tsx` implements the same contract as MapLibre. `lib/map/config.ts` picks Mapbox in production when `MAPBOX_API_KEY` holds a valid public token, MapLibre otherwise, and `MAP_PROVIDER` can force either. In development and tests the free map is the default, so they never bill. With no token the portal never breaks.
- **Token**: only a public token (`pk.`) is accepted; a secret token (`sk.`) is rejected in code and covered by a test. A public token is meant for the browser, so it is handed to the page as a prop. It must be restricted to the portal's address in the Mapbox account, which is what stops others using it.
- **Terms**: Mapbox GL JS is proprietary. The Mapbox logo and attribution stay visible. Usage beyond the free allowance is billed, so keep an eye on map loads in the Mapbox dashboard.
- **Privacy**: Mapbox GL JS sends usage events to `events.mapbox.com`. Maps are shown only to signed-in administrators, and no student data goes into those requests, but it is a third party the school should know about.
- **Styles**: the default is `mapbox://styles/mapbox/streets-v12`; `MAP_STYLE_URL` can point at another Mapbox style. A matching dark style for dark mode is a follow-up.

## Keeping Mapbox cheap (2026-11-04)
Mapbox GL JS bills per **map load**: each time a map is created on a page. Panning, zooming and switching style cost nothing, and a session lasts up to 12 hours. Prices and the free allowance change; read the current figures on [Mapbox's GL JS pricing page](https://docs.mapbox.com/mapbox-gl-js/guides/pricing/) (at last check the first 50,000 loads a month were free, with a much lower cap on accounts without a payment method). The only lever that matters is therefore how many maps get created, and the portal controls it like this:

- **One map per browser tab.** The Mapbox provider creates a map once and moves the same map into whichever page needs it (`components/map/providers/mapbox.tsx`). Visiting the stops list, a form and back is one load, and React's double mount in development is one load, not two. Proven by `e2e/mapbox.spec.ts`: three page views, one style request.
- **A per-browser budget.** At most 30 new Mapbox maps per browser per 24 hours (`lib/map/budget.ts`). Past that the free MapLibre map is drawn instead, with no call to Mapbox. This catches our own mistakes (a remount loop, a page that creates a map on every render); it does not stop a determined abuser, who could clear their storage.
- **Mapbox only in production by default.** Development, tests and CI use the free map unless `MAP_PROVIDER=mapbox` is set on purpose. The Mapbox tests are opt-in and cost about two loads a run: `E2E_PROD=1 E2E_PORT=3100 MAP_PROVIDER=mapbox npx playwright test e2e/mapbox.spec.ts`.
- **Maps only where they are needed.** Only the Stops pages draw a map, and only for signed-in administrators. Other pages create nothing.
- **No other paid Mapbox APIs.** No geocoding, directions or static images until a decision says so.

Rough scale: ten administrators opening the map pages five times a day is about a thousand loads a month, far inside the free allowance. A student-facing map would change that, and the mobile apps are billed differently (per monthly active user), so decide the student app's map separately before Phase 3; free options such as MapLibre with OpenStreetMap-based tiles are the default candidate.

Token hygiene, for the owner:
- Use two tokens in the Mapbox account: one restricted to the production address (URL restriction) in the production environment, and a separate one for local development (restricted to `localhost` and `127.0.0.1`) in `apps/admin_web/.env.local`. Never a secret (`sk.`) token, and never commit either.
- Restrict each token to the scopes it needs (public styles and tiles reading); the portal needs nothing else.
- Check the usage page in the Mapbox account after the first week and monthly after that, and look in the account's billing and usage settings for usage notifications or limits. I cannot verify which alerting features your plan offers, so check them in your account; if a hard cap exists, set it.
- If the token leaks, rotate it in the Mapbox account, update the environment, and the old one stops working.
