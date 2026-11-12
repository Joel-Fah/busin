import { ArrowLeft01Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "./Button";

/** The "Back to ..." link at the top of a detail or form page. */
export function BackLink({ href, children }: { href: string; children: string }) {
  return (
    <div>
      <ButtonLink href={href} variant="ghost" icon={ArrowLeft01Icon} className="-ml-4">
        {children}
      </ButtonLink>
    </div>
  );
}
