import type { Metadata } from "next";
import { Suspense } from "react";

import { AccountLookup } from "@/components/platform/AccountLookup";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { PageHeader } from "@/components/ui/PageHeader";
import { requirePlatformAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";

import { lookupAccount } from "./actions";

export const metadata: Metadata = { title: "Account lookup" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function PlatformLookupPage() {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <Lookup />
    </Suspense>
  );
}

async function Lookup() {
  await requirePlatformAdmin();
  const { locale, t } = await getMessages();
  const l = t.platform.lookup;
  return (
    <>
      <PageHeader
        title={l.title}
        help={{
          label: t.help.open,
          title: l.help.title,
          intro: l.help.intro,
          scenarios: Object.values(l.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
      />
      <AccountLookup action={lookupAccount} text={l} roles={t.role} statuses={t.accountStatus} subscriptionStatuses={t.status} locale={locale} />
    </>
  );
}
