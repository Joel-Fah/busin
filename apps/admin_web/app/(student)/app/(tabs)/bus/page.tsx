import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { BusTracker, type RunningTrip } from "@/components/student/BusTracker";
import { RefreshOnReturn } from "@/components/student/RefreshOnReturn";
import { StudentPage } from "@/components/student/StudentPage";
import { EmptyState } from "@/components/ui/EmptyState";
import { Skeleton } from "@/components/ui/Skeleton";
import { busLabel } from "@/lib/buses";
import { parsePoint } from "@/lib/geo";
import { getStudentCopy } from "@/lib/i18n/server";
import { resolveMapConfig } from "@/lib/map/config";
import type { Position, StopPoint } from "@/lib/student/bus";
import { requireStudent } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";
import { todayInZone } from "@/lib/zoned";

export const metadata: Metadata = { title: "My bus" };
export const instant = false;

export default function BusPage() {
  return (
    <Suspense
      fallback={
        <main className="mx-auto flex w-full max-w-[640px] flex-col gap-4 px-4 pt-6" aria-busy="true">
          <Skeleton className="h-[52dvh] rounded-lg" />
        </main>
      }
    >
      <Bus />
    </Suspense>
  );
}

/**
 * My bus, as in the app. Following a bus is for a student with an approved subscription for today (`can_follow_buses`,
 * the same rule RLS applies to positions). The map is always the free one (MapLibre, open tiles), so student traffic
 * never bills a paid provider (ADR 0021).
 */
async function Bus() {
  const student = await requireStudent();
  const { locale, s } = await getStudentCopy();
  const c = s.bus;
  const supabase = await createClient();

  const { data: allowed } = await supabase.rpc("can_follow_buses");
  if (allowed !== true) {
    return (
      <StudentPage lang={locale} title={c.title}>
        <RefreshOnReturn />
        <EmptyState
          title={c.lockedTitle}
          body={c.lockedBody}
          action={
            <Link href="/app/subscription" className="inline-flex h-12 items-center rounded-sm bg-accent px-5 font-semibold text-on-accent no-underline">
              {c.lockedAction}
            </Link>
          }
        />
      </StudentPage>
    );
  }

  const today = todayInZone(student.schoolTimezone);
  const [trips, stops, semester] = await Promise.all([
    supabase.from("trips").select("id, bus_id, direction, started_at").eq("status", "active").order("started_at", { ascending: true }).limit(20),
    supabase.from("stops").select("id, name, location").eq("active", true).order("name").limit(500),
    supabase.from("semesters").select("id").lte("start_date", today).gte("end_date", today).order("start_date", { ascending: false }).limit(1).maybeSingle(),
  ]);
  const running = trips.data ?? [];
  const busIds = [...new Set(running.map((t) => t.bus_id))];
  const [buses, positions, mine] = await Promise.all([
    busIds.length ? supabase.from("buses").select("id, plate, name").in("id", busIds) : { data: [] as { id: string; plate: string; name: string | null }[] },
    busIds.length ? supabase.from("live_positions").select("bus_id, trip_id, location, speed_mps, recorded_at").in("bus_id", busIds) : { data: [] as { bus_id: string; trip_id: string | null; location: unknown; speed_mps: number | null; recorded_at: string }[] },
    semester.data ? supabase.from("subscriptions").select("stop_id").eq("student_id", student.userId).eq("semester_id", semester.data.id).eq("status", "approved").limit(1).maybeSingle() : { data: null },
  ]);

  const labels = new Map((buses.data ?? []).map((bus) => [bus.id, busLabel(bus)]));
  const runningTrips: RunningTrip[] = running.map((t) => ({ id: t.id, busId: t.bus_id, bus: labels.get(t.bus_id) ?? "", direction: t.direction }));
  const stopPoints: StopPoint[] = (stops.data ?? []).flatMap((stop) => {
    const position = parsePoint(stop.location);
    return position ? [{ id: stop.id, name: stop.name, position }] : [];
  });
  const myStop = stopPoints.find((stop) => stop.id === mine.data?.stop_id) ?? null;
  const initial: Record<string, Position> = {};
  for (const row of positions.data ?? []) {
    const position = parsePoint(row.location);
    if (position) initial[row.bus_id] = { tripId: row.trip_id, position, speedMps: row.speed_mps, recordedAt: Date.parse(row.recorded_at) };
  }
  // Students always get the free map, whatever the portal uses.
  const map = resolveMapConfig({ ...process.env, MAP_PROVIDER: "maplibre", MAPBOX_API_KEY: "" });

  return (
    <StudentPage lang={locale} title={c.title}>
      {runningTrips.length === 0 ? (
        <>
          <RefreshOnReturn />
          <EmptyState title={c.noneTitle} body={c.noneBody} />
        </>
      ) : (
        <BusTracker copy={c} locale={locale} map={map} trips={runningTrips} stops={stopPoints} myStop={myStop} initial={initial} />
      )}
    </StudentPage>
  );
}
