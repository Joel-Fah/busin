import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { MapView } from "@/components/map/MapView";
import type { MapMarker } from "@/components/map/types";
import { requireAdmin } from "@/lib/auth";
import { centroid, formatLatLng } from "@/lib/geo";
import { getMessages } from "@/lib/i18n/server";
import { mapConfig } from "@/lib/map/config";
import { loadStops } from "@/lib/stops-data";

export const metadata: Metadata = { title: "Stops" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function StopsPage() {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <StopsList />
    </Suspense>
  );
}

async function StopsList() {
  await requireAdmin();
  const { t } = await getMessages();
  const config = mapConfig();
  const { stops, failed } = await loadStops();

  const markers: MapMarker[] = stops.flatMap((stop) =>
    stop.position
      ? [{ id: stop.id, position: stop.position, label: stop.name, href: `/stops/${stop.id}`, muted: !stop.active }]
      : [],
  );
  const center = centroid(markers.map((marker) => marker.position)) ?? config.fallbackCenter;

  return (
    <>
      <header className="page-head">
        <h1>{t.stops.title}</h1>
        <p>{t.stops.subtitle}</p>
      </header>

      <div className="row">
        <Link className="btn btn-primary" href="/stops/new">
          {t.stops.add}
        </Link>
      </div>

      {failed ? (
        <p className="notice" role="alert">
          {t.stops.loadError}
        </p>
      ) : stops.length === 0 ? (
        <p className="card">{t.stops.empty}</p>
      ) : (
        <>
          <MapView
            provider={config.provider}
            styleUrl={config.styleUrl}
            center={center}
            zoom={config.fallbackZoom}
            markers={markers}
            ariaLabel={t.stops.mapLabel}
            unavailableLabel={t.stops.mapUnavailable}
          />
          <div className="table-wrap card">
            <table>
              <thead>
                <tr>
                  <th scope="col">{t.stops.columns.name}</th>
                  <th scope="col">{t.stops.columns.position}</th>
                  <th scope="col">{t.stops.columns.status}</th>
                </tr>
              </thead>
              <tbody>
                {stops.map((stop) => (
                  <tr key={stop.id}>
                    <td>
                      <Link href={`/stops/${stop.id}`}>{stop.name}</Link>
                    </td>
                    <td>{stop.position ? formatLatLng(stop.position) : "-"}</td>
                    <td>
                      <span className={stop.active ? "pill pill-ok" : "pill"}>
                        {stop.active ? t.stops.status.active : t.stops.status.inactive}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </>
  );
}
