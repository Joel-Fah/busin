import type { Metadata } from "next";
import { Suspense } from "react";
import { Building03Icon } from "@hugeicons/core-free-icons";

import { DeleteAccount } from "@/components/DeleteAccount";
import { isDeletionError, parseScheduled } from "@/lib/account-deletion";
import { cancelAccountDeletion, requestAccountDeletion } from "@/lib/account-deletion-actions";
import { deletionCatalogues } from "@/lib/i18n/account-deletion";
import { FlashToast } from "@/components/FlashToast";
import { LanguageSwitch } from "@/components/LanguageSwitch";
import { SignOutButton } from "@/components/SignOutButton";
import { Avatar } from "@/components/ui/Avatar";
import { ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { PageHeader } from "@/components/ui/PageHeader";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { requirePlatformAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Your console account" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ deletion?: string | string[]; deletion_error?: string | string[] }>;

export default function PlatformAccountPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <Account searchParams={searchParams} />
    </Suspense>
  );
}

/** The console's profile tab: who is signed in, the way back to their school's portal, appearance, language, sign out. */
async function Account({ searchParams }: { searchParams: SearchParams }) {
  const platform = await requirePlatformAdmin();
  const { locale, t } = await getMessages();
  const query = await searchParams;
  const supabase = await createClient();
  const { data: deletionRows } = await supabase.rpc("my_account_deletion");
  const d = deletionCatalogues[locale];
  const deletion = Array.isArray(query.deletion) ? query.deletion[0] : query.deletion;
  const deletionError = Array.isArray(query.deletion_error) ? query.deletion_error[0] : query.deletion_error;
  const a = t.platform.account;
  const name = platform.fullName || platform.email;

  return (
    <>
      {deletion === "requested" || deletion === "cancelled" ? <FlashToast message={d.done[deletion]} /> : null}
      <PageHeader title={a.title} subtitle={a.subtitle} />
      <div className="grid gap-6 lg:grid-cols-[minmax(0,22rem)_minmax(0,1fr)]">
        <Card className="flex flex-col items-start gap-5">
          <Avatar name={name} url={platform.avatarUrl} size={88} />
          <div>
            <h2 className="text-2xl font-extrabold tracking-tight">{name}</h2>
            <p className="mt-1 text-sm break-all text-muted">{platform.email}</p>
          </div>
          <dl className="m-0 grid w-full gap-3 text-sm">
            <div>
              <dt className="text-muted">{a.role}</dt>
              <dd className="m-0 font-semibold">{a.platformAdmin}</dd>
            </div>
            {platform.schoolName ? (
              <div>
                <dt className="text-muted">{a.school}</dt>
                <dd className="m-0 font-semibold">{platform.schoolName}</dd>
              </div>
            ) : null}
          </dl>
          {platform.schoolAdmin ? (
            <ButtonLink href="/" variant="secondary" icon={Building03Icon}>
              {a.openSchool}
            </ButtonLink>
          ) : null}
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
          <DeleteAccount
            scheduled={parseScheduled(deletionRows)}
            back="/platform/account"
            copy={d}
            locale={locale}
            error={isDeletionError(deletionError) ? deletionError : null}
            request={requestAccountDeletion}
            cancel={cancelAccountDeletion}
          />
        </div>
      </div>
    </>
  );
}
