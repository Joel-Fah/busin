import type { ReactNode } from "react";
import { Megaphone01Icon } from "@hugeicons/core-free-icons";

import { Icon } from "@/components/ui/Icon";
import { RichText } from "@/components/ui/RichText";
import { Clamp } from "@/components/ui/Clamp";
import { cleanDoc } from "@/lib/rich-text";

type Props = {
  title: string;
  /** The rich text of the notice, when it has one; older notices have plain text only. */
  doc: unknown;
  /** The plain text, shown as it always was when there is no usable document. */
  text: string;
  labels: { showMore: string; showLess: string; newTab: string };
  /** The buttons at the end (open the page, dismiss). */
  actions: ReactNode;
  /** The console's preview: links are drawn but lead nowhere. */
  preview?: boolean;
};

/**
 * One reminder from the BusIn platform, as a school's administrators see it on their overview (ADR 0027). The same card
 * is the preview in the platform console. A long notice is kept to a few lines with "Show more".
 */
export function NoticeCard({ title, doc, text, labels, actions, preview = false }: Props) {
  const { doc: clean } = cleanDoc(doc);
  const rich = clean !== null && clean.content.length > 0;
  return (
    // In a narrow space (a phone, the console's preview) the buttons go under the text; in a wide one they sit at the
    // end of the row. The card measures its own space, so the preview in a side sheet looks like a phone.
    <div className="@container min-w-0">
      <article className="flex min-w-0 flex-col gap-3 rounded-lg bg-info-bg p-5 text-fg shadow-soft @2xl:flex-row @2xl:items-start @2xl:gap-4">
        <div className="flex min-w-0 flex-1 items-start gap-3">
          <span className="grid size-10 shrink-0 place-items-center rounded-md bg-surface text-info">
            <Icon icon={Megaphone01Icon} size={20} />
          </span>
          <div className="min-w-0 flex-1">
            <h2 className="m-0 text-base font-bold">{title}</h2>
            {rich ? (
              <Clamp moreLabel={labels.showMore} lessLabel={labels.showLess} className="mt-1">
                <RichText doc={clean} headingLevel={3} newTabLabel={labels.newTab} linkable={!preview} className="text-sm" />
              </Clamp>
            ) : (
              <p className="m-0 mt-1 text-sm break-words whitespace-pre-line">{text}</p>
            )}
          </div>
        </div>
        <div className="flex shrink-0 flex-wrap items-center gap-2">{actions}</div>
      </article>
    </div>
  );
}
