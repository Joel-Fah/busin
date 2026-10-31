"use client";

import "maplibre-gl/dist/maplibre-gl.css";

import { LngLatBounds, Map as MapLibreMap, Marker, NavigationControl } from "maplibre-gl";
import { useEffect, useRef, useState } from "react";

import type { MapViewProps } from "../types";

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
  picker,
  ariaLabel,
  unavailableLabel,
  className,
}: MapViewProps) {
  // This module only ever runs in the browser (the selector loads it without server rendering).
  const [supported] = useState(webglAvailable);
  const container = useRef<HTMLDivElement>(null);
  const initialView = useRef({ center, zoom });
  const [map, setMap] = useState<MapLibreMap | null>(null);
  const onPick = useRef(picker?.onChange);
  const pickable = picker !== undefined;
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
    return () => {
      created.remove();
      setMap(null);
    };
  }, [supported, styleUrl]);

  // Fixed markers, for example the stops on the overview map.
  useEffect(() => {
    if (!map || !markers || markers.length === 0) return;
    const placed = markers.map((item) => {
      const element = document.createElement(item.href ? "a" : "div");
      element.className = item.muted ? "map-marker map-marker-muted" : "map-marker";
      element.setAttribute("aria-label", item.label);
      element.title = item.label;
      if (item.href && element instanceof HTMLAnchorElement) element.href = item.href;
      return new Marker({ element }).setLngLat([item.position.lng, item.position.lat]).addTo(map);
    });

    if (!pickable) {
      const bounds = new LngLatBounds();
      for (const item of markers) bounds.extend([item.position.lng, item.position.lat]);
      map.fitBounds(bounds, { padding: 56, maxZoom: 15, animate: false });
    }
    return () => placed.forEach((marker) => marker.remove());
  }, [map, markers, pickable]);

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
