"use client";

import dynamic from "next/dynamic";
import type { ComponentType } from "react";

import type { MapProviderId } from "@/lib/map/config";

import type { MapViewProps } from "./types";

function Loading() {
  return <div className="map map-loading" aria-busy="true" />;
}

/**
 * The only place map providers are registered. To add one, create `providers/<name>.tsx` with a
 * default export that implements `MapViewProps`, add its id to `MAP_PROVIDERS` in
 * `lib/map/config.ts`, and add it here. Map libraries need the browser, so they load on demand.
 */
const providers: Record<MapProviderId, ComponentType<MapViewProps>> = {
  maplibre: dynamic(() => import("./providers/maplibre"), { ssr: false, loading: Loading }),
};

export function MapView({ provider, ...props }: MapViewProps & { provider: MapProviderId }) {
  const Provider = providers[provider];
  return <Provider {...props} />;
}
