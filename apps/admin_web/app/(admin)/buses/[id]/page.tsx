import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { BusForm } from "@/components/BusForm";
import { requireAdmin } from "@/lib/auth";
import { isBusDone, isBusFormErrorKey } from "@/lib/buses";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { createClient } from "@/lib/supabase/server";

import { updateBus } from "../actions";

export const metadata: Metadata = { title: "Bus" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

export default function BusPage({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <BusDetail params={params} searchParams={searchParams} />
    </Suspense>
  );
}

function single(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

async function BusDetail({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  await requireAdmin();
  const { t } = await getMessages();
  const { id } = await params;
  if (!isUuid(id)) notFound();

  const supabase = await createClient();
  const { data: bus } = await supabase
    .from("buses")
    .select("id, plate, capacity, in_service")
    .eq("id", id)
    .maybeSingle();
  if (!bus) notFound();

  const query = await searchParams;
  const doneParam = single(query.done);
  const errorParam = single(query.error);
  const done = isBusDone(doneParam) ? doneParam : null;
  const errorKey = isBusFormErrorKey(errorParam) ? errorParam : null;

  return (
    <>
      <p>
        <Link href="/buses">{t.buses.form.back}</Link>
      </p>
      <header className="page-head">
        <h1>{bus.plate}</h1>
      </header>
      {done ? (
        <p className="success" role="status">
          {t.buses.done[done]}
        </p>
      ) : null}
      {errorKey ? (
        <p className="notice" role="alert">
          {t.buses.errors[errorKey]}
        </p>
      ) : null}
      <BusForm
        action={updateBus}
        t={t}
        bus={{ id: bus.id, plate: bus.plate, capacity: bus.capacity, inService: bus.in_service }}
      />
    </>
  );
}
