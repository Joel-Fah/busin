import { ArrowDownRight01Icon, ArrowUpRight01Icon, MinusSignIcon } from "@hugeicons/core-free-icons";

import { TONE_TEXT, type Trend } from "@/lib/money-tones";

import { Icon } from "./Icon";

/**
 * This month against the last, in its state colour with an arrow and words, so the colour is never the only sign:
 * "Up 20% on last month", or "Was 0 last month" when there is no percentage (the arrow gives the direction). The words
 * come from the page's copy.
 */
export function TrendChip({ trend, words, testId }: { trend: Trend; words: { up: string; down: string; flat: string; fromNothing: string }; testId?: string }) {
  const icon = trend.direction === "up" ? ArrowUpRight01Icon : trend.direction === "down" ? ArrowDownRight01Icon : MinusSignIcon;
  const text =
    trend.direction === "flat"
      ? words.flat
      : trend.percent === null
        ? words.fromNothing
        : (trend.direction === "up" ? words.up : words.down).replace("{percent}", String(trend.percent));
  return (
    <span data-testid={testId} data-tone={trend.tone} className={`inline-flex items-center gap-1 text-xs font-semibold ${TONE_TEXT[trend.tone]}`}>
      <Icon icon={icon} size={14} />
      {text}
    </span>
  );
}
