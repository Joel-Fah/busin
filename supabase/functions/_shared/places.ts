// The logic of place search for "My area" (docs/decisions/0013-coarse-home-area.md), kept free of Deno and network
// calls so Node can test it. The Edge Function in ../places-search/index.ts only wires it up.
//
// Mapbox Geocoding v6 (forward). Mapbox gets the text and the bias around the school, never who searched.

export type Bias = {
  centre_lng: number | null;
  centre_lat: number | null;
  min_lng: number | null;
  min_lat: number | null;
  max_lng: number | null;
  max_lat: number | null;
};

/** One result as the app receives it: a short name, where it is, and a point. Nothing else from Mapbox is passed on. */
export type Place = { label: string; detail: string; lat: number; lng: number };

/** The search text, trimmed, or null when it is too short or too long to search. */
export function cleanQuery(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const text = value.replace(/\s+/g, " ").trim();
  return text.length >= 2 && text.length <= 80 ? text : null;
}

const clamp = (value: number, low: number, high: number) => Math.min(high, Math.max(low, value));
const round = (value: number) => Math.round(value * 1e4) / 1e4;

export function mapboxUrl(query: string, bias: Bias | null, language: string, token: string): string {
  const params = new URLSearchParams({
    q: query,
    access_token: token,
    limit: "6",
    language: language === "fr" ? "fr" : "en",
    types: "neighborhood,locality,place,street,address",
    autocomplete: "true",
  });
  if (bias && bias.centre_lng !== null && bias.centre_lat !== null) {
    params.set("proximity", `${round(bias.centre_lng)},${round(bias.centre_lat)}`);
  }
  if (bias && bias.min_lng !== null && bias.min_lat !== null && bias.max_lng !== null && bias.max_lat !== null) {
    params.set(
      "bbox",
      [clamp(bias.min_lng, -180, 180), clamp(bias.min_lat, -85, 85), clamp(bias.max_lng, -180, 180), clamp(bias.max_lat, -85, 85)]
        .map(round)
        .join(","),
    );
  }
  return `https://api.mapbox.com/search/geocode/v6/forward?${params}`;
}

type Feature = {
  properties?: {
    name?: unknown;
    place_formatted?: unknown;
    coordinates?: { latitude?: unknown; longitude?: unknown };
  };
};

/** The places in a Mapbox answer, cut down to what the app needs. Anything malformed is skipped. */
export function parsePlaces(body: unknown): Place[] {
  const features = (body as { features?: unknown })?.features;
  if (!Array.isArray(features)) return [];
  const places: Place[] = [];
  for (const feature of features as Feature[]) {
    const p = feature?.properties;
    const lat = p?.coordinates?.latitude;
    const lng = p?.coordinates?.longitude;
    if (typeof p?.name !== "string" || typeof lat !== "number" || typeof lng !== "number") continue;
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) continue;
    places.push({
      label: p.name.slice(0, 80),
      detail: typeof p.place_formatted === "string" ? p.place_formatted.slice(0, 120) : "",
      lat,
      lng,
    });
  }
  return places;
}
