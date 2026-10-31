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
  /** Where the base map comes from. Each provider says what it expects (a style URL for MapLibre). */
  styleUrl: string;
  /** Points to show. With no picker the map fits them all. */
  markers?: MapMarker[];
  /** Turns the map into a place to choose a position. */
  picker?: MapPicker;
  /** Describes the map for assistive technology. */
  ariaLabel: string;
  /** Shown instead of the map when the browser cannot draw it. */
  unavailableLabel: string;
  className?: string;
};
