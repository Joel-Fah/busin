import { ArrowRight01Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";
import Link from "next/link";

import { Icon } from "@/components/ui/Icon";
import { Contour } from "@/components/ui/Contour";

/** A row that opens a page of the profile: an icon, a title, one line about it, and the arrow. */
export function LinkRow({ href, icon, title, body }: { href: string; icon: IconSvgElement; title: string; body: string }) {
  return (
    <Link href={href} className="flex items-center gap-4 relative rounded-md bg-surface p-4 text-fg no-underline shadow-soft transition-shadow duration-(--dur-fast) hover:shadow-float focus-visible:outline-3 focus-visible:outline-focus">
      <Contour radius={20} inset={7} />
      <span className="grid size-11 shrink-0 place-items-center rounded-sm bg-surface-2">
        <Icon icon={icon} size={20} />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block font-bold">{title}</span>
        <span className="block text-sm text-muted">{body}</span>
      </span>
      <Icon icon={ArrowRight01Icon} size={18} className="text-muted" />
    </Link>
  );
}
