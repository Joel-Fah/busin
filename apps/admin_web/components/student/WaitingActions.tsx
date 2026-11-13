"use client";

import { useActionState } from "react";

import { Button } from "@/components/ui/Button";
import { Notice } from "@/components/ui/Notice";
import type { StudentCopy } from "@/lib/i18n/student";
import { checkAgain, withdrawRequest, type JoinState } from "@/lib/student/onboarding";

/** Check again (the server decides where the student belongs now) or withdraw to choose another school. */
export function WaitingActions({ copy, errors }: { copy: StudentCopy["waiting"]; errors: StudentCopy["join"] }) {
  const [state, withdraw, pending] = useActionState<JoinState, FormData>(withdrawRequest, { error: null });
  return (
    <div className="flex flex-col gap-3">
      {state.error ? <Notice tone="bad">{errors[state.error]}</Notice> : null}
      <form action={checkAgain}>
        <Button type="submit" className="w-full">
          {copy.check}
        </Button>
      </form>
      <form action={withdraw}>
        <Button type="submit" variant="secondary" className="w-full" disabled={pending}>
          {copy.change}
        </Button>
      </form>
    </div>
  );
}
