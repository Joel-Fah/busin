import { ArrowLeft01Icon } from "@hugeicons/core-free-icons";
import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { BrandMark } from "@/components/brand/BrandMark";
import { DeletionRequestForm } from "@/components/landing/DeletionRequestForm";
import { InterestProvider } from "@/components/landing/interest/Interest";
import { LandingFooter } from "@/components/landing/LandingFooter";
import "@/components/landing/landing.css";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import { RoughFilter } from "@/components/ui/RoughFilter";
import { deletionCatalogues } from "@/lib/i18n/account-deletion";
import { landingCatalogues } from "@/lib/i18n/landing";
import { getMessages } from "@/lib/i18n/server";
import { siteUrl } from "@/lib/landing/site";

import { requestDeletionByEmail } from "./actions";

// Depends on the visitor's language (a cookie), so it is rendered per request.
export const instant = false;

export async function generateMetadata(): Promise<Metadata> {
  const { locale } = await getMessages();
  const copy = deletionCatalogues[locale].page;
  return {
    metadataBase: new URL(siteUrl()),
    title: { absolute: `${copy.title}: BusIn` },
    description: copy.meta,
    alternates: { canonical: "/delete-account" },
    robots: { index: true, follow: true },
  };
}

export default function DeleteAccountPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <DeleteAccountInfo />
    </Suspense>
  );
}

/**
 * How to delete a BusIn account (ADR 0028): the steps in the apps, what is erased and what the school keeps, and a form for
 * someone who cannot sign in any more. Public, in English and French; this is the link given to Google Play.
 */
async function DeleteAccountInfo() {
  const { locale, t } = await getMessages();
  const all = landingCatalogues[locale];
  const d = deletionCatalogues[locale];
  const p = d.page;
  return (
    <InterestProvider copy={all.form} locale={locale}>
      <div lang={locale} className="relative min-h-dvh bg-bg text-fg">
        <RoughFilter />
        <main className="mx-auto max-w-[48rem] px-5 pt-12 pb-16 sm:px-8 sm:pt-16">
          <div className="flex items-center justify-between gap-4">
            <Link href="/" aria-label="BusIn" className="text-fg">
              <BrandMark className="h-10 w-auto" />
            </Link>
            <Link href="/" className="inline-flex items-center gap-1.5 text-sm font-semibold text-fg no-underline hover:text-accent">
              <Icon icon={ArrowLeft01Icon} size={16} />
              {p.back}
            </Link>
          </div>
          <h1 className="m-0 mt-14 text-5xl font-extrabold tracking-tight">{p.title}</h1>
          <p className="m-0 mt-4 text-pretty text-lg leading-relaxed text-muted">{p.intro}</p>

          <h2 className="m-0 mt-12 text-2xl font-extrabold tracking-tight">{p.stepsTitle}</h2>
          <ol className="m-0 mt-4 flex flex-col gap-2 pl-6 text-base leading-relaxed">
            {p.steps.map((step) => (
              <li key={step}>{step}</li>
            ))}
          </ol>

          <div className="mt-12 grid gap-6 sm:grid-cols-2">
            <section className="relative rounded-xl bg-surface p-6 shadow-soft">
              <Contour radius={36} inset={10} />
              <h2 className="relative m-0 text-xl font-extrabold tracking-tight">{p.erasedTitle}</h2>
              <ul className="relative m-0 mt-3 flex list-disc flex-col gap-1 pl-5 text-sm">
                {d.confirm.erased.map((line) => (
                  <li key={line}>{line}</li>
                ))}
              </ul>
            </section>
            <section className="relative rounded-xl bg-surface p-6 shadow-soft">
              <Contour radius={36} inset={10} />
              <h2 className="relative m-0 text-xl font-extrabold tracking-tight">{p.keptTitle}</h2>
              <p className="relative m-0 mt-3 text-sm">{d.confirm.kept}</p>
              <p className="relative m-0 mt-2 text-sm text-muted">{d.confirm.signInAgain}</p>
            </section>
          </div>

          <section className="mt-12 rounded-xl bg-surface-2 p-6 sm:p-8">
            <h2 className="m-0 text-2xl font-extrabold tracking-tight">{p.lostTitle}</h2>
            <p className="m-0 mt-2 mb-5 text-sm text-muted">{p.lostBody}</p>
            <DeletionRequestForm action={requestDeletionByEmail} copy={p} locale={locale} />
          </section>
        </main>
        <LandingFooter copy={all.footer} nav={all.nav} invite={all.schools.invite} locale={locale} t={t} />
      </div>
    </InterestProvider>
  );
}
