"use client";

import { useState, useTransition, type FormEvent } from "react";

import type { PaymentActionState } from "@/lib/payments";

/**
 * Sends a form to a server action without letting React clear the form afterwards, so what was typed stays when the
 * server answers with a problem. `state` is the action's last answer.
 */
export function useFormAction(
  action: (previous: PaymentActionState, formData: FormData) => Promise<PaymentActionState>,
  /** Called with each answer, for what follows it (a toast, closing a sheet). */
  onAnswer?: (state: PaymentActionState) => void,
) {
  const [state, setState] = useState<PaymentActionState>(null);
  const [pending, start] = useTransition();
  const onSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    start(async () => {
      const answer = await action(null, data);
      setState(answer);
      onAnswer?.(answer);
    });
  };
  return { state, pending, onSubmit, reset: () => setState(null) };
}
