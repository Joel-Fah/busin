import { Suspense } from "react";

import { BrandIntro } from "@/components/brand/BrandIntro";
import { FloatingNav, type NavKey } from "@/components/nav/FloatingNav";
import { RoughFilter } from "@/components/ui/RoughFilter";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";

// Everything in the shell depends on who is signed in, so it renders at request time
// behind a Suspense boundary. The fallback is the only part prerendered. Visitors who are not
// signed in are redirected, so Next's "instant navigation" check cannot apply here.
export const instant = false;

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <Suspense fallback={<div aria-busy="true" />}>
      <AdminShell>{children}</AdminShell>
    </Suspense>
  );
}

const KEYS: NavKey[] = ["overview", "subscriptions", "people", "trips", "scans"];

async function AdminShell({ children }: { children: React.ReactNode }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();

  return (
    <div lang={locale}>
      <BrandIntro />
      <RoughFilter />
      <main className="mx-auto flex w-full max-w-7xl min-w-0 flex-col gap-6 px-[clamp(1rem,4vw,2.5rem)] pt-8 pb-44">
        {children}
      </main>
      <FloatingNav
        keys={KEYS}
        labels={t.nav}
        groups={[
          { label: t.nav.groupDaily, keys: ["subscriptions", "trips", "scans"] },
          { label: t.nav.groupGeneral, keys: ["overview", "people"] },
        ]}
        profile={{ name: admin.fullName || admin.email, avatarUrl: admin.avatarUrl, href: "/profile", also: ["/stops", "/buses", "/semesters", "/academics"] }}
        text={t.nav}
      />
    </div>
  );
}
