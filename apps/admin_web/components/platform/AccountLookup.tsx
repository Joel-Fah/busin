"use client";

import Link from "next/link";
import { useActionState, useState } from "react";
import { Delete02Icon, Mail01Icon, Search01Icon, UserCheck01Icon } from "@hugeicons/core-free-icons";

import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Input } from "@/components/ui/Input";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import type { LookupState } from "@/app/(platform)/platform/lookup/actions";
import { format } from "@/lib/i18n/format";
import type { Messages } from "@/lib/i18n/messages";

type Props = {
  action: (state: LookupState, formData: FormData) => Promise<LookupState>;
  text: Messages["platform"]["lookup"];
  roles: Messages["role"];
  statuses: Messages["accountStatus"];
  subscriptionStatuses: Record<string, string>;
  locale: string;
};

const STATUS_TONE = { verified: "ok", pending: "warn", suspended: "bad" } as const;

/** An email that wraps before its "@" when it does not fit on one line, rather than in the middle of a word. */
function breakableEmail(email: string) {
  const at = email.lastIndexOf("@");
  if (at <= 0) return email;
  return (
    <>
      <span className="inline-block max-w-full">{email.slice(0, at)}</span>
      <span className="inline-block max-w-full">{email.slice(at)}</span>
    </>
  );
}

