import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { AuthShell } from "@/components/AuthShell";
import { SignOutForm } from "@/components/student/SignOutForm";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireGate } from "@/lib/student/session";

export const metadata: Metadata = { title: "No access" };
export const instant = false;

export default function BlockedPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh bg-bg" aria-busy="true" />}>
      <Blocked />
    </Suspense>
  );
}

/** A staff, administrator or suspended account, told why (the student app's blocked screen). */
async function Blocked() {
  const { access, profile } = await requireGate("blocked");
  const { locale, s } = await getStudentCopy();
  const staff = access.kind === "blocked" && access.reason === "notStudent";
  return (
    <AuthShell lang={locale} title={staff ? s.blocked.staffTitle : s.blocked.suspendedTitle}>
      <p className="m-0 text-muted">{staff ? s.blocked.staffBody : s.blocked.suspendedBody}</p>
      <p className="m-0 text-sm">{profile.email}</p>
      <div className="flex flex-wrap gap-3">
        {staff && profile.role === "admin" ? (
          <Link href="/" className="inline-flex h-11 items-center rounded-sm px-4 font-semibold text-link no-underline hover:bg-surface-2">
            {s.blocked.portal}
          </Link>
        ) : null}
        <SignOutForm label={s.profile.signOut} />
      </div>
    </AuthShell>
  );
}
