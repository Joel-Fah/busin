import { ArrowLeft01Icon, ArrowUpRight01Icon } from "@hugeicons/core-free-icons";
import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { BrandMark } from "@/components/brand/BrandMark";
import { InterestProvider } from "@/components/landing/interest/Interest";
import { LandingFooter } from "@/components/landing/LandingFooter";
import "@/components/landing/landing.css";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import { RoughFilter } from "@/components/ui/RoughFilter";
import { landingCatalogues } from "@/lib/i18n/landing";
import { getMessages } from "@/lib/i18n/server";
import { siteUrl } from "@/lib/landing/site";

// Depends on the visitor's language (a cookie), so it is rendered per request.
export const instant = false;

export async function generateMetadata(): Promise<Metadata> {
  const { locale } = await getMessages();
  const copy = landingCatalogues[locale].credits;
  const title = `${copy.title}: BusIn`;
  return {
    metadataBase: new URL(siteUrl()),
    title: { absolute: title },
    description: copy.meta,
    alternates: { canonical: "/credits" },
    robots: { index: true, follow: true },
    openGraph: { title, description: copy.meta, type: "website", url: "/credits", siteName: "BusIn", locale: locale === "fr" ? "fr_FR" : "en_US" },
    twitter: { card: "summary", title, description: copy.meta },
  };
}

export default function CreditsPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Credits />
    </Suspense>
  );
}

const external = "inline-flex w-fit items-center gap-1 font-semibold text-fg no-underline hover:text-accent";

/** Credits: what the public site uses that others made, and under which licence. Public, in English and French. */
async function Credits() {
  const { locale, t } = await getMessages();
  const all = landingCatalogues[locale];
  const copy = all.credits;
  return (
    <InterestProvider copy={all.form} locale={locale}>
      <div lang={locale} className="relative min-h-dvh bg-bg text-fg">
        <RoughFilter />
        <main className="mx-auto max-w-[56rem] px-5 pt-12 sm:px-8 sm:pt-16">
          <div className="flex items-center justify-between gap-4">
            <Link href="/" aria-label="BusIn" className="text-fg">
              <BrandMark className="h-10 w-auto" />
            </Link>
            <Link href="/" className="inline-flex items-center gap-1.5 text-sm font-semibold text-fg no-underline hover:text-accent">
              <Icon icon={ArrowLeft01Icon} size={16} />
              {copy.back}
            </Link>
          </div>
          <h1 className="m-0 mt-14 text-5xl font-extrabold tracking-tight">{copy.title}</h1>
          <p className="m-0 mt-4 max-w-[38rem] text-pretty text-lg leading-relaxed text-muted">{copy.intro}</p>

          <ul className="relative m-0 mt-10 flex list-none flex-col gap-1 rounded-xl bg-surface p-4 shadow-soft [--thread-color:var(--color-line)] sm:p-6">
            <Contour radius={36} inset={10} />
            {copy.items.map((item) => (
              <li key={item.name} className="relative grid gap-1 rounded-sm px-4 py-3 sm:grid-cols-[12rem_1fr_auto] sm:items-center sm:gap-4">
                <a href={item.href} target="_blank" rel="noopener noreferrer" className={external}>
                  {item.name}
                  <Icon icon={ArrowUpRight01Icon} size={14} />
                </a>
                <span className="text-muted">{item.what}</span>
                <span className="w-fit rounded-xs bg-surface-2 px-2.5 py-1 text-xs font-bold">{item.licence}</span>
              </li>
            ))}
          </ul>

          <h2 className="m-0 mt-14 text-2xl font-extrabold tracking-tight">{copy.photos}</h2>
          <ul className="m-0 mt-5 flex list-none flex-col gap-3 p-0">
            {copy.photoList.map((photo) => (
              <li key={photo.href}>
                <a href={photo.href} target="_blank" rel="noopener noreferrer" className={external}>
                  {photo.what}
                  <Icon icon={ArrowUpRight01Icon} size={14} />
                </a>
              </li>
            ))}
          </ul>
        </main>
        <LandingFooter copy={all.footer} nav={all.nav} invite={all.schools.invite} locale={locale} t={t} />
      </div>
    </InterestProvider>
  );
}
