import { InformationCircleIcon } from "@hugeicons/core-free-icons";

import { Icon } from "@/components/ui/Icon";
import { LEVEL_KEYS, signalSentence, signalValue, thresholdsText, type HealthCopy, type Signal } from "@/lib/platform-health";

import { LevelChip } from "./LevelChip";

type Props = {
  signal: Signal;
  copy: HealthCopy;
  locale: string;
  levels: { ok: string; watch: string; needsHelp: string; critical: string; off: string };
  /** The date the signal is paused until, when a contact paused it. */
  pausedUntil?: string;
};

const RING = ["", "ring-1 ring-info/40", "ring-1 ring-warn/50", "ring-2 ring-bad/50"] as const;

/**
 * One signal on a school's page: its short name, its value in large type, its level, and what is missing when it is a
 * list. The sentence and the thresholds sit behind the information button (a tip), so the page reads at a glance.
 */
export function SignalTile({ signal, copy, locale, levels, pausedUntil }: Props) {
  const measured = signal.value !== null;
  const items = signal.detail.map((key) => copy.items[key] ?? key);
  const tip = `${signalSentence(signal, copy, locale)}. ${thresholdsText(signal, copy, locale)}.`;
  return (
    <li
      data-testid={`signal-${signal.signal}`}
      data-level={LEVEL_KEYS[measured ? signal.level : 0]}
      className={`flex min-w-0 flex-col gap-2 rounded-md p-4 ${measured ? `bg-surface-2/70 ${RING[signal.level]}` : "bg-surface-2/35"}`}
    >
      <div className="flex items-start justify-between gap-2">
        <p className="m-0 text-sm font-semibold text-muted">{copy.signals[signal.signal].short}</p>
        <button
          type="button"
          data-tip={tip}
          aria-label={tip}
          className="-m-1 grid size-7 shrink-0 cursor-help place-items-center rounded-xs border-0 bg-transparent p-0 text-muted hover:text-fg focus-visible:outline-3 focus-visible:outline-focus"
        >
          <Icon icon={InformationCircleIcon} size={16} />
        </button>
      </div>
      <p className={`m-0 font-extrabold tracking-tight tabular-nums ${measured ? "text-2xl" : "text-base text-muted"}`}>{signalValue(signal, copy, locale)}</p>
      {items.length > 0 ? (
        <ul className="m-0 flex list-none flex-wrap gap-1 p-0">
          {items.map((item) => (
            <li key={item} className="rounded-xs bg-surface px-2 py-0.5 text-xs">
              {item}
            </li>
          ))}
        </ul>
      ) : null}
      <div className="mt-auto flex flex-wrap items-center gap-1.5">
        {measured ? <LevelChip level={signal.level} labels={levels} /> : null}
        {signal.graced ? <span className="text-xs text-muted">{copy.gracedShort}</span> : null}
        {pausedUntil ? (
          <span className="text-xs font-semibold text-muted" data-testid="signal-paused">
            {copy.pausedShort} · {pausedUntil}
          </span>
        ) : null}
      </div>
    </li>
  );
}
