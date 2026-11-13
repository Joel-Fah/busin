"use client";

import { useEffect } from "react";

const OWNER = "busin-owner";

/**
 * Forgets the pages the service worker saved when a different person uses this browser (a session that ended without a
 * sign-out, then someone else signing in): saved pages hold the student's own data.
 */
export function SessionOwner({ userId }: { userId: string }) {
  useEffect(() => {
    try {
      const before = window.localStorage.getItem(OWNER);
      if (before && before !== userId) navigator.serviceWorker?.controller?.postMessage("clear");
      window.localStorage.setItem(OWNER, userId);
    } catch {
      // Private mode: nothing was saved for anyone.
    }
  }, [userId]);
  return null;
}
