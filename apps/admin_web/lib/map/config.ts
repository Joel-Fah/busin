import { isValidLatLng, type LatLng } from "@/lib/geo";

/**
 * Which map implementation the portal uses. To add one (for example Mapbox), add its id here, a
 * provider file under `components/map/providers/`, and an entry in `components/map/MapView.tsx`.
 * See docs/decisions/0008-map-provider.md.
 */
export const MAP_PROVIDERS = ["maplibre"] as const;
export type MapProviderId = (typeof MAP_PROVIDERS)[number];

export type MapConfig = {
  provider: MapProviderId;
  /** Where the base map comes from (a style document for MapLibre). */
  styleUrl: string;
  /** Used only when a school has no stops yet. */
  fallbackCenter: LatLng;
  fallbackZoom: number;
};

// OpenFreeMap: free vector tiles with no key. Replace through MAP_STYLE_URL, for example to self-host.
export const DEFAULT_STYLE_URL = "https://tiles.openfreemap.org/styles/liberty";
export const DEFAULT_CENTER: LatLng = { lat: 3.848, lng: 11.502 };
export const DEFAULT_ZOOM = 12;

type Env = Record<string, string | undefined>;

function isStyleUrl(value: string): boolean {
  try {
    const url = new URL(value);
    const local = url.hostname === "127.0.0.1" || url.hostname === "localhost";
    return url.protocol === "https:" || (url.protocol === "http:" && local);
  } catch {
    return false;
  }
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
  const requested = env.MAP_PROVIDER?.trim();
  const provider = MAP_PROVIDERS.find((id) => id === requested) ?? "maplibre";

  const styleUrl = env.MAP_STYLE_URL && isStyleUrl(env.MAP_STYLE_URL.trim()) ? env.MAP_STYLE_URL.trim() : DEFAULT_STYLE_URL;

  const lat = number(env.MAP_DEFAULT_LAT);
  const lng = number(env.MAP_DEFAULT_LNG);
  const fallbackCenter = lat !== null && lng !== null && isValidLatLng(lat, lng) ? { lat, lng } : DEFAULT_CENTER;

  const zoom = number(env.MAP_DEFAULT_ZOOM);
  const fallbackZoom = zoom !== null && zoom >= 1 && zoom <= 20 ? zoom : DEFAULT_ZOOM;

  return { provider, styleUrl, fallbackCenter, fallbackZoom };
}

/** The settings for this process. */
export function mapConfig(): MapConfig {
  return resolveMapConfig(process.env);
}
