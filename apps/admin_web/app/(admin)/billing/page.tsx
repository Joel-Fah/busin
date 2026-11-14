import type { Metadata } from "next";
import { Suspense } from "react";

import { BillingForm } from "@/components/billing/BillingForm";
import { FlashToast } from "@/components/FlashToast";
import { BackLink } from "@/components/ui/BackLink";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { requireAdmin } from "@/lib/auth";
import { schoolBilling, type BillingField } from "@/lib/billing";
import { getMessages } from "@/lib/i18n/server";
import { first } from "@/lib/pagination";
import { createClient } from "@/lib/supabase/server";

import { saveBilling } from "./actions";

export const metadata: Metadata = { title: "Billing" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

const ERRORS: readonly (BillingField | "generic")[] = ["period", "price", "plan", "generic"];

export default function BillingPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={3} />}>
      <Billing searchParams={searchParams} />
    </Suspense>
  );
}

/** The school's billing (ADR 0022): per semester or per month, the price, and whether students may pay in installments. */
async function Billing({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const b = t.billing;
  const query = await searchParams;
  const errorParam = first(query.error);
  const error = ERRORS.find((key) => key === errorParam) ?? null;

  const supabase = await createClient();
  const { data: school } = await supabase.from("schools").select("billing_period, price_xaf, installment_plan, currency").eq("id", admin.schoolId).maybeSingle();
  const current = schoolBilling(school);

  return (
    <>
      <BackLink href="/profile">{b.back}</BackLink>
      <PageHeader title={b.title} subtitle={b.subtitle} />
      {first(query.done) === "saved" ? <FlashToast message={b.saved} /> : null}
      {current ? null : <Notice tone="warn">{b.notSet}</Notice>}
      <BillingForm copy={b} current={current} locale={locale} action={saveBilling} error={error} />
    </>
  );
}
