import { browserClient } from "@/lib/supabase/browser";

/**
 * Push in the student web app (ADR 0021, ADR 0010): the browser's FCM token is registered as platform "web" and the
 * service worker (public/app/sw.js) shows what arrives. Firebase is loaded only when push is used. All values below are
 * public (the Firebase web config and the Web Push key are meant for browsers).
 */
const CONFIG = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};
const VAPID_KEY = process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY;
const TOKEN_KEY = "busin-push-token";

export type PushState = "unconfigured" | "unsupported" | "needsInstall" | "denied" | "off" | "on";

function configured(): boolean {
  return Boolean(CONFIG.apiKey && CONFIG.projectId && CONFIG.messagingSenderId && CONFIG.appId && VAPID_KEY);
}

function storedToken(): string | null {
  try {
    return window.localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

function storeToken(token: string | null) {
  try {
    if (token) window.localStorage.setItem(TOKEN_KEY, token);
    else window.localStorage.removeItem(TOKEN_KEY);
  } catch {
    // Private mode: the token is registered again next time.
  }
}

/** Where this browser stands. An iPhone or iPad gets push only from the app added to the home screen (iOS 16.4+). */
export function pushState(): PushState {
  if (!configured()) return "unconfigured";
  const ios = /iphone|ipad|ipod/i.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  const standalone = window.matchMedia("(display-mode: standalone)").matches || (navigator as Navigator & { standalone?: boolean }).standalone === true;
  if (ios && !standalone) return "needsInstall";
  if (!("Notification" in window) || !("serviceWorker" in navigator) || !("PushManager" in window)) return "unsupported";
  if (Notification.permission === "denied") return "denied";
  return Notification.permission === "granted" && storedToken() ? "on" : "off";
}

/** The browser's token for our service worker, registered with the server. Assumes permission is granted. */
async function registerToken(locale: "en" | "fr"): Promise<boolean> {
  const registration = await navigator.serviceWorker.getRegistration("/app/");
  if (!registration) return false;
  const [{ initializeApp, getApps }, messaging] = await Promise.all([import("firebase/app"), import("firebase/messaging")]);
  if (!(await messaging.isSupported())) return false;
  const app = getApps()[0] ?? initializeApp(CONFIG);
  const token = await messaging.getToken(messaging.getMessaging(app), { vapidKey: VAPID_KEY, serviceWorkerRegistration: registration });
  if (!token) return false;
  const { error } = await browserClient().rpc("register_device_token", { p_token: token, p_platform: "web", p_locale: locale });
  if (error) return false;
  storeToken(token);
  return true;
}

/** Asked only after the student taps: the browser's question, then the token. */
export async function enablePush(locale: "en" | "fr"): Promise<PushState> {
  if (pushState() === "unconfigured") return "unconfigured";
  const permission = await Notification.requestPermission();
  if (permission !== "granted") return permission === "denied" ? "denied" : "off";
  try {
    return (await registerToken(locale)) ? "on" : "off";
  } catch {
    return "off";
  }
}

/** Quietly keeps the token current when the student already allowed push (a new token, a new language). */
export async function syncPush(locale: "en" | "fr"): Promise<void> {
  if (!configured() || !("Notification" in window) || Notification.permission !== "granted") return;
  try {
    await registerToken(locale);
  } catch {
    // Tried again next time.
  }
}

/** Stops push in this browser: the server forgets the token (also on sign-out). */
export async function disablePush(): Promise<void> {
  const token = storedToken();
  storeToken(null);
  if (!token) return;
  await browserClient().rpc("unregister_device_token", { p_token: token });
  try {
    const [{ getApps }, messaging] = await Promise.all([import("firebase/app"), import("firebase/messaging")]);
    const app = getApps()[0];
    if (app) await messaging.deleteToken(messaging.getMessaging(app));
  } catch {
    // The server no longer has it, which is what matters.
  }
}
