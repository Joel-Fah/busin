import type { Metadata } from "next";
import { Suspense } from "react";
import { Delete02Icon, Mail01Icon, UserShield01Icon } from "@hugeicons/core-free-icons";

import { FlashToast } from "@/components/FlashToast";
import { BackLink } from "@/components/ui/BackLink";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Input } from "@/components/ui/Input";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Select } from "@/components/ui/Select";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";
import { requireAdmin } from "@/lib/auth";
import { format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { daysLeft, INVITE_ROLES, MAX_EMAIL_LENGTH, parseInviteDone, parseInviteError } from "@/lib/invites";
import { roleTone } from "@/lib/people";
import { createClient } from "@/lib/supabase/server";

import { cancelInvite, inviteStaff } from "../actions";

export const metadata: Metadata = { title: "Add staff by email" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

// A school invites a handful of people at a time; the cap keeps the page light.
const MAX_INVITES = 100;

type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

export default function InvitePage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={3} />}>
      <Invite searchParams={searchParams} />
    </Suspense>
  );
}

async function Invite({ searchParams }: { searchParams: SearchParams }) {
  await requireAdmin();
  const { t } = await getMessages();
  const s = t.people.invite;
  const query = await searchParams;
  const done = parseInviteDone(query.done);
  const errorKey = parseInviteError(query.error);

  // Row Level Security returns only this school's invites, and only to its admins.
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("staff_invites")
    .select("email, role, expires_at")
    .gt("expires_at", new Date().toISOString())
    .order("created_at", { ascending: false })
    .limit(MAX_INVITES);
  const invites = data ?? [];
  const now = new Date();

  return (
    <>
      <BackLink href="/people">{t.people.detail.back}</BackLink>
      <PageHeader title={s.title} subtitle={s.subtitle} />

      {done ? <FlashToast message={s.done[done]} /> : null}
      {errorKey ? <Notice tone="bad">{s.errors[errorKey]}</Notice> : null}

      <Card className="max-w-2xl">
        <form action={inviteStaff} className="flex flex-col gap-5">
          <Input id="invite-email" name="email" type="email" label={s.email} icon={Mail01Icon} required maxLength={MAX_EMAIL_LENGTH} autoComplete="off" hint={s.emailHint} />
          <Select
            id="invite-role"
            name="role"
            label={s.role}
            icon={UserShield01Icon}
            hint={s.roleHint}
            defaultValue="staff"
            options={INVITE_ROLES.map((role) => ({ value: role, label: t.role[role] }))}
          />
          <Button type="submit" className="self-start">
            {s.submit}
          </Button>
        </form>
      </Card>

      <section aria-labelledby="open-invites" className="flex flex-col gap-3">
        <h2 id="open-invites" className="text-xl font-bold">
          {s.openTitle}
        </h2>
        {error ? (
          <Notice tone="bad">{t.people.loadError}</Notice>
        ) : invites.length === 0 ? (
          <p className="text-sm text-muted">{s.none}</p>
        ) : (
          <TableCard>
            <DataTable minWidth="32rem">
              <Head>
                <Th>{s.email}</Th>
                <Th>{s.role}</Th>
                <Th>{s.expires}</Th>
                <Th>
                  <span className="sr-only">{s.cancel}</span>
                </Th>
              </Head>
              <tbody>
                {invites.map((invite) => (
                  <Tr key={invite.email}>
                    <Td className="break-all">{invite.email}</Td>
                    <Td>
                      <Chip tone={roleTone(invite.role)}>{t.role[invite.role]}</Chip>
                    </Td>
                    <Td className="text-muted">{format(s.daysLeft, { count: daysLeft(invite.expires_at, now) })}</Td>
                    <Td>
                      <form action={cancelInvite}>
                        <input type="hidden" name="email" value={invite.email} />
                        <Button type="submit" variant="ghost" icon={Delete02Icon} aria-label={format(s.cancelFor, { email: invite.email })}>
                          {s.cancel}
                        </Button>
                      </form>
                    </Td>
                  </Tr>
                ))}
              </tbody>
            </DataTable>
          </TableCard>
        )}
      </section>
    </>
  );
}
