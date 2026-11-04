import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { ArrowRight01Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { BackLink } from "@/components/ui/BackLink";
import { Chip } from "@/components/ui/Chip";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";

import { TripForm } from "@/components/TripForm";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { isDirection, isTripDone, isTripFormErrorKey, isTripStatus, tripStatusTone } from "@/lib/trips";
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
    <Suspense fallback={<ListSkeleton rows={2} />}>
      <TripDetail params={params} searchParams={searchParams} />
    </Suspense>
  );
}

function single(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

async function TripDetail({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
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
      <BackLink href="/trips">{t.trips.form.back}</BackLink>
      <header>
        <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">{t.trips.direction[trip.direction]}</h1>
        <p className="mt-2">
          <Chip tone={tripStatusTone(trip.status)}>{t.trips.status[trip.status]}</Chip>
        </p>
      </header>

      {done ? <Notice tone="ok">{t.trips.done[done]}</Notice> : null}
      {errorKey ? <Notice tone="bad">{t.trips.errors[errorKey]}</Notice> : null}

      {failed ? (
        <Notice tone="bad">{t.trips.loadError}</Notice>
      ) : editable ? (
        <TripForm
          action={updateTrip}
          t={t}
          locale={locale}
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
        <Card className="flex max-w-2xl flex-col items-start gap-4">
          <p>{t.trips.locked}</p>
          <ButtonLink href={`/scans?trip=${trip.id}`} variant="secondary" icon={ArrowRight01Icon}>
            {t.trips.viewBoardings}
          </ButtonLink>
        </Card>
      )}
    </>
  );
}
