import { Bus01Icon, CheckmarkCircle02Icon, Invoice01Icon, Location01Icon, Notification03Icon, Tick02Icon, WifiOff01Icon } from "@hugeicons/core-free-icons";
import type { ReactNode } from "react";

import { BrandMark } from "@/components/brand/BrandMark";
import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

type Copy = LandingCopy["day"];

function Header({ label }: { label: string }) {
  return (
    <div className="flex items-center justify-between px-5 pb-3 pt-11">
      <p className="m-0 text-lg font-extrabold tracking-tight">{label}</p>
      <BrandMark className="h-5 w-auto text-fg/70" label="" />
    </div>
  );
}

/** 6:40: the subscription moving through its stages, and the message that it was approved. */
function SubscriptionScreen({ copy }: { copy: Copy["sub"] }) {
  return (
    <>
      <Header label={copy.label} />
      <div className="day-push absolute inset-x-3 top-10 z-10 flex items-start gap-3 rounded-md bg-surface p-3 shadow-float">
        <span className="grid size-9 shrink-0 place-items-center rounded-xs bg-accent text-on-accent">
          <Icon icon={Notification03Icon} size={18} />
        </span>
        <span className="flex min-w-0 flex-col">
          <span className="text-xs font-bold">{copy.pushTitle}</span>
          <span className="text-xs leading-snug text-muted">{copy.push}</span>
        </span>
      </div>
      <div className="mx-4 mt-16 rounded-lg bg-surface p-4 shadow-soft">
        <p className="m-0 text-sm font-bold">{copy.route}</p>
        <ol className="m-0 mt-4 flex list-none flex-col gap-0 p-0">
          {copy.stages.map((stage, i) => (
            <li key={stage} className="relative flex items-center gap-3 pb-4 last:pb-0">
              {i < copy.stages.length - 1 && <span className="absolute left-[11px] top-6 h-[calc(100%-1rem)] w-0.5 rounded-xs bg-ok/40" />}
              <span className={`grid size-6 shrink-0 place-items-center rounded-xs ${i === 2 ? "day-approve bg-ok text-white" : "bg-ok-bg text-ok"}`}>
                <Icon icon={Tick02Icon} size={14} />
              </span>
              <span className={`text-sm ${i === 2 ? "font-bold text-ok" : "text-muted"}`}>{stage}</span>
            </li>
          ))}
        </ol>
      </div>
      <div className="mx-4 mt-3 flex flex-col gap-2 rounded-lg bg-surface p-4 text-xs shadow-soft">
        <p className="m-0 flex items-center justify-between gap-2">
          <span className="text-muted">{copy.semester}</span>
        </p>
        <p className="m-0 flex items-center gap-2 font-semibold">
          <span className="grid size-6 place-items-center rounded-xs bg-surface-2 text-muted">
            <Icon icon={Invoice01Icon} size={14} />
          </span>
          {copy.receipt}
        </p>
      </div>
    </>
  );
}

/** A code-like pattern: fixed (never a real code), with the three corner squares a scanner looks for. */
export function FakeCode() {
  const cells: ReactNode[] = [];
  let seed = 7;
  for (let y = 0; y < 21; y++) {
    for (let x = 0; x < 21; x++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      const corner = (x < 8 && y < 8) || (x > 12 && y < 8) || (x < 8 && y > 12);
      if (!corner && seed % 100 < 46) cells.push(<rect key={`${x}-${y}`} x={x} y={y} width="1" height="1" rx="0.2" />);
    }
  }
  const finder = (x: number, y: number) => (
    <g key={`f${x}${y}`}>
      <rect x={x + 0.5} y={y + 0.5} width="6" height="6" rx="1.4" fill="none" stroke="currentColor" strokeWidth="1" />
      <rect x={x + 2} y={y + 2} width="3" height="3" rx="0.7" />
    </g>
  );
  return (
    <svg viewBox="0 0 21 21" className="size-full" fill="currentColor">
      {cells}
      {finder(0, 0)}
      {finder(14, 0)}
      {finder(0, 14)}
    </svg>
  );
}

