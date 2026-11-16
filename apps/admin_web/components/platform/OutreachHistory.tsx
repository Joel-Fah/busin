import { Tick02Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { format } from "@/lib/i18n/format";
import type { Locale, Messages } from "@/lib/i18n/messages";
import type { OutreachEntry } from "@/lib/platform-outreach";

type Props = {
  entries: OutreachEntry[];
  schoolId: string;
  locale: Locale;
  text: Messages["platform"]["outreach"];
  titles: Record<string, string>;
  completeFollowUp: (formData: FormData) => Promise<void>;
};

/** Every contact with a school, newest first: how, about what, the note, the pause, the follow-up and the notice's state. */
export function OutreachHistory({ entries, schoolId, locale, text, titles, completeFollowUp }: Props) {
  if (entries.length === 0) return <p className="m-0 text-sm text-muted">{text.historyEmpty}</p>;
  const when = (iso: string) => new Intl.DateTimeFormat(locale, { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }).format(new Date(iso));
  const day = (iso: string) => new Intl.DateTimeFormat(locale, { day: "numeric", month: "long", timeZone: "UTC" }).format(new Date(`${iso.slice(0, 10)}T00:00:00Z`));
  const today = new Date().toISOString().slice(0, 10);

  return (
    <ol className="m-0 flex list-none flex-col gap-4 p-0" data-testid="outreach-history">
      {entries.map((entry) => (
        <li key={entry.id} className="flex flex-col gap-1.5 text-sm">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <span className="font-semibold">{text.channels[entry.channel]}</span>
            <span className="text-xs text-muted tabular-nums">{when(entry.createdAt)}</span>
          </div>
          {entry.signals.length > 0 ? (
            <div className="flex flex-wrap gap-1">
              {entry.signals.map((signal) => (
                <Chip key={signal}>{titles[signal] ?? signal}</Chip>
              ))}
            </div>
          ) : null}
          {entry.note ? <p className="m-0 whitespace-pre-line text-muted">{entry.note}</p> : null}
          <div className="flex flex-wrap gap-x-3 gap-y-1 text-xs text-muted">
            {entry.snoozeUntil && entry.snoozeUntil >= today ? <span>{format(text.paused, { date: day(entry.snoozeUntil) })}</span> : null}
            {entry.channel === "notice" ? <span>{entry.noticeDismissedAt ? text.noticeDismissed : text.noticeOpen}</span> : null}
            {entry.followUpOn ? <span>{entry.followUpDoneAt ? text.followUpDone : format(text.followUpOn, { date: day(entry.followUpOn) })}</span> : null}
          </div>
          {entry.followUpOn && !entry.followUpDoneAt ? (
            <form action={completeFollowUp}>
              <input type="hidden" name="outreach" value={entry.id} />
              <input type="hidden" name="school" value={schoolId} />
              <input type="hidden" name="back" value="school" />
              <Button type="submit" variant="ghost" icon={Tick02Icon} className="-ml-3">
                {text.markDone}
              </Button>
            </form>
          ) : null}
        </li>
      ))}
    </ol>
  );
}
