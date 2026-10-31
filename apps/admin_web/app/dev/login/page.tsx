import Image from "next/image";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { devLoginAllowed } from "@/lib/dev-login";
import { getMessages } from "@/lib/i18n/server";

import { signInWithPassword } from "./actions";
import styles from "./page.module.css";

// Depends on the runtime environment and on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[] }>;

export default function DevLoginPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<main className="center" aria-busy="true" />}>
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
    <main className="center" lang={locale}>
      <div className="card">
        <Image src="/brand/cyan.svg" alt={t.appName} width={205} height={126} className="logo" />
        <h1>{t.devLogin.title}</h1>
        <p className={styles.warning} role="note">
          {t.devLogin.warning}
        </p>
        <p>{t.devLogin.hint}</p>
        {error ? (
          <p className="notice" role="alert">
            {t.devLogin.error}
          </p>
        ) : null}
        <form action={signInWithPassword} className="stack">
          <div className={styles.field}>
            <label htmlFor="email">{t.devLogin.email}</label>
            <input id="email" name="email" type="email" autoComplete="username" required />
          </div>
          <div className={styles.field}>
            <label htmlFor="password">{t.devLogin.password}</label>
            <input id="password" name="password" type="password" autoComplete="current-password" required />
          </div>
          <div className="row">
            <button type="submit" className="btn btn-primary">
              {t.devLogin.button}
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}
