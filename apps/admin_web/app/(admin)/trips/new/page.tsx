import type { Metadata } from "next";
import { Suspense } from "react";
import { BackLink } from "@/components/ui/BackLink";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";

import { TripForm } from "@/components/TripForm";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { isTripFormErrorKey } from "@/lib/trips";
import { loadTripOptions } from "@/lib/trips-data";

import { createTrip } from "../actions";

export const metadata: Metadata = { title: "Schedule a trip" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[] }>;

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

  const { error } = await searchParams;
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
          <TripForm action={createTrip} t={t} locale={locale} buses={buses} drivers={drivers} timeZone={admin.schoolTimezone} />
        </>
      )}
    </>
  );
}
