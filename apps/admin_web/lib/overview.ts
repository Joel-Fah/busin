/** Pure helpers for the overview tiles: chart scaling, week-on-week change, shares and ages. */

export type DayCount = { day: string; boardings: number };

/** A round upper bound for a chart axis, so the tallest bar never touches the top. At least 4. */
export function niceMax(value: number): number {
  if (!Number.isFinite(value) || value <= 4) return 4;
  const magnitude = 10 ** Math.floor(Math.log10(value));
  for (const step of [1, 2, 2.5, 5, 10]) {
    if (step * magnitude >= value) return step * magnitude;
  }
  return 10 * magnitude;
}

export type Trend = { current: number; previous: number; change: number | null };

/**
 * The last seven days against the seven before them. `change` is a whole percent, or null when
 * there is nothing earlier to compare with (a percentage of zero means nothing).
 */
export function weekTrend(days: readonly DayCount[]): Trend {
  const sum = (items: readonly DayCount[]) => items.reduce((total, d) => total + d.boardings, 0);
  const current = sum(days.slice(-7));
  const previous = sum(days.slice(-14, -7));
  return { current, previous, change: previous === 0 ? null : Math.round(((current - previous) / previous) * 100) };
}

/**
 * Shares of a whole as whole percents that add up to exactly 100 (largest remainder), so a stacked
 * bar and its legend never disagree. An empty whole gives all zeros.
 */
export function shares(counts: readonly number[]): number[] {
  const total = counts.reduce((a, b) => a + b, 0);
  if (total === 0) return counts.map(() => 0);
  const exact = counts.map((c) => (c / total) * 100);
  const floors = exact.map(Math.floor);
  let left = 100 - floors.reduce((a, b) => a + b, 0);
  const order = exact.map((value, index) => ({ index, rest: value - Math.floor(value) })).sort((a, b) => b.rest - a.rest);
  for (const { index } of order) {
    if (left <= 0) break;
    floors[index] += 1;
    left -= 1;
  }
  return floors;
}

/** How long something has waited: whole hours under two days, whole days after. */
export function waitingAge(since: string, now: Date): { unit: "hours" | "days"; value: number } {
  const hours = Math.max(0, Math.floor((now.getTime() - new Date(since).getTime()) / 3_600_000));
  return hours < 48 ? { unit: "hours", value: hours } : { unit: "days", value: Math.floor(hours / 24) };
}

/** Where `today` falls in a semester, as a day number and a share, clamped to the semester's span. Dates are YYYY-MM-DD. */
export function semesterProgress(start: string, end: string, today: string): { day: number; total: number; percent: number } {
  const ms = (iso: string) => Date.parse(`${iso}T00:00:00Z`);
  const total = Math.max(1, Math.round((ms(end) - ms(start)) / 86_400_000) + 1);
  const day = Math.min(total, Math.max(1, Math.round((ms(today) - ms(start)) / 86_400_000) + 1));
  return { day, total, percent: Math.round((day / total) * 100) };
}
