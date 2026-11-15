import { LEVEL_TONES, signalSentence, signalValue, type HealthCopy, type Signal } from "@/lib/platform-health";

const TONE_CLASSES = {
  ok: "bg-ok-bg text-ok",
  info: "bg-info-bg text-info",
  warn: "bg-warn-bg text-warn",
  bad: "bg-bad-bg text-bad",
} as const;

/**
 * One signal in a few words, "Answer time 4.6 days", in its level's tone. The full sentence shows as a tip on hover and
 * keyboard focus. Used where space is short: the schools list and "Needs you".
 */
export function SignalChip({ signal, copy, locale, paused = false }: { signal: Signal; copy: HealthCopy; locale: string; paused?: boolean }) {
  const tone = TONE_CLASSES[LEVEL_TONES[signal.level]];
  return (
    <span
      tabIndex={0}
      data-tip={signalSentence(signal, copy, locale)}
      data-signal={signal.signal}
      className={`inline-flex max-w-full items-center gap-1.5 rounded-xs px-2.5 py-1 text-xs font-semibold focus-visible:outline-3 focus-visible:outline-focus ${paused ? "bg-surface-2 text-muted" : tone}`}
    >
      <span className="truncate">{copy.signals[signal.signal].short}</span>
      <span className="shrink-0 font-extrabold tabular-nums">{signalValue(signal, copy, locale)}</span>
    </span>
  );
}
