import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { TripForm } from "@/components/TripForm";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { isDirection, isTripDone, isTripFormErrorKey, isTripStatus, statusPill } from "@/lib/trips";
import { loadTripOptions } from "@/lib/trips-data";
import { createClient } from "@/lib/supabase/server";
import { utcToZonedLocal } from "@/lib/zoned";

import { updateTrip } from "../actions";

export const metadata: Metadata = { title: "Trip" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

export default function TripPage({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <TripDetail params={params} searchParams={searchParams} />
    </Suspense>
  );
}

function single(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

async function TripDetail({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { t } = await getMessages();
  const { id } = await params;
  if (!isUuid(id)) notFound();

  const supabase = await createClient();
  const { data: trip } = await supabase
    .from("trips")
    .select("id, bus_id, driver_id, direction, status, scheduled_start, started_at, ended_at")
    .eq("id", id)
    .maybeSingle();
  if (!trip || !isDirection(trip.direction) || !isTripStatus(trip.status)) notFound();

  const { buses, drivers, failed } = await loadTripOptions(trip.bus_id);

  const query = await searchParams;
  const doneParam = single(query.done);
  const errorParam = single(query.error);
  const done = isTripDone(doneParam) ? doneParam : null;
  const errorKey = isTripFormErrorKey(errorParam) ? errorParam : null;
  const editable = trip.status === "scheduled";

  return (
    <>
      <p>
        <Link href="/trips">{t.trips.form.back}</Link>
      </p>
      <header className="page-head">
        <h1>{t.trips.direction[trip.direction]}</h1>
        <p>
          <span className={statusPill(trip.status)}>{t.trips.status[trip.status]}</span>
        </p>
      </header>
      {done ? (
        <p className="success" role="status">
          {t.trips.done[done]}
        </p>
      ) : null}
      {errorKey ? (
        <p className="notice" role="alert">
          {t.trips.errors[errorKey]}
        </p>
      ) : null}
      {failed ? (
        <p className="notice" role="alert">
          {t.trips.loadError}
        </p>
      ) : editable ? (
        <TripForm
          action={updateTrip}
          t={t}
          buses={buses}
          drivers={drivers}
          timeZone={admin.schoolTimezone}
          trip={{
            id: trip.id,
            busId: trip.bus_id,
            driverId: trip.driver_id,
            direction: trip.direction,
            start: utcToZonedLocal(trip.scheduled_start, admin.schoolTimezone),
          }}
        />
      ) : (
        <div className="card stack">
          <p>{t.trips.locked}</p>
          <p>
            <Link href={`/scans?trip=${trip.id}`}>{t.trips.viewBoardings}</Link>
          </p>
        </div>
      )}
    </>
  );
}
