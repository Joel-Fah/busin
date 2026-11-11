"use client";

import { useEffect, useId, useState, useSyncExternalStore, type ReactNode, type Ref } from "react";
import { createPortal } from "react-dom";
import { usePathname } from "next/navigation";
import { ArrowDown01Icon, ArrowUp01Icon } from "@hugeicons/core-free-icons";

import { Icon } from "@/components/ui/Icon";

export const NAV_DOCK_ID = "nav-dock";

const subscribe = () => () => {};
const getDock = () => document.getElementById(NAV_DOCK_ID);

// Wait this long before opening, so the page has finished arriving and the bar then opens calmly.
const DELAY_MS = 350;
// On the first load the bar is still sliding in (and the logo may be playing), so wait for that too.
const FIRST_LOAD_DELAY_MS = 1300;

const FOLD_KEY = "busin.dock-folded:";

function readFolded(path: string): boolean {
  try {
    return window.localStorage.getItem(FOLD_KEY + path) === "1";
  } catch {
    return false;
  }
}

function saveFolded(path: string, folded: boolean) {
  try {
    if (folded) window.localStorage.setItem(FOLD_KEY + path, "1");
    else window.localStorage.removeItem(FOLD_KEY + path);
  } catch {
    // Storage can be unavailable (private window); the choice then lasts for the visit.
  }
}

type Props = {
  /** Always shown: the page's title, help and main actions. */
  header?: ReactNode;
  /** What folds away: lists, notices, controls. Without it there is nothing to fold. */
  children?: ReactNode;
  /** Names the region for assistive technology. */
  label: string;
  /** The fold button's names. */
  labels: { dockHide: string; dockShow: string };
  /** The region itself, for pages that measure where the dock begins. */
  sectionRef?: Ref<HTMLElement>;
};

/**
 * Puts content in the space above the tabs of the floating navigation bar. The bar grows upward to hold it while the
 * tabs stay where they are, so a page can show a list or controls right at the thumb. The header (title, help, actions)
 * always shows; the rest can be folded away with the chevron at the end of the header, to give the map or canvas the
 * room, and each page remembers the choice in this browser. The dock opens gently: a short pause after the page arrives,
 * then a slow, soft growth. With reduced motion it appears at once. The content is removed with the page that rendered it.
 */
export function NavDock({ header, children, label, labels, sectionRef }: Props) {
  const dock = useSyncExternalStore(subscribe, getDock, () => null);
  const path = usePathname();
  const bodyId = useId();
  const [open, setOpen] = useState(false);
  // The dock renders nothing on the server, so reading the browser's choice here never mismatches.
  const [folded, setFolded] = useState(() => (typeof window === "undefined" ? false : readFolded(path)));
  const hasBody = children !== undefined && children !== null && children !== false;

  useEffect(() => {
    const calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const arriving = document.documentElement.dataset.reveal !== undefined;
    const timer = window.setTimeout(() => setOpen(true), calm ? 0 : arriving ? FIRST_LOAD_DELAY_MS : DELAY_MS);
    return () => window.clearTimeout(timer);
  }, []);

  const toggle = () =>
    setFolded((f) => {
      saveFolded(path, !f);
      return !f;
    });

  if (!dock) return null;
  return createPortal(
    <div
      className={
        "grid transition-[grid-template-rows,opacity] duration-[750ms] ease-soft motion-reduce:transition-none " +
        (open ? "grid-rows-[1fr] opacity-100" : "grid-rows-[0fr] opacity-0")
      }
    >
      <div className="min-w-0 overflow-hidden">
        <section ref={sectionRef} aria-label={label} className="flex min-w-0 flex-col px-4 pt-4">
          {header !== undefined || hasBody ? (
            <div className="flex min-w-0 items-start gap-2">
              <div className="min-w-0 flex-1">{header}</div>
              {hasBody ? (
                <button
                  type="button"
                  aria-expanded={!folded}
                  aria-controls={bodyId}
                  aria-label={folded ? labels.dockShow : labels.dockHide}
                  data-tip={folded ? labels.dockShow : labels.dockHide}
                  onClick={toggle}
                  className="mt-1 grid size-9 shrink-0 cursor-pointer place-items-center rounded-sm border-0 bg-transparent text-muted transition-colors duration-(--dur-fast) hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus"
                >
                  <Icon icon={folded ? ArrowUp01Icon : ArrowDown01Icon} size={20} />
                </button>
              ) : null}
            </div>
          ) : null}
          {hasBody ? (
            <div
              id={bodyId}
              inert={folded}
              className={
                "grid transition-[grid-template-rows,opacity,visibility] duration-(--dur-slow) ease-soft motion-reduce:transition-none " +
                (folded ? "invisible grid-rows-[0fr] opacity-0" : "visible grid-rows-[1fr] opacity-100")
              }
            >
              <div className="min-w-0 overflow-hidden">
                <div className="flex min-w-0 flex-col gap-3 pt-3">{children}</div>
              </div>
            </div>
          ) : null}
        </section>
      </div>
    </div>,
    dock,
  );
}
