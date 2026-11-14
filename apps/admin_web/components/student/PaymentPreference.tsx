"use client";

import { useState, useTransition } from "react";

import { Contour } from "@/components/ui/Contour";
import { useToast } from "@/components/ui/Toast";
import type { StudentCopy } from "@/lib/i18n/student";
import { setPaymentPreference } from "@/lib/student/settings";

type Mode = "full" | "installments";

/** How the student prefers to pay (ADR 0022), as the app's segmented choice. Saved at once. */
export function PaymentPreference({ copy, labels, current }: { copy: StudentCopy["me"]["payment"]; labels: { full: string; installments: string; failed: string }; current: Mode | null }) {
  const toast = useToast();
  const [value, setValue] = useState<Mode | null>(current);
  const [pending, start] = useTransition();

  const choose = (mode: Mode) => {
    if (mode === value || pending) return;
    const before = value;
    setValue(mode);
    start(async () => {
      if (await setPaymentPreference(mode)) toast(copy.saved, { tone: "ok" });
      else {
        setValue(before);
        toast(labels.failed, { tone: "bad" });
      }
    });
  };

  return (
    <section className="relative flex flex-col gap-3 rounded-lg bg-surface p-5 shadow-soft">
      <Contour radius={28} inset={10} />
      <div role="radiogroup" aria-label={copy.title} className="grid grid-cols-2 gap-1 rounded-md bg-surface-2 p-1">
        {(["full", "installments"] as const).map((mode) => (
          <button
            key={mode}
            type="button"
            role="radio"
            aria-checked={value === mode}
            onClick={() => choose(mode)}
            className={
              "min-h-11 cursor-pointer rounded-sm border-0 px-3 font-sans text-sm font-semibold text-fg transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus " +
              (value === mode ? "bg-surface shadow-soft" : "bg-transparent text-muted hover:text-fg")
            }
          >
            {labels[mode]}
          </button>
        ))}
      </div>
      {value === null ? <p className="m-0 text-sm text-muted">{copy.none}</p> : null}
    </section>
  );
}
