"use client";

import "mapbox-gl/dist/mapbox-gl.css";

import mapboxgl, { LngLatBounds, Map as MapboxMap, Marker, NavigationControl } from "mapbox-gl";
import dynamic from "next/dynamic";
import { useEffect, useRef, useState } from "react";

import { mapBudgetAvailable, takeMapLoad } from "@/lib/map/budget";
import { DEFAULT_STYLE_URL } from "@/lib/map/config";

import { areaColor, placeAreas, type AreaHost } from "../area-layer";
import { placeCircles } from "../circle-layer";
import { placeMarkers } from "../place-markers";
import type { MapViewProps } from "../types";

// The free map, used when this browser has spent its Mapbox budget. Loaded only if it is needed.
const FreeMap = dynamic(() => import("./maplibre"), { ssr: false });

function webglAvailable(): boolean {
  try {
    const canvas = document.createElement("canvas");
    return Boolean(canvas.getContext("webgl2") ?? canvas.getContext("webgl"));
  } catch {
    return false;
  }
}

/**
 * Mapbox bills for every map that is created, so this tab keeps exactly one and hands the same map to
 * every page that needs it. Going from the stops list to a form and back costs one load, not three,
 * and React's double mount in development costs one, not two. The map's element is moved into
 * whichever page is showing and parked when the page goes away.
 */
type Shared = { key: string; map: MapboxMap; host: HTMLDivElement };
let shared: Shared | null = null;

function acquire(token: string, style: string, view: { center: [number, number]; zoom: number }): Shared | null {
  const key = `${token}|${style}`;
  if (shared?.key === key) return shared;

  // A different style or token needs a new map, which is a new load.
  shared?.map.remove();
  shared = null;

  // The budget is checked and spent only when a real load is about to happen, never for a reuse.
  if (!takeMapLoad(localStorage)) return null;

  const host = document.createElement("div");
  host.style.cssText = "width:100%;height:100%";
  mapboxgl.accessToken = token;
  const map = new MapboxMap({
    container: host,
    style,
    center: view.center,
    zoom: view.zoom,
    attributionControl: true, // the Mapbox logo and attribution must stay visible (their terms)
    performanceMetricsCollection: false,
  });
  map.addControl(new NavigationControl({ showCompass: false }), "top-right");
  shared = { key, map, host };
  return shared;
}

/**
 * Mapbox GL JS implementation of the map contract. It needs a public access token (pk.), which the
 * portal passes in; the token is restricted to this site in the Mapbox account. Mapbox GL JS is
 * proprietary software under Mapbox's terms (see docs/decisions/0008-map-provider.md).
 */
