import { niceMax, type DayCount } from "@/lib/overview";

type Props = {
  days: readonly DayCount[];
  locale: string;
  /** Accessible name of the chart. */
  label: string;
  todayLabel: string;
  /** Builds the text for one bar, for screen readers and the hover tip. */
  barLabel: (day: string, n: number) => string;
};

const longDay = (iso: string, locale: string) =>
  new Intl.DateTimeFormat(locale, { weekday: "long", day: "numeric", month: "long", timeZone: "UTC" }).format(new Date(`${iso}T00:00:00Z`));

/**
 * Daily boardings as bars. Plain HTML so it scales with the tile and needs no script. The newest day is
 * the accent colour and also says "Today" in text, so meaning never rests on colour. The same figures are
 * available to screen readers as a list.
 */
export function BoardingsChart({ days, locale, label, todayLabel, barLabel }: Props) {
  const max = niceMax(Math.max(0, ...days.map((d) => d.boardings)));
  const last = days.length - 1;

  return (
    <figure className="m-0 flex flex-1 flex-col gap-2">
      <div role="img" aria-label={label} className="relative flex min-h-44 flex-1 gap-3">
        <div aria-hidden className="flex flex-col justify-between pb-6 text-[11px] font-semibold tabular-nums text-muted">
          <span>{max}</span>
          <span>{max / 2}</span>
          <span>0</span>
        </div>
        <div className="relative flex-1">
          <div aria-hidden className="absolute inset-x-0 top-0 bottom-6 flex flex-col justify-between">
            {[0, 1, 2].map((line) => (
              <span key={line} className="block h-px bg-line" />
            ))}
          </div>
          <div className="absolute inset-0 flex items-stretch gap-1 sm:gap-1.5">
            {days.map((d, index) => {
              const height = d.boardings === 0 ? 0 : Math.max(3, (d.boardings / max) * 100);
              const isToday = index === last;
              return (
                <div key={d.day} className="group flex min-w-0 flex-1 flex-col" title={barLabel(longDay(d.day, locale), d.boardings)}>
                  <div className="flex flex-1 items-end pb-0.5">
                    <span
                      aria-hidden
                      className={
                        "block w-full rounded-t-xs transition-opacity duration-(--dur-fast) " +
                        (isToday ? "bg-accent" : "bg-[color-mix(in_srgb,var(--fg)_26%,transparent)] group-hover:bg-[color-mix(in_srgb,var(--fg)_44%,transparent)]")
                      }
                      style={{ height: `${height}%` }}
                    />
                  </div>
                  <span
                    aria-hidden
                    className={`flex h-6 items-end justify-center text-[11px] tabular-nums ${isToday ? "font-bold text-fg" : "font-medium text-muted"}`}
                  >
                    {Number(d.day.slice(8))}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
      <figcaption className="sr-only">
        <ul>
          {days.map((d, index) => (
            <li key={d.day}>
              {barLabel(longDay(d.day, locale), d.boardings)}
              {index === last ? ` (${todayLabel})` : ""}
            </li>
          ))}
        </ul>
      </figcaption>
    </figure>
  );
}
