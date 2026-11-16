import { LEVEL_KEYS, type Level } from "@/lib/platform-health";

type Props = {
  history: { day: string; level: Level; score: number }[];
  locale: string;
  label: string;
  levels: Record<(typeof LEVEL_KEYS)[number], string>;
  /** "{day}: {level}, score {score}" */
  dayLabel: (day: string, level: string, score: number) => string;
};

const BAR = ["bg-ok", "bg-info", "bg-warn", "bg-bad"] as const;

const shortDay = (iso: string, locale: string) =>
  new Intl.DateTimeFormat(locale, { day: "numeric", month: "short", timeZone: "UTC" }).format(new Date(`${iso}T00:00:00Z`));

/**
 * A school's score each night over the last 30 days: one bar per day, as tall as the score and in its level's colour.
 * Every bar has its day, level and score as a tip and for screen readers (a list), so colour is never the only cue.
 */
export function HealthTrend({ history, locale, label, levels, dayLabel }: Props) {
  return (
    <figure className="m-0">
      <ul aria-label={label} className="m-0 flex h-36 list-none items-end gap-1 p-0">
        {history.map((h) => {
          const text = dayLabel(shortDay(h.day, locale), levels[LEVEL_KEYS[h.level]], h.score);
          return (
            <li key={h.day} className="flex h-full min-w-1.5 flex-1 items-end" data-tip={text}>
              <span className="sr-only">{text}</span>
              <span aria-hidden className={`block w-full rounded-t-xs ${BAR[h.level]}`} style={{ height: `${Math.max(4, h.score)}%` }} />
            </li>
          );
        })}
      </ul>
      {history.length > 0 ? (
        <figcaption aria-hidden className="mt-2 flex justify-between text-xs text-muted tabular-nums">
          <span>{shortDay(history[0].day, locale)}</span>
          <span>{shortDay(history[history.length - 1].day, locale)}</span>
        </figcaption>
      ) : null}
    </figure>
  );
}
