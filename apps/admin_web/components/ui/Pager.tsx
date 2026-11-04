import { ArrowLeft01Icon, ArrowRight01Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "./Button";

type Step = { href: string; label: string };

/** "Showing 1 to 20 of 87" with previous and next buttons, below a paginated list. */
export function Pager({ range, label, previous, next }: { range: string; label: string; previous?: Step; next?: Step }) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <p className="text-sm text-muted">{range}</p>
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
