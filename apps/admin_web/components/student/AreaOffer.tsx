"use client";

import { Home01Icon } from "@hugeicons/core-free-icons";
import { useEffect, useState, useSyncExternalStore } from "react";

import { Button, ButtonLink } from "@/components/ui/Button";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import type { StudentCopy } from "@/lib/i18n/student";
import { areaOffered, markAreaOffered } from "@/lib/student/area-offer";
import { browserClient } from "@/lib/supabase/browser";

import { pushOfferShowing } from "./PushOptIn";

const noSubscription = () => () => {};
// Read on the client only: on the server the card stays hidden, so it never flashes in and out.
const shouldOffer = () => !areaOffered() && !pushOfferShowing();

/**
 * Offers My area once to a student who never added it (ADR 0023), when no other offer is showing. Either answer hides
 * it for good in this browser; My area stays in the profile.
 */
export function AreaOffer({ copy }: { copy: StudentCopy["area"] }) {
  const offer = useSyncExternalStore(noSubscription, shouldOffer, () => false);
  // Asked only while it may be offered, so a student who answered never loads it here.
  const [hasArea, setHasArea] = useState<boolean | null>(null);
  const [answered, setAnswered] = useState(false);
  useEffect(() => {
    if (!offer) return;
    let cancelled = false;
    browserClient()
      .rpc("my_area")
      .then(({ data, error }) => {
        if (!cancelled) setHasArea(error ? true : (data?.length ?? 0) > 0);
      });
    return () => {
      cancelled = true;
    };
  }, [offer]);
  if (!offer || hasArea !== false || answered) return null;

  const answer = () => {
    markAreaOffered();
    setAnswered(true);
  };

  return (
    <section aria-labelledby="area-offer-title" className="relative flex flex-col gap-3 rounded-lg bg-surface p-5 shadow-soft" data-testid="area-offer">
      <Contour radius={28} inset={10} />
      <div className="flex items-start gap-3">
        <span className="grid size-10 shrink-0 place-items-center rounded-sm bg-seed text-white">
          <Icon icon={Home01Icon} size={20} />
        </span>
        <div className="min-w-0">
          <h2 id="area-offer-title" className="m-0 text-base font-bold">
            {copy.offerTitle}
          </h2>
          <p className="m-0 mt-1 text-sm text-muted">{copy.offerBody}</p>
        </div>
      </div>
      <div className="flex flex-wrap gap-2">
        {/* Following the link counts as the answer too. */}
        <span className="contents" onClickCapture={markAreaOffered}>
          <ButtonLink href="/app/settings/area">{copy.offerAdd}</ButtonLink>
        </span>
        <Button variant="ghost" onClick={answer}>
          {copy.notNow}
        </Button>
      </div>
    </section>
  );
}
