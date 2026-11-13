import type { Metadata } from "next";
import { Suspense } from "react";

import { BusForm } from "@/components/BusForm";
import { BackLink } from "@/components/ui/BackLink";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { requireAdmin } from "@/lib/auth";
import { isBusFormErrorKey } from "@/lib/buses";
import { getMessages } from "@/lib/i18n/server";
import { safeNext } from "@/lib/next-path";

import { createBus } from "../actions";

export const metadata: Metadata = { title: "Add a bus" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[]; next?: string | string[] }>;

export default function NewBusPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={2} />}>
      <NewBus searchParams={searchParams} />
    </Suspense>
  );
}

async function NewBus({ searchParams }: { searchParams: SearchParams }) {
  await requireAdmin();
  const { t } = await getMessages();

  const { error, next: nextParam } = await searchParams;
  const next = safeNext(Array.isArray(nextParam) ? nextParam[0] : nextParam);
  const errorParam = Array.isArray(error) ? error[0] : error;
  const errorKey = isBusFormErrorKey(errorParam) ? errorParam : null;

  return (
    <>
      <BackLink href={next ?? "/buses"}>{next === "/trips/new" ? t.trips.form.backToTrip : t.buses.form.back}</BackLink>
      <PageHeader title={t.buses.form.newTitle} />

      {errorKey ? <Notice tone="bad">{t.buses.errors[errorKey]}</Notice> : null}

      <BusForm action={createBus} t={t} next={next} />
    </>
  );
}
