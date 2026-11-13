"use client";

import { useRouter } from "next/navigation";
import { useEffect, useRef } from "react";

import { useToast } from "@/components/ui/Toast";
import type { StudentCopy } from "@/lib/i18n/student";
import type { SubscriptionStatus } from "@/lib/student/subscription";
import { browserClient } from "@/lib/supabase/browser";

/** Which message a change of status deserves, if any. Getting a revoked subscription back is its own good news. */
export function announcementFor(before: SubscriptionStatus | undefined, after: SubscriptionStatus): keyof StudentCopy["subscription"]["live"] | null {
  if (before === after) return null;
  if (after === "approved") return before === "revoked" ? "reinstated" : "approved";
  if (after === "rejected" || after === "revoked") return after;
  return null;
}

/**
 * Follows the student's own requests while the page is open (Realtime, filtered to this student on the server, where
 * RLS applies too), as the app's live feed: a decision refreshes the page and is said once in a toast. Only while the
 * tab is visible; coming back refreshes.
 */
export function LiveSubscriptions({ studentId, known, copy }: { studentId: string; known: Record<string, SubscriptionStatus>; copy: StudentCopy["subscription"]["live"] }) {
  const router = useRouter();
  const toast = useToast();
  const statuses = useRef(known);

  useEffect(() => {
    statuses.current = { ...statuses.current, ...known };
  }, [known]);

  useEffect(() => {
    const supabase = browserClient();
    let channel: ReturnType<typeof supabase.channel> | null = null;

    let stopped = false;
    const open = async () => {
      if (channel) return;
      // The channel must carry the student's token, or RLS shows it nothing: the browser client reads the session from
      // its cookie lazily, so it is passed explicitly before joining.
      const { data } = await supabase.auth.getSession();
      if (stopped || channel || !data.session) return;
      await supabase.realtime.setAuth(data.session.access_token);
      if (stopped || channel) return;
      channel = supabase
        .channel(`subscriptions:${studentId}`)
        .on("postgres_changes", { event: "*", schema: "public", table: "subscriptions", filter: `student_id=eq.${studentId}` }, (payload) => {
          const row = payload.new as { id?: string; status?: SubscriptionStatus } | null;
          if (!row?.id || !row.status) return;
          const said = announcementFor(statuses.current[row.id], row.status);
          statuses.current = { ...statuses.current, [row.id]: row.status };
          if (said) toast(copy[said], { tone: said === "approved" || said === "reinstated" ? "ok" : "warn" });
          router.refresh();
        })
        .subscribe();
    };
    const close = () => {
      if (channel) void supabase.removeChannel(channel);
      channel = null;
    };
    const onVisibility = () => {
      if (document.visibilityState === "visible") {
        void open();
        router.refresh();
      } else close();
    };

    if (document.visibilityState === "visible") void open();
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      stopped = true;
      document.removeEventListener("visibilitychange", onVisibility);
      close();
    };
  }, [studentId, copy, router, toast]);

  return null;
}
