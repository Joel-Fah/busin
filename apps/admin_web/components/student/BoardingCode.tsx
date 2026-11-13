"use client";

import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";

import { BrandMark } from "@/components/brand/BrandMark";
import { Button } from "@/components/ui/Button";
import { Contour } from "@/components/ui/Contour";
import { EmptyState } from "@/components/ui/EmptyState";
import { Skeleton } from "@/components/ui/Skeleton";
import type { StudentCopy } from "@/lib/i18n/student";
import { deleteKey, loadKey, saveKey } from "@/lib/student/key-store";
import { format } from "@/lib/i18n/format";
import { generateCode, importSecret } from "@/lib/student/qr";
import { browserClient } from "@/lib/supabase/browser";
import { todayInZone } from "@/lib/zoned";

import { QrDots } from "./QrDots";

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
export function BoardingCode({ copy, studentId, name, matricule, timeZone, approved, validUntil, locale }: Props & { locale: string }) {
  const [state, setState] = useState<State>({ kind: "checking" });
  // The code of this 30-second window. No countdown is shown: when it changes is nobody's business but the scanner's.
  const [code, setCode] = useState<string | null>(null);
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

  // A new code each window.
  useEffect(() => {
    if (state.kind !== "ready") return;
    let cancelled = false;
    const tick = async () => {
      const next = await generateCode(state.key, studentId, Date.now(), timeZone);
      if (cancelled || next === lastCode.current) return;
      lastCode.current = next;
      setCode(next);
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

  const until = validUntil ? new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: "UTC" }).format(new Date(`${validUntil}T00:00:00Z`)) : null;

  return (
    <section aria-label={copy.title} className="relative mx-auto w-full max-w-sm" data-testid="boarding-ticket">
      <div className="texture-grain relative overflow-hidden rounded-xl bg-seed text-white shadow-float [--grain:0.7] [--thread-color:rgb(255_255_255/0.28)]">
        <Contour radius={36} inset={10} />
        <div className="relative flex items-center justify-between px-7 pt-7">
          <BrandMark className="h-7 w-auto text-white" />
          <span className="inline-flex items-center gap-2 rounded-full bg-white/12 px-3 py-1.5 text-sm font-bold">
            <span className="relative flex size-2.5">
              <span className="absolute inline-flex size-full animate-ping rounded-full bg-ok opacity-60 motion-reduce:animate-none" />
              <span className="relative inline-flex size-2.5 rounded-full bg-ok" />
            </span>
            {copy.live}
          </span>
        </div>

        <div className="relative mx-auto mt-6 aspect-square w-[82%] overflow-hidden rounded-[2rem] bg-white p-1.5 shadow-[0_10px_30px_rgb(0_0_0/0.25)]">
          {code ? (
            <div key={code} className="size-full animate-[student-rise_var(--dur)_var(--ease-soft)] motion-reduce:animate-none" data-testid="boarding-qr" data-code={code}>
              <QrDots code={code} label={copy.imageLabel} />
            </div>
          ) : null}
        </div>

        {/* The tear line: a row of round holes, with a round notch at each end. */}
        <div aria-hidden className="relative my-7 flex items-center">
          <span className="-ml-4 size-8 shrink-0 rounded-full bg-bg" />
          <span className="flex flex-1 justify-between px-3">
            {Array.from({ length: 16 }, (_, i) => (
              <span key={i} className="size-1.5 rounded-full bg-white/30" />
            ))}
          </span>
          <span className="-mr-4 size-8 shrink-0 rounded-full bg-bg" />
        </div>

        <div className="relative px-7 pb-8">
          <p className="m-0 text-2xl leading-tight font-extrabold">{name}</p>
          {matricule ? <p className="m-0 mt-1 text-lg tracking-[0.12em] text-white/85">{matricule}</p> : null}
          {until ? <p className="m-0 mt-3 text-sm text-white/65">{format(copy.validUntil, { date: until })}</p> : null}
        </div>
      </div>
    </section>
  );
}
