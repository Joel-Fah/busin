"use client";

import { useEffect, useState } from "react";

export type RailItem = { id: string; label: string };

/**
 * A slim sticky rail of ticks with labels, in the manner of a conversation outline. It sits in the page margin, so the parent places it outside the content column. The section
 * being read is longer and orange. No backgrounds, so it stays quiet next to the content.
 */
export function SectionRail({ items }: { items: readonly RailItem[] }) {
  const [active, setActive] = useState(items[0]?.id);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries.filter((e) => e.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        if (visible[0]) setActive(visible[0].target.id);
      },
      { rootMargin: "-12% 0px -72% 0px" },
    );
    for (const { id } of items) {
      const el = document.getElementById(id);
      if (el) observer.observe(el);
    }
    return () => observer.disconnect();
  }, [items]);

  function go(event: React.MouseEvent<HTMLAnchorElement>, id: string) {
    const el = document.getElementById(id);
    if (!el) return;
    event.preventDefault();
    const calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    el.scrollIntoView({ behavior: calm ? "auto" : "smooth", block: "start" });
    history.replaceState(null, "", `#${id}`);
    setActive(id);
  }

  return (
    <nav aria-label="Sections" className="sticky top-10 w-44">
      <ul className="m-0 flex list-none flex-col gap-1 p-0">
        {items.map(({ id, label }) => {
          const current = id === active;
          return (
            <li key={id}>
              <a
                href={`#${id}`}
                onClick={(e) => go(e, id)}
                aria-current={current ? "location" : undefined}
                className={
                  "group flex items-center gap-3 rounded-xs py-1.5 text-sm no-underline transition-colors duration-(--dur-fast) " +
                  "focus-visible:outline-3 focus-visible:outline-focus " +
                  (current ? "font-semibold text-fg" : "text-muted hover:text-fg")
                }
              >
                <span
                  aria-hidden
                  className={
                    "h-0.5 shrink-0 rounded-xs transition-[width,background-color] duration-(--dur) ease-soft " +
                    (current ? "w-7 bg-accent" : "w-3.5 bg-line group-hover:w-5 group-hover:bg-muted")
                  }
                />
                {label}
              </a>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
