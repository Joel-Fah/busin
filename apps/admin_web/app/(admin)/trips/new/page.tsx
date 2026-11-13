import type { Metadata } from "next";
import { Suspense } from "react";
import { BackLink } from "@/components/ui/BackLink";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Add01Icon, UserAdd01Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";

import { TripForm } from "@/components/TripForm";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { isTripFormErrorKey } from "@/lib/trips";
import { todayInZone } from "@/lib/zoned";
import { loadTripOptions } from "@/lib/trips-data";

import { createTrip } from "../actions";

export const metadata: Metadata = { title: "Schedule a trip" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[]; bus?: string | string[] }>;

export default function NewTripPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={2} />}>
      <NewTrip searchParams={searchParams} />
    </Suspense>
  );
}

async function NewTrip({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const { buses, drivers, failed } = await loadTripOptions();

  const { error, bus } = await searchParams;
  const busParam = Array.isArray(bus) ? bus[0] : bus;
  // Back from adding a bus: that bus is chosen, if it is one of the school's.
  const busId = isUuid(busParam) && buses.some((b) => b.id === busParam) ? busParam : undefined;
  const q = t.trips.form.quick;
  const errorParam = Array.isArray(error) ? error[0] : error;
  const errorKey = isTripFormErrorKey(errorParam) ? errorParam : null;

  return (
    <>
      <BackLink href="/trips">{t.trips.form.back}</BackLink>
      <PageHeader title={t.trips.form.newTitle} />

      {failed ? (
        <Notice tone="bad">{t.trips.loadError}</Notice>
      ) : (
        <>
          {errorKey ? <Notice tone="bad">{t.trips.errors[errorKey]}</Notice> : null}
          {busId ? <Notice tone="ok">{q.busAdded}</Notice> : null}
          {/* What a trip needs, one click away: no going back to other pages to set them up. */}
          {buses.length === 0 ? (
            <div className="flex max-w-2xl flex-col items-start gap-3">
              <Notice tone="warn">{q.noBus}</Notice>
              <ButtonLink href="/buses/new?next=%2Ftrips%2Fnew" icon={Add01Icon}>
                {q.addBus}
              </ButtonLink>
            </div>
          ) : null}
          {drivers.length === 0 ? (
            <div className="flex max-w-2xl flex-col items-start gap-3">
              <Notice tone="info">{q.noStaff}</Notice>
              <ButtonLink href="/people/invite" variant="secondary" icon={UserAdd01Icon}>
                {q.inviteStaff}
              </ButtonLink>
            </div>
          ) : null}
          <TripForm action={createTrip} t={t} locale={locale} buses={buses} drivers={drivers} timeZone={admin.schoolTimezone} today={todayInZone(admin.schoolTimezone)} busId={busId} />
        </>
      )}
    </>
  );
}
