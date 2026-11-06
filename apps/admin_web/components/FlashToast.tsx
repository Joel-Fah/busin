"use client";

import { usePathname, useSearchParams } from "next/navigation";
import { useEffect } from "react";

import { useToast } from "@/components/ui/Toast";
import type { ToastTone } from "@/lib/ui/toast";

/**
 * Shows a confirmation as a toast when a page opens after saving (the address carries `?done=`), then takes `done`
 * out of the address so a reload does not repeat it. Renders nothing.
 */
export function FlashToast({ message, tone = "ok" }: { message: string; tone?: ToastTone }) {
  const toast = useToast();
  const pathname = usePathname();
  const search = useSearchParams();

  useEffect(() => {
    toast(message, { tone });
    const next = new URLSearchParams(search.toString());
    if (next.has("done")) {
      next.delete("done");
      const query = next.toString();
      window.history.replaceState(null, "", query ? `${pathname}?${query}` : pathname);
    }
    // Only once per arrival: the message is what identifies it.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [message]);

  return null;
}
