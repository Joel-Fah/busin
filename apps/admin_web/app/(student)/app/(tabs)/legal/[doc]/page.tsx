import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { StudentPage } from "@/components/student/StudentPage";
import { format } from "@/lib/i18n/format";
import { getStudentCopy } from "@/lib/i18n/server";
import { LEGAL_UPDATED, legalDocument, readingMinutes, type LegalDoc } from "@/lib/student/legal";
import { requireStudent } from "@/lib/student/session";

export const metadata: Metadata = { title: "Legal" };
export const instant = false;

const DOCS: LegalDoc[] = ["terms", "privacy", "acceptable-use"];
type Params = Promise<{ doc: string }>;

export default function LegalDocPage({ params }: { params: Params }) {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Doc params={params} />
    </Suspense>
  );
}

/** One legal document, as the app shows it: what matters in short, then the full text, and who to ask. */
async function Doc({ params }: { params: Params }) {
  const student = await requireStudent();
  const { doc } = await params;
  if (!DOCS.includes(doc as LegalDoc)) notFound();
  const { locale, s } = await getStudentCopy();
  const l = s.legal;
  const document = legalDocument(doc as LegalDoc, locale);
  const title = doc === "terms" ? l.terms : doc === "privacy" ? l.privacy : l.acceptable;
  const updated = new Intl.DateTimeFormat(locale, { dateStyle: "long", timeZone: "UTC" }).format(new Date(`${LEGAL_UPDATED}T00:00:00Z`));

  return (
    <StudentPage lang={locale} title={title} subtitle={`${format(l.updated, { date: updated })} · ${format(l.readTime, { minutes: readingMinutes(document) })} · ${format(l.appliesTo, { school: student.schoolName })}`}>
      <section className="rounded-lg bg-surface-2 p-5">
        <h2 className="m-0 mb-2 text-lg font-bold">{l.inShort}</h2>
        <ul className="m-0 flex flex-col gap-1.5 pl-5">
          {document.highlights.map((line) => (
            <li key={line}>{line}</li>
          ))}
        </ul>
      </section>
      <article className="flex flex-col gap-5">
        {document.sections.map((section) => (
          <section key={section.title} className="flex flex-col gap-2">
            <h2 className="m-0 text-lg font-bold">{section.title}</h2>
            {(section.paragraphs ?? []).map((text) => (
              <p key={text} className="m-0 leading-relaxed">
                {text}
              </p>
            ))}
            {section.bullets?.length ? (
              <ul className="m-0 flex flex-col gap-1 pl-5">
                {section.bullets.map((text) => (
                  <li key={text}>{text}</li>
                ))}
              </ul>
            ) : null}
          </section>
        ))}
      </article>
      <section className="rounded-lg bg-surface p-5 shadow-soft">
        <h2 className="m-0 text-base font-bold">{l.questionsTitle}</h2>
        <p className="m-0 mt-1 text-sm text-muted">{l.questionsBody}</p>
      </section>
    </StudentPage>
  );
}
