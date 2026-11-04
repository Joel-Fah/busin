import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { Navigation03Icon, ReceiptTextIcon, Ticket03Icon, UserMultiple02Icon } from "@hugeicons/core-free-icons";

import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";

import { PageHeader } from "@/components/ui/PageHeader";
import { requireAdmin } from "@/lib/auth";
import { format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { createClient } from "@/lib/supabase/server";
import { startOfDayInTimeZone } from "@/lib/time";

export const metadata: Metadata = { title: "Overview" };

// The figures depend on who is signed in, so this page cannot be an instant navigation.
export const instant = false;

export default function OverviewPage() {
  return (
    <Suspense fallback={<ListSkeleton rows={2} />}>
      <Overview />
    </Suspense>
  );
}

// Each figure leads to where its detail lives.
const DESTINATIONS = {
  pendingSubscriptions: { href: "/subscriptions", icon: Ticket03Icon },
  students: { href: "/people?role=student", icon: UserMultiple02Icon },
  activeTrips: { href: "/trips?status=active", icon: Navigation03Icon },
  scansToday: { href: "/scans", icon: ReceiptTextIcon },
} as const;

type Figure = { key: "pendingSubscriptions" | "students" | "activeTrips" | "scansToday"; value: number | null };

async function Overview() {
  const admin = await requireAdmin();
  const { t } = await getMessages();
  const supabase = await createClient();

  const startOfToday = startOfDayInTimeZone(admin.schoolTimezone, new Date()).toISOString();

  // Counts only: no rows are downloaded. Row Level Security limits each count to this school.
  const [pending, students, trips, scans] = await Promise.all([
    supabase.from("subscriptions").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "student"),
    supabase.from("trips").select("id", { count: "exact", head: true }).eq("status", "active"),
    supabase.from("scans").select("id", { count: "exact", head: true }).gte("scanned_at", startOfToday),
  ]);

  const failed = [pending, students, trips, scans].some((result) => result.error);
  const figures: Figure[] = [
    { key: "pendingSubscriptions", value: pending.count },
    { key: "students", value: students.count },
    { key: "activeTrips", value: trips.count },
    { key: "scansToday", value: scans.count },
  ];

  return (
    <>
      <PageHeader
        title={t.overview.title}
        subtitle={format(t.overview.subtitle, { school: admin.schoolName })}
        help={{
          label: t.help.open,
          title: t.overview.help.title,
          intro: t.overview.help.intro,
          scenarios: Object.values(t.overview.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
      />

      {failed ? (
        <Notice tone="bad">{t.overview.loadError}</Notice>
      ) : (
        <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4" aria-label={t.overview.title}>
          {figures.map((figure) => {
            const { href, icon } = DESTINATIONS[figure.key];
            // What needs attention comes first and is set apart when there is something waiting.
            const waiting = figure.key === "pendingSubscriptions" && (figure.value ?? 0) > 0;
            return (
              <Link
                key={figure.key}
                href={href}
                data-testid={`stat-${figure.key}`}
                className={
                  "group relative flex min-h-40 flex-col justify-between rounded-lg p-7 text-fg no-underline shadow-soft transition-shadow duration-(--dur) ease-soft " +
                  "hover:shadow-float focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus " +
                  (waiting ? "bg-[color-mix(in_srgb,var(--accent)_18%,var(--surface))]" : "bg-surface")
                }
              >
                <Contour radius={28} inset={14} live />
                <span className="flex items-center justify-between gap-3">
                  <span className="stat-label text-sm font-semibold text-muted">{t.overview[figure.key]}</span>
                  <Icon icon={icon} size={22} />
                </span>
                <span className="stat-value text-5xl font-extrabold tracking-tight tabular-nums">{figure.value ?? 0}</span>
              </Link>
            );
          })}
        </section>
      )}
    </>
  );
}