export default function MapboxView(props: MapViewProps) {
  const { center, zoom, styleUrl, accessToken, markers, areas, circles, picker, ariaLabel, unavailableLabel, className, clusterLabel = "{count}", clustering = true } = props;
  // This module only ever runs in the browser (the selector loads it without server rendering).
  const [supported] = useState(webglAvailable);
  // Spent its budget in this browser: draw the free map instead. A map already in this tab is reused, so it never counts.
  const [spent] = useState(() => shared === null && !mapBudgetAvailable(localStorage));
  const container = useRef<HTMLDivElement>(null);
  const initialView = useRef({ center, zoom });
  const [map, setMap] = useState<MapboxMap | null>(null);
  const fittedFor = useRef("");
  const onPick = useRef(picker?.onChange);
  const pickable = picker !== undefined;
  const focusKey = props.focusKey;
  const focusLat = props.focus?.lat;
  const focusLng = props.focus?.lng;
  const pinLat = picker?.position?.lat;
  const pinLng = picker?.position?.lng;

  useEffect(() => {
    onPick.current = picker?.onChange;
  });

  // Take the tab's map (creating it only if there is none) and put it in this page.
  useEffect(() => {
    const slot = container.current;
    if (spent || !supported || !slot || !accessToken) return;
    const view = { center: [initialView.current.center.lng, initialView.current.center.lat] as [number, number], zoom: initialView.current.zoom };
    const got = acquire(accessToken, styleUrl, view);
    if (!got) return;
    slot.appendChild(got.host);
    got.map.resize();
    setMap(got.map);
    // The container can change size without the window doing so (a side panel opening), so follow it.
    const watcher = new ResizeObserver(() => got.map.resize());
    watcher.observe(slot);
    return () => {
      watcher.disconnect();
      // Park the map instead of destroying it, so the next page can use it for free.
      got.host.remove();
      setMap(null);
    };
  }, [spent, supported, styleUrl, accessToken]);

  // Fixed markers, for example the stops. Overlapping ones merge into numbered bubbles when zoomed out.
  useEffect(() => {
    if (!map || !markers || markers.length === 0) return;

    // Fit all the points once for a given set of markers, not every time the page re-renders or a form closes.
    const set = markers.map((item) => item.id).join(",");
    if (!pickable && fittedFor.current !== set) {
      fittedFor.current = set;
      const bounds = new LngLatBounds();
      for (const item of markers) bounds.extend([item.position.lng, item.position.lat]);
      map.fitBounds(bounds, { padding: 56, maxZoom: 15, animate: false });
    }

    return placeMarkers(
      {
        getZoom: () => map.getZoom(),
        onZoom: (listener) => {
          map.on("zoom", listener);
          return () => {
            map.off("zoom", listener);
          };
        },
        fitTo: (bounds) => map.fitBounds(bounds, { padding: 90, maxZoom: 17, duration: 600 }),
        place: (element, position) => new Marker({ element }).setLngLat(position).addTo(map),
      },
      markers,
      { clustering: !pickable && clustering, clusterLabel },
    );
  }, [map, markers, pickable, clustering, clusterLabel]);

  // Where students live, under the markers.
  useEffect(() => {
    if (!map || !areas || areas.length === 0) return;
    return placeAreas(map as unknown as AreaHost, areas, areaColor());
  }, [map, areas]);

  // Circles, for example the load of each stop, under the markers.
  useEffect(() => {
    if (!map || !circles || circles.length === 0) return;
    return placeCircles(map as unknown as AreaHost, circles);
  }, [map, circles]);

  // Glide to the position the page is focused on, for example the stop picked from a list.
  useEffect(() => {
    if (!map || focusLat === undefined || focusLng === undefined) return;
    map.easeTo({ center: [focusLng, focusLat], zoom: Math.max(map.getZoom(), 15), duration: 600 });
  }, [map, focusLat, focusLng, focusKey]);

  // Choosing a position: click the map or drag the pin.
  useEffect(() => {
    if (!map || !pickable) return;
    const handleClick = (event: { lngLat: { wrap(): { lat: number; lng: number } } }) => {
      const { lat, lng } = event.lngLat.wrap();
      onPick.current?.({ lat, lng });
    };
    map.on("click", handleClick);
    map.getCanvas().style.cursor = "crosshair";
    return () => {
      map.off("click", handleClick);
      map.getCanvas().style.cursor = "";
    };
  }, [map, pickable]);

  // The draggable pin follows the chosen position, including when it is typed in.
  useEffect(() => {
    if (!map || !pickable || pinLat === undefined || pinLng === undefined) return;
    const pin = new Marker({ draggable: true, color: "#f5951f" }).setLngLat([pinLng, pinLat]).addTo(map);
    pin.on("dragend", () => {
      const { lat, lng } = pin.getLngLat().wrap();
      onPick.current?.({ lat, lng });
    });
    if (!map.getBounds()?.contains([pinLng, pinLat])) map.easeTo({ center: [pinLng, pinLat], duration: 300 });
    return () => {
      pin.remove();
    };
  }, [map, pickable, pinLat, pinLng]);

  if (spent) return <FreeMap {...props} styleUrl={DEFAULT_STYLE_URL} />;

  if (!supported) {
    return (
      <div className="map map-fallback" role="status">
        {unavailableLabel}
      </div>
    );
  }

  return <div ref={container} className={className ? `map ${className}` : "map"} role="region" aria-label={ariaLabel} />;
}
