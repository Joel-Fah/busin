import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { BusForm } from "@/components/BusForm";
import { BackLink } from "@/components/ui/BackLink";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { FlashToast } from "@/components/FlashToast";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
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
    <Suspense fallback={<ListSkeleton rows={2} />}>
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
      <BackLink href="/buses">{t.buses.form.back}</BackLink>
      <PageHeader title={bus.plate} />

      {done ? <FlashToast message={t.buses.done[done]} /> : null}
      {errorKey ? <Notice tone="bad">{t.buses.errors[errorKey]}</Notice> : null}

      <BusForm action={updateBus} t={t} bus={{ id: bus.id, plate: bus.plate, capacity: bus.capacity, inService: bus.in_service }} />
    </>
  );
}
