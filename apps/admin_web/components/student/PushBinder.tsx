"use client";

import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";

import { useToast } from "@/components/ui/Toast";
import { syncPush } from "@/lib/student/push";

/**
 * Keeps push working while the app is open: the token is refreshed quietly when push is already allowed, and a message
 * that arrives while a page is on screen (the service worker passes it on instead of showing it) refreshes the page and,
 * for the bus, says so. Subscription decisions are said by the page's own live feed, so they are not said twice.
 */
export function PushBinder({ locale, busNear }: { locale: "en" | "fr"; busNear: string }) {
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
      if (data.kind === "bus_near_stop" && !pathname.startsWith("/app/bus")) toast(busNear, { tone: "info" });
      router.refresh();
    };
    navigator.serviceWorker.addEventListener("message", onMessage);
    return () => navigator.serviceWorker.removeEventListener("message", onMessage);
  }, [busNear, pathname, router, toast]);

  return null;
}
