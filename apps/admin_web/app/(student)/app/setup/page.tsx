import { School01Icon } from "@hugeicons/core-free-icons";
import type { Metadata } from "next";
import { Suspense } from "react";

import { GatePage } from "@/components/student/GatePage";
import { SetupForm, type Academics } from "@/components/student/SetupForm";
import { SignOutForm } from "@/components/student/SignOutForm";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
import { supabaseConfig } from "@/lib/env";
import { format } from "@/lib/i18n/format";
import { getStudentCopy } from "@/lib/i18n/server";
import { logoUrl } from "@/lib/school";
import { firstName } from "@/lib/overview";
import { requireGate } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Your details" };
export const instant = false;

export default function SetupPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh bg-bg" aria-busy="true" />}>
      <Setup />
    </Suspense>
  );
}

/** A verified student tells the school who they are before using the app: the app's setup screen. */
async function Setup() {
  const { profile } = await requireGate("needsSetup");
  const { locale, s } = await getStudentCopy();
  const supabase = await createClient();
  // The school's lists, at most a few hundred rows each; RLS keeps them to the student's school.
  const [faculties, departments, programs] = await Promise.all([
    supabase.from("faculties").select("id, name").order("name").limit(300),
    supabase.from("departments").select("id, faculty_id, name").order("name").limit(1000),
    supabase.from("programs").select("id, name").order("sort_order").order("name").limit(100),
  ]);
  const academics: Academics = {
    faculties: faculties.data ?? [],
    departments: (departments.data ?? []).map((d) => ({ id: d.id, facultyId: d.faculty_id, name: d.name })),
    programs: programs.data ?? [],
  };
  const school = profile.schools?.name ?? "";
  const logo = logoUrl(profile.schools?.logo_path, supabaseConfig().url);
  const name = firstName(profile.full_name ?? "");

  return (
    <GatePage lang={locale} title={name ? format(s.setup.welcome, { name }) : s.setup.body} intro={name ? s.setup.body : undefined}>
      <Card className="flex flex-col gap-3 p-5">
        <div className="flex items-center gap-4">
          <span className="grid size-12 shrink-0 place-items-center overflow-hidden rounded-sm bg-white">
            {logo ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={logo} alt="" className="size-full object-contain" />
            ) : (
              <Icon icon={School01Icon} size={22} className="text-brand" />
            )}
          </span>
          <div className="min-w-0">
            <p className="m-0 font-bold">{format(s.setup.joiningTitle, { school })}</p>
            <p className="m-0 text-sm text-muted">{s.setup.joiningBody}</p>
          </div>
        </div>
        <details className="group">
          <summary className="cursor-pointer text-sm font-semibold text-link">{s.setup.notMineTitle}</summary>
          <div className="mt-3 flex flex-col gap-3">
            <p className="m-0 text-sm text-muted">{format(s.setup.notMineBody, { school })}</p>
            <SignOutForm label={s.profile.signOut} />
          </div>
        </details>
      </Card>
      <SetupForm
        copy={s.setup}
        fields={s.fields}
        academics={academics}
        initial={{ fullName: profile.full_name ?? "", matricule: profile.matricule ?? "", phone: profile.phone ?? "", faculty: "", department: "", program: "" }}
      />
    </GatePage>
  );
}
