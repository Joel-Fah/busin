import { Suspense } from "react";

import { BrandIntro } from "@/components/brand/BrandIntro";
import { type NavKey } from "@/components/nav/FloatingNav";
import { LiveFloatingNav } from "@/components/nav/LiveFloatingNav";
import { RoughFilter } from "@/components/ui/RoughFilter";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { createClient } from "@/lib/supabase/server";

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

const KEYS: NavKey[] = ["overview", "subscriptions", "people", "trips", "scans", "insights"];

/**
 * What waits for the admin, for the badges on the nav: subscription requests to review and students who asked to join
 * the school. Head-only counts (no rows), already limited to the admin's school by Row Level Security. A server action
 * that revalidates a page refreshes them; otherwise they are as fresh as the last page load.
 */
async function waitingCounts(): Promise<Partial<Record<NavKey, number>>> {
  const supabase = await createClient();
  const [subscriptions, people, overdue] = await Promise.all([
    supabase.from("subscriptions").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "student").eq("status", "pending").not("join_requested_at", "is", null),
    // Running trips that should probably have ended (at most 100 rows, ids and reasons only).
    supabase.rpc("admin_overdue_trips"),
  ]);
  return { subscriptions: subscriptions.count ?? 0, people: people.count ?? 0, trips: overdue.data?.length ?? 0 };
}

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
      <LiveFloatingNav
        schoolId={admin.schoolId}
        keys={KEYS}
        labels={t.nav}
        groups={[
          { label: t.nav.groupDaily, keys: ["subscriptions", "trips", "scans"] },
          { label: t.nav.groupGeneral, keys: ["overview", "people", "insights"] },
        ]}
        profile={{ name: admin.fullName || admin.email, avatarUrl: admin.avatarUrl, href: "/profile", also: ["/stops", "/buses", "/semesters", "/academics", "/school"] }}
        text={t.nav}
        counts={await waitingCounts()}
      />
    </div>
  );
}
