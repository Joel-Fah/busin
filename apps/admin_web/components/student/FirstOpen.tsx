"use client";

import { Cancel01Icon, DownloadCircle01Icon } from "@hugeicons/core-free-icons";
import Image from "next/image";
import { useState, useSyncExternalStore } from "react";

import { Button } from "@/components/ui/Button";
import { Checkbox } from "@/components/ui/Choice";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import type { StudentCopy } from "@/lib/i18n/student";

import { Sheet } from "./Sheet";

const WELCOMED = "busin-welcomed";
const WELCOMED_NOW = "busin-welcomed-now";
const APP_SHEET = "busin-app-sheet";
const APP_SHEET_SEEN = "busin-app-sheet-seen";

type Decision = "server" | "none" | "welcome" | { app: string };

function read(store: () => Storage, key: string): string | null {
  try {
    return store().getItem(key);
  } catch {
    return null;
  }
}

function write(store: () => Storage, key: string, value: string) {
  try {
    store().setItem(key, value);
  } catch {
    // Private mode: it may show again next time.
  }
}

const local = () => window.localStorage;
const session = () => window.sessionStorage;
const noSubscription = () => () => {};

/**
 * What to show on opening: the welcome the very first time; on a later visit from a phone, the offer of the app for that
 * phone (when a store or file link exists), once a visit, until the student says never. Nothing inside the installed web
 * app, which is already where they chose to be.
 */
function decide(links: { android: string | null; ios: string | null }): Decision {
  const standalone = window.matchMedia("(display-mode: standalone)").matches || (navigator as Navigator & { standalone?: boolean }).standalone === true;
  if (standalone) return "none";
  if (read(local, WELCOMED) !== "1") return "welcome";
  if (read(session, WELCOMED_NOW) === "1" || read(session, APP_SHEET_SEEN) === "1" || read(local, APP_SHEET) === "never") return "none";
  const ua = navigator.userAgent;
  const ios = /iphone|ipad|ipod/i.test(ua) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  const link = ios ? links.ios : /android/i.test(ua) ? links.android : null;
  return link ? { app: link } : "none";
}

let cached: { key: string; value: Decision } | null = null;

/** The first-open welcome and the "better in the app" sheet of the student web app. */
export function FirstOpen({ welcome, appSheet, links }: { welcome: StudentCopy["welcome"]; appSheet: StudentCopy["appSheet"]; links: { android: string | null; ios: string | null } }) {
  const key = `${links.android}|${links.ios}`;
  const decision = useSyncExternalStore(
    noSubscription,
    () => {
      // The answer is read once per page load: the storage it reads is written below as the student answers.
      if (!cached || cached.key !== key) cached = { key, value: decide(links) };
      return cached.value;
    },
    () => "server" as Decision,
  );
  const [closed, setClosed] = useState(false);
  const [never, setNever] = useState(false);

  const closeWelcome = () => {
    write(local, WELCOMED, "1");
    write(session, WELCOMED_NOW, "1");
    setClosed(true);
  };
  const closeSheet = () => {
    write(session, APP_SHEET_SEEN, "1");
    if (never) write(local, APP_SHEET, "never");
    setClosed(true);
  };

  if (decision === "welcome") {
    return (
      <Sheet open={!closed} onClose={closeWelcome} label={welcome.title} className="mt-[max(5rem,15dvh)] mb-auto overflow-visible">
        {/* Three stickers, a little stacked, half above the top edge: the face scan (the boarding code), the bus in front, the ticket. */}
        <div aria-hidden className="pointer-events-none absolute inset-x-0 top-0 flex -translate-y-1/2 items-end justify-center">
          <Image src="/landing/stickers/face-scan.webp" alt="" width={112} height={112} className="relative z-0 -mr-8 mb-2 size-20 -rotate-12 object-contain drop-shadow-xl" />
          <Image src="/landing/stickers/bus.webp" alt="" width={176} height={176} priority className="relative z-10 size-32 object-contain drop-shadow-2xl" />
          <Image src="/landing/stickers/ticket.webp" alt="" width={112} height={112} className="relative z-0 -ml-8 mb-3 size-20 rotate-12 object-contain drop-shadow-xl" />
        </div>
        <Contour radius={36} inset={12} />
        <button
          type="button"
          onClick={closeWelcome}
          aria-label={welcome.close}
          className="absolute top-5 right-5 z-10 grid size-10 cursor-pointer place-items-center rounded-full border-0 bg-surface-2 text-fg focus-visible:outline-3 focus-visible:outline-focus"
        >
          <Icon icon={Cancel01Icon} size={18} />
        </button>
        <div className="relative flex flex-col gap-4 px-8 pt-24 pb-9 text-center" data-testid="welcome">
          <h2 className="relative m-0 mx-auto w-fit text-3xl leading-tight font-extrabold tracking-tight text-balance">
            <span aria-hidden className="texture-rough absolute inset-x-[-0.1em] bottom-[0.04em] h-[0.32em] rounded-xs bg-accent/55" />
            <span className="relative">{welcome.title}</span>
          </h2>
          <p className="m-0 text-pretty text-muted">{welcome.body}</p>
          <Button className="mt-2 h-14 w-full text-base" onClick={closeWelcome}>
            {welcome.go}
          </Button>
        </div>
      </Sheet>
    );
  }

  if (typeof decision === "object") {
    return (
      <Sheet open={!closed} onClose={closeSheet} label={appSheet.title} placement="bottom">
        <Contour radius={36} inset={12} />
        <div className="relative flex flex-col gap-4 px-7 pt-4 pb-2" data-testid="app-sheet">
          <span aria-hidden className="mx-auto h-1.5 w-12 rounded-full bg-line" />
          <div className="flex items-center gap-4">
            <Image src="/app-icons/icon-192.png" alt="" width={56} height={56} className="size-14 rounded-md shadow-soft" />
            <div className="min-w-0">
              <h2 className="m-0 text-xl font-extrabold tracking-tight">{appSheet.title}</h2>
              <p className="m-0 text-sm text-muted">{appSheet.body}</p>
            </div>
          </div>
          <a
            href={decision.app}
            onClick={closeSheet}
            className="inline-flex h-14 w-full items-center justify-center gap-2 rounded-sm bg-accent px-5 text-base font-semibold text-on-accent no-underline focus-visible:outline-3 focus-visible:outline-focus"
          >
            <Icon icon={DownloadCircle01Icon} size={20} />
            {appSheet.open}
          </a>
          <Button variant="secondary" className="h-12 w-full" onClick={closeSheet}>
            {appSheet.stay}
          </Button>
          <Checkbox label={appSheet.never} checked={never} onChange={(event) => setNever(event.target.checked)} />
        </div>
      </Sheet>
    );
  }

  return null;
}