/** 7:05: the pass, and a note that it works without a signal. */
function PassScreen({ copy }: { copy: Copy["pass"] }) {
  return (
    <>
      <Header label={copy.label} />
      <div className="mx-4 rounded-lg bg-brand p-4 text-on-brand shadow-soft">
        <p className="m-0 text-sm font-bold">{copy.name}</p>
        <p className="m-0 text-xs opacity-75">{copy.valid}</p>
        <div className="mt-3 rounded-md bg-white p-3 text-[#0b1a1f]">
          <FakeCode />
        </div>
      </div>
      <p className="mx-4 mt-3 flex w-fit items-center gap-2 rounded-xs bg-ok-bg px-2.5 py-1.5 text-xs font-semibold text-ok">
        <Icon icon={WifiOff01Icon} size={14} />
        {copy.offline}
      </p>
      <p className="mx-4 mt-3 flex items-center gap-2 rounded-md bg-surface p-3 text-xs font-semibold shadow-soft">
        <span className="grid size-7 place-items-center rounded-xs bg-accent/15 text-accent">
          <Icon icon={Bus01Icon} size={15} />
        </span>
        {copy.stop}
      </p>
    </>
  );
}

/** 7:22: a small map, the route, the bus moving along it towards the student's stop. */
function LiveScreen({ copy }: { copy: Copy["live"] }) {
  const route = "M30 330C40 270 120 260 130 210C140 160 60 150 70 100C78 62 130 50 170 40";
  return (
    <>
      <Header label={copy.label} />
      <div className="relative mx-4 h-[27rem] overflow-hidden rounded-lg bg-surface-2">
        <svg viewBox="0 0 200 360" className="absolute inset-0 size-full" preserveAspectRatio="xMidYMid slice">
          <g className="stroke-line" strokeWidth="10" fill="none" strokeLinecap="round">
            <path d="M-10 120H210M-10 250H210M60 -10V370M150 -10V370" />
          </g>
          <path d={route} fill="none" className="stroke-accent" strokeWidth="5" strokeLinecap="round" strokeDasharray="1 9" />
          <path d={route} fill="none" className="stroke-accent" strokeWidth="5" strokeLinecap="round" pathLength="1" strokeDasharray="0.55 1" />
          {[
            [30, 330],
            [130, 210],
            [170, 40],
          ].map(([x, y], i) => (
            <circle key={i} cx={x} cy={y} r={i === 1 ? 8 : 6} className={i === 1 ? "fill-ok stroke-surface" : "fill-fg stroke-surface"} strokeWidth="3" />
          ))}
        </svg>
        <div
          className="day-bus absolute left-0 top-0 grid size-8 place-items-center rounded-xs bg-accent text-[11px] font-black text-on-accent shadow-float"
          style={{ offsetPath: `path("${route}")` }}
        >
          2
        </div>
        <p className="absolute left-3 top-3 m-0 rounded-xs bg-surface px-2.5 py-1.5 text-xs font-bold shadow-soft">
          {copy.bus} <span className="text-ok">{copy.eta}</span>
        </p>
        <ul className="absolute bottom-3 right-3 m-0 flex list-none flex-col gap-1 p-0 text-right text-[11px] text-muted">
          {copy.stops.map((s, i) => (
            <li key={s} className={i === 1 ? "font-bold text-ok" : ""}>
              {s}
            </li>
          ))}
        </ul>
      </div>
    </>
  );
}

/** 7:31: the scan at the door went through. */
function BoardScreen({ copy }: { copy: Copy["board"] }) {
  return (
    <>
      <Header label={copy.label} />
      <div className="flex flex-col items-center px-6 pt-10 text-center">
        <span className="day-tick grid size-28 place-items-center rounded-[36px] bg-ok text-white shadow-float">
          <Icon icon={CheckmarkCircle02Icon} size={56} />
        </span>
        <p className="m-0 mt-6 text-2xl font-extrabold tracking-tight">{copy.done}</p>
        <p className="m-0 mt-1 text-sm text-muted">{copy.hello}</p>
        <p className="m-0 mt-5 rounded-xs bg-surface-2 px-3 py-1.5 text-xs font-semibold">{copy.seat}</p>
        <p className="m-0 mt-10 flex items-center gap-2 text-xs text-muted">
          <Icon icon={Location01Icon} size={14} />
          {copy.next}
        </p>
      </div>
    </>
  );
}

/** The four screens in order, one per step of the morning. */
export function DayScreen({ index, copy }: { index: number; copy: Copy }) {
  switch (index) {
    case 0:
      return <SubscriptionScreen copy={copy.sub} />;
    case 1:
      return <PassScreen copy={copy.pass} />;
    case 2:
      return <LiveScreen copy={copy.live} />;
    default:
      return <BoardScreen copy={copy.board} />;
  }
}
