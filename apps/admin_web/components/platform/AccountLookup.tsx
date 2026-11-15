"use client";

import Link from "next/link";
import { useActionState } from "react";
import { Mail01Icon, Search01Icon } from "@hugeicons/core-free-icons";

import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Input } from "@/components/ui/Input";
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

/** The lookup form and where the account found stands. Read only. */
export function AccountLookup({ action, text, roles, statuses, subscriptionStatuses, locale }: Props) {
  const [state, formAction, pending] = useActionState(action, { email: "", result: null, error: null });
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
            <div className="flex flex-wrap items-center gap-4">
              <Avatar name={r.fullName ?? r.email ?? ""} url={r.avatarUrl} size={56} />
              <div className="min-w-0 flex-1">
                <p className="m-0 text-xl font-extrabold tracking-tight">{r.fullName || r.email}</p>
                <p className="m-0 text-sm break-all text-muted">{r.email}</p>
              </div>
              <div className="flex flex-wrap gap-1.5">
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
          </Card>
        </div>
      ) : null}
    </div>
  );
}
