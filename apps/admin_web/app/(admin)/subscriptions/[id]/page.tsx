import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Image from "next/image";
import { Suspense } from "react";
import { ArrowLeft01Icon, ArrowUpRight01Icon, Cancel01Icon, Comment01Icon, Tick02Icon } from "@hugeicons/core-free-icons";

import { Avatar } from "@/components/ui/Avatar";
import { Button, ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Textarea } from "@/components/ui/Textarea";

import { requireAdmin } from "@/lib/auth";
import { format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { createClient } from "@/lib/supabase/server";
import { MAX_REASON_LENGTH, isReviewErrorKey, isUuid, statusTone } from "@/lib/subscriptions";

import { reviewSubscription } from "../actions";

export const metadata: Metadata = { title: "Subscription" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

export default function SubscriptionPage({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={3} />}>
      <SubscriptionDetail params={params} searchParams={searchParams} />
    </Suspense>
  );
}

function single(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

async function SubscriptionDetail({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const { id } = await params;
  if (!isUuid(id)) notFound();

  const supabase = await createClient();
  const { data: row } = await supabase
    .from("subscriptions")
    .select(
      `id, status, created_at, proof_path, review_note, reviewed_at,
       student:profiles!subscriptions_student_id_school_id_fkey(full_name, email, matricule),
       semester:semesters!subscriptions_semester_id_school_id_fkey(name, year),
       stop:stops!subscriptions_stop_id_school_id_fkey(name),
       reviewer:profiles!subscriptions_reviewed_by_fkey(full_name)`,
    )
    .eq("id", id)
    .maybeSingle();
  if (!row) notFound();

  // A short-lived link: the proof bucket is private and the link stops working after a minute.
  let proofUrl: string | null = null;
  let proofFailed = false;
  if (row.proof_path) {
    const { data, error } = await supabase.storage.from("proofs").createSignedUrl(row.proof_path, 60);
    if (error || !data) proofFailed = true;
    else proofUrl = data.signedUrl;
  }

  const query = await searchParams;
  const done = single(query.done);
  const errorParam = single(query.error);
  const errorKey = isReviewErrorKey(errorParam) ? errorParam : null;

  const dateTime = (value: string) =>
    new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone: admin.schoolTimezone }).format(
      new Date(value),
    );
  const studentName = row.student?.full_name || row.student?.email || "";

  return (
    <>
      <div>
        <ButtonLink href="/subscriptions" variant="ghost" icon={ArrowLeft01Icon} className="-ml-4">
          {t.subscriptions.detail.back}
        </ButtonLink>
      </div>

      <header className="flex flex-wrap items-center gap-4">
        <Avatar name={studentName} url={null} size={64} />
        <div>
          <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">{studentName}</h1>
          <p className="mt-2">
            <Chip tone={statusTone(row.status)}>{t.status[row.status]}</Chip>
          </p>
        </div>
      </header>

      {done === "approved" || done === "rejected" ? (
        <p className="rounded-md bg-ok-bg px-5 py-4 text-sm font-semibold text-ok" role="status">
          {t.subscriptions.done[done]}
        </p>
      ) : null}
      {errorKey ? (
        <p className="rounded-md bg-bad-bg px-5 py-4 text-sm text-bad" role="alert">
          {t.subscriptions.errors[errorKey]}
        </p>
      ) : null}

      <div className="grid gap-6 lg:grid-cols-[minmax(0,2fr)_minmax(0,3fr)]">
        <div className="flex flex-col gap-6">
          <Card>
            <dl className="m-0 grid gap-5 sm:grid-cols-2">
              {[
                [t.subscriptions.detail.email, row.student?.email],
                [t.subscriptions.detail.matricule, row.student?.matricule || "-"],
                [t.subscriptions.detail.semester, row.semester ? `${t.semester[row.semester.name]} ${row.semester.year}` : "-"],
                [t.subscriptions.detail.stop, row.stop?.name ?? "-"],
                [t.subscriptions.detail.submitted, dateTime(row.created_at)],
              ].map(([label, value], index) => (
                // The email is long, so it takes the whole row.
                <div key={label} className={`min-w-0 ${index === 0 ? "sm:col-span-2" : ""}`}>
                  <dt className="text-sm text-muted">{label}</dt>
                  <dd className="m-0 font-semibold break-all">{value}</dd>
                </div>
              ))}
            </dl>
          </Card>

          {row.status === "pending" ? (
            <Card className="flex flex-col gap-5">
              <h2 className="text-xl font-bold">{t.subscriptions.detail.decision}</h2>
              <form action={reviewSubscription} className="flex flex-col gap-3">
                <input type="hidden" name="id" value={row.id} />
                <input type="hidden" name="decision" value="approved" />
                <p className="text-sm text-muted">{t.subscriptions.detail.approveHint}</p>
                <div>
                  <Button type="submit" icon={Tick02Icon}>
                    {t.subscriptions.detail.approve}
                  </Button>
                </div>
              </form>

              <details className="group">
                <summary className="inline-flex cursor-pointer list-none items-center gap-2 rounded-sm px-4 py-2.5 text-sm font-semibold text-bad transition-colors duration-(--dur-fast) hover:bg-bad-bg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden">
                  {t.subscriptions.detail.rejectOpen}
                </summary>
                <form action={reviewSubscription} className="mt-4 flex flex-col gap-4">
                  <input type="hidden" name="id" value={row.id} />
                  <input type="hidden" name="decision" value="rejected" />
                  <Textarea
                    id="note"
                    name="note"
                    label={t.subscriptions.detail.reasonLabel}
                    icon={Comment01Icon}
                    required
                    maxLength={MAX_REASON_LENGTH}
                    rows={3}
                    hint={t.subscriptions.detail.reasonHint}
                    placeholder={t.subscriptions.detail.reasonPlaceholder}
                  />
                  <div>
                    <Button type="submit" variant="danger" icon={Cancel01Icon}>
                      {t.subscriptions.detail.rejectConfirm}
                    </Button>
                  </div>
                </form>
              </details>
            </Card>
          ) : (
            <Card className="flex flex-col gap-4">
              <h2 className="text-xl font-bold">{t.subscriptions.detail.decision}</h2>
              {row.reviewed_at ? (
                <p>
                  {format(t.subscriptions.detail.reviewedBy, {
                    name: row.reviewer?.full_name || "-",
                    date: dateTime(row.reviewed_at),
                  })}
                </p>
              ) : null}
              {row.review_note ? (
                <div className="rounded-md bg-surface-2 p-4">
                  <p className="text-sm font-semibold text-muted">{t.subscriptions.detail.note}</p>
                  <p className="mt-1">{row.review_note}</p>
                </div>
              ) : null}
            </Card>
          )}
        </div>

        <Card className="flex flex-col gap-4 self-start">
          <h2 className="text-xl font-bold">{t.subscriptions.detail.proof}</h2>
          {proofUrl ? (
            <>
              {/* A signed, short-lived storage URL: not suitable for the image optimizer. */}
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={proofUrl} alt={t.subscriptions.detail.proofImageAlt} className="max-h-[32rem] w-full rounded-md bg-surface-2 object-contain" />
              <div>
                <a
                  href={proofUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex h-11 items-center gap-2 rounded-sm bg-surface-2 px-5 text-sm font-semibold text-fg no-underline transition-colors duration-(--dur-fast) hover:bg-line focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus"
                >
                  <Icon icon={ArrowUpRight01Icon} size={18} />
                  {t.subscriptions.detail.proofOpen}
                </a>
              </div>
            </>
          ) : proofFailed ? (
            <p className="rounded-md bg-bad-bg px-4 py-3 text-sm text-bad" role="alert">
              {t.subscriptions.detail.proofUnavailable}
            </p>
          ) : (
            <div className="flex flex-col items-center gap-3 rounded-md bg-surface-2 px-6 py-10 text-center">
              <Image src="/illustrations/papers.webp" alt="" width={96} height={96} className="size-24" />
              <p className="font-semibold">{t.subscriptions.detail.proofMissing}</p>
            </div>
          )}
        </Card>
      </div>
    </>
  );
}
