"use client";

import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";

import { Button } from "@/components/ui/Button";
import { GoogleMark } from "@/components/ui/GoogleMark";
import { signInWithGoogle } from "@/lib/auth-actions";
import type { StudentCopy } from "@/lib/i18n/student";
import { browserClient } from "@/lib/supabase/browser";

type Gis = {
  accounts: {
    id: {
      initialize(options: Record<string, unknown>): void;
      renderButton(parent: HTMLElement, options: Record<string, unknown>): void;
    };
  };
};

declare global {
  interface Window {
    google?: Gis;
  }
}

const GIS_SCRIPT = "https://accounts.google.com/gsi/client";
const CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID;

function hex(bytes: ArrayBuffer | Uint8Array): string {
  return Array.from(bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes), (b) => b.toString(16).padStart(2, "0")).join("");
}

/** Loads Google's script once; resolves false when it cannot (offline, blocked by the browser, or too slow). */
function loadGis(): Promise<boolean> {
  if (window.google?.accounts?.id) return Promise.resolve(true);
  return new Promise((resolve) => {
    const script = document.createElement("script");
    script.src = GIS_SCRIPT;
    script.async = true;
    const timer = window.setTimeout(() => resolve(false), 8000);
    script.onload = () => {
      window.clearTimeout(timer);
      resolve(Boolean(window.google?.accounts?.id));
    };
    script.onerror = () => {
      window.clearTimeout(timer);
      resolve(false);
    };
    document.head.appendChild(script);
  });
}

/** What a refused sign-in means for the student. The database refuses an email domain no school accepts. */
export function signInErrorKey(message: string): "notAllowed" | "failed" {
  return /Database error saving new user|not allowed|domain/i.test(message) ? "notAllowed" : "failed";
}

/**
 * Google sign-in for the student web app (ADR 0021). Google Identity Services gives an ID token that Supabase checks
 * (with a nonce, as the phone does); this works in an installed iPhone web app, where a full-page redirect can lose the
 * session. When Google's script cannot be used, the same orange button as the portal starts the redirect flow instead.
 */
export function SignInPanel({ copy, locale, initialError }: { copy: StudentCopy["signIn"]; locale: string; initialError: string | null }) {
  const router = useRouter();
  const slot = useRef<HTMLDivElement>(null);
  const [mode, setMode] = useState<"loading" | "gis" | "fallback">(CLIENT_ID ? "loading" : "fallback");
  const [message, setMessage] = useState<string | null>(initialError);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!CLIENT_ID) return;
    let cancelled = false;
    (async () => {
      if (!(await loadGis()) || cancelled || !slot.current) {
        if (!cancelled) setMode("fallback");
        return;
      }
      // A fresh nonce for this attempt: Google signs its hash into the token, Supabase checks the token against it.
      const raw = hex(crypto.getRandomValues(new Uint8Array(32)));
      const hashed = hex(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(raw)));
      window.google!.accounts.id.initialize({
        client_id: CLIENT_ID,
        nonce: hashed,
        ux_mode: "popup",
        auto_select: false,
        itp_support: true,
        use_fedcm_for_button: true,
        callback: async ({ credential }: { credential?: string }) => {
          if (!credential) {
            setMessage(copy.cancelled);
            return;
          }
          setBusy(true);
          setMessage(null);
          const { error } = await browserClient().auth.signInWithIdToken({ provider: "google", token: credential, nonce: raw });
          if (error) {
            setBusy(false);
            setMessage(copy[signInErrorKey(error.message)]);
            return;
          }
          router.replace("/app");
          router.refresh();
        },
      });
      window.google!.accounts.id.renderButton(slot.current, {
        type: "standard",
        theme: "outline",
        size: "large",
        text: "continue_with",
        shape: "rectangular",
        logo_alignment: "left",
        width: Math.min(400, slot.current.offsetWidth || 320),
        locale,
      });
      if (!cancelled) setMode("gis");
    })();
    return () => {
      cancelled = true;
    };
  }, [copy, locale, router]);

  return (
    <div className="flex flex-col gap-4">
      {message ? (
        <p role="alert" className="m-0 rounded-md bg-[#3a1512]/80 px-4 py-3 text-sm font-semibold text-[#ffb4ab]">
          {message}
        </p>
      ) : null}
      {busy ? (
        <p role="status" className="m-0 text-sm font-semibold text-white/85">
          {copy.working}
        </p>
      ) : null}
      <div ref={slot} hidden={mode !== "gis" || busy} className="min-h-11 w-full max-w-[400px] overflow-hidden rounded-sm" data-testid="gis-button" />
      {mode === "fallback" ? (
        <form action={signInWithGoogle}>
          <input type="hidden" name="from" value="app" />
          <Button type="submit" className="h-14 w-full max-w-[400px] text-base">
            <span className="inline-flex items-center gap-2.5">
              <GoogleMark />
              {copy.button}
            </span>
          </Button>
        </form>
      ) : null}
      {mode === "loading" ? <div aria-hidden className="h-11 w-full max-w-[400px] animate-pulse rounded-sm bg-white/15" /> : null}
    </div>
  );
}
