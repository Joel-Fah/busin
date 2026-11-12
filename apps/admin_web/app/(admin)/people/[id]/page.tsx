import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { Cancel01Icon, Tick02Icon, UserMultiple02Icon } from "@hugeicons/core-free-icons";

import { JoinRequestActions } from "@/components/people/JoinRequestActions";
import { Avatar } from "@/components/ui/Avatar";
import { BackLink } from "@/components/ui/BackLink";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { FlashToast } from "@/components/FlashToast";
import { Notice } from "@/components/ui/Notice";
import { Select } from "@/components/ui/Select";

import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { ROLES, accountTone, isPeopleDone, isPeopleErrorKey, roleTone } from "@/lib/people";
import { createClient } from "@/lib/supabase/server";

import { changeRole, changeStatus, declineMember, verifyMember } from "../actions";

export const metadata: Metadata = { title: "Person" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

export default function PersonPage({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={3} />}>
      <PersonDetail params={params} searchParams={searchParams} />
    </Suspense>
  );
}

function single(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

async function PersonDetail({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const { id } = await params;
  if (!isUuid(id)) notFound();

  const supabase = await createClient();
  const { data: person } = await supabase
    .from("profiles")
    .select("id, full_name, email, avatar_url, phone, role, status, matricule, department, program, created_at, join_requested_at")
    .eq("id", id)
    .maybeSingle();
  if (!person) notFound();

  const query = await searchParams;
  const doneParam = single(query.done);
  const errorParam = single(query.error);
  const done = isPeopleDone(doneParam) ? doneParam : null;
  const errorKey = isPeopleErrorKey(errorParam) ? errorParam : null;

  const isSelf = person.id === admin.userId;
  const joined = new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: admin.schoolTimezone }).format(
    new Date(person.created_at),
  );
  const d = t.people.detail;

  return (
    <>
      <BackLink href="/people">{d.back}</BackLink>

      <header className="flex flex-wrap items-center gap-4">
        <Avatar name={person.full_name || person.email} url={person.avatar_url} size={64} />
        <div>
          <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">{person.full_name || person.email}</h1>
          <p className="mt-2 flex flex-wrap gap-2">
            <Chip tone={roleTone(person.role)}>{t.role[person.role]}</Chip>
            <Chip tone={accountTone(person.status)}>{t.accountStatus[person.status]}</Chip>
          </p>
        </div>
      </header>

      {done ? <FlashToast message={t.people.done[done]} /> : null}
      {errorKey ? <Notice tone="bad">{t.people.errors[errorKey]}</Notice> : null}

      <div className="grid gap-6 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <Card>
          <dl className="m-0 grid gap-5 sm:grid-cols-2">
            {[
              [d.email, person.email, true],
              [d.phone, person.phone || "-", false],
              [d.matricule, person.matricule || "-", false],
              [d.department, person.department || "-", false],
              [d.program, person.program || "-", false],
              [d.joined, joined, false],
            ].map(([label, value, wide]) => (
              <div key={String(label)} className={`min-w-0 ${wide ? "sm:col-span-2" : ""}`}>
                <dt className="text-sm text-muted">{label}</dt>
                <dd className="m-0 font-semibold break-all">{value}</dd>
              </div>
            ))}
          </dl>
        </Card>

        {isSelf ? (
          <Card className="self-start">
            <p role="note">{d.own}</p>
          </Card>
        ) : (
          <div className="flex flex-col gap-6">
            <Card className="flex flex-col gap-4">
              <h2 className="text-xl font-bold">{d.roleHeading}</h2>
              <form action={changeRole} className="flex flex-col gap-5">
                <input type="hidden" name="id" value={person.id} />
                <Select
                  id="role"
                  name="role"
                  label={d.roleLabel}
                  icon={UserMultiple02Icon}
                  hint={d.roleHint}
                  defaultValue={person.role}
                  options={ROLES.map((role) => ({ value: role, label: t.role[role] }))}
                />
                <div>
                  <Button type="submit">{d.roleButton}</Button>
                </div>
              </form>
            </Card>

            <Card className="flex flex-col gap-4">
              <h2 className="text-xl font-bold">{d.accountHeading}</h2>
              {person.status === "pending" && person.join_requested_at ? (
                <div className="flex flex-col gap-4">
                  <p className="text-sm text-muted">{t.people.verify.detailHint}</p>
                  <JoinRequestActions id={person.id} from="detail" copy={t.people.verify} verify={verifyMember} decline={declineMember} />
                </div>
              ) : person.status === "suspended" ? (
                <form action={changeStatus} className="flex flex-col gap-4">
                  <input type="hidden" name="id" value={person.id} />
                  <input type="hidden" name="status" value="verified" />
                  <p className="text-sm text-muted">{d.restoreHint}</p>
                  <div>
                    <Button type="submit" icon={Tick02Icon}>
                      {d.restore}
                    </Button>
                  </div>
                </form>
              ) : (
                <details>
                  <summary className="inline-flex cursor-pointer list-none items-center gap-2 rounded-sm px-4 py-2.5 text-sm font-semibold text-bad transition-colors duration-(--dur-fast) hover:bg-bad-bg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden">
                    {d.suspendOpen}
                  </summary>
                  <form action={changeStatus} className="mt-4 flex flex-col gap-4">
                    <input type="hidden" name="id" value={person.id} />
                    <input type="hidden" name="status" value="suspended" />
                    <p className="text-sm text-muted">{d.suspendHint}</p>
                    <div>
                      <Button type="submit" variant="danger" icon={Cancel01Icon}>
                        {d.suspendConfirm}
                      </Button>
                    </div>
                  </form>
                </details>
              )}
            </Card>
          </div>
        )}
      </div>
    </>
  );
}
