import type { Metadata } from "next";
import { Suspense } from "react";

import { SetupForm, type Academics } from "@/components/student/SetupForm";
import { phoneCountryFor } from "@/lib/phone/server";
import { StudentPage } from "@/components/student/StudentPage";
import { getStudentCopy } from "@/lib/i18n/server";
import { saveProfile } from "@/lib/student/onboarding";
import { requireStudent } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Edit details" };
export const instant = false;

export default function EditProfilePage() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <EditProfile />
    </Suspense>
  );
}

/** The student's details, changed later: the same form as setup, filled in. */
async function EditProfile() {
  const student = await requireStudent();
  const { locale, s } = await getStudentCopy();
  const supabase = await createClient();
  const [own, faculties, departments, programs] = await Promise.all([
    supabase.from("profiles").select("department_id, program_id").eq("id", student.userId).maybeSingle(),
    supabase.from("faculties").select("id, name").order("name").limit(300),
    supabase.from("departments").select("id, faculty_id, name").order("name").limit(1000),
    supabase.from("programs").select("id, name").order("sort_order").order("name").limit(100),
  ]);
  const academics: Academics = {
    faculties: faculties.data ?? [],
    departments: (departments.data ?? []).map((d) => ({ id: d.id, facultyId: d.faculty_id, name: d.name })),
    programs: programs.data ?? [],
  };
  const department = academics.departments.find((d) => d.id === own.data?.department_id);

  return (
    <StudentPage lang={locale} title={s.me.edit}>
      <SetupForm
        copy={s.setup}
        fields={s.fields}
        academics={academics}
        save={saveProfile}
        submitLabel={s.me.save}
        cancel={{ href: "/app/profile", label: s.me.cancel }}
        locale={locale}
        initial={{
          fullName: student.fullName,
          matricule: student.matricule ?? "",
          phone: student.phone ?? "",
          phoneCountry: await phoneCountryFor(student.schoolId, student.phone),
          faculty: department?.facultyId ?? "",
          department: department?.id ?? "",
          program: own.data?.program_id ?? "",
        }}
      />
    </StudentPage>
  );
}
