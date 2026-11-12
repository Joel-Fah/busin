import type { Metadata } from "next";
import { Suspense } from "react";

import { StopsExplorer } from "@/components/StopsExplorer";
import { requireAdmin } from "@/lib/auth";
import { centroid } from "@/lib/geo";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { mapConfig } from "@/lib/map/config";
import { loadAreaCounts, loadStops } from "@/lib/stops-data";

export const metadata: Metadata = { title: "Stops" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ add?: string | string[]; edit?: string | string[] }>;

export default function StopsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <Stops searchParams={searchParams} />
    </Suspense>
  );
}

async function Stops({ searchParams }: { searchParams: SearchParams }) {
  await requireAdmin();
  const { t } = await getMessages();
  const config = mapConfig();
  const [{ stops, failed }, areas] = await Promise.all([loadStops(), loadAreaCounts()]);

  const { add, edit } = await searchParams;
  const editId = Array.isArray(edit) ? edit[0] : edit;
  const initialSheet = add !== undefined ? "new" : isUuid(editId) ? { edit: editId } : null;

  const center = centroid(stops.flatMap((stop) => (stop.position ? [stop.position] : []))) ?? config.fallbackCenter;

  return (
    <StopsExplorer
      stops={stops}
      areas={areas}
      failed={failed}
      map={{ provider: config.provider, styleUrl: config.styleUrl, accessToken: config.accessToken, center, zoom: config.fallbackZoom }}
      initialSheet={initialSheet}
      t={t}
    />
  );
}
