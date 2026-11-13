"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

/**
 * Asks the server again when the student comes back to the tab or the installed app, so a decision made meanwhile (a
 * school accepting them, a suspension) shows without a manual reload. The page's guard then sends them on.
 */
export function RefreshOnReturn() {
  const router = useRouter();
  useEffect(() => {
    const onVisible = () => {
      if (document.visibilityState === "visible") router.refresh();
    };
    document.addEventListener("visibilitychange", onVisible);
    return () => document.removeEventListener("visibilitychange", onVisible);
  }, [router]);
  return null;
}
