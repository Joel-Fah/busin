import Image from "next/image";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Suspense } from "react";

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
    <Suspense fallback={<main className="center" aria-busy="true" />}>
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
    <main className="center" lang={locale}>
      <div className="card">
        <Image src="/brand/cyan.svg" alt={t.appName} width={205} height={126} className="logo" priority />
        <h1>{t.login.title}</h1>
        <p>{t.login.hint}</p>
        {errorText ? (
          <p className="notice" role="alert">
            {errorText}
          </p>
        ) : null}
        <form action={signInWithGoogle}>
          <button type="submit" className="btn btn-primary">
            {t.login.button}
          </button>
        </form>
        {devLoginAllowed() ? (
          <p>
            <Link href="/dev/login">{t.devLogin.link}</Link>
          </p>
        ) : null}
        <LanguageSwitch locale={locale} t={t} />
      </div>
    </main>
  );
}
