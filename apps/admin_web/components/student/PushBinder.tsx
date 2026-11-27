"use client";

import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";

import { useToast } from "@/components/ui/Toast";
import type { StudentCopy } from "@/lib/i18n/student";
import { TRIP_STARTED_EVENT } from "@/lib/student/bus-news";
import { syncPush } from "@/lib/student/push";

/** What the bus notifications say while a page is open, as the app's short messages. */
export function busPushText(kind: string | null | undefined, copy: StudentCopy["push"]): string | null {
  switch (kind) {
    case "bus_near_stop":
      return copy.busNear;
    case "trip_started":
      return copy.tripStarted;
    case "bus_at_stop":
      return copy.atStop;
    case "bus_left_stop":
      return copy.leftStop;
    case "bus_at_campus":
      return copy.atCampus;
    default:
      return null;
  }
}

/**
 * Keeps push working while the app is open: the token is refreshed quietly when push is already allowed, and a message
 * that arrives while a page is on screen (the service worker passes it on instead of showing it) refreshes the page and,
 * for the bus, says so (My bus shows it on its own). A trip that started also lights the My bus tab. Subscription
 * decisions are said by the page's own live feed, so they are not said twice.
 */
export function PushBinder({ locale, copy }: { locale: "en" | "fr"; copy: StudentCopy["push"] }) {
  const router = useRouter();
  const pathname = usePathname();
  const toast = useToast();

  useEffect(() => {
    void syncPush(locale);
  }, [locale]);

  useEffect(() => {
    if (!("serviceWorker" in navigator)) return;
    const onMessage = (event: MessageEvent) => {
      const data = event.data as { type?: string; kind?: string } | null;
      if (data?.type !== "busin-push") return;
      const bus = busPushText(data.kind, copy);
      if (bus && !pathname.startsWith("/app/bus")) toast(bus, { tone: "info" });
      if (data.kind === "trip_started") window.dispatchEvent(new Event(TRIP_STARTED_EVENT));
      router.refresh();
    };
    navigator.serviceWorker.addEventListener("message", onMessage);
    return () => navigator.serviceWorker.removeEventListener("message", onMessage);
  }, [copy, pathname, router, toast]);

  return null;
}
