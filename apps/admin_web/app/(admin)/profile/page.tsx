import type { Metadata } from "next";
import { Suspense } from "react";

import { LanguageSwitch } from "@/components/LanguageSwitch";
import { SignOutButton } from "@/components/SignOutButton";
import { Avatar } from "@/components/ui/Avatar";
import { Card } from "@/components/ui/Card";
import { PageHeader } from "@/components/ui/PageHeader";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";

export const metadata: Metadata = { title: "Your profile" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function ProfilePage() {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <Profile />
    </Suspense>
  );
}

async function Profile() {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const name = admin.fullName || admin.email;

  return (
    <>
      <PageHeader title={t.profile.title} subtitle={t.profile.subtitle} />

      <div className="grid gap-6 lg:grid-cols-[minmax(0,22rem)_minmax(0,1fr)]">
        <Card className="flex flex-col items-start gap-5">
          <Avatar name={name} url={admin.avatarUrl} size={88} />
          <div>
            <h2 className="text-2xl font-extrabold tracking-tight">{name}</h2>
            <p className="mt-1 text-sm break-all text-muted">{admin.email}</p>
          </div>
          <dl className="m-0 grid w-full gap-3 text-sm">
            <div>
              <dt className="text-muted">{t.profile.role}</dt>
              <dd className="m-0 font-semibold">{t.profile.administrator}</dd>
            </div>
            <div>
              <dt className="text-muted">{t.profile.school}</dt>
              <dd className="m-0 font-semibold">{admin.schoolName}</dd>
            </div>
          </dl>
        </Card>

        <div className="flex flex-col gap-6">
          <Card>
            <h2 className="text-xl font-bold">{t.profile.appearance}</h2>
            <p className="mt-1 mb-4 text-sm text-muted">{t.profile.appearanceHint}</p>
            <ThemeToggle labels={t.profile.theme} />
          </Card>

          <Card>
            <h2 className="mb-4 text-xl font-bold">{t.profile.language}</h2>
            <LanguageSwitch locale={locale} t={t} />
          </Card>

          <Card>
            <h2 className="text-xl font-bold">{t.profile.session}</h2>
            <p className="mt-1 mb-4 text-sm text-muted">{t.profile.sessionHint}</p>
            <SignOutButton label={t.nav.signOut} />
          </Card>
        </div>
      </div>
    </>
  );
}
