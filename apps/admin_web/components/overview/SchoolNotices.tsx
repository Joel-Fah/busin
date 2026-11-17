import { ArrowRight01Icon, Cancel01Icon } from "@hugeicons/core-free-icons";

import { NoticeCard } from "@/components/overview/NoticeCard";
import { Button, ButtonLink } from "@/components/ui/Button";
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
 * A notice written with formatting is drawn from its document by the whitelist renderer; an older one is plain text.
 */
export async function SchoolNotices({ text, dismiss }: Props) {
  const supabase = await createClient();
  const { data } = await supabase
    .from("school_notices")
    .select("id, body, body_doc, link_path, created_at")
    .is("dismissed_at", null)
    .gt("expires_at", new Date().toISOString())
    .order("created_at", { ascending: false })
    .limit(3);
  if (!data || data.length === 0) return null;

  return (
    <section aria-label={text.label} className="flex flex-col gap-3" data-testid="school-notices">
      {data.map((notice) => (
        <NoticeCard
          key={notice.id}
          title={text.from}
          doc={notice.body_doc}
          text={notice.body}
          labels={text}
          actions={
            <>
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
            </>
          }
        />
      ))}
    </section>
  );
}
