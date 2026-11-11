import type { Metadata } from "next";
import { Suspense } from "react";

import { RouteEditor } from "@/components/route/RouteEditor";
import { requireAdmin } from "@/lib/auth";
import { centroid } from "@/lib/geo";
import { getMessages } from "@/lib/i18n/server";
import { mapConfig } from "@/lib/map/config";
import { loadRoute } from "@/lib/route-data";

export const metadata: Metadata = { title: "Bus route" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function RoutePage() {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <Route />
    </Suspense>
  );
}

async function Route() {
  await requireAdmin();
  const { t } = await getMessages();
  const config = mapConfig();
  const { route, stops, failed } = await loadRoute();
  const center = centroid(stops.map((s) => s.position)) ?? config.fallbackCenter;
  return (
    <RouteEditor
      route={route}
      stops={stops}
      failed={failed}
      map={{ provider: config.provider, styleUrl: config.styleUrl, accessToken: config.accessToken, center, zoom: config.fallbackZoom }}
      t={t}
    />
  );
}
