"use client";

import { useEffect } from "react";

/** Fired on window when a new version of the app has taken over this page (see UpdateNotice). */
export const UPDATED_EVENT = "busin:updated";

/**
 * Registers the student web app's service worker (public/app/sw.js, scope /app/). Only in a production build: in
 * development its caching would fight hot reloading. A browser without service workers simply runs online.
 *
 * Updates apply by themselves (the worker takes over at once). So that an app left open for hours notices one, it asks
 * for a new version whenever the student comes back to it; when a new worker takes over a page that already had one,
 * the page is told, and offers a reload.
 */
export function ServiceWorker() {
  useEffect(() => {
    if (process.env.NODE_ENV !== "production" || !("serviceWorker" in navigator)) return;
    const hadController = Boolean(navigator.serviceWorker.controller);
    navigator.serviceWorker.register("/app/sw.js", { scope: "/app/" }).catch(() => {
      // Not fatal: the app works online without it.
    });
    const onChange = () => {
      if (hadController) window.dispatchEvent(new Event(UPDATED_EVENT));
    };
    const onVisible = () => {
      if (document.visibilityState !== "visible") return;
      void navigator.serviceWorker.getRegistration("/app/").then((registration) => registration?.update()).catch(() => undefined);
    };
    navigator.serviceWorker.addEventListener("controllerchange", onChange);
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      navigator.serviceWorker.removeEventListener("controllerchange", onChange);
      document.removeEventListener("visibilitychange", onVisible);
    };
  }, []);
  return null;
}
