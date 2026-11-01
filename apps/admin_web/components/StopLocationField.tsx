"use client";

import { useState } from "react";

import { MapView } from "@/components/map/MapView";
import { isValidLatLng, type LatLng } from "@/lib/geo";
import type { MapProviderId } from "@/lib/map/config";
import { parseCoordinate } from "@/lib/stops";

type Props = {
  initial: LatLng | null;
  provider: MapProviderId;
  styleUrl: string;
  center: LatLng;
  zoom: number;
  labels: {
    latitude: string;
    longitude: string;
    pickerLabel: string;
    locationHint: string;
    mapUnavailable: string;
  };
};

/**
 * Position fields for a stop: a map to click or a pin to drag, and two number fields that stay
 * in step with it. The fields are the accessible way to set a position without a mouse.
 */
export function StopLocationField({ initial, provider, styleUrl, center, zoom, labels }: Props) {
  const [lat, setLat] = useState(initial ? initial.lat.toFixed(6) : "");
  const [lng, setLng] = useState(initial ? initial.lng.toFixed(6) : "");

  const parsedLat = parseCoordinate(lat);
  const parsedLng = parseCoordinate(lng);
  const position =
    parsedLat !== null && parsedLng !== null && isValidLatLng(parsedLat, parsedLng)
      ? { lat: parsedLat, lng: parsedLng }
      : null;

  return (
    <div className="stack">
      <MapView
        provider={provider}
        styleUrl={styleUrl}
        center={initial ?? center}
        zoom={initial ? 15 : zoom}
        picker={{
          position,
          onChange: (next) => {
            setLat(next.lat.toFixed(6));
            setLng(next.lng.toFixed(6));
          },
        }}
        ariaLabel={labels.pickerLabel}
        unavailableLabel={labels.mapUnavailable}
      />
      <p className="muted">{labels.locationHint}</p>
      <div className="coords">
        <div className="field">
          <label htmlFor="lat">{labels.latitude}</label>
          <input
            id="lat"
            name="lat"
            type="number"
            step="any"
            min={-90}
            max={90}
            required
            value={lat}
            onChange={(event) => setLat(event.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="lng">{labels.longitude}</label>
          <input
            id="lng"
            name="lng"
            type="number"
            step="any"
            min={-180}
            max={180}
            required
            value={lng}
            onChange={(event) => setLng(event.target.value)}
          />
        </div>
      </div>
    </div>
  );
}
