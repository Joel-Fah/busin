// The service worker of the student web app (ADR 0021), scope /app/. Hand-written, no library.
//
// - Pages under /app: the network first; when it fails, the copy saved the last time the page opened, else the offline page.
//   A slow network is not offline: the server gets 8 seconds before a saved copy is shown (as the apps' serverOrSaved), and
//   with no saved copy it is waited for. Saved pages are the student's own, so signing out, or another person signing in,
//   deletes them (message "clear").
// - Next's static files (hashed, never change) and the app's icons: from the cache first.
// - Everything else, and every call to Supabase (another origin), is left to the network: data is kept by the app itself.

const VERSION = "v2";
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
