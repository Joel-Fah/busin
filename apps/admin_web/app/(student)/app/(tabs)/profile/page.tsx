import { Clock01Icon, Edit02Icon, FireIcon, Home01Icon, LegalDocument01Icon, Notification03Icon } from "@hugeicons/core-free-icons";
import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { FlashToast } from "@/components/FlashToast";
import { InstallCard } from "@/components/student/InstallCard";
import { LanguageChoice } from "@/components/student/LanguageChoice";
import { LinkRow } from "@/components/student/LinkRow";
import { SignOutForm } from "@/components/student/SignOutForm";
import { StudentPage } from "@/components/student/StudentPage";
import { Avatar } from "@/components/ui/Avatar";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { displayPhone } from "@/lib/phone/phone";
import { format } from "@/lib/i18n/format";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";
import { Contour } from "@/components/ui/Contour";

export const metadata: Metadata = { title: "Profile" };
export const instant = false;

type SearchParams = Promise<{ saved?: string | string[] }>;

export default function ProfilePage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Profile searchParams={searchParams} />
    </Suspense>
  );
}

/** The profile tab, as in the app: who the student is, their details, the pages behind it, appearance, and sign-out. */
async function Profile({ searchParams }: { searchParams: SearchParams }) {
  const student = await requireStudent();
  const { locale, s } = await getStudentCopy();
  const p = s.profile;
  const m = s.me;
  const supabase = await createClient();
  const { data: extra } = await supabase.from("profiles").select("created_at, department_id, program_id").eq("id", student.userId).maybeSingle();
  const [department, program] = await Promise.all([
    extra?.department_id ? supabase.from("departments").select("name").eq("id", extra.department_id).maybeSingle() : { data: null },
    extra?.program_id ? supabase.from("programs").select("name").eq("id", extra.program_id).maybeSingle() : { data: null },
  ]);
  const { saved } = await searchParams;
  const rows: [string, string | null | undefined][] = [
    [s.fields.matricule, student.matricule],
    [s.fields.phone, student.phone ? displayPhone(student.phone) : null],
    [s.fields.department, department.data?.name],
    [s.fields.program, program.data?.name],
  ];
  const since = extra?.created_at ? new Intl.DateTimeFormat(locale, { dateStyle: "medium" }).format(new Date(extra.created_at)) : null;

  return (
    <StudentPage lang={locale} title={p.title}>
      {saved === "1" ? <FlashToast message={m.saved} /> : null}
      <Card className="flex items-center gap-4 p-5">
        <Avatar name={student.fullName || student.email} url={student.avatarUrl} size={56} />
        <div className="min-w-0">
          <p className="m-0 truncate text-lg font-bold">{student.fullName}</p>
          <p className="m-0 truncate text-sm text-muted">{student.email}</p>
          <p className="m-0 truncate text-sm text-muted">{student.schoolName}</p>
        </div>
      </Card>

      <section aria-labelledby="details-title" className="flex flex-col gap-3 relative rounded-lg bg-surface p-5 shadow-soft">
        <Contour radius={28} inset={10} />
        <div className="flex items-center justify-between gap-3">
          <h2 id="details-title" className="m-0 text-lg font-bold">
            {m.details}
          </h2>
          <Link href="/app/profile/edit" className="inline-flex h-10 items-center gap-2 rounded-sm bg-surface-2 px-3 text-sm font-semibold text-fg no-underline">
            <Icon icon={Edit02Icon} size={16} />
            {m.edit}
          </Link>
        </div>
        <dl className="m-0 grid gap-3">
          {rows.map(([label, value]) => (
            <div key={label}>
              <dt className="text-sm text-muted">{label}</dt>
              <dd className="m-0 font-semibold">{value?.trim() ? value : <span className="font-normal text-muted">{m.notSet}</span>}</dd>
            </div>
          ))}
        </dl>
      </section>

      <nav className="flex flex-col gap-2" aria-label={p.title}>
        <LinkRow href="/app/history" icon={Clock01Icon} title={m.links.history} body={m.links.historyBody} />
        <LinkRow href="/app/settings/notifications" icon={Notification03Icon} title={m.links.notifications} body={m.links.notificationsBody} />
        <LinkRow href="/app/settings/area" icon={Home01Icon} title={m.links.area} body={m.links.areaBody} />
        <LinkRow href="/app/streaks" icon={FireIcon} title={m.links.streaks} body={m.links.streaksBody} />
        <LinkRow href="/app/legal" icon={LegalDocument01Icon} title={m.links.legal} body={m.links.legalBody} />
      </nav>

      <InstallCard copy={s.install} />

      <Card className="flex flex-col gap-4 p-5">
        <div>
          <h2 className="m-0 text-lg font-bold">{p.appearance}</h2>
          <p className="m-0 text-sm text-muted">{p.appearanceHint}</p>
        </div>
        <div className="flex flex-col gap-2">
          <span className="text-sm font-semibold">{p.theme}</span>
          <ThemeToggle labels={{ group: p.theme, ...p.themes }} />
        </div>
        <div className="flex flex-col gap-2">
          <span className="text-sm font-semibold">{p.language}</span>
          <LanguageChoice locale={locale} label={p.language} />
        </div>
      </Card>

      {since ? <p className="m-0 text-center text-sm text-muted">{format(m.memberSince, { date: since })}</p> : null}
      <SignOutForm label={p.signOut} />
      <p className="m-0 text-center text-xs text-muted">{m.credits}</p>
    </StudentPage>
  );
}
