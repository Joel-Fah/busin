"use client";

import type { IconSvgElement } from "@hugeicons/react";
import { useActionState, type ReactNode } from "react";

import { ReasonField, type ReasonFieldText } from "@/components/ReasonField";
import { Button } from "@/components/ui/Button";

/** What a reason action answers when it did not go through: which problem, and the text typed, to put back. */
export type ReasonFormState = { error: string; text: string } | null;

type Props = {
  action: (previous: ReasonFormState, formData: FormData) => Promise<ReasonFormState>;
  /** Fields the action needs, such as the subscription's id. */
  hidden: Record<string, string>;
  idPrefix: string;
  text: ReasonFieldText;
  presets: readonly string[];
  max: number;
  required?: boolean;
  /** Words for every problem the action can answer with; "generic" is the fallback. */
  errors: Record<string, string>;
  submit: { label: string; icon: IconSvgElement; variant?: "primary" | "danger" };
  /** A sentence above the field. */
  intro?: ReactNode;
};

/**
 * A form that asks for a reason and keeps what was typed when the server refuses it, with the problem said in words
 * under the field instead of a banner after a reload. Success is the action redirecting to the page's own message.
 */
export function ReasonForm({ action, hidden, idPrefix, text, presets, max, required = true, errors, submit, intro }: Props) {
  const [state, formAction, pending] = useActionState(action, null);
  return (
    <form action={formAction} className="mt-4 flex flex-col gap-4">
      {Object.entries(hidden).map(([name, value]) => (
        <input key={name} type="hidden" name={name} value={value} />
      ))}
      {intro}
      {/* A new answer from the server puts the typed text back in a fresh field. */}
      <ReasonField
        key={state ? `${state.error}:${state.text}` : "new"}
        id={`${idPrefix}-note`}
        name="note"
        text={text}
        presets={presets}
        max={max}
        required={required}
        defaultValue={state?.text ?? ""}
        error={state ? (errors[state.error] ?? errors.generic) : undefined}
      />
      <div>
        <Button type="submit" variant={submit.variant ?? "primary"} icon={submit.icon} disabled={pending}>
          {submit.label}
        </Button>
      </div>
    </form>
  );
}
