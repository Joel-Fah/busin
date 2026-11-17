import { ArrowLeft01Icon } from "@hugeicons/core-free-icons";
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
import { format } from "@/lib/i18n/format";
import { landingCatalogues } from "@/lib/i18n/landing";
import { getMessages, getStudentCopy } from "@/lib/i18n/server";
import { siteUrl } from "@/lib/landing/site";
import { LEGAL_UPDATED, legalDocument, readingMinutes, type LegalDoc } from "@/lib/student/legal";

const DOCS: LegalDoc[] = ["terms", "privacy", "acceptable-use", "payments"];

async function titleOf(doc: LegalDoc): Promise<string> {
  const { s } = await getStudentCopy();
  return doc === "terms" ? s.legal.terms : doc === "privacy" ? s.legal.privacy : doc === "payments" ? s.legal.payments : s.legal.acceptable;
}

/** The metadata of one legal page (its route file passes it on). */
export async function legalMetadata(doc: LegalDoc): Promise<Metadata> {
  const title = `${await titleOf(doc)}: BusIn`;
  return {
    metadataBase: new URL(siteUrl()),
    title: { absolute: title },
    alternates: { canonical: `/legal/${doc}` },
    robots: { index: true, follow: true },
  };
}

/** One public legal page; each document has its own route, so any other address is a real 404. */
export function PublicLegalPage({ doc }: { doc: LegalDoc }) {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <PublicLegal doc={doc} />
    </Suspense>
  );
}

/**
 * The terms of use, the privacy policy and the acceptable use rules, public, the same text the apps show (one source:
 * lib/student/legal.ts, mirrored in the apps). The links the app stores ask for. In English and French.
 */
async function PublicLegal({ doc }: { doc: LegalDoc }) {
  const { locale, t } = await getMessages();
  const { s } = await getStudentCopy();
  const l = s.legal;
  const all = landingCatalogues[locale];
  const document = legalDocument(doc, locale);
  const updated = new Intl.DateTimeFormat(locale, { dateStyle: "long", timeZone: "UTC" }).format(new Date(`${LEGAL_UPDATED}T00:00:00Z`));
  const title = await titleOf(doc);
  const others = await Promise.all(DOCS.filter((d) => d !== doc).map(async (d) => ({ doc: d, title: await titleOf(d) })));

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
              {all.credits.back}
            </Link>
          </div>
          <h1 className="m-0 mt-14 text-5xl font-extrabold tracking-tight">{title}</h1>
          <p className="m-0 mt-3 text-sm text-muted">
            {format(l.updated, { date: updated })} · {format(l.readTime, { minutes: readingMinutes(document) })}
          </p>

          <section className="relative mt-10 rounded-xl bg-surface p-6 shadow-soft">
            <Contour radius={36} inset={10} />
            <h2 className="relative m-0 mb-3 text-xl font-extrabold tracking-tight">{l.inShort}</h2>
            <ul className="relative m-0 flex flex-col gap-1.5 pl-5">
              {document.highlights.map((line) => (
                <li key={line}>{line}</li>
              ))}
            </ul>
          </section>

          <article className="mt-10 flex flex-col gap-7">
            {document.sections.map((section) => (
              <section key={section.title} className="flex flex-col gap-2">
                <h2 className="m-0 text-xl font-extrabold tracking-tight">{section.title}</h2>
                {(section.paragraphs ?? []).map((text) => (
                  <p key={text} className="m-0 leading-relaxed">
                    {text}
                  </p>
                ))}
                {section.bullets?.length ? (
                  <ul className="m-0 flex flex-col gap-1 pl-5 leading-relaxed">
                    {section.bullets.map((text) => (
                      <li key={text}>{text}</li>
                    ))}
                  </ul>
                ) : null}
              </section>
            ))}
          </article>

          <section className="mt-12 rounded-xl bg-surface-2 p-6">
            <h2 className="m-0 text-lg font-bold">{l.questionsTitle}</h2>
            <p className="m-0 mt-1 text-sm text-muted">{l.questionsBody}</p>
          </section>

          <nav aria-label={l.title} className="mt-8 flex flex-wrap gap-x-6 gap-y-2">
            {others.map((other) => (
              <Link key={other.doc} href={`/legal/${other.doc}`} className="font-semibold text-fg no-underline hover:text-accent">
                {other.title}
              </Link>
            ))}
            <Link href="/delete-account" className="font-semibold text-fg no-underline hover:text-accent">
              {all.footer.legal.deleteAccount}
            </Link>
          </nav>
        </main>
        <LandingFooter copy={all.footer} nav={all.nav} invite={all.schools.invite} locale={locale} t={t} />
      </div>
    </InterestProvider>
  );
}
