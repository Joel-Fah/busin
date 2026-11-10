import type { Metadata } from "next";
import { Suspense } from "react";

import { BusStopScene } from "@/components/landing/BusStopScene";
import { HeroHead, HeroLead } from "@/components/landing/HeroHead";
import { LandingFooter } from "@/components/landing/LandingFooter";
import { LandingNav } from "@/components/landing/LandingNav";
import { SectionHead } from "@/components/landing/SectionHead";
import { Sky } from "@/components/landing/Sky";
import "@/components/landing/landing.css";
import { RoughFilter } from "@/components/ui/RoughFilter";
import { landingCatalogues } from "@/lib/i18n/landing";
import { getMessages } from "@/lib/i18n/server";
import { siteUrl } from "@/lib/landing/site";

// Depends on the visitor's language (a cookie), so it is rendered per request.
export const instant = false;

export async function generateMetadata(): Promise<Metadata> {
  const { locale } = await getMessages();
  const copy = landingCatalogues[locale].meta;
  return {
    metadataBase: new URL(siteUrl()),
    title: { absolute: copy.title },
    description: copy.description,
    alternates: { canonical: "/" },
    robots: { index: true, follow: true },
    openGraph: { title: copy.shareTitle, description: copy.description, type: "website", url: "/", siteName: "BusIn", locale: locale === "fr" ? "fr_FR" : "en_US" },
    twitter: { card: "summary_large_image", title: copy.shareTitle, description: copy.description },
  };
}

export default function LandingPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <LandingContent />
    </Suspense>
  );
}

async function LandingContent() {
  const { locale, t } = await getMessages();
  const copy = landingCatalogues[locale];
  const sections = copy.sections;

  return (
    <div lang={locale} data-landing className="relative bg-bg text-fg">
      <RoughFilter />
      <Sky />
      <HeroHead copy={copy.hero} />
      <LandingNav copy={copy.nav} locale={locale} labels={{ theme: t.profile.theme, language: t.language }} />
      <HeroLead copy={copy.hero} />
      <BusStopScene chips={copy.hero.chips} />

      <main className="relative z-10">
        {/* The scenes arrive in the next slices; each already has its place and its anchor. */}
        {(["day", "people", "private", "download", "schools", "faq"] as const).map((key) => (
          <section key={key} aria-labelledby={key} className="mx-auto max-w-[88rem] px-5 pt-28 sm:px-8">
            <SectionHead id={key} {...sections[key]} />
          </section>
        ))}
      </main>
      <LandingFooter copy={copy.footer} locale={locale} t={t} />
    </div>
  );
}
