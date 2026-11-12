import type { ReactNode } from "react";

const TONES = {
  ok: "bg-ok-bg text-ok font-semibold",
  bad: "bg-bad-bg text-bad",
  warn: "bg-warn-bg text-warn",
  info: "bg-info-bg text-info",
} as const;

/** A short message in a tone. Errors are announced at once (role alert); successes politely (role status). */
export function Notice({ tone, children, className = "" }: { tone: keyof typeof TONES; children: ReactNode; className?: string }) {
  return (
    <p role={tone === "bad" ? "alert" : "status"} className={`rounded-md px-5 py-4 text-sm ${TONES[tone]} ${className}`}>
      {children}
    </p>
  );
}
