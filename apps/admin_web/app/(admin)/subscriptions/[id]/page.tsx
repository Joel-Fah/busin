import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import Image from "next/image";
import { Suspense } from "react";
import { ArrowLeft01Icon, ArrowUpRight01Icon, Cancel01Icon, Tick02Icon } from "@hugeicons/core-free-icons";
import Link from "next/link";

import { FlashToast } from "@/components/FlashToast";
import { ReasonForm } from "@/components/ReasonForm";
import { StatusSummary } from "@/components/subscriptions/StatusSummary";
import { Accordion } from "@/components/ui/Accordion";
import { Avatar } from "@/components/ui/Avatar";
import { Button, ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";

import { PlanParts } from "@/components/billing/PlanParts";
import { requireAdmin } from "@/lib/auth";
import { formatAmount, isInstallmentPlan, planPercents, type InstallmentRow } from "@/lib/billing";
import { format } from "@/lib/i18n/messages";
import { REASON_MIN } from "@/lib/reasons";
import { getMessages } from "@/lib/i18n/server";
import { createClient } from "@/lib/supabase/server";
import {
  MAX_REASON_LENGTH,
  eventTone,
  isEventAction,
  isReviewErrorKey,
  isUuid,
  liveRequest,
  orderHistory,
  statusTone,
  type RequestHistory,
  type SubscriptionOperation,
} from "@/lib/subscriptions";

import { approveSubscription, markInstallmentPaid, reinstateSubscription, rejectInstallment, rejectSubscription, revokeSubscription } from "../actions";

export const metadata: Metadata = { title: "Subscription" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[]; partError?: string | string[]; past?: string | string[] }>;

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
      `id, status, created_at, proof_path, review_note, reviewed_at, student_id, semester_id,
       period_start, period_end, payment_mode, amount_xaf, installment_plan,
       student:profiles!subscriptions_student_id_school_id_fkey(full_name, email, matricule, status),
       semester:semesters!subscriptions_semester_id_school_id_fkey(name, year),
       stop:stops!subscriptions_stop_id_school_id_fkey(name),
       reviewer:profiles!subscriptions_reviewed_by_fkey(full_name)`,
    )
    .eq("id", id)
    .maybeSingle();
  if (!row) notFound();

  // Everything this student asked for in this period (the semester, or the month for monthly billing), and what happened
  // to each: the history.
  const siblingsQuery = supabase
    .from("subscriptions")
    .select("id, status, created_at, stop:stops!subscriptions_stop_id_school_id_fkey(name)")
    .eq("student_id", row.student_id)
    .eq("semester_id", row.semester_id);
  const { data: siblings } = await (row.period_start ? siblingsQuery.eq("period_start", row.period_start) : siblingsQuery.is("period_start", null))
    .order("created_at", { ascending: false })
    .limit(50);

  // The parts of a subscription paid in installments (ADR 0022), each with a short-lived link to its proof.
  const { data: partRows } =
    row.payment_mode === "installments"
      ? await supabase
          .from("subscription_installments")
          .select("id, seq, percent, amount_xaf, due_date, status, proof_path, review_note")
          .eq("subscription_id", row.id)
          .order("seq")
          .limit(4)
      : { data: [] as InstallmentRow[] };
  const parts = await Promise.all(
    (partRows ?? []).map(async (part) => {
      if (!part.proof_path || part.seq === 1) return { ...part, proofUrl: null as string | null };
      const { data } = await supabase.storage.from("proofs").createSignedUrl(part.proof_path, 60);
      return { ...part, proofUrl: data?.signedUrl ?? null };
    }),
  );
  const siblingIds = (siblings ?? []).map((s) => s.id);
  const { data: events } = siblingIds.length
    ? await supabase
        .from("subscription_events")
        .select("subscription_id, action, note, created_at, actor_id, actor:profiles!subscription_events_actor_id_fkey(full_name)")
        .in("subscription_id", siblingIds)
        .order("created_at", { ascending: false })
        .limit(500)
    : { data: [] };
  // Every receipt sent for a part stays in the history (ADR 0022), each with a short-lived link.
  const { data: receipts } = siblingIds.length
    ? await supabase
        .from("installment_receipts")
        .select("id, subscription_id, seq, proof_path, sent_at, decision, note, decided_at, decider:profiles!installment_receipts_decided_by_fkey(full_name)")
        .in("subscription_id", siblingIds)
        .order("sent_at")
        .limit(200)
    : { data: [] };
  const receiptPaths = (receipts ?? []).flatMap((r) => (r.proof_path ? [r.proof_path] : []));
  const { data: signedReceipts } = receiptPaths.length ? await supabase.storage.from("proofs").createSignedUrls(receiptPaths, 60) : { data: [] };
  const receiptUrl = new Map((signedReceipts ?? []).flatMap((s) => (s.path && s.signedUrl ? [[s.path, s.signedUrl] as const] : [])));
  const receiptOperations = (subscriptionId: string): SubscriptionOperation[] =>
    (receipts ?? [])
      .filter((r) => r.subscription_id === subscriptionId)
      .flatMap((r) => [
        ...(r.proof_path
          ? [{ action: "partSent" as const, at: r.sent_at, actorName: null, byStudent: true, note: null, seq: r.seq, proofUrl: receiptUrl.get(r.proof_path) ?? null }]
          : []),
        ...(r.decision === "paid" || r.decision === "rejected"
          ? [
              {
                action: r.decision === "paid" ? ("partPaid" as const) : ("partRejected" as const),
                at: r.decided_at ?? r.sent_at,
                actorName: r.decider?.full_name || null,
                byStudent: false,
                note: r.decision === "rejected" ? r.note : null,
                seq: r.seq,
              },
            ]
          : []),
      ]);
  const history: RequestHistory[] = orderHistory(
    (siblings ?? []).map((s) => ({
      id: s.id,
      status: s.status,
      createdAt: s.created_at,
      stopName: s.stop?.name ?? null,
      operations: (events ?? [])
        .filter((e) => e.subscription_id === s.id && isEventAction(e.action))
        .map((e) => ({
          action: e.action as RequestHistory["operations"][number]["action"],
          at: e.created_at,
          actorName: e.actor?.full_name || null,
          byStudent: e.actor_id === row.student_id,
          note: e.note,
        }))
        .concat(receiptOperations(s.id)),
    })),
  );

  // A student who asked again has one request that matters now (pending or approved). Opening an older one lands on it,
  // unless the admin came here on purpose from the history ("past").
  const query = await searchParams;
  const live = liveRequest(history);
  const asked = single(query.past) === "1";
  if (live && live.id !== row.id && !asked) {
    const keep = new URLSearchParams();
    for (const key of ["done", "error"] as const) {
      const value = single(query[key]);
      if (value) keep.set(key, value);
    }
    redirect(`/subscriptions/${live.id}${keep.size ? `?${keep}` : ""}`);
  }
  const supersededBy = live && live.id !== row.id ? live : null;

  // How many requests the student has made so far, by state.
  const { data: everything } = await supabase.from("subscriptions").select("status").eq("student_id", row.student_id).limit(200);
  const allStatuses = (everything ?? []).map((s) => s.status);

  // A short-lived link: the proof bucket is private and the link stops working after a minute.
  let proofUrl: string | null = null;
  let proofFailed = false;
  if (row.proof_path) {
    const { data, error } = await supabase.storage.from("proofs").createSignedUrl(row.proof_path, 60);
    if (error || !data) proofFailed = true;
    else proofUrl = data.signedUrl;
  }

  const done = single(query.done);
  const errorParam = single(query.error);
  const errorKey = isReviewErrorKey(errorParam) ? errorParam : null;
  const partErrorParam = single(query.partError);
  const partErrorKey = partErrorParam === "not_open" || partErrorParam === "not_found" || partErrorParam === "generic" ? partErrorParam : null;
  const pt = t.subscriptions.detail.parts;
  const todayIso = new Intl.DateTimeFormat("en-CA", { timeZone: admin.schoolTimezone }).format(new Date());
  const day = (iso: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: "UTC" }).format(new Date(`${iso}T00:00:00Z`));
  const month = row.period_start ? new Intl.DateTimeFormat(locale, { month: "long", year: "numeric", timeZone: "UTC" }).format(new Date(`${row.period_start}T00:00:00Z`)) : null;
  const plan = isInstallmentPlan(row.installment_plan) ? row.installment_plan : null;

  // Words for the reason forms: the shared labels, and what each problem the server can answer with says.
  const reasonText = { presetsLabel: t.reasons.presetsLabel, counter: t.reasons.counter, minimum: t.reasons.minimum };
  const reasonErrors: Record<string, string> = {
    ...t.subscriptions.errors,
    reason_required: t.reasons.problems.reason_required,
    reason_too_short: format(t.reasons.problems.reason_too_short, { min: REASON_MIN }),
    reason_too_long: format(t.reasons.problems.reason_too_long, { max: MAX_REASON_LENGTH }),
    part_not_open: pt.errors.not_open,
    part_not_found: pt.errors.not_found,
    part_generic: pt.errors.generic,
  };

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
          <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-2">
            <Chip tone={statusTone(row.status)}>{t.status[row.status]}</Chip>
            <StatusSummary statuses={allStatuses} label={t.subscriptions.detail.summaryLabel} names={t.status} />
          </div>
        </div>
      </header>

      {done === "approved" || done === "rejected" || done === "revoked" || done === "reinstated" ? <FlashToast message={t.subscriptions.done[done]} /> : null}
      {done === "part_paid" ? <FlashToast message={pt.done.paid} /> : done === "part_rejected" ? <FlashToast message={pt.done.rejected} /> : null}
      {partErrorKey ? <Notice tone="bad">{pt.errors[partErrorKey]}</Notice> : null}
      {supersededBy ? (
        <Notice tone="warn" className="flex flex-wrap items-center gap-x-4 gap-y-2">
          <span>{format(t.subscriptions.detail.superseded, { status: t.status[supersededBy.status].toLowerCase() })}</span>
          <Link href={`/subscriptions/${supersededBy.id}`} className="font-semibold">
            {t.subscriptions.detail.supersededOpen}
          </Link>
        </Notice>
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
                ...(month ? [[t.subscriptions.detail.month, month]] : []),
                [t.subscriptions.detail.stop, row.stop?.name ?? "-"],
                ...(row.amount_xaf !== null
                  ? [
                      [t.subscriptions.detail.amount, formatAmount(row.amount_xaf, locale)],
                      [
                        t.subscriptions.detail.payment,
                        plan ? format(t.subscriptions.detail.paymentInstallments, { plan }) : t.subscriptions.detail.paymentFull,
                      ],
                    ]
                  : []),
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

          {/* A suspended student's subscription is frozen: nothing is done to it until the account is restored. */}
          {row.student?.status === "suspended" ? (
            <Card className="flex flex-col gap-3">
              <h2 className="text-xl font-bold">{t.subscriptions.detail.decision}</h2>
              <Notice tone="warn">{t.subscriptions.detail.studentSuspended}</Notice>
              <div>
                <ButtonLink href={`/people/${row.student_id}`} variant="secondary">
                  {t.subscriptions.detail.openPerson}
                </ButtonLink>
              </div>
            </Card>
          ) : row.status === "pending" ? (
            <Card className="flex flex-col gap-5">
              <h2 className="text-xl font-bold">{t.subscriptions.detail.decision}</h2>
              <form action={approveSubscription} className="flex flex-col gap-3">
                <input type="hidden" name="id" value={row.id} />
                {row.proof_path ? (
                  <p className="text-sm text-muted">{t.subscriptions.detail.approveHint}</p>
                ) : (
                  <Notice tone="warn">{t.subscriptions.detail.approveNeedsProof}</Notice>
                )}
                <div>
                  <Button type="submit" icon={Tick02Icon} disabled={!row.proof_path}>
                    {t.subscriptions.detail.approve}
                  </Button>
                </div>
              </form>

              <details className="group">
                <summary className="inline-flex cursor-pointer list-none items-center gap-2 rounded-sm px-4 py-2.5 text-sm font-semibold text-bad transition-colors duration-(--dur-fast) hover:bg-bad-bg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden">
                  {t.subscriptions.detail.rejectOpen}
                </summary>
                <ReasonForm
                  action={rejectSubscription}
                  hidden={{ id: row.id }}
                  idPrefix="reject"
                  text={{ ...reasonText, label: t.subscriptions.detail.reasonLabel, hint: t.subscriptions.detail.reasonHint, placeholder: t.subscriptions.detail.reasonPlaceholder }}
                  presets={t.subscriptions.reasons.reject}
                  max={MAX_REASON_LENGTH}
                  errors={reasonErrors}
                  submit={{ label: t.subscriptions.detail.rejectConfirm, icon: Cancel01Icon, variant: "danger" }}
                />
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
              {row.status === "approved" ? (
                <details className="group">
                  <summary className="inline-flex cursor-pointer list-none items-center gap-2 rounded-sm px-4 py-2.5 text-sm font-semibold text-bad transition-colors duration-(--dur-fast) hover:bg-bad-bg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden">
                    {t.subscriptions.detail.revokeOpen}
                  </summary>
                  <ReasonForm
                    action={revokeSubscription}
                    hidden={{ id: row.id }}
                    idPrefix="revoke"
                    intro={<p className="text-sm text-muted">{t.subscriptions.detail.revokeHint}</p>}
                    text={{ ...reasonText, label: t.subscriptions.detail.revokeReasonLabel, hint: t.subscriptions.detail.reasonHint, placeholder: t.subscriptions.detail.reasonPlaceholder }}
                    presets={t.subscriptions.reasons.revoke}
                    max={MAX_REASON_LENGTH}
                    errors={reasonErrors}
                    submit={{ label: t.subscriptions.detail.revokeConfirm, icon: Cancel01Icon, variant: "danger" }}
                  />
                </details>
              ) : null}
              {row.status === "revoked" && !supersededBy ? (
                <details className="group">
                  <summary className="inline-flex cursor-pointer list-none items-center gap-2 rounded-sm px-4 py-2.5 text-sm font-semibold text-ok transition-colors duration-(--dur-fast) hover:bg-ok-bg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden">
                    {t.subscriptions.detail.reinstateOpen}
                  </summary>
                  <ReasonForm
                    action={reinstateSubscription}
                    hidden={{ id: row.id }}
                    idPrefix="reinstate"
                    intro={<p className="text-sm text-muted">{t.subscriptions.detail.reinstateHint}</p>}
                    text={{ ...reasonText, label: t.subscriptions.detail.reinstateNoteLabel, hint: t.subscriptions.detail.reasonHint }}
                    presets={t.subscriptions.reasons.reinstate}
                    max={MAX_REASON_LENGTH}
                    errors={reasonErrors}
                    submit={{ label: t.subscriptions.detail.reinstateConfirm, icon: Tick02Icon }}
                  />
                </details>
              ) : null}
            </Card>
          )}
          {parts.length > 0 ? (
            <Card className="flex flex-col gap-4" data-testid="parts">
              <div>
                <h2 className="text-xl font-bold">{pt.title}</h2>
                <p className="mt-1 text-sm text-muted">{pt.hint}</p>
              </div>
              {plan ? <PlanParts percents={planPercents(plan)} amounts={parts.map((p) => formatAmount(p.amount_xaf, locale))} label={pt.title} /> : null}
              <ol className="m-0 flex list-none flex-col gap-3 p-0">
                {parts.map((part) => {
                  const late = part.seq > 1 && (part.status === "due" || part.status === "rejected") && part.due_date <= todayIso;
                  const status = part.status as keyof typeof pt.statuses;
                  return (
                    <li key={part.id} className="flex flex-col gap-3 rounded-md bg-surface-2 p-4" data-testid={`part-${part.seq}`}>
                      <div className="flex flex-wrap items-center justify-between gap-2">
                        <div>
                          <p className="font-bold">
                            {format(pt.part, { n: part.seq })} · {format(pt.share, { percent: part.percent })} · {formatAmount(part.amount_xaf, locale)}
                          </p>
                          <p className="text-sm text-muted">{format(pt.due, { date: day(part.due_date) })}</p>
                        </div>
                        <span className="flex flex-wrap gap-1.5">
                          <Chip tone={part.status === "paid" ? "ok" : part.status === "rejected" ? "bad" : part.status === "submitted" ? "warn" : "neutral"}>{pt.statuses[status]}</Chip>
                          {late ? <Chip tone="bad">{pt.late}</Chip> : null}
                        </span>
                      </div>
                      {part.review_note && part.status === "rejected" ? <p className="text-sm">{part.review_note}</p> : null}
                      {part.seq > 1 && part.status !== "paid" && row.status === "approved" ? (
                        <div className="flex flex-wrap items-center gap-2">
                          {part.proofUrl ? (
                            <a href={part.proofUrl} target="_blank" rel="noopener noreferrer" className="inline-flex h-11 items-center gap-2 rounded-sm bg-surface px-4 text-sm font-semibold text-fg no-underline hover:bg-line focus-visible:outline-3 focus-visible:outline-focus">
                              <Icon icon={ArrowUpRight01Icon} size={18} />
                              {pt.proofOpen}
                            </a>
                          ) : null}
                          <form action={markInstallmentPaid}>
                            <input type="hidden" name="subscription" value={row.id} />
                            <input type="hidden" name="part" value={part.id} />
                            <Button type="submit" icon={Tick02Icon}>
                              {pt.markPaid}
                            </Button>
                          </form>
                          {part.status === "submitted" ? (
                            <details className="group w-full">
                              <summary className="inline-flex cursor-pointer list-none items-center gap-2 rounded-sm px-4 py-2.5 text-sm font-semibold text-bad transition-colors duration-(--dur-fast) hover:bg-bad-bg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden">
                                {pt.rejectOpen}
                              </summary>
                              <ReasonForm
                                action={rejectInstallment}
                                hidden={{ subscription: row.id, part: part.id }}
                                idPrefix={`part-${part.seq}`}
                                text={{ ...reasonText, label: pt.reasonLabel, hint: t.subscriptions.detail.reasonHint, placeholder: t.subscriptions.detail.reasonPlaceholder }}
                                presets={t.subscriptions.reasons.reject}
                                max={MAX_REASON_LENGTH}
                                errors={reasonErrors}
                                submit={{ label: pt.rejectConfirm, icon: Cancel01Icon, variant: "danger" }}
                              />
                            </details>
                          ) : null}
                        </div>
                      ) : null}
                    </li>
                  );
                })}
              </ol>
            </Card>
          ) : null}
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

      <Card className="flex flex-col gap-4">
        <div>
          <h2 className="text-xl font-bold">{t.subscriptions.detail.history.title}</h2>
          <p className="mt-1 text-sm text-muted">{t.subscriptions.detail.history.hint}</p>
        </div>
        <div className="flex flex-col gap-3">
          {history.map((request, index) => (
            // The latest request opens first; the others wait closed.
            <Accordion
              key={request.id}
              defaultOpen={index === 0}
              summary={
                <span className="flex flex-wrap items-center gap-x-3 gap-y-1">
                  <span className="font-semibold">{format(t.subscriptions.detail.history.request, { date: dateTime(request.createdAt) })}</span>
                  <Chip tone={statusTone(request.status)}>{t.status[request.status]}</Chip>
                  {request.stopName ? <span className="text-sm text-muted">{request.stopName}</span> : null}
                  {request.id === row.id ? <span className="text-sm text-muted">{t.subscriptions.detail.history.thisOne}</span> : null}
                </span>
              }
            >
              <ol className="m-0 flex list-none flex-col gap-3 p-0">
                {request.operations.map((op, i) => (
                  <li key={`${op.action}-${op.at}-${i}`} className="flex flex-col gap-1 border-l-2 border-line pl-4">
                    <p className="flex flex-wrap items-center gap-x-3 gap-y-1">
                      <Chip tone={eventTone(op.action)}>{format(t.subscriptions.detail.history.events[op.action], { n: op.seq ?? "" })}</Chip>
                      <span className="text-sm text-muted">
                        {dateTime(op.at)}
                        {op.byStudent
                          ? ` ${t.subscriptions.detail.history.byStudent}`
                          : op.actorName
                            ? ` ${format(t.subscriptions.detail.history.by, { name: op.actorName })}`
                            : ""}
                      </span>
                    </p>
                    {op.note ? <p className="text-sm">{op.note}</p> : null}
                    {op.proofUrl ? (
                      <a href={op.proofUrl} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1.5 text-sm font-semibold">
                        <Icon icon={ArrowUpRight01Icon} size={16} />
                        {t.subscriptions.detail.parts.proofOpen}
                      </a>
                    ) : null}
                  </li>
                ))}
              </ol>
              {request.id !== row.id ? (
                <p className="mt-3">
                  <Link href={`/subscriptions/${request.id}?past=1`} className="text-sm font-semibold">
                    {t.subscriptions.detail.history.open}
                  </Link>
                </p>
              ) : null}
            </Accordion>
          ))}
        </div>
      </Card>
    </>
  );
}
