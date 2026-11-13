import type { Metadata } from "next";
import { Suspense } from "react";

import { InstallCard } from "@/components/student/InstallCard";
import { LanguageChoice } from "@/components/student/LanguageChoice";
import { SignOutForm } from "@/components/student/SignOutForm";
import { StudentPage } from "@/components/student/StudentPage";
import { Avatar } from "@/components/ui/Avatar";
import { Card } from "@/components/ui/Card";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";

export const metadata: Metadata = { title: "Profile" };
export const instant = false;

export default function ProfilePage() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Profile />
    </Suspense>
  );
}

async function Profile() {
  const student = await requireStudent();
  const { locale, s } = await getStudentCopy();
  const p = s.profile;
  return (
    <StudentPage lang={locale} title={p.title}>
      <Card className="flex items-center gap-4 p-5">
        <Avatar name={student.fullName || student.email} url={student.avatarUrl} size={56} />
        <div className="min-w-0">
          <p className="m-0 truncate text-lg font-bold">{student.fullName}</p>
          <p className="m-0 truncate text-sm text-muted">{student.email}</p>
          <p className="m-0 truncate text-sm text-muted">{student.schoolName}</p>
        </div>
      </Card>
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
      <SignOutForm label={p.signOut} />
    </StudentPage>
  );
}
