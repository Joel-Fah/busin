import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { BusForm } from "@/components/BusForm";
import { requireAdmin } from "@/lib/auth";
import { isBusFormErrorKey } from "@/lib/buses";
import { getMessages } from "@/lib/i18n/server";

import { createBus } from "../actions";

export const metadata: Metadata = { title: "Add a bus" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[] }>;

export default function NewBusPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <NewBus searchParams={searchParams} />
    </Suspense>
  );
}

async function NewBus({ searchParams }: { searchParams: SearchParams }) {
  await requireAdmin();
  const { t } = await getMessages();

  const { error } = await searchParams;
  const errorParam = Array.isArray(error) ? error[0] : error;
  const errorKey = isBusFormErrorKey(errorParam) ? errorParam : null;

  return (
    <>
      <p>
        <Link href="/buses">{t.buses.form.back}</Link>
      </p>
      <header className="page-head">
        <h1>{t.buses.form.newTitle}</h1>
      </header>
      {errorKey ? (
        <p className="notice" role="alert">
          {t.buses.errors[errorKey]}
        </p>
      ) : null}
      <BusForm action={createBus} t={t} />
    </>
  );
}
