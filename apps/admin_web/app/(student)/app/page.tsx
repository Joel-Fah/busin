import { redirect } from "next/navigation";
import { Suspense } from "react";

import { GATE_PATHS } from "@/lib/student/access";
import { currentAccess } from "@/lib/student/session";

// Depends on who is signed in.
export const instant = false;

export default function StudentStart() {
  return (
    <Suspense fallback={<main className="min-h-dvh bg-bg" aria-busy="true" />}>
      <Start />
    </Suspense>
  );
}

/** Where the app opens: the person's gate if they have one, else their subscription. */
async function Start(): Promise<never> {
  const { access } = await currentAccess();
  redirect(access.kind === "allowed" ? "/app/subscription" : GATE_PATHS[access.kind]);
}
