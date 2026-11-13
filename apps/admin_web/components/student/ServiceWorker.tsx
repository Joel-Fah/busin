"use client";

import { useEffect } from "react";

/**
 * Registers the student web app's service worker (public/app/sw.js, scope /app/). Only in a production build: in
 * development its caching would fight hot reloading. A browser without service workers simply runs online.
 */
export function ServiceWorker() {
  useEffect(() => {
    if (process.env.NODE_ENV !== "production" || !("serviceWorker" in navigator)) return;
    navigator.serviceWorker.register("/app/sw.js", { scope: "/app/" }).catch(() => {
      // Not fatal: the app works online without it.
    });
  }, []);
  return null;
}
