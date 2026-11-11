import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { Building03Icon, Bus01Icon, Calendar02Icon, FlagTriangleRightIcon } from "@hugeicons/core-free-icons";

import { LanguageSwitch } from "@/components/LanguageSwitch";
import { SignOutButton } from "@/components/SignOutButton";
import { Avatar } from "@/components/ui/Avatar";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
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

      <section aria-labelledby="setup" className="flex flex-col gap-4">
        <div>
          <h2 id="setup" className="text-xl font-bold">
            {t.profile.setup.title}
          </h2>
          <p className="text-sm text-muted">{t.profile.setup.hint}</p>
        </div>
        <ul className="m-0 grid list-none gap-4 p-0 sm:grid-cols-2 xl:grid-cols-4">
          {(
            [
              ["/stops", FlagTriangleRightIcon, t.profile.setup.stops],
              ["/buses", Bus01Icon, t.profile.setup.buses],
              ["/semesters", Calendar02Icon, t.profile.setup.semesters],
              ["/school", Building03Icon, t.profile.setup.school],
            ] as const
          ).map(([href, icon, text]) => (
            <li key={href}>
              <Link href={href} className="group block h-full no-underline">
                <Card className="flex h-full flex-col gap-3 p-6 transition-transform duration-(--dur) ease-soft group-hover:-translate-y-0.5 motion-reduce:transition-none">
                  <span className="grid size-11 place-items-center rounded-md bg-surface-2 text-fg">
                    <Icon icon={icon} size={22} />
                  </span>
                  <span className="text-lg font-bold text-fg">{text.title}</span>
                  <span className="text-sm text-muted">{text.body}</span>
                </Card>
              </Link>
            </li>
          ))}
        </ul>
      </section>

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
