"use client";

import {
  Alert02Icon,
  ArrowRight02Icon,
  ArrowUp01Icon,
  Bus01Icon,
  Cancel01Icon,
  CheckmarkCircle02Icon,
  Location01Icon,
  Location04Icon,
  Notification03Icon,
  PauseCircleIcon,
  PlayCircleIcon,
  Wifi01Icon,
  WifiDisconnected01Icon,
} from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";
import { useId, useState } from "react";

import { Icon } from "@/components/ui/Icon";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import type { BusUpdate, BusUpdateKind } from "@/lib/student/bus";

type Copy = StudentCopy["bus"];
type Tone = "ok" | "warn" | "info";

/** The tone and icon of each kind, as in the app: what needs the student's attention is warm, the rest is calm. Never colour alone. */
const LOOK: Record<BusUpdateKind, { tone: Tone; icon: IconSvgElement }> = {
  following: { tone: "info", icon: Bus01Icon },
  atStop: { tone: "info", icon: Location04Icon },
  leftStop: { tone: "info", icon: ArrowRight02Icon },
  stopped: { tone: "warn", icon: PauseCircleIcon },
  moving: { tone: "ok", icon: PlayCircleIcon },
  nearMyStop: { tone: "ok", icon: Location01Icon },
  passedMyStop: { tone: "warn", icon: Alert02Icon },
  signalLost: { tone: "warn", icon: WifiDisconnected01Icon },
  signalBack: { tone: "ok", icon: Wifi01Icon },
  tripEnded: { tone: "info", icon: CheckmarkCircle02Icon },
};

const TONES: Record<Tone, string> = {
  ok: "bg-ok-bg text-ok",
  warn: "bg-warn-bg text-warn",
  info: "bg-info-bg text-info",
};

export const updateIcon = (kind: BusUpdateKind) => LOOK[kind].icon;

/** The words for an update. A trip that ended names its own bus (kept in `stopName`). */
export function updateText(copy: Copy, update: BusUpdate, bus: string, direction: string, now: number): string {
  return format(copy.updates[update.kind], {
    bus: update.kind === "tripEnded" ? (update.stopName ?? "") : bus,
    direction,
    stop: update.stopName ?? "",
    minutes: update.minutes ?? Math.max(1, Math.round((now - (update.since ?? now)) / 60_000)),
  });
}

const keyOf = (u: BusUpdate) => `${u.kind}:${u.seq}:${u.at}`;

/** One short update over the map. A newer one replaces it; the student can hide it until the next. */
export function UpdateStrip({ update, text, dismiss }: { update: BusUpdate | null; text: string | null; dismiss: string }) {
  const [hidden, setHidden] = useState<string | null>(null);
  if (!update || !text || hidden === keyOf(update)) return null;
  const look = LOOK[update.kind];
  return (
    <p key={keyOf(update)} role="status" className={`bus-update-in m-0 flex items-center gap-3 rounded-md py-2 pr-2 pl-4 text-sm font-semibold shadow-soft ${TONES[look.tone]}`}>
      <Icon icon={look.icon} size={18} />
      <span className="min-w-0 flex-1">{text}</span>
      <button
        type="button"
        onClick={() => setHidden(keyOf(update))}
        aria-label={dismiss}
        title={dismiss}
        className="grid size-9 shrink-0 cursor-pointer place-items-center rounded-sm border-0 bg-transparent text-current focus-visible:outline-3 focus-visible:outline-focus"
      >
        <Icon icon={Cancel01Icon} size={16} />
      </button>
    </p>
  );
}

/** The trip's updates, newest first: the newest stands out, and where the bus reached a stop is in full colour and bolder. */
export function UpdateList({ updates, copy, bus, direction, now, locale }: { updates: BusUpdate[]; copy: Copy; bus: string; direction: string; now: number; locale: string }) {
  if (updates.length === 0) return <p className="m-0 text-sm text-muted">{copy.updatesEmpty}</p>;
  const time = new Intl.DateTimeFormat(locale, { hour: "2-digit", minute: "2-digit" });
  const [first, ...rest] = updates;
  const look = LOOK[first.kind];
  return (
    <div className="flex flex-col gap-3" data-testid="bus-updates">
      <p className={`m-0 flex items-center gap-3 rounded-md px-4 py-3 text-sm font-semibold ${TONES[look.tone]}`}>
        <Icon icon={look.icon} size={18} />
        <span className="min-w-0 flex-1">{updateText(copy, first, bus, direction, now)}</span>
        <span className="text-xs font-normal">{time.format(first.at)}</span>
      </p>
      {rest.length ? (
        <ul className="m-0 flex list-none flex-col gap-3 px-4 pb-1">
          {rest.map((u) => {
            const reached = u.kind === "atStop";
            return (
              <li key={keyOf(u)} className="flex items-center gap-3 text-sm" data-reached={reached || undefined}>
                <span className={reached ? "text-accent" : "text-muted"}>
                  <Icon icon={LOOK[u.kind].icon} size={18} />
                </span>
                <span className={`min-w-0 flex-1 ${reached ? "font-bold text-fg" : "text-muted"}`}>{updateText(copy, u, bus, direction, now)}</span>
                <span className="text-xs text-muted">{time.format(u.at)}</span>
              </li>
            );
          })}
        </ul>
      ) : null}
    </div>
  );
}

/**
 * The updates folded into the bus card, as on the phone: closed, the newest update itself on one line, with how many
 * there are; open, the whole list, scrolling inside a bounded height so the map stays visible.
 */
export function UpdatesFold({ count, latest, title, toggle, children }: { count: number; latest: { text: string; icon: IconSvgElement } | null; title: string; toggle: string; children: React.ReactNode }) {
  const [open, setOpen] = useState(false);
  const panel = useId();
  const showLatest = !open && latest !== null;
  return (
    <div className="flex flex-col">
      <button
        type="button"
        aria-expanded={open}
        aria-controls={panel}
        aria-label={toggle}
        onClick={() => setOpen((o) => !o)}
        className="flex min-h-11 w-full cursor-pointer items-center gap-2 rounded-sm border-0 bg-transparent px-0 py-2 text-left font-sans text-fg focus-visible:outline-3 focus-visible:outline-focus"
      >
        <span className="text-muted">
          <Icon icon={showLatest ? latest.icon : Notification03Icon} size={18} />
        </span>
        <span className="min-w-0 flex-1 truncate text-sm font-semibold" data-testid="bus-update" aria-live="polite">
          {showLatest ? latest.text : title}
        </span>
        {count > 0 ? <span className="rounded-sm bg-surface-2 px-2 py-0.5 text-xs font-semibold">{count}</span> : null}
        <span className={`text-muted transition-transform duration-(--dur) ease-soft ${open ? "rotate-180" : ""}`}>
          <Icon icon={ArrowUp01Icon} size={18} />
        </span>
      </button>
      <div id={panel} className={`grid transition-[grid-template-rows] duration-(--dur) ease-soft ${open ? "grid-rows-[1fr]" : "grid-rows-[0fr]"}`} inert={!open}>
        <div className="min-h-0 overflow-hidden">
          <div className="max-h-[32dvh] overflow-y-auto pt-2">{children}</div>
        </div>
      </div>
    </div>
  );
}
