"use client";

import { Cancel01Icon } from "@hugeicons/core-free-icons";
import { useState } from "react";

import { Icon } from "@/components/ui/Icon";
import { Sheet } from "./Sheet";

/**
 * The payment proof: a thumbnail on the status card that opens the photo in a dialog at its own proportions (as large as
 * the screen allows), not on another page. The address is a signed one from the private bucket, valid for ten minutes.
 */
export function ProofViewer({ url, label, close }: { url: string; label: string; close: string }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button type="button" onClick={() => setOpen(true)} className="shrink-0 cursor-zoom-in rounded-sm border-0 bg-transparent p-0 focus-visible:outline-3 focus-visible:outline-focus" data-testid="proof-thumbnail">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={url} alt={label} className="size-20 rounded-sm object-cover shadow-soft" />
      </button>
      <Sheet open={open} onClose={() => setOpen(false)} label={label} fit>
        <div className="relative p-2">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={url} alt={label} className="block max-h-[80dvh] w-auto max-w-full rounded-lg object-contain" data-testid="proof-full" />
          <button
            type="button"
            onClick={() => setOpen(false)}
            aria-label={close}
            className="absolute top-4 right-4 grid size-10 cursor-pointer place-items-center rounded-full border-0 bg-surface/90 text-fg shadow-soft focus-visible:outline-3 focus-visible:outline-focus"
          >
            <Icon icon={Cancel01Icon} size={18} />
          </button>
        </div>
      </Sheet>
    </>
  );
}
