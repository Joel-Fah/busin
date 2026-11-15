import { ArrowRight01Icon, Cancel01Icon, Megaphone01Icon } from "@hugeicons/core-free-icons";

import { Button, ButtonLink } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import type { Messages } from "@/lib/i18n/messages";
import { isPortalPath } from "@/lib/platform-outreach";
import { createClient } from "@/lib/supabase/server";

type Props = {
  text: Messages["notices"];
  dismiss: (formData: FormData) => Promise<void>;
};

/**
 * Reminders the BusIn platform sent this school (ADR 0027), at the top of its overview until an administrator dismisses
 * them or they expire. Row Level Security limits them to this school's administrators. At most three, newest first.
 */
export async function SchoolNotices({ text, dismiss }: Props) {
  const supabase = await createClient();
  const { data } = await supabase
    .from("school_notices")
    .select("id, body, link_path, created_at")
    .is("dismissed_at", null)
    .gt("expires_at", new Date().toISOString())
    .order("created_at", { ascending: false })
    .limit(3);
  if (!data || data.length === 0) return null;

  return (
    <section aria-label={text.label} className="flex flex-col gap-3" data-testid="school-notices">
      {data.map((notice) => (
        <article key={notice.id} className="flex flex-wrap items-start gap-4 rounded-lg bg-info-bg p-5 text-fg shadow-soft">
          <span className="grid size-10 shrink-0 place-items-center rounded-md bg-surface text-info">
            <Icon icon={Megaphone01Icon} size={20} />
          </span>
          <div className="min-w-0 flex-1">
            <h2 className="m-0 text-base font-bold">{text.from}</h2>
            <p className="m-0 mt-1 text-sm whitespace-pre-line">{notice.body}</p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {isPortalPath(notice.link_path) ? (
              <ButtonLink href={notice.link_path} variant="secondary" icon={ArrowRight01Icon}>
                {text.open}
              </ButtonLink>
            ) : null}
            <form action={dismiss}>
              <input type="hidden" name="notice" value={notice.id} />
              <Button type="submit" variant="ghost" icon={Cancel01Icon}>
                {text.dismiss}
              </Button>
            </form>
          </div>
        </article>
      ))}
    </section>
  );
}
