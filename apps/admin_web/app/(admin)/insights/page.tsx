import type { Metadata } from "next";
import { Suspense } from "react";

import { InsightsExplorer } from "@/components/insights/InsightsExplorer";
import { requireAdmin } from "@/lib/auth";
import { centroid } from "@/lib/geo";
import { getMessages } from "@/lib/i18n/server";
import { parseLoadPeriod } from "@/lib/insights";
import { loadStopLoads } from "@/lib/insights-data";
import { mapConfig } from "@/lib/map/config";

export const metadata: Metadata = { title: "Insights" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ days?: string | string[] }>;

export default function InsightsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <Insights searchParams={searchParams} />
    </Suspense>
  );
}

async function Insights({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const config = mapConfig();
  const period = parseLoadPeriod((await searchParams).days);
  const { loads, failed } = await loadStopLoads(period);

  // Dates are written here, in the school's time zone, so the server and the browser show the same text.
  const counted = loads.refreshedAt
    ? new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone: admin.schoolTimezone }).format(new Date(loads.refreshedAt))
    : null;
  const dayFormat = new Intl.DateTimeFormat(locale, { day: "numeric", month: "short", timeZone: "UTC" });
  const days = Object.fromEntries(
    loads.stops.flatMap((stop) => (stop.lastDay ? [[stop.lastDay, dayFormat.format(new Date(`${stop.lastDay}T00:00:00Z`))]] : [])),
  );

  const center = centroid(loads.stops.flatMap((stop) => (stop.position ? [stop.position] : []))) ?? config.fallbackCenter;

  return (
    <InsightsExplorer
      loads={loads}
      period={period}
      failed={failed}
      counted={counted}
      days={days}
      map={{ provider: config.provider, styleUrl: config.styleUrl, accessToken: config.accessToken, center, zoom: config.fallbackZoom }}
      t={t}
    />
  );
}
