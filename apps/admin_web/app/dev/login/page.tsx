import { notFound } from "next/navigation";
import { Suspense } from "react";
import { LockPasswordIcon, Mail01Icon } from "@hugeicons/core-free-icons";

import { AuthShell } from "@/components/AuthShell";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Notice } from "@/components/ui/Notice";

import { devLoginAllowed } from "@/lib/dev-login";
import { getMessages } from "@/lib/i18n/server";

import { signInWithPassword } from "./actions";

// Depends on the runtime environment and on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[] }>;

export default function DevLoginPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<main className="grid min-h-dvh place-items-center" aria-busy="true" />}>
      <DevLoginContent searchParams={searchParams} />
    </Suspense>
  );
}

async function DevLoginContent({ searchParams }: { searchParams: SearchParams }) {
  // Not found everywhere except a development server with a local backend.
  if (!devLoginAllowed()) notFound();

  const { error } = await searchParams;
  const { locale, t } = await getMessages();

  return (
    <AuthShell lang={locale} title={t.devLogin.title}>
      <p role="note" className="rounded-md bg-warn-bg px-4 py-3 text-sm font-semibold text-warn">
        {t.devLogin.warning}
      </p>
      <p className="text-sm text-muted">{t.devLogin.hint}</p>
      {error ? <Notice tone="bad">{t.devLogin.error}</Notice> : null}
      <form action={signInWithPassword} className="flex flex-col gap-4">
        <Input id="email" name="email" type="email" label={t.devLogin.email} icon={Mail01Icon} autoComplete="username" required />
        <Input id="password" name="password" type="password" label={t.devLogin.password} icon={LockPasswordIcon} autoComplete="current-password" required />
        <div>
          <Button type="submit">{t.devLogin.button}</Button>
        </div>
      </form>
    </AuthShell>
  );
}
