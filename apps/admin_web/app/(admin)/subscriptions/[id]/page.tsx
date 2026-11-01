import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { requireAdmin } from "@/lib/auth";
import { format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { createClient } from "@/lib/supabase/server";
import { MAX_REASON_LENGTH, isReviewErrorKey, isUuid, pillClass } from "@/lib/subscriptions";

import { reviewSubscription } from "../actions";

export const metadata: Metadata = { title: "Subscription" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

export default function SubscriptionPage({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
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
      <p>
        <Link href="/subscriptions">{t.subscriptions.detail.back}</Link>
      </p>
      <header className="page-head">
        <h1>{studentName}</h1>
        <p>
          <span className={pillClass(row.status)}>{t.status[row.status]}</span>
        </p>
      </header>

      {done === "approved" || done === "rejected" ? (
        <p className="success" role="status">
          {t.subscriptions.done[done]}
        </p>
      ) : null}
      {errorKey ? (
        <p className="notice" role="alert">
          {t.subscriptions.errors[errorKey]}
        </p>
      ) : null}

      <section className="card">
        <dl className="detail-grid">
          <div>
            <dt>{t.subscriptions.detail.email}</dt>
            <dd>{row.student?.email}</dd>
          </div>
          <div>
            <dt>{t.subscriptions.detail.matricule}</dt>
            <dd>{row.student?.matricule || "-"}</dd>
          </div>
          <div>
            <dt>{t.subscriptions.detail.semester}</dt>
            <dd>{row.semester ? `${t.semester[row.semester.name]} ${row.semester.year}` : "-"}</dd>
          </div>
          <div>
            <dt>{t.subscriptions.detail.stop}</dt>
            <dd>{row.stop?.name ?? "-"}</dd>
          </div>
          <div>
            <dt>{t.subscriptions.detail.submitted}</dt>
            <dd>{dateTime(row.created_at)}</dd>
          </div>
        </dl>
      </section>

      <section className="card stack">
        <h2>{t.subscriptions.detail.proof}</h2>
        {proofUrl ? (
          <>
            {/* A signed, short-lived storage URL: not suitable for the image optimizer. */}
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={proofUrl} alt={t.subscriptions.detail.proofImageAlt} className="proof" />
            <a href={proofUrl} target="_blank" rel="noopener noreferrer">
              {t.subscriptions.detail.proofOpen}
            </a>
          </>
        ) : proofFailed ? (
          <p className="notice" role="alert">
            {t.subscriptions.detail.proofUnavailable}
          </p>
        ) : (
          <p>{t.subscriptions.detail.proofMissing}</p>
        )}
      </section>

      {row.status === "pending" ? (
        <section className="card stack">
          <h2>{t.subscriptions.detail.decision}</h2>
          <form action={reviewSubscription} className="stack">
            <input type="hidden" name="id" value={row.id} />
            <input type="hidden" name="decision" value="approved" />
            <p>{t.subscriptions.detail.approveHint}</p>
            <div className="row">
              <button type="submit" className="btn btn-primary">
                {t.subscriptions.detail.approve}
              </button>
            </div>
          </form>

          <details className="reject">
            <summary>{t.subscriptions.detail.rejectOpen}</summary>
            <form action={reviewSubscription} className="stack">
              <input type="hidden" name="id" value={row.id} />
              <input type="hidden" name="decision" value="rejected" />
              <div className="field">
                <label htmlFor="note">{t.subscriptions.detail.reasonLabel}</label>
                <textarea
                  id="note"
                  name="note"
                  required
                  maxLength={MAX_REASON_LENGTH}
                  rows={3}
                  aria-describedby="note-hint"
                />
                <span id="note-hint" className="muted">
                  {t.subscriptions.detail.reasonHint}
                </span>
              </div>
              <div className="row">
                <button type="submit" className="btn btn-secondary btn-danger">
                  {t.subscriptions.detail.rejectConfirm}
                </button>
              </div>
            </form>
          </details>
        </section>
      ) : (
        <section className="card stack">
          <h2>{t.subscriptions.detail.decision}</h2>
          {row.reviewed_at ? (
            <p>
              {format(t.subscriptions.detail.reviewedBy, {
                name: row.reviewer?.full_name || "-",
                date: dateTime(row.reviewed_at),
              })}
            </p>
          ) : null}
          {row.review_note ? (
            <div>
              <strong>{t.subscriptions.detail.note}</strong>
              <p>{row.review_note}</p>
            </div>
          ) : null}
        </section>
      )}
    </>
  );
}
