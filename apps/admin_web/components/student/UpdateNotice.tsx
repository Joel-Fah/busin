"use client";

import { Refresh01Icon } from "@hugeicons/core-free-icons";
import { useEffect, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import type { StudentCopy } from "@/lib/i18n/student";

import { UPDATED_EVENT } from "./ServiceWorker";

/**
 * A quiet note when a new version of BusIn took over while the app was open: one tap reloads into it. It never blocks
 * anything; ignoring it is fine, the next page opened is the new version anyway.
 */
export function UpdateNotice({ copy }: { copy: StudentCopy["update"] }) {
  const [shown, setShown] = useState(false);
  useEffect(() => {
    const onUpdated = () => setShown(true);
    window.addEventListener(UPDATED_EVENT, onUpdated);
    return () => window.removeEventListener(UPDATED_EVENT, onUpdated);
  }, []);
  if (!shown) return null;
  return (
    <div role="status" className="fixed inset-x-0 bottom-[calc(max(0.75rem,env(safe-area-inset-bottom))+5.5rem)] z-50 flex justify-center px-3" data-testid="update-notice">
      <div className="flex w-full max-w-md animate-[student-rise_var(--dur)_var(--ease-soft)] items-center gap-3 rounded-lg bg-seed p-3 pl-4 text-white shadow-float motion-reduce:animate-none">
        <Icon icon={Refresh01Icon} size={20} className="shrink-0" />
        <span className="min-w-0 flex-1 text-sm font-semibold">{copy.text}</span>
        <Button variant="secondary" onClick={() => window.location.reload()}>
          {copy.reload}
        </Button>
        <button type="button" onClick={() => setShown(false)} aria-label={copy.close} className="cursor-pointer rounded-sm border-0 bg-transparent px-2 py-1 text-sm text-white/75 hover:text-white focus-visible:outline-3 focus-visible:outline-focus">
          {copy.later}
        </button>
      </div>
    </div>
  );
}
