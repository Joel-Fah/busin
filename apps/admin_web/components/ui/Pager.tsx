import { ArrowLeft01Icon, ArrowRight01Icon } from "@hugeicons/core-free-icons";
import Link from "next/link";

import { ButtonLink } from "./Button";

type Step = { href: string; label: string };

/** The "per page" choice: the sizes on offer, each a link to the list at that size (and back to its first page). */
export type PerPage = { label: string; groupLabel: string; current: number; options: { size: number; href: string }[] };

/** "Showing 1 to 20 of 87" with previous and next buttons below a paginated list, and how many rows a page shows. */
export function Pager({ range, label, previous, next, perPage }: { range: string; label: string; previous?: Step; next?: Step; perPage?: PerPage }) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <div className="flex flex-wrap items-center gap-x-5 gap-y-2">
        <p className="text-sm text-muted">{range}</p>
        {perPage ? (
          <div className="flex items-center gap-2 text-sm text-muted">
            <span aria-hidden>{perPage.label}</span>
            <nav aria-label={perPage.groupLabel} className="inline-flex gap-1 rounded-md bg-surface-2 p-1">
              {perPage.options.map((option) => {
                const current = option.size === perPage.current;
                return (
                  <Link
                    key={option.size}
                    href={option.href}
                    aria-current={current ? "true" : undefined}
                    className={
                      "inline-flex h-8 min-w-9 items-center justify-center rounded-sm px-2 font-semibold tabular-nums no-underline transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus " +
                      (current ? "bg-surface text-fg shadow-soft" : "text-muted hover:text-fg")
                    }
                  >
                    {option.size}
                  </Link>
                );
              })}
            </nav>
          </div>
        ) : null}
      </div>
      <nav className="flex gap-2" aria-label={label}>
        {previous ? (
          <ButtonLink variant="secondary" icon={ArrowLeft01Icon} href={previous.href}>
            {previous.label}
          </ButtonLink>
        ) : null}
        {next ? (
          <ButtonLink variant="secondary" icon={ArrowRight01Icon} href={next.href}>
            {next.label}
          </ButtonLink>
        ) : null}
      </nav>
    </div>
  );
}
