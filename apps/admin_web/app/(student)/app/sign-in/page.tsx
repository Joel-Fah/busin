import type { Metadata } from "next";
import Image from "next/image";
import { redirect } from "next/navigation";
import { Suspense } from "react";

import { BrandMark } from "@/components/brand/BrandMark";
import { SignInPanel } from "@/components/student/SignInPanel";
import { getStudentCopy } from "@/lib/i18n/server";
import { getStudentProfile } from "@/lib/student/session";

export const metadata: Metadata = { title: "Sign in" };

// Depends on who is signed in, so it renders at request time.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[] }>;

const ERRORS = ["notAllowed", "failed", "cancelled"] as const;

export default function StudentSignInPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<main className="min-h-dvh bg-brand" aria-busy="true" />}>
      <SignIn searchParams={searchParams} />
    </Suspense>
  );
}

/**
 * The student web app's door, as on the phone: the night bus photo under a teal veil, the words and Google's button at
 * the bottom where a thumb reaches.
 */
async function SignIn({ searchParams }: { searchParams: SearchParams }) {
  if (await getStudentProfile()) redirect("/app");
  const { locale, s } = await getStudentCopy();
  const { error } = await searchParams;
  const key = ERRORS.find((k) => k === error);

  return (
    <main lang={locale} className="relative isolate flex min-h-dvh flex-col justify-end overflow-hidden bg-brand text-white">
      <Image src="/app/night-bus.webp" alt="" fill priority sizes="100vw" className="-z-10 object-cover object-[55%_65%]" />
      <div aria-hidden className="absolute inset-0 -z-10 bg-[linear-gradient(to_bottom,rgb(0_42_51/0.25),rgb(0_42_51/0.45)_40%,rgb(0_42_51/0.96)_82%)]" />
      <BrandMark className="absolute top-[max(1.5rem,env(safe-area-inset-top))] left-6 h-11 w-auto text-white" label="BusIn" />
      <div className="mx-auto flex w-full max-w-[640px] flex-col gap-4 px-6 pt-40 pb-[max(2.5rem,env(safe-area-inset-bottom))]">
        <h1 className="relative m-0 w-fit text-4xl leading-[1.1] font-extrabold tracking-tight text-balance">
          <span aria-hidden className="texture-rough absolute inset-x-[-0.1em] bottom-[0.05em] h-[0.35em] rounded-xs bg-accent/70" />
          <span className="relative">{s.signIn.title}</span>
        </h1>
        <p className="m-0 text-lg leading-relaxed text-white/85">{s.signIn.subtitle}</p>
        <div className="mt-4">
          <SignInPanel copy={s.signIn} locale={locale} initialError={key ? s.signIn[key] : null} />
        </div>
      </div>
    </main>
  );
}
