import type { Metadata } from "next";
import { Suspense } from "react";

import { UnitRow } from "@/components/UnitRow";
import { Card } from "@/components/ui/Card";
import { EmptyState } from "@/components/ui/EmptyState";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { FlashToast } from "@/components/FlashToast";
import { Notice } from "@/components/ui/Notice";
import { BackLink } from "@/components/ui/BackLink";
import { PageHeader } from "@/components/ui/PageHeader";

import { isUnitDoneKey, isUnitErrorKey } from "@/lib/academics";
import { loadAcademics } from "@/lib/academics-data";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";

import { addDepartment, addFaculty, addProgram, removeDepartment, removeFaculty, removeProgram, saveDepartment, saveFaculty, saveProgram } from "./actions";

export const metadata: Metadata = { title: "Faculties and departments" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

const first = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);

export default function AcademicsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={4} />}>
      <Academics searchParams={searchParams} />
    </Suspense>
  );
}

async function Academics({ searchParams }: { searchParams: SearchParams }) {
  await requireAdmin();
  const { t } = await getMessages();
  const a = t.academics;
  const params = await searchParams;
  const done = first(params.done);
  const error = first(params.error);
  const { faculties, programs, failed } = await loadAcademics();

  return (
    <>
      <BackLink href="/school">{t.school.backToSchool}</BackLink>
      <PageHeader
        title={a.title}
        subtitle={a.subtitle}
        help={{
          label: t.help.open,
          title: a.help.title,
          intro: a.help.intro,
          scenarios: Object.values(a.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
      />

      {isUnitErrorKey(error) ? <Notice tone="bad">{a.errors[error]}</Notice> : null}
      {isUnitDoneKey(done) ? <FlashToast message={a.done[done]} /> : null}

      {failed ? (
        <Notice tone="bad">{a.loadError}</Notice>
      ) : (
        <>
          <section aria-labelledby="faculties" className="flex flex-col gap-4">
            <h2 id="faculties" className="text-lg font-bold">
              {a.faculties}
            </h2>

            {faculties.length === 0 ? <EmptyState illustration="/illustrations/semester.webp" title={a.empty} /> : null}

            {faculties.map((faculty) => (
              <Card key={faculty.id} className="flex flex-col gap-5">
                <UnitRow
                  id={faculty.id}
                  name={faculty.name}
                  code={faculty.code}
                  nameLabel={a.facultyName}
                  codeLabel={a.code}
                  codeHint={a.codeHint}
                  save={saveFaculty}
                  remove={removeFaculty}
                  saveLabel={a.save}
                  removeLabel={a.remove}
                />

                <div className="flex flex-col gap-3 pl-0 sm:pl-6">
                  <h3 className="text-sm font-semibold text-muted">{a.departments}</h3>
                  {faculty.departments.length === 0 ? <p className="text-sm text-muted">{a.noDepartments}</p> : null}
                  {faculty.departments.map((department) => (
                    <UnitRow
                      key={department.id}
                      id={department.id}
                      name={department.name}
                      code={department.code}
                      nameLabel={a.departmentName}
                      codeLabel={a.code}
                      codeHint={a.codeHint}
                      save={saveDepartment}
                      remove={removeDepartment}
                      saveLabel={a.save}
                      removeLabel={a.remove}
                    />
                  ))}
                  <UnitRow
                    hidden={{ faculty_id: faculty.id }}
                    nameLabel={a.departmentName}
                    codeLabel={a.code}
                    codeHint={a.codeHint}
                    save={addDepartment}
                    saveLabel={a.addDepartment}
                  />
                </div>
              </Card>
            ))}

            <Card className="flex flex-col gap-3">
              <UnitRow nameLabel={a.facultyName} codeLabel={a.code} codeHint={a.codeHint} save={addFaculty} saveLabel={a.addFaculty} />
            </Card>
          </section>

          <section aria-labelledby="programs" className="flex flex-col gap-4">
            <div>
              <h2 id="programs" className="text-lg font-bold">
                {a.programs}
              </h2>
              <p className="text-sm text-muted">{a.programsHint}</p>
            </div>
            <Card className="flex flex-col gap-3">
              {programs.length === 0 ? <p className="text-sm text-muted">{a.noPrograms}</p> : null}
              {programs.map((program) => (
                <UnitRow
                  key={program.id}
                  id={program.id}
                  name={program.name}
                  withCode={false}
                  nameLabel={a.programName}
                  save={saveProgram}
                  remove={removeProgram}
                  saveLabel={a.save}
                  removeLabel={a.remove}
                />
              ))}
              <UnitRow withCode={false} nameLabel={a.programName} save={addProgram} saveLabel={a.addProgram} />
            </Card>
          </section>
        </>
      )}
    </>
  );
}
