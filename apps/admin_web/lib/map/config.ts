import { isValidLatLng, type LatLng } from "@/lib/geo";

/**
 * Which map implementation the portal uses. To add one, add its id here, a
 * provider file under `components/map/providers/`, and an entry in `components/map/MapView.tsx`.
 * See docs/decisions/0008-map-provider.md.
 */
export const MAP_PROVIDERS = ["maplibre", "mapbox"] as const;
export type MapProviderId = (typeof MAP_PROVIDERS)[number];

export type MapConfig = {
  provider: MapProviderId;
  /** Where the base map comes from (a style document for MapLibre, a mapbox:// style for Mapbox). */
  styleUrl: string;
  /**
   * Mapbox public access token (starts with pk.). It is meant for the browser and is restricted to this
   * site in the Mapbox account. Empty for other providers. A secret token (sk.) is never accepted.
   */
  accessToken: string;
  /** Used only when a school has no stops yet. */
  fallbackCenter: LatLng;
  fallbackZoom: number;
};

// OpenFreeMap: free vector tiles with no key. Replace through MAP_STYLE_URL, for example to self-host.
export const DEFAULT_STYLE_URL = "https://tiles.openfreemap.org/styles/liberty";
export const DEFAULT_MAPBOX_STYLE_URL = "mapbox://styles/mapbox/streets-v12";
export const DEFAULT_CENTER: LatLng = { lat: 3.848, lng: 11.502 };
export const DEFAULT_ZOOM = 12;

type Env = Record<string, string | undefined>;

function isStyleUrl(value: string, allowMapbox: boolean): boolean {
  try {
    const url = new URL(value);
    const local = url.hostname === "127.0.0.1" || url.hostname === "localhost";
    return url.protocol === "https:" || (url.protocol === "http:" && local) || (allowMapbox && url.protocol === "mapbox:");
  } catch {
    return false;
  }
}

/** A Mapbox public token starts with pk. Anything else, above all a secret sk. token, is ignored. */
export function isPublicMapboxToken(value: string | undefined): value is string {
  return typeof value === "string" && /^pk\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(value.trim());
}

function number(value: string | undefined): number | null {
  if (value === undefined || value.trim() === "") return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

/**
 * Reads the map settings from environment variables, falling back to safe defaults for anything
 * missing or invalid. Public values only: nothing here is a secret.
 */
export function resolveMapConfig(env: Env): MapConfig {
  const token = isPublicMapboxToken(env.MAPBOX_API_KEY) ? env.MAPBOX_API_KEY.trim() : "";

  // Mapbox bills per map load, so it is the default only in production. Development and tests use the free
  // map unless MAP_PROVIDER=mapbox is set on purpose. Without a valid token the free map is always used,
  // so the portal never breaks.
  const requested = env.MAP_PROVIDER?.trim();
  const wanted = MAP_PROVIDERS.find((id) => id === requested) ?? (token && env.NODE_ENV === "production" ? "mapbox" : "maplibre");
  const provider: MapProviderId = wanted === "mapbox" && !token ? "maplibre" : wanted;

  const fallbackStyle = provider === "mapbox" ? DEFAULT_MAPBOX_STYLE_URL : DEFAULT_STYLE_URL;
  const styleUrl =
    env.MAP_STYLE_URL && isStyleUrl(env.MAP_STYLE_URL.trim(), provider === "mapbox") ? env.MAP_STYLE_URL.trim() : fallbackStyle;

  const lat = number(env.MAP_DEFAULT_LAT);
  const lng = number(env.MAP_DEFAULT_LNG);
  const fallbackCenter = lat !== null && lng !== null && isValidLatLng(lat, lng) ? { lat, lng } : DEFAULT_CENTER;

  const zoom = number(env.MAP_DEFAULT_ZOOM);
  const fallbackZoom = zoom !== null && zoom >= 1 && zoom <= 20 ? zoom : DEFAULT_ZOOM;

  return { provider, styleUrl, accessToken: provider === "mapbox" ? token : "", fallbackCenter, fallbackZoom };
}

/** The settings for this process. */
export function mapConfig(): MapConfig {
  return resolveMapConfig(process.env);
}
