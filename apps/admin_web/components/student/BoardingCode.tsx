"use client";

import Link from "next/link";
import QRCode from "qrcode";
import { useCallback, useEffect, useRef, useState } from "react";

import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Skeleton } from "@/components/ui/Skeleton";
import type { StudentCopy } from "@/lib/i18n/student";
import { deleteKey, loadKey, saveKey } from "@/lib/student/key-store";
import { generateCode, importSecret, secondsRemaining } from "@/lib/student/qr";
import { browserClient } from "@/lib/supabase/browser";
import { todayInZone } from "@/lib/zoned";

type State = { kind: "checking" } | { kind: "none" } | { kind: "offline" } | { kind: "failed" } | { kind: "ready"; key: CryptoKey };

type Props = {
  copy: StudentCopy["code"];
  studentId: string;
  name: string;
  matricule: string | null;
  timeZone: string;
  /** The server's answer when the page was made: an approved subscription for today, and the last day of its semester. */
  approved: boolean;
  validUntil: string | null;
};

/**
 * The boarding ticket, as in the app: a seed-teal card with a live pill, the code on a white sticker, and the student's
 * name and number for the staff at the door. The secret comes from `get_my_qr_secret` whenever the tab opens with a
 * connection, and is kept only as a non-extractable key (ADR 0021); without a connection the kept key works until its
 * semester ends. The server's refusal deletes it. The screen stays awake while the code shows.
 */
export function BoardingCode({ copy, studentId, name, matricule, timeZone, approved, validUntil }: Props) {
  const [state, setState] = useState<State>({ kind: "checking" });
  const [image, setImage] = useState<{ url: string; code: string } | null>(null);
  const [left, setLeft] = useState(30);
  const lastCode = useRef<string | null>(null);

  const refresh = useCallback(async () => {
    const today = todayInZone(timeZone);
    if (!approved) {
      await deleteKey(studentId);
      setState({ kind: "none" });
      return;
    }
    if (navigator.onLine) {
      const { data, error } = await browserClient().rpc("get_my_qr_secret");
      if (!error && typeof data === "string") {
        const key = await importSecret(data);
        if (validUntil) await saveKey({ userId: studentId, key, validUntil });
        setState({ kind: "ready", key });
        return;
      }
      if (error?.code === "42501") {
        // Not allowed today (no approved subscription for today): the kept key goes too.
        await deleteKey(studentId);
        setState({ kind: "none" });
        return;
      }
    }
    const kept = await loadKey(studentId, today);
    setState(kept ? { kind: "ready", key: kept } : navigator.onLine ? { kind: "failed" } : { kind: "offline" });
  }, [approved, studentId, timeZone, validUntil]);

  useEffect(() => {
    // Asking the server (or the kept key) on open is the point of this component; the answer arrives later.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void refresh();
    const onVisible = () => {
      if (document.visibilityState === "visible") void refresh();
    };
    document.addEventListener("visibilitychange", onVisible);
    return () => document.removeEventListener("visibilitychange", onVisible);
  }, [refresh]);

  // A new code each window, and the seconds left in this one.
  useEffect(() => {
    if (state.kind !== "ready") return;
    let cancelled = false;
    const tick = async () => {
      const now = Date.now();
      setLeft(secondsRemaining(now));
      const code = await generateCode(state.key, studentId, now, timeZone);
      if (cancelled || code === lastCode.current) return;
      lastCode.current = code;
      const url = await QRCode.toDataURL(code, { errorCorrectionLevel: "Q", margin: 1, width: 600, color: { dark: "#002a33", light: "#ffffff" } });
      if (!cancelled) setImage({ url, code });
    };
    void tick();
    const timer = window.setInterval(() => void tick(), 1000);
    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, [state, studentId, timeZone]);

  // Keep the screen on while the code shows (where the browser allows it).
  useEffect(() => {
    if (state.kind !== "ready" || !("wakeLock" in navigator)) return;
    let lock: WakeLockSentinel | null = null;
    const take = async () => {
      try {
        lock = await navigator.wakeLock.request("screen");
      } catch {
        lock = null;
      }
    };
    const onVisible = () => {
      if (document.visibilityState === "visible") void take();
    };
    void take();
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      document.removeEventListener("visibilitychange", onVisible);
      void lock?.release();
    };
  }, [state.kind]);

  if (state.kind === "checking") {
    return (
      <div role="status" aria-label={copy.checking} className="mx-auto w-full max-w-sm">
        <Skeleton className="h-[30rem] rounded-xl" />
      </div>
    );
  }
  if (state.kind === "none") {
    return (
      <EmptyState
        title={copy.noneTitle}
        body={copy.noneBody}
        action={
          <Link href="/app/subscription" className="inline-flex h-12 items-center rounded-sm bg-accent px-5 font-semibold text-on-accent no-underline">
            {copy.toSubscription}
          </Link>
        }
      />
    );
  }
  if (state.kind === "offline" || state.kind === "failed") {
    return (
      <EmptyState
        title={state.kind === "offline" ? copy.offlineTitle : copy.failed}
        body={state.kind === "offline" ? copy.offlineBody : undefined}
        action={
          <Button variant="secondary" onClick={() => void refresh()}>
            {copy.retry}
          </Button>
        }
      />
    );
  }

  return (
    <section aria-label={copy.title} className="relative mx-auto w-full max-w-sm overflow-hidden rounded-xl bg-seed p-6 text-white shadow-float" data-testid="boarding-ticket">
      <div className="flex items-center justify-between">
        <span className="inline-flex items-center gap-2 rounded-xs bg-white/12 px-3 py-1.5 text-sm font-bold">
          <span className="relative flex size-2.5">
            <span className="absolute inline-flex size-full animate-ping rounded-full bg-ok opacity-60 motion-reduce:animate-none" />
            <span className="relative inline-flex size-2.5 rounded-full bg-ok" />
          </span>
          {copy.live}
        </span>
        <span className="text-sm font-semibold text-white/75 tabular-nums" aria-hidden>
          {left}s
        </span>
      </div>
      <div className="mx-auto mt-5 aspect-square w-full max-w-[18rem] rounded-lg bg-white p-3">
        {image ? (
          // The code as a picture made in the browser; never sent anywhere.
          // eslint-disable-next-line @next/next/no-img-element
          <img src={image.url} alt={copy.imageLabel} className="size-full" data-testid="boarding-qr" data-code={image.code} />
        ) : null}
      </div>
      <div aria-hidden className="relative my-6 -mx-6 h-0.5 bg-[repeating-linear-gradient(90deg,rgb(255_255_255/0.3)_0_8px,transparent_8px_14px)]">
        <span className="absolute -top-3 -left-3 size-6 rounded-full bg-bg" />
        <span className="absolute -top-3 -right-3 size-6 rounded-full bg-bg" />
      </div>
      <p className="m-0 text-2xl font-extrabold">{name}</p>
      {matricule ? <p className="m-0 mt-1 text-lg tracking-[0.08em] text-white/85">{matricule}</p> : null}
    </section>
  );
}
