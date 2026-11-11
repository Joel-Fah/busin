import type { LatLng } from "@/lib/geo";

/**
 * The contract every map provider implements. Pages and forms depend on this and never on a
 * specific map library, so a provider can be swapped by adding one file under `providers/`.
 * Positions are plain WGS 84 latitude and longitude, the same as the database stores.
 */
export type MapMarker = {
  id: string;
  position: LatLng;
  /** Accessible name and tooltip. */
  label: string;
  /** When set, the marker is a link to this address. */
  href?: string;
  /** Drawn in a quieter style, for example an inactive stop. */
  muted?: boolean;
  /** When set (and there is no href), the marker is a button that calls this. */
  onSelect?: () => void;
  /** Drawn larger, as the marker the page is focused on. */
  selected?: boolean;
  /** "me" is the visitor's own position: a blue dot with a halo, not a pin. */
  variant?: "me";
};

/** A zone of about 500 m where students live, with how many (only zones with 5 or more ever reach the portal). */
export type MapArea = {
  position: LatLng;
  students: number;
};

/** A translucent circle under the markers, for example the load of a stop. */
export type MapCircle = {
  id: string;
  position: LatLng;
  /** 0 (smallest) to 1 (largest). */
  size: number;
  /** A CSS colour: a value ("#b3261e") or a theme token ("var(--bad)"), read from the page when drawn. */
  color: string;
};

export type MapPicker = {
  /** The chosen position, or null while nothing is chosen. */
  position: LatLng | null;
  /** Called when the user clicks the map or drags the pin. */
  onChange: (position: LatLng) => void;
};

export type MapViewProps = {
  /** Where the map opens when there is nothing to fit. */
  center: LatLng;
  zoom: number;
  /** Where the base map comes from. Each provider says what it expects (a style URL for MapLibre, a mapbox:// style for Mapbox). */
  styleUrl: string;
  /** Mapbox public access token. Ignored by other providers. */
  accessToken?: string;
  /** Points to show. With no picker the map fits them all. */
  markers?: MapMarker[];
  /** Zones where students live, drawn as soft discs under the markers. */
  areas?: MapArea[];
  /** Circles drawn under the markers. */
  circles?: MapCircle[];
  /** Turns the map into a place to choose a position. */
  picker?: MapPicker;
  /** When this changes, the map glides to it. For example the stop picked from a list. */
  focus?: LatLng | null;
  /** Change this to glide to `focus` again even when it has not moved, for example after the map was panned away. */
  focusKey?: number;
  /** Text for a bubble standing for several stops that would overlap, with {count} for the number. */
  clusterLabel?: string;
  /** Merge markers that would overlap into numbered bubbles when zoomed out. On by default. */
  clustering?: boolean;
  /** Describes the map for assistive technology. */
  ariaLabel: string;
  /** Shown instead of the map when the browser cannot draw it. */
  unavailableLabel: string;
  className?: string;
};
