import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

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
    <Suspense fallback={<section aria-busy="true" />}>
      <NewTrip searchParams={searchParams} />
    </Suspense>
  );
}

async function NewTrip({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { t } = await getMessages();
  const { buses, drivers, failed } = await loadTripOptions();

  const { error } = await searchParams;
  const errorParam = Array.isArray(error) ? error[0] : error;
  const errorKey = isTripFormErrorKey(errorParam) ? errorParam : null;

  return (
    <>
      <p>
        <Link href="/trips">{t.trips.form.back}</Link>
      </p>
      <header className="page-head">
        <h1>{t.trips.form.newTitle}</h1>
      </header>
      {failed ? (
        <p className="notice" role="alert">
          {t.trips.loadError}
        </p>
      ) : (
        <>
          {errorKey ? (
            <p className="notice" role="alert">
              {t.trips.errors[errorKey]}
            </p>
          ) : null}
          <TripForm action={createTrip} t={t} buses={buses} drivers={drivers} timeZone={admin.schoolTimezone} />
        </>
      )}
    </>
  );
}
