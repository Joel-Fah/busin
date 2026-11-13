// The service worker of the student web app (ADR 0021), scope /app/. Hand-written, no library.
//
// - Pages under /app: the network first; when it fails, the copy saved the last time the page opened, else the offline page.
//   A slow network is not offline: the server gets 8 seconds before a saved copy is shown (as the apps' serverOrSaved), and
//   with no saved copy it is waited for. Saved pages are the student's own, so signing out, or another person signing in,
//   deletes them (message "clear").
// - Next's static files (hashed, never change) and the app's icons: from the cache first.
// - Everything else, and every call to Supabase (another origin), is left to the network: data is kept by the app itself.

const VERSION = "v3";
const SLOW_MS = 8000;
const STATIC = `busin-static-${VERSION}`;
const PAGES = `busin-pages-${VERSION}`;
const OFFLINE = "/app/offline";

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(PAGES)
      .then((cache) => cache.add(new Request(OFFLINE, { cache: "reload" })))
      .catch(() => undefined)
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((key) => key.startsWith("busin-") && key !== STATIC && key !== PAGES).map((key) => caches.delete(key))))
      .then(() => self.clients.claim()),
  );
});

function isStatic(url) {
  return url.origin === self.location.origin && (url.pathname.startsWith("/_next/static/") || url.pathname.startsWith("/app-icons/") || url.pathname === "/app/night-bus.webp");
}

/** A page of the app worth keeping for offline use: not the sign-in page, not a Next data request. */
function isAppPage(request, url) {
  return (
    request.mode === "navigate" &&
    url.origin === self.location.origin &&
    (url.pathname === "/app" || url.pathname.startsWith("/app/")) &&
    !url.pathname.startsWith("/app/sign-in")
  );
}

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") return;
  const url = new URL(request.url);

  if (isStatic(url)) {
    event.respondWith(
      caches.open(STATIC).then(async (cache) => {
        const hit = await cache.match(request);
        if (hit) return hit;
        const response = await fetch(request);
        if (response.ok) cache.put(request, response.clone());
        return response;
      }),
    );
    return;
  }

  if (isAppPage(request, url)) {
    event.respondWith(
      (async () => {
        const cache = await caches.open(PAGES);
        const saved = await cache.match(url.pathname);
        const network = fetch(request).then((response) => {
          // Only a real page of the app is kept: not a redirect to sign-in, not an error.
          if (response.ok && !response.redirected) cache.put(url.pathname, response.clone());
          return response;
        });
        try {
          if (!saved) return await network;
          // A saved copy exists: the server's answer wins if it comes within 8 seconds, else the copy is shown.
          const slow = new Promise((resolve) => setTimeout(() => resolve(null), SLOW_MS));
          return (await Promise.race([network, slow])) || saved;
        } catch {
          return saved || (await cache.match(OFFLINE)) || Response.error();
        }
      })(),
    );
  }
});

self.addEventListener("message", (event) => {
  // Sent on sign-out: the saved pages belong to the person who just left.
  if (event.data === "clear") {
    event.waitUntil(caches.delete(PAGES).then(() => caches.open(PAGES)).then((cache) => cache.add(new Request(OFFLINE, { cache: "reload" }))).catch(() => undefined));
  }
});

// ---------------------------------------------------------------------------- push (ADR 0021, ADR 0010)
//
// FCM delivers a web push here: { notification: { title, body, icon }, data: { kind, ref_id }, fcmOptions: { link } }.
// The words are the server's (supabase/functions/_shared/push.ts); nothing personal is in them. When a page of the app
// is on screen it is told instead (it refreshes and shows a short message); otherwise the notification is shown, and a
// tap opens the page it is about.

function routeFor(kind) {
  if (kind === "bus_near_stop") return "/app/bus";
  if (kind && kind.startsWith("subscription_")) return "/app/subscription";
  return "/app";
}

/** Only an address of this site is opened from a notification. */
function sameSite(link) {
  try {
    const url = new URL(link, self.location.origin);
    return url.origin === self.location.origin ? url.pathname + url.search : null;
  } catch {
    return null;
  }
}

self.addEventListener("push", (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch {
    payload = {};
  }
  const notification = payload.notification || {};
  const data = payload.data || {};
  const link = sameSite((payload.fcmOptions && payload.fcmOptions.link) || notification.click_action || "") || routeFor(data.kind);
  event.waitUntil(
    (async () => {
      const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
      const onScreen = windows.find((client) => client.visibilityState === "visible" && new URL(client.url).pathname.startsWith("/app"));
      if (onScreen) {
        onScreen.postMessage({ type: "busin-push", kind: data.kind || null, refId: data.ref_id || null });
        return;
      }
      await self.registration.showNotification(notification.title || "BusIn", {
        body: notification.body || "",
        icon: "/app-icons/icon-192.png",
        badge: "/app-icons/badge-96.png",
        tag: data.kind ? `${data.kind}:${data.ref_id || ""}` : undefined,
        data: { link },
      });
    })(),
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const link = sameSite((event.notification.data && event.notification.data.link) || "") || "/app";
  event.waitUntil(
    (async () => {
      const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
      const open = windows.find((client) => new URL(client.url).pathname.startsWith("/app"));
      if (open) {
        await open.focus();
        return open.navigate(link);
      }
      return self.clients.openWindow(link);
    })(),
  );
});
