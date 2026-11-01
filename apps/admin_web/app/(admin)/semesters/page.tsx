import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { semesterPhase, todayIso } from "@/lib/semesters";
import { loadSemesters } from "@/lib/semesters-data";

export const metadata: Metadata = { title: "Semesters" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function SemestersPage() {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <SemestersList />
    </Suspense>
  );
}

async function SemestersList() {
  await requireAdmin();
  const { t } = await getMessages();
  const { semesters, failed } = await loadSemesters();
  const today = todayIso();

  return (
    <>
      <header className="page-head">
        <h1>{t.semesters.title}</h1>
        <p>{t.semesters.subtitle}</p>
      </header>

      <div className="row">
        <Link className="btn btn-primary" href="/semesters/new">
          {t.semesters.add}
        </Link>
      </div>

      {failed ? (
        <p className="notice" role="alert">
          {t.semesters.loadError}
        </p>
      ) : semesters.length === 0 ? (
        <p className="card">{t.semesters.empty}</p>
      ) : (
        <div className="table-wrap card">
          <table>
            <thead>
              <tr>
                <th scope="col">{t.semesters.columns.semester}</th>
                <th scope="col">{t.semesters.columns.dates}</th>
                <th scope="col">{t.semesters.columns.status}</th>
              </tr>
            </thead>
            <tbody>
              {semesters.map((semester) => {
                const phase = semesterPhase(semester.startDate, semester.endDate, today);
                return (
                  <tr key={semester.id}>
                    <td>
                      <Link href={`/semesters/${semester.id}`}>
                        {t.semester[semester.name]} {semester.year}
                      </Link>
                    </td>
                    <td>
                      {semester.startDate} - {semester.endDate}
                    </td>
                    <td>
                      <span className={phase === "current" ? "pill pill-ok" : "pill"}>{t.semesters.phase[phase]}</span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
