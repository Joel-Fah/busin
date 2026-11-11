"use client";

import "maplibre-gl/dist/maplibre-gl.css";

import { LngLatBounds, Map as MapLibreMap, Marker, NavigationControl, setWorkerUrl } from "maplibre-gl";
import { useEffect, useRef, useState } from "react";

import { areaColor, placeAreas, type AreaHost } from "../area-layer";
import { placeCircles } from "../circle-layer";
import { placeMarkers } from "../place-markers";
import type { MapViewProps } from "../types";

// The bundler does not emit MapLibre's worker, which left the map blank. It is copied to public/vendor by
// tools/copy-map-workers.mjs (run before dev and build) and served as a plain file.
setWorkerUrl("/vendor/maplibre/maplibre-gl-worker.mjs");

function webglAvailable(): boolean {
  try {
    const canvas = document.createElement("canvas");
    return Boolean(canvas.getContext("webgl2") ?? canvas.getContext("webgl"));
  } catch {
    return false;
  }
}

/** MapLibre GL implementation of the map contract. Free and open source (BSD-3-Clause). */
export default function MapLibreView({
  center,
  zoom,
  styleUrl,
  markers,
  areas,
  circles,
  picker,
  focus,
  focusKey,
  clusterLabel = "{count}",
  clustering = true,
  ariaLabel,
  unavailableLabel,
  className,
}: MapViewProps) {
  // This module only ever runs in the browser (the selector loads it without server rendering).
  const [supported] = useState(webglAvailable);
  const container = useRef<HTMLDivElement>(null);
  const initialView = useRef({ center, zoom });
  const [map, setMap] = useState<MapLibreMap | null>(null);
  const fittedFor = useRef("");
  const onPick = useRef(picker?.onChange);
  const pickable = picker !== undefined;
  const focusLat = focus?.lat;
  const focusLng = focus?.lng;
  const pinLat = picker?.position?.lat;
  const pinLng = picker?.position?.lng;

  useEffect(() => {
    onPick.current = picker?.onChange;
  });

  // Create the map once for this style, and remove it when the component goes away.
  useEffect(() => {
    if (!supported || !container.current) return;
    const created = new MapLibreMap({
      container: container.current,
      style: styleUrl,
      center: [initialView.current.center.lng, initialView.current.center.lat],
      zoom: initialView.current.zoom,
      attributionControl: { compact: true },
    });
    created.addControl(new NavigationControl({ showCompass: false }), "top-right");
    setMap(created);
    // The container can change size without the window doing so (a side panel opening), so follow it.
    const watcher = new ResizeObserver(() => created.resize());
    watcher.observe(container.current);
    return () => {
      watcher.disconnect();
      created.remove();
      setMap(null);
    };
  }, [supported, styleUrl]);

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
    if (!map.getBounds().contains([pinLng, pinLat])) map.easeTo({ center: [pinLng, pinLat], duration: 300 });
    return () => {
      pin.remove();
    };
  }, [map, pickable, pinLat, pinLng]);

  if (!supported) {
    return (
      <div className="map map-fallback" role="status">
        {unavailableLabel}
      </div>
    );
  }

  return <div ref={container} className={className ? `map ${className}` : "map"} role="region" aria-label={ariaLabel} />;
}
