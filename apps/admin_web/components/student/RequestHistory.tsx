import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import type { buildRequestHistory } from "@/lib/student/subscription";

/**
 * "Your requests this semester", as in the app: one fold per request, the latest open, and inside it everything that
 * happened, the latest first, with the school's note when it gave one.
 */
export function RequestHistory({ copy, history, dateOf, timeOf }: { copy: StudentCopy["subscription"]; history: ReturnType<typeof buildRequestHistory>; dateOf: (iso: string) => string; timeOf: (iso: string) => string }) {
  if (history.length === 0) return null;
  return (
    <section aria-labelledby="requests-title" className="flex flex-col gap-3">
      <div>
        <h2 id="requests-title" className="m-0 text-lg font-bold">
          {copy.requestsTitle}
        </h2>
        <p className="m-0 text-sm text-muted">{copy.requestsHint}</p>
      </div>
      {history.map(({ subscription, events }, index) => (
        <details key={subscription.id} open={index === 0} className="rounded-md bg-surface p-4 shadow-soft">
          <summary className="flex cursor-pointer items-center justify-between gap-3 font-semibold">
            <span>{format(copy.requestOf, { date: dateOf(subscription.created_at) })}</span>
            <span className="text-sm font-normal text-muted">{copy.status[subscription.status]}</span>
          </summary>
          <ol className="m-0 mt-3 flex list-none flex-col gap-3 p-0">
            {events.map((event) => (
              <li key={event.id} className="flex flex-col gap-0.5 border-0">
                <span className="text-sm font-semibold">{copy.events[event.action]}</span>
                <span className="text-xs text-muted">{timeOf(event.created_at)}</span>
                {event.note?.trim() ? <span className="text-sm text-muted">{event.note}</span> : null}
              </li>
            ))}
          </ol>
        </details>
      ))}
    </section>
  );
}
