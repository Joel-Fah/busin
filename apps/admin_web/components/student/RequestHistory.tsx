import { Accordion } from "@/components/ui/Accordion";
import { Chip } from "@/components/ui/Chip";
import { Contour } from "@/components/ui/Contour";
import { ProofViewer } from "@/components/student/ProofViewer";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import type { buildRequestHistory } from "@/lib/student/subscription";

const TONE = { pending: "warn", approved: "ok", rejected: "bad", revoked: "bad", expired: "neutral" } as const;

/**
 * "Your requests this semester", as in the app: one fold per request, the latest open, easing open and shut (the portal's
 * accordion), and inside it everything that happened, the latest first, on a little timeline, with the school's note.
 */
export function RequestHistory({
  copy,
  history,
  dateOf,
  timeOf,
  receiptUrls = {},
}: {
  copy: StudentCopy["subscription"];
  history: ReturnType<typeof buildRequestHistory>;
  dateOf: (iso: string) => string;
  timeOf: (iso: string) => string;
  /** Short-lived links to the receipts of parts, by their stored path. */
  receiptUrls?: Record<string, string>;
}) {
  if (history.length === 0) return null;
  return (
    <section aria-labelledby="requests-title" className="relative flex flex-col gap-3 rounded-lg bg-surface p-6 shadow-soft">
      <Contour radius={28} inset={10} />
      <div>
        <h2 id="requests-title" className="m-0 text-lg font-bold">
          {copy.requestsTitle}
        </h2>
        <p className="m-0 text-sm text-muted">{copy.requestsHint}</p>
      </div>
      {history.map(({ subscription, events }, index) => (
        <Accordion
          key={subscription.id}
          name="requests"
          defaultOpen={index === 0}
          summary={
            <span className="flex items-center justify-between gap-3">
              <span className="font-semibold">{format(copy.requestOf, { date: dateOf(subscription.created_at) })}</span>
              <Chip tone={TONE[subscription.status]}>{copy.status[subscription.status]}</Chip>
            </span>
          }
        >
          <ol className="m-0 flex list-none flex-col gap-0 p-0">
            {events.map((event, i) => (
              <li key={event.key} className="relative flex gap-3 pb-3 last:pb-0">
                <span aria-hidden className="relative flex w-3 shrink-0 justify-center">
                  <span className={`mt-1.5 size-2.5 rounded-full ${i === 0 ? "bg-accent" : "bg-muted/50"}`} />
                  {i < events.length - 1 ? <span className="absolute top-4 bottom-[-0.25rem] w-0.5 rounded-xs bg-line" /> : null}
                </span>
                <span className="flex min-w-0 flex-col gap-0.5">
                  <span className="text-sm font-semibold">{format(copy.events[event.action], { n: event.seq ?? "" })}</span>
                  <span className="text-xs text-muted">{timeOf(event.at)}</span>
                  {event.note?.trim() ? <span className="text-sm text-muted">{event.note}</span> : null}
                  {event.proofPath && receiptUrls[event.proofPath] ? (
                    <span className="mt-1">
                      <ProofViewer url={receiptUrls[event.proofPath]} label={format(copy.events.partSent, { n: event.seq ?? "" })} close={copy.close} />
                    </span>
                  ) : null}
                </span>
              </li>
            ))}
          </ol>
        </Accordion>
      ))}
    </section>
  );
}
