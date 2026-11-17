import type { Metadata } from "next";
import { Suspense } from "react";

import { PaymentSettingsForm } from "@/components/platform/PaymentSettingsForm";
import { BackLink } from "@/components/ui/BackLink";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { requirePlatformAdmin } from "@/lib/auth";
import { format } from "@/lib/i18n/messages";
import { platformPaymentsCatalogues } from "@/lib/i18n/platform-payments";
import { getMessages } from "@/lib/i18n/server";
import { parseSettings } from "@/lib/platform-payments";
import { createClient } from "@/lib/supabase/server";

import { savePaymentSettings } from "../actions";

export const metadata: Metadata = { title: "Payment settings" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function PlatformPaymentSettingsPage() {
  return (
    <Suspense fallback={<ListSkeleton rows={4} />}>
      <Settings />
    </Suspense>
  );
}

/** The platform's payment settings (ADR 0029), in plain words, each change confirmed and in the platform audit. */
async function Settings() {
  await requirePlatformAdmin();
  const { locale } = await getMessages();
  const c = platformPaymentsCatalogues[locale];
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("platform_payment_settings");
  const header = (
    <>
      <BackLink href="/platform/payments">{c.settings.back}</BackLink>
      <PageHeader title={c.settings.title} subtitle={c.settings.subtitle} />
    </>
  );
  if (error) {
    return (
      <>
        {header}
        <Notice tone="bad">{c.settings.loadError}</Notice>
      </>
    );
  }
  const current = parseSettings(data);
  const updated = current.updatedAt ? new Intl.DateTimeFormat(locale, { dateStyle: "long", timeStyle: "short" }).format(new Date(current.updatedAt)) : null;

  return (
    <>
      {header}
      {updated ? <p className="-mt-3 text-sm text-muted">{format(c.settings.updated, { date: updated })}</p> : null}
      <PaymentSettingsForm current={current} locale={locale} copy={c.settings} operators={c.operators} errors={c.errors} action={savePaymentSettings} />
    </>
  );
}
