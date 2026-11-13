"use client";

import { Notification03Icon } from "@hugeicons/core-free-icons";
import { useState, useSyncExternalStore } from "react";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import type { StudentCopy } from "@/lib/i18n/student";
import { disablePush, enablePush, pushState, type PushState } from "@/lib/student/push";

const noSubscription = () => () => {};

/**
 * The offer to turn on notifications, as the app's card: shown where waiting for something makes it useful (a pending
 * request, the notification settings). The browser's question comes only after the student taps. Hidden where push is
 * not set up for the site; on an iPhone outside the installed app it says to add BusIn to the home screen first.
 */
export function PushOptIn({ copy, locale, compact = false }: { copy: StudentCopy["push"]; locale: "en" | "fr"; compact?: boolean }) {
  const initial = useSyncExternalStore(noSubscription, pushState, () => "unconfigured" as PushState);
  const [state, setState] = useState<PushState | null>(null);
  const [failed, setFailed] = useState(false);
  const [busy, setBusy] = useState(false);
  const [dismissed, setDismissed] = useState(false);
  const now = state ?? initial;

  if (now === "unconfigured" || dismissed || (compact && now === "on")) return null;

  const text = now === "denied" ? copy.denied : now === "needsInstall" ? copy.needsInstall : now === "unsupported" ? copy.unsupported : now === "on" ? copy.on : copy.body;

  return (
    <section aria-labelledby="push-title" className="flex flex-col gap-3 rounded-lg bg-surface p-5 shadow-soft" data-testid="push-opt-in">
      <div className="flex items-start gap-3">
        <span className="grid size-10 shrink-0 place-items-center rounded-sm bg-seed text-white">
          <Icon icon={Notification03Icon} size={20} />
        </span>
        <div className="min-w-0">
          <h2 id="push-title" className="m-0 text-base font-bold">
            {copy.title}
          </h2>
          <p className="m-0 mt-1 text-sm text-muted">{failed ? copy.failed : text}</p>
        </div>
      </div>
      {now === "off" ? (
        <div className="flex flex-wrap gap-2">
          <Button
            disabled={busy}
            onClick={async () => {
              setBusy(true);
              const result = await enablePush(locale);
              setBusy(false);
              setFailed(result === "off");
              setState(result);
            }}
          >
            {copy.enable}
          </Button>
          {compact ? (
            <Button variant="ghost" onClick={() => setDismissed(true)}>
              {copy.later}
            </Button>
          ) : null}
        </div>
      ) : now === "on" ? (
        <div>
          <Button
            variant="ghost"
            disabled={busy}
            onClick={async () => {
              setBusy(true);
              await disablePush();
              setBusy(false);
              setState("off");
            }}
          >
            {copy.off}
          </Button>
        </div>
      ) : null}
    </section>
  );
}
