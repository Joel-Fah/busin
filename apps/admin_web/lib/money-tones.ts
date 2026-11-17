// The state colours of money on the payment dashboards (ADR 0029): money coming in is good (ok), money going out is bad,
// money waiting or owed is a warning, payouts are information; a figure that can go either way (a margin) takes the
// colour of its sign. A trend compares this month with the last and is coloured by whether going up is good for that
// figure. Colour is never the only sign: every coloured figure keeps its words, and a trend carries an arrow and words.

export type Tone = "ok" | "bad" | "warn" | "info" | "neutral";

/** A figure's colour: a fixed tone, or "signed" for one that is good above zero and bad below. */
export type ToneRule = Tone | "signed";

export function toneOf(rule: ToneRule, value: number): Tone {
  if (rule !== "signed") return rule;
  return value > 0 ? "ok" : value < 0 ? "bad" : "neutral";
}

/** Tailwind classes for each tone: text, a solid bar, a dot. */
export const TONE_TEXT: Record<Tone, string> = { ok: "text-ok", bad: "text-bad", warn: "text-warn", info: "text-info", neutral: "text-fg" };
export const TONE_BAR: Record<Tone, string> = {
  ok: "bg-ok",
  bad: "bg-bad",
  warn: "bg-warn",
  info: "bg-info",
  neutral: "bg-[color-mix(in_srgb,var(--fg)_30%,transparent)]",
};

export type Trend = { direction: "up" | "down" | "flat"; percent: number | null; tone: Tone };

/**
 * This month against the last. `goodWhenUp` says whether a rise is good news (money in, a margin) or bad (refunds,
 * costs). The percentage is null when last month was zero (a rise from nothing has no percentage); a change under half
 * a percent reads as flat.
 */
export function trend(current: number, previous: number, goodWhenUp = true): Trend {
  const diff = current - previous;
  const percent = previous === 0 ? null : Math.round((diff / Math.abs(previous)) * 100);
  const flat = diff === 0 || (percent !== null && Math.abs((diff / Math.abs(previous)) * 100) < 0.5);
  if (flat) return { direction: "flat", percent: 0, tone: "neutral" };
  const direction = diff > 0 ? "up" : "down";
  const good = (direction === "up") === goodWhenUp;
  return { direction, percent: percent === null ? null : Math.abs(percent), tone: good ? "ok" : "bad" };
}
