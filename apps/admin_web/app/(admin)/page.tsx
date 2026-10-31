import type { Metadata } from "next";
import { Suspense } from "react";

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
    <Suspense fallback={<section aria-busy="true" />}>
      <Overview />
    </Suspense>
  );
}

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
      <header className="page-head">
        <h1>{t.overview.title}</h1>
        <p>{format(t.overview.subtitle, { school: admin.schoolName })}</p>
      </header>

      {failed ? (
        <p className="notice" role="alert">
          {t.overview.loadError}
        </p>
      ) : (
        <section className="stat-grid" aria-label={t.overview.title}>
          {figures.map((figure) => (
            <div className="card stat" key={figure.key} data-testid={`stat-${figure.key}`}>
              <span className="stat-label">{t.overview[figure.key]}</span>
              <span className="stat-value">{figure.value ?? 0}</span>
            </div>
          ))}
        </section>
      )}
    </>
  );
}
