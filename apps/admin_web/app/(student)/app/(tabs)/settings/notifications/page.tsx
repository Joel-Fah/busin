import type { Metadata } from "next";
import { Suspense } from "react";

import { NotificationSettings } from "@/components/student/NotificationSettings";
import { PushOptIn } from "@/components/student/PushOptIn";
import { StudentPage } from "@/components/student/StudentPage";
import { Notice } from "@/components/ui/Notice";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Notifications" };
export const instant = false;

export default function NotificationsPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Notifications />
    </Suspense>
  );
}

async function Notifications() {
  await requireStudent();
  const { locale, s } = await getStudentCopy();
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("my_notification_preferences");
  const now = data?.[0];
  return (
    <StudentPage lang={locale} title={s.notifications.title} subtitle={s.notifications.hint}>
      <PushOptIn copy={s.push} locale={locale} />
      {error || !now ? (
        <Notice tone="bad">{s.notifications.failed}</Notice>
      ) : (
        <NotificationSettings copy={s.notifications} initial={{ ridingDays: now.riding_days, busNearOn: now.bus_near_on, busNearMinutes: now.bus_near_minutes, boardingOn: now.boarding_messages_on }} />
      )}
    </StudentPage>
  );
}
