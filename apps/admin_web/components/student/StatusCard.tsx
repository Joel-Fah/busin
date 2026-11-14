import { QrCodeIcon } from "@hugeicons/core-free-icons";
import Link from "next/link";
import type { ReactNode } from "react";

import { Icon } from "@/components/ui/Icon";
import { Chip } from "@/components/ui/Chip";
import { ProofViewer } from "@/components/student/ProofViewer";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import { stageOf, type SubscriptionRow } from "@/lib/student/subscription";
import { Contour } from "@/components/ui/Contour";

const TONE = { pending: "warn", approved: "ok", rejected: "bad", revoked: "bad", expired: "neutral" } as const;

/**
 * Where the request stands, as the app's status card: the state with its label, the date it was sent, the three steps
 * (sent, checking, decision), the school's reason when it said no, the stop, the proof photo, and what to do next.
 */
export function StatusCard({
  copy,
  subscription,
  stopName,
  sentOn,
  proofUrl,
  requestAgainHref,
  parts = null,
}: {
  copy: StudentCopy["subscription"];
  subscription: SubscriptionRow;
  stopName: string;
  sentOn: string;
  proofUrl: string | null;
  requestAgainHref: string | null;
  /** Paid in installments (ADR 0022): the parts, shown under the stop. */
  parts?: ReactNode;
}) {
  const status = subscription.status;
  const title = { pending: copy.pendingTitle, approved: copy.approvedTitle, rejected: copy.rejectedTitle, revoked: copy.revokedTitle, expired: copy.expiredTitle }[status];
  const body = status === "pending" ? copy.pendingBody : status === "approved" ? format(copy.approvedBody, { stop: stopName }) : status === "expired" ? copy.expiredBody : null;
  const { reached, failed } = stageOf(status);
  const stages = [copy.stages.sent, copy.stages.checking, copy.stages.decided];

  return (
    <section className="flex flex-col gap-4 relative rounded-lg bg-surface p-5 shadow-soft" aria-labelledby="status-title" data-testid="status-card">
      <Contour radius={28} inset={10} />
      <div className="flex flex-wrap items-center justify-between gap-2">
        <Chip tone={TONE[status]}>{copy.status[status]}</Chip>
        <span className="text-sm text-muted">{format(copy.sent, { date: sentOn })}</span>
      </div>
      <div>
        <h2 id="status-title" className="m-0 text-2xl font-extrabold tracking-tight">
          {title}
        </h2>
        {body ? <p className="m-0 mt-1 text-muted">{body}</p> : null}
      </div>
      <ol className="m-0 grid list-none grid-cols-3 gap-2 p-0">
        {stages.map((label, index) => {
          const n = index + 1;
          const done = n <= reached;
          const bad = failed && n === reached;
          return (
            <li key={label} aria-label={format(copy.stages.step, { number: n, total: 3, label })} aria-current={n === reached ? "step" : undefined} className="flex flex-col gap-1.5">
              <span className={`h-1.5 rounded-xs ${bad ? "bg-bad" : done ? "bg-ok" : "bg-surface-2"}`} />
              <span className={`text-xs font-semibold ${done ? "text-fg" : "text-muted"}`}>{label}</span>
            </li>
          );
        })}
      </ol>
      {status === "rejected" || status === "revoked" ? (
        <div className="rounded-md bg-bad-bg p-4 text-sm">
          <p className="m-0 font-semibold text-bad">{copy.reason}</p>
          <p className="m-0 mt-1 text-fg">{subscription.review_note?.trim() || copy.noReason}</p>
        </div>
      ) : null}
      <div className="flex items-center gap-4">
        <div className="min-w-0 flex-1">
          <p className="m-0 text-sm text-muted">{copy.stop}</p>
          <p className="m-0 truncate font-bold">{stopName}</p>
        </div>
        {proofUrl ? (
          <ProofViewer url={proofUrl} label={copy.proofLabel} close={copy.close} />
        ) : subscription.proof_path ? (
          <p className="m-0 max-w-40 text-xs text-muted">{copy.proofUnavailable}</p>
        ) : null}
      </div>
      {parts}
      {status === "approved" ? (
        <Link href="/app/code" className="inline-flex h-14 items-center justify-center gap-2 rounded-sm bg-accent px-5 font-semibold text-on-accent no-underline focus-visible:outline-3 focus-visible:outline-focus">
          <Icon icon={QrCodeIcon} size={20} />
          {copy.approvedAction}
        </Link>
      ) : null}
      {requestAgainHref ? (
        <Link href={requestAgainHref} className="inline-flex h-12 items-center justify-center rounded-sm bg-surface-2 px-5 font-semibold text-fg no-underline focus-visible:outline-3 focus-visible:outline-focus">
          {copy.requestAgain}
        </Link>
      ) : null}
    </section>
  );
}
