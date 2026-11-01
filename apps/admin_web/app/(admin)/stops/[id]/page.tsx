import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { StopForm } from "@/components/StopForm";
import { requireAdmin } from "@/lib/auth";
import { parsePoint } from "@/lib/geo";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { mapConfig } from "@/lib/map/config";
import { isStopDone, isStopFormErrorKey } from "@/lib/stops";
import { createClient } from "@/lib/supabase/server";

import { updateStop } from "../actions";

export const metadata: Metadata = { title: "Stop" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

export default function StopPage({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <StopDetail params={params} searchParams={searchParams} />
    </Suspense>
  );
}

function single(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

async function StopDetail({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  await requireAdmin();
  const { t } = await getMessages();
  const { id } = await params;
  if (!isUuid(id)) notFound();

  const supabase = await createClient();
  const { data: stop } = await supabase
    .from("stops")
    .select("id, name, active, location")
    .eq("id", id)
    .maybeSingle();
  if (!stop) notFound();

  const config = mapConfig();
  const query = await searchParams;
  const doneParam = single(query.done);
  const errorParam = single(query.error);
  const done = isStopDone(doneParam) ? doneParam : null;
  const errorKey = isStopFormErrorKey(errorParam) ? errorParam : null;
  const position = parsePoint(stop.location);

  return (
    <>
      <p>
        <Link href="/stops">{t.stops.form.back}</Link>
      </p>
      <header className="page-head">
        <h1>{stop.name}</h1>
      </header>
      {done ? (
        <p className="success" role="status">
          {t.stops.done[done]}
        </p>
      ) : null}
      {errorKey ? (
        <p className="notice" role="alert">
          {t.stops.errors[errorKey]}
        </p>
      ) : null}
      <StopForm
        action={updateStop}
        t={t}
        config={config}
        center={position ?? config.fallbackCenter}
        zoom={config.fallbackZoom}
        stop={{ id: stop.id, name: stop.name, active: stop.active, position }}
      />
    </>
  );
}
