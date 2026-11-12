import { redirect } from "next/navigation";
import { Suspense } from "react";

import { AuthShell } from "@/components/AuthShell";

import { LanguageSwitch } from "@/components/LanguageSwitch";
import { SignOutButton } from "@/components/SignOutButton";
import { decideAccess } from "@/lib/access";
import { getCurrentUser } from "@/lib/auth";
import { format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";

// These routes depend on who is signed in and redirect visitors who are not, so Next's
// "instant navigation" check cannot apply. Their user-specific parts stream behind <Suspense>.
export const instant = false;

export default function NoAccessPage() {
  return (
    <Suspense fallback={<main className="grid min-h-dvh place-items-center" aria-busy="true" />}>
      <NoAccessContent />
    </Suspense>
  );
}

async function NoAccessContent() {
  const current = await getCurrentUser();
  if (!current) redirect("/login");
  if (decideAccess(current.profile) === "admin") redirect("/");

  const { locale, t } = await getMessages();
  const email = current.profile?.email ?? current.user.email ?? "";

  return (
    <AuthShell lang={locale} title={t.noAccess.title}>
      <p className="text-muted">{t.noAccess.body}</p>
      <p className="text-sm">{format(t.noAccess.signedInAs, { email })}</p>
      <div>
        <SignOutButton label={t.noAccess.signOut} />
      </div>
      <LanguageSwitch locale={locale} t={t} />
    </AuthShell>
  );
}
