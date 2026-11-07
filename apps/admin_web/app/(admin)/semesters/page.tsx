import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { Add01Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";

import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { semesterPhase, todayIso } from "@/lib/semesters";
import { loadSemesters } from "@/lib/semesters-data";

export const metadata: Metadata = { title: "Semesters" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function SemestersPage() {
  return (
    <Suspense fallback={<ListSkeleton rows={3} />}>
      <SemestersList />
    </Suspense>
  );
}

async function SemestersList() {
  await requireAdmin();
  const { locale, t } = await getMessages();
  const { semesters, failed } = await loadSemesters();
  const today = todayIso();
  // A calendar day, not a moment: read it as UTC so the time zone cannot move it.
  const plainDate = (iso: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: "UTC" }).format(new Date(`${iso}T00:00:00Z`));

  return (
    <>
      <PageHeader
        title={t.semesters.title}
        subtitle={t.semesters.subtitle}
        help={{
          label: t.help.open,
          title: t.semesters.help.title,
          intro: t.semesters.help.intro,
          scenarios: Object.values(t.semesters.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
        action={
          <ButtonLink href="/semesters/new" icon={Add01Icon}>
            {t.semesters.add}
          </ButtonLink>
        }
      />

      {failed ? (
        <Notice tone="bad">{t.semesters.loadError}</Notice>
      ) : semesters.length === 0 ? (
        <EmptyState illustration="/illustrations/semester.webp" title={t.semesters.empty} />
      ) : (
        <TableCard>
          <DataTable minWidth="32rem">
            <Head>
              <Th>{t.semesters.columns.semester}</Th>
              <Th>{t.semesters.columns.dates}</Th>
              <Th>{t.semesters.columns.status}</Th>
            </Head>
            <tbody>
              {semesters.map((semester) => {
                const phase = semesterPhase(semester.startDate, semester.endDate, today);
                return (
                  <Tr key={semester.id}>
                    <Td>
                      <Link href={`/semesters/${semester.id}`} className="font-semibold text-fg no-underline hover:text-link">
                        {t.semester[semester.name]} {semester.year}
                      </Link>
                    </Td>
                    <Td className="text-muted">
                      <span className="block">
                        {t.semesters.dateFrom}: <span className="font-semibold text-fg">{plainDate(semester.startDate)}</span>
                      </span>
                      <span className="block">
                        {t.semesters.dateTo}: <span className="font-semibold text-fg">{plainDate(semester.endDate)}</span>
                      </span>
                    </Td>
                    <Td>
                      <Chip tone={phase === "current" ? "ok" : phase === "upcoming" ? "info" : "neutral"}>{t.semesters.phase[phase]}</Chip>
                    </Td>
                  </Tr>
                );
              })}
            </tbody>
          </DataTable>
        </TableCard>
      )}
    </>
  );
}
