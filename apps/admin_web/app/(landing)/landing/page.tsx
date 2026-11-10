import type { Metadata } from "next";
import { Suspense } from "react";

import { BusStopScene } from "@/components/landing/BusStopScene";
import { HeroHead, HeroLead } from "@/components/landing/HeroHead";
import { LandingFooter } from "@/components/landing/LandingFooter";
import { LandingIntro } from "@/components/landing/LandingIntro";
import { LandingNav } from "@/components/landing/LandingNav";
import { SectionHead } from "@/components/landing/SectionHead";
import { Sky } from "@/components/landing/Sky";
import { DownloadSection } from "@/components/landing/DownloadSection";
import { FaqSection } from "@/components/landing/FaqSection";
import { SchoolsSection } from "@/components/landing/SchoolsSection";
import { InterestProvider } from "@/components/landing/interest/Interest";
import { downloads } from "@/lib/landing/downloads";
import { DayStory } from "@/components/landing/day/DayStory";
import { PeopleSection } from "@/components/landing/people/PeopleSection";
import "@/components/landing/landing.css";
import { LanguageSwitch } from "@/components/LanguageSwitch";
import { RoughFilter } from "@/components/ui/RoughFilter";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { landingCatalogues } from "@/lib/i18n/landing";
import { getMessages } from "@/lib/i18n/server";
import { loadWallSchools } from "@/lib/landing/schools";
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
    openGraph: {
      title: copy.shareTitle,
      description: copy.description,
      type: "website",
      url: "/",
      siteName: "BusIn",
      locale: locale === "fr" ? "fr_FR" : "en_US",
    },
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
    <InterestProvider copy={copy.form} locale={locale}>
      <div lang={locale} data-landing className="relative bg-bg text-fg">
        <RoughFilter />
        <LandingIntro />
        <Sky />
        <HeroHead copy={copy.hero} />
        <LandingNav
          copy={copy.nav}
          locale={locale}
          labels={{ theme: t.profile.theme, language: t.language }}
          menuControls={
            <>
              <LanguageSwitch locale={locale} t={t} compact />
              <ThemeToggle labels={t.profile.theme} iconOnly />
            </>
          }
        />
        <HeroLead copy={copy.hero} />
        <BusStopScene chips={copy.hero.chips} />

        <main className="relative z-10">
          <section aria-labelledby="day" className="mx-auto max-w-[88rem] px-5 pt-28 sm:px-8 sm:pt-36">
            <SectionHead id="day" {...sections.day} />
            <DayStory copy={copy.day} />
          </section>

          <section aria-labelledby="people" className="pt-28 sm:pt-36">
            <div className="mx-auto max-w-[88rem] px-5 sm:px-8">
              <SectionHead id="people" {...sections.people} />
            </div>
            <div className="mx-auto max-w-[88rem] px-5 sm:px-8 lg:max-w-none lg:px-0">
              <PeopleSection copy={copy.people} calmHead={sections.private} calm={copy.private} />
            </div>
          </section>

          <section aria-labelledby="download" className="mx-auto max-w-[88rem] px-5 pt-28 sm:px-8 sm:pt-36">
            <SectionHead id="download" {...sections.download} />
            <DownloadSection copy={copy.download} day={copy.day} links={downloads()} />
          </section>

          <section aria-labelledby="schools" className="mx-auto max-w-[88rem] px-5 pt-28 sm:px-8 sm:pt-36">
            <SectionHead id="schools" {...sections.schools} />
            <SchoolsSection copy={copy.schools} schools={await loadWallSchools()} />
          </section>

          <section aria-labelledby="faq" className="mx-auto max-w-[88rem] px-5 pt-28 sm:px-8 sm:pt-36">
            <SectionHead id="faq" {...sections.faq} />
            <FaqSection copy={copy.faq} />
          </section>
        </main>
        <LandingFooter copy={copy.footer} nav={copy.nav} invite={copy.schools.invite} locale={locale} t={t} />
      </div>
    </InterestProvider>
  );
}
