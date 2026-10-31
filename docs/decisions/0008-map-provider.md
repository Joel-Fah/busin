# 0008: Map provider behind a provider-neutral component

Status: accepted, 2026-10-31.

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
