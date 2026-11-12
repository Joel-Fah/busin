import type { ReactNode } from "react";
import type { IconSvgElement } from "@hugeicons/react";

import { Icon } from "./Icon";

export type ChipTone = "neutral" | "accent" | "ok" | "warn" | "bad" | "info";

const TONES: Record<ChipTone, string> = {
  neutral: "bg-surface-2 text-muted",
  accent: "bg-[color-mix(in_srgb,var(--accent)_24%,transparent)] text-fg",
  ok: "bg-ok-bg text-ok",
  warn: "bg-warn-bg text-warn",
  bad: "bg-bad-bg text-bad",
  info: "bg-info-bg text-info",
};

type Props = {
  tone?: ChipTone;
  /** State is never colour alone: pair the tone with an icon or a clear label. */
  icon?: IconSvgElement;
  children: ReactNode;
};

export function Chip({ tone = "neutral", icon, children }: Props) {
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-xs px-2.5 py-1 text-xs font-semibold ${TONES[tone]}`}>
      {icon ? <Icon icon={icon} size={14} /> : null}
      {children}
    </span>
  );
}
