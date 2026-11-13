# 0021: The student app on the web (PWA)

Date: 2026-11-13. Status: accepted (owner, 2026-11-13). Builds on [ADR 0002](0002-admin-web-nextjs.md),
[ADR 0006](0006-rotating-qr-design.md), [ADR 0009](0009-design-system.md), [ADR 0010](0010-push-notifications.md) and
[ADR 0014](0014-day-keys.md).

## Context

Some students cannot install the Android or iOS app (no space, an old phone, a borrowed device, no store access). They
still need to subscribe, show a boarding code and follow the bus. The web portal already has a design system whose
tokens are the same as the mobile one (ADR 0009, ADR 0011), and the database rules do not depend on the client.

## Decision

1. **A progressive web app at `/app`, inside the portal's Next.js project** (`apps/admin_web`, route group
   `app/(student)`). One deployment. The student pages have their own layout, navigation and words and import nothing
   from the admin pages, so Next's per-route code splitting keeps admin code out of what a student downloads. The
   service worker and the manifest are scoped to `/app/`. The mobile screens are the reference: same flows, same rules,
   same wording (copied from the shared ARB files).
2. **Same access rules as the app.** A verified student gets in; pending accounts choose or wait for a school
   (ADR 0012); staff, administrators and suspended accounts are turned away. The rule is a pure function ported from
   `access.dart`, checked again on the server for every page and action. RLS stays the real guard.
3. **Sign-in with Google Identity Services**, which gives an ID token for `signInWithIdToken` with a nonce, as on the
   phone. A full-page OAuth redirect can lose the session in an installed iPhone web app, so it is only the fallback.
   The callback sends each person by role: administrators to the portal, students to `/app`.
4. **The boarding code secret is kept as a non-extractable Web Crypto key** in IndexedDB, with the end of the semester
   it is valid for. Codes are made on the device (offline too) exactly as in the app (`busin2`, ADR 0014); page
   scripts can use the key but never read its bytes. It is deleted on sign-out, when the server refuses it, and when
   the semester ends.
5. **Push on the web through FCM** (ADR 0010): the `device_tokens.platform` value `web`, a `webpush` block in the
   sender, and the PWA's own service worker. Permission is asked only after the student taps; on iPhone it needs the
   app added to the home screen (iOS 16.4 or later).
6. **No morning or evening reminders on the web for now.** The phone schedules them itself; a browser cannot do that
   reliably. The settings screen hides them. Every server push (decisions, school notices, bus near my stop) works.
7. **Maps use MapLibre with open tiles** on `/app` (ADR 0008), so student traffic never bills a paid provider.
8. **The icon is the teal BusIn mark on white**, so the web app is told apart from the installed mobile app.

## Consequences

- **Weaker device protections than the phone.** No secure storage, no screenshot blocking, no Play Integrity. The
  non-extractable key keeps the secret from being copied out, but a script running in the page (an XSS) could still
  make codes while the page is open. Codes rotate every 30 seconds and staff see the student's photo and name, as
  ADR 0006 already accepts. Output is always encoded (React), no user HTML is rendered, and a nonce-based CSP for the
  portal stays the follow-up it already was.
- **The session is a cookie** set by the Supabase SSR helpers (HTTP only is not possible for the browser client, which
  must read it). Sign-out clears it, the IndexedDB stores and the push token.
- **Location:** a browser cannot ask for coarse location only. My area takes one low-accuracy reading and rounds it to
  0.01 degrees on the device before sending (the server snaps it further, ADR 0013). Show me (ADR 0016) reads the
  position only after a tap, only while the Bus tab is visible, and never sends it.
- **Not every browser can install or receive push** (desktop Firefox has no install; iPhone needs the home screen).
  The app works in every modern browser without them and says what is missing.
- **Two clients now share one set of words.** A change to student wording goes into the ARB files and `lib/i18n/student.ts`
  together.
- **The owner must** add the site to the Google OAuth client's authorized JavaScript origins, register a Firebase web
  app with a Web Push (VAPID) key, and approve the hosted migration and function redeploy for web push.
