import type { Metadata } from "next";
import { Suspense } from "react";

import { GraphExplorer } from "@/components/insights/GraphExplorer";
import { InsightsExplorer } from "@/components/insights/InsightsExplorer";
import { SuggestionsExplorer } from "@/components/insights/SuggestionsExplorer";
import { ProximityExplorer } from "@/components/insights/ProximityExplorer";
import { requireAdmin } from "@/lib/auth";
import { centroid } from "@/lib/geo";
import { getMessages } from "@/lib/i18n/server";
import { DEFAULT_LOAD_PERIOD, parseInsightView, parseLoadPeriod } from "@/lib/insights";
import { loadProximity, loadStopLoads, loadSuggestions } from "@/lib/insights-data";
import { mapConfig } from "@/lib/map/config";

export const metadata: Metadata = { title: "Insights" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ days?: string | string[]; view?: string | string[] }>;

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
  const query = await searchParams;
  const mapProps = { provider: config.provider, styleUrl: config.styleUrl, accessToken: config.accessToken, zoom: config.fallbackZoom };

  // Each view loads only its own data.
  const view = parseInsightView(query.view);
  if (view === "graph") {
    const [{ loads, failed: loadFailed }, { proximity, failed: proximityFailed }, { suggestions }] = await Promise.all([
      loadStopLoads(DEFAULT_LOAD_PERIOD),
      loadProximity(),
      loadSuggestions(),
    ]);
    return <GraphExplorer loads={loads} proximity={proximity} suggestions={suggestions} failed={loadFailed || proximityFailed} t={t} />;
  }
  if (view === "suggestions") {
    const { suggestions, stops, failed } = await loadSuggestions();
    const center = centroid(stops.flatMap((stop) => (stop.position ? [stop.position] : []))) ?? config.fallbackCenter;
    return <SuggestionsExplorer suggestions={suggestions} stops={stops} failed={failed} map={{ ...mapProps, center }} t={t} />;
  }
  if (view === "proximity") {
    const { proximity, failed } = await loadProximity();
    const center = centroid(proximity.stops.flatMap((stop) => (stop.position ? [stop.position] : []))) ?? config.fallbackCenter;
    return <ProximityExplorer proximity={proximity} failed={failed} map={{ ...mapProps, center }} t={t} />;
  }

  const period = parseLoadPeriod(query.days);
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
      map={{ ...mapProps, center }}
      t={t}
    />
  );
}
