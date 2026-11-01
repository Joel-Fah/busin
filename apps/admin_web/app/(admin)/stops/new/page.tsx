import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { StopForm } from "@/components/StopForm";
import { requireAdmin } from "@/lib/auth";
import { centroid } from "@/lib/geo";
import { getMessages } from "@/lib/i18n/server";
import { mapConfig } from "@/lib/map/config";
import { isStopFormErrorKey } from "@/lib/stops";
import { loadStops } from "@/lib/stops-data";

import { createStop } from "../actions";

export const metadata: Metadata = { title: "Add a stop" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[] }>;

export default function NewStopPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <NewStop searchParams={searchParams} />
    </Suspense>
  );
}

async function NewStop({ searchParams }: { searchParams: SearchParams }) {
  await requireAdmin();
  const { t } = await getMessages();
  const config = mapConfig();
  const { stops } = await loadStops();

  // Open the map where the school's other stops are, or at the configured default.
  const existing = stops.flatMap((stop) => (stop.position ? [stop.position] : []));
  const center = centroid(existing) ?? config.fallbackCenter;
  const zoom = existing.length > 0 ? 13 : config.fallbackZoom;

  const { error } = await searchParams;
  const errorParam = Array.isArray(error) ? error[0] : error;
  const errorKey = isStopFormErrorKey(errorParam) ? errorParam : null;

  return (
    <>
      <p>
        <Link href="/stops">{t.stops.form.back}</Link>
      </p>
      <header className="page-head">
        <h1>{t.stops.form.newTitle}</h1>
      </header>
      {errorKey ? (
        <p className="notice" role="alert">
          {t.stops.errors[errorKey]}
        </p>
      ) : null}
      <StopForm action={createStop} t={t} config={config} center={center} zoom={zoom} />
    </>
  );
}
