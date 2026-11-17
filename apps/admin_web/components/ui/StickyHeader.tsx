"use client";

import type { ReactNode } from "react";

import { useStickyMorph } from "./useStickyMorph";

type Props = {
  /** The picture: a logo or an avatar. Shrinks into the compact bar. */
  media?: ReactNode;
  /** The page's headline (its h1). */
  title: ReactNode;
  /** What stays beside the title in the compact bar: a status chip, a score. */
  meta?: ReactNode;
  /** What only the roomy header shows: a date, a long description. */
  extra?: ReactNode;
  /** An action at the far end, for example a button. Stays in the compact bar. */
  action?: ReactNode;
};

const flipTargets = (bar: HTMLElement) => Array.from(bar.querySelectorAll("[data-flip]"));
const MORPH_PROPS = "width,height,fontSize";

/**
 * The header of a detail page (a school in the platform console). When the page scrolls, the header morphs into a
 * compact glass bar that stays at the top (small picture, short title, its chips), so who or what the page is about is
 * always in view; back at the top it returns to its roomy layout. The same mechanism as StickyToolbar: the parts glide
 * between the two layouts, instantly for reduced motion, and the page below never jumps. It must sit directly in the
 * page column. The compact layout is plain CSS on [data-stuck="true"] (see .sticky-header in app/theme.css).
 */
export function StickyHeader({ media, title, meta, extra, action }: Props) {
  const { ref: bar, stuck } = useStickyMorph<HTMLElement>({ targets: flipTargets, props: MORPH_PROPS });

  return (
    <header ref={bar} data-stuck={stuck} data-testid="sticky-header" className="sticky-header sticky top-4 z-20 flex items-center gap-5">
      {media ? (
        <div data-flip className="sticky-header-media shrink-0">
          {media}
        </div>
      ) : null}
      <div className="min-w-0 flex-1">
        <div data-flip className="sticky-header-title min-w-0">
          {title}
        </div>
        <div className="sticky-header-meta mt-2 flex flex-wrap items-center gap-2">
          {meta ? (
            <div data-flip className="flex flex-wrap items-center gap-2">
              {meta}
            </div>
          ) : null}
          {extra ? <div className="sticky-header-extra">{extra}</div> : null}
        </div>
      </div>
      {action ? (
        <div data-flip className="shrink-0">
          {action}
        </div>
      ) : null}
    </header>
  );
}
