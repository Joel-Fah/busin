"use client";

import { WifiDisconnected01Icon } from "@hugeicons/core-free-icons";
import { useSyncExternalStore } from "react";

import { Icon } from "@/components/ui/Icon";

function subscribe(onChange: () => void) {
  window.addEventListener("online", onChange);
  window.addEventListener("offline", onChange);
  return () => {
    window.removeEventListener("online", onChange);
    window.removeEventListener("offline", onChange);
  };
}

/**
 * Says the browser is offline, as the app's banner: the page on screen is the copy saved when it last opened, the pass
 * and code still work, and anything that sends needs the internet. Only when the device has no network at all; a slow
 * network is not offline.
 */
export function OfflineBanner({ text }: { text: string }) {
  const online = useSyncExternalStore(subscribe, () => navigator.onLine, () => true);
  if (online) return null;
  return (
    <div role="status" className="sticky top-0 z-30 flex items-center gap-3 bg-warn-bg px-4 py-3 text-sm font-semibold text-warn" data-testid="offline-banner">
      <Icon icon={WifiDisconnected01Icon} size={18} className="shrink-0" />
      <span className="mx-auto w-full max-w-[592px]">{text}</span>
    </div>
  );
}