/** The lookup form and where the account found stands. Read only. */
export function AccountLookup({ action, text, roles, statuses, subscriptionStatuses, locale }: Props) {
  const [state, formAction, pending] = useActionState(action, { email: "", result: null, error: null });
  const [confirming, setConfirming] = useState(false);
  const day = (iso: string) => new Intl.DateTimeFormat(locale, { day: "numeric", month: "long", year: "numeric" }).format(new Date(iso));
  const when = (iso: string) => new Intl.DateTimeFormat(locale, { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" }).format(new Date(iso));
  const r = state.result;

  return (
    <div className="flex flex-col gap-6">
      <form action={formAction} className="flex flex-wrap items-end gap-3">
        <div className="min-w-0 flex-1 basis-72">
          <Input
            id="lookup-email"
            name="email"
            type="email"
            label={text.email}
            icon={Mail01Icon}
            placeholder={text.emailPlaceholder}
            defaultValue={state.email}
            autoComplete="off"
            required
            hint={text.hint}
          />
        </div>
        <Button type="submit" icon={Search01Icon} disabled={pending} className="mb-6">
          {text.search}
        </Button>
      </form>

      {state.error ? <Notice tone="bad">{text.errors[state.error]}</Notice> : null}

      {r && !r.found ? (
        <div data-testid="lookup-result">
        <Card className="flex flex-col gap-2 p-6!">
          <p className="m-0 font-semibold">{text.notFound}</p>
          {r.invite?.schoolName && r.invite.expiresAt ? (
            <p className="m-0 text-sm text-muted">
              {format(text.invited, { role: roles[(r.invite.role ?? "staff") as keyof typeof roles] ?? r.invite.role ?? "", school: r.invite.schoolName, date: day(r.invite.expiresAt) })}
            </p>
          ) : null}
        </Card>
        </div>
      ) : null}

      {r && r.found ? (
        <div data-testid="lookup-result">
          <Card className="flex flex-col gap-5 p-6!">
            {/* On a phone the header stacks (avatar, name, email, then the chips) so the name has the card's width;
                from sm up they sit on one row, chips at the end. */}
            <div data-testid="lookup-header" className="flex flex-col items-start gap-3 sm:flex-row sm:flex-wrap sm:items-center sm:gap-4">
              <Avatar name={r.fullName ?? r.email ?? ""} url={r.avatarUrl} size={56} />
              <div className="flex w-full min-w-0 flex-col gap-0.5 sm:w-auto sm:flex-1">
                <p data-testid="lookup-name" className="m-0 text-xl font-extrabold tracking-tight wrap-break-word">
                  {r.fullName || r.email}
                </p>
                {r.email ? <p className="m-0 text-sm text-muted wrap-anywhere">{breakableEmail(r.email)}</p> : null}
              </div>
              <div data-testid="lookup-chips" className="flex flex-wrap gap-1.5">
                {r.role ? <Chip>{roles[r.role]}</Chip> : null}
                {r.status ? <Chip tone={STATUS_TONE[r.status]}>{statuses[r.status]}</Chip> : null}
                {r.platformAdmin ? <Chip tone="accent">{text.platformAdmin}</Chip> : null}
              </div>
            </div>
            <dl className="m-0 grid gap-4 text-sm sm:grid-cols-2 lg:grid-cols-3">
              <div>
                <dt className="text-muted">{text.school}</dt>
                <dd className="m-0 font-semibold">
                  {r.schoolId && r.schoolName ? (
                    <Link href={`/platform/schools/${r.schoolId}`} className="text-link no-underline">
                      {r.schoolName}
                    </Link>
                  ) : (
                    text.noSchool
                  )}
                </dd>
              </div>
              <div>
                <dt className="text-muted">{text.lastSignIn}</dt>
                <dd className="m-0 font-semibold">{r.lastSignInAt ? when(r.lastSignInAt) : text.never}</dd>
              </div>
              <div>
                <dt className="text-muted">{text.created}</dt>
                <dd className="m-0 font-semibold">{r.createdAt ? day(r.createdAt) : "-"}</dd>
              </div>
              <div>
                <dt className="text-muted">{text.requests}</dt>
                <dd className="m-0 font-semibold">
                  {[
                    r.joinRequestedAt ? format(text.joinWaiting, { date: day(r.joinRequestedAt) }) : null,
                    r.joinDeclinedAt ? format(text.joinDeclined, { date: day(r.joinDeclinedAt) }) : null,
                    r.staffRequestedAt ? format(text.staffWaiting, { school: r.staffRequestSchool ?? "", date: day(r.staffRequestedAt) }) : null,
                    r.staffDeclinedAt ? format(text.staffDeclined, { date: day(r.staffDeclinedAt) }) : null,
                  ]
                    .filter(Boolean)
                    .join(" · ") || text.noRequests}
                </dd>
              </div>
              <div>
                <dt className="text-muted">{text.subscriptions}</dt>
                <dd className="m-0 font-semibold">
                  {Object.entries(r.subscriptions)
                    .map(([status, n]) => `${n} ${subscriptionStatuses[status] ?? status}`)
                    .join(" · ") || text.noSubscriptions}
                </dd>
              </div>
              <div>
                <dt className="text-muted">{text.devices}</dt>
                <dd className="m-0 font-semibold tabular-nums">{r.devices}</dd>
              </div>
              <div data-testid="lookup-deletion">
                <dt className="text-muted">{text.deletion}</dt>
                <dd className="m-0 font-semibold">
                  {r.deletionDueAt
                    ? format(text.deletionOn, { date: day(r.deletionDueAt), who: r.deletionBy === "platform" ? text.deletionPlatform : text.deletionSelf })
                    : text.deletionNone}
                </dd>
              </div>
              {r.provider ? (
                <div>
                  <dt className="text-muted">{text.signIn}</dt>
                  <dd className="m-0 font-semibold capitalize">{r.provider}</dd>
                </div>
              ) : null}
            </dl>
            {r.invite?.schoolName && r.invite.expiresAt ? (
              <p className="m-0 text-sm text-muted">
                {format(text.invited, { role: roles[(r.invite.role ?? "staff") as keyof typeof roles] ?? "", school: r.invite.schoolName, date: day(r.invite.expiresAt) })}
              </p>
            ) : null}
            {r.id ? (
              <div>
                {r.deletionDueAt ? (
                  <form action={formAction}>
                    <input type="hidden" name="email" value={state.email} />
                    <input type="hidden" name="user" value={r.id} />
                    <input type="hidden" name="intent" value="cancel" />
                    <Button type="submit" variant="secondary" icon={UserCheck01Icon} disabled={pending}>
                      {text.cancelDeletion}
                    </Button>
                  </form>
                ) : (
                  <Button variant="ghost" icon={Delete02Icon} onClick={() => setConfirming(true)} className="-ml-3">
                    {text.scheduleDeletion}
                  </Button>
                )}
              </div>
            ) : null}
          </Card>
          <Modal
            open={confirming}
            onClose={() => setConfirming(false)}
            title={text.scheduleTitle}
            description={text.scheduleBody}
            actions={
              <>
                <Button variant="ghost" onClick={() => setConfirming(false)}>
                  {text.cancel}
                </Button>
                <form action={formAction} onSubmit={() => setConfirming(false)}>
                  <input type="hidden" name="email" value={state.email} />
                  <input type="hidden" name="user" value={r.id ?? ""} />
                  <input type="hidden" name="intent" value="schedule" />
                  <Button type="submit" variant="danger" icon={Delete02Icon}>
                    {text.scheduleDeletion}
                  </Button>
                </form>
              </>
            }
          />
        </div>
      ) : null}
    </div>
  );
}
