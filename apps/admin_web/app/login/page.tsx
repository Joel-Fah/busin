import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";
import { Login03Icon } from "@hugeicons/core-free-icons";

import { AuthShell } from "@/components/AuthShell";
import { Button } from "@/components/ui/Button";
import { Notice } from "@/components/ui/Notice";

import { LanguageSwitch } from "@/components/LanguageSwitch";
import { getCurrentUser } from "@/lib/auth";
import { signInWithGoogle } from "@/lib/auth-actions";
import { devLoginAllowed } from "@/lib/dev-login";
import { getMessages } from "@/lib/i18n/server";

// These routes depend on who is signed in and redirect visitors who are not, so Next's
// "instant navigation" check cannot apply. Their user-specific parts stream behind <Suspense>.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[] }>;

export default function LoginPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<main className="grid min-h-dvh place-items-center" aria-busy="true" />}>
      <LoginContent searchParams={searchParams} />
    </Suspense>
  );
}

async function LoginContent({ searchParams }: { searchParams: SearchParams }) {
  const current = await getCurrentUser();
  if (current) redirect("/");

  const { error } = await searchParams;
  const { locale, t } = await getMessages();
  const errorKey = typeof error === "string" ? error : undefined;
  const errorText = errorKey
    ? (t.login.errors[errorKey as keyof typeof t.login.errors] ?? t.login.errors.generic)
    : null;

  return (
    <AuthShell lang={locale} title={t.login.title}>
      <p className="text-muted">{t.login.hint}</p>
      {errorText ? <Notice tone="bad">{errorText}</Notice> : null}
      <form action={signInWithGoogle}>
        <Button type="submit" icon={Login03Icon} className="w-full">
          {t.login.button}
        </Button>
      </form>
      {devLoginAllowed() ? (
        <Link href="/dev/login" className="text-sm font-semibold text-muted no-underline hover:text-fg">
          {t.devLogin.link}
        </Link>
      ) : null}
      <LanguageSwitch locale={locale} t={t} />
    </AuthShell>
  );
}
