"use client";

import { useActionState, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Switch } from "@/components/ui/Choice";
import { Notice } from "@/components/ui/Notice";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import { saveNotifications, type SettingsState } from "@/lib/student/settings";
import { Contour } from "@/components/ui/Contour";

export type Preferences = { ridingDays: number; busNearOn: boolean; busNearMinutes: number; boardingOn: boolean };

const MINUTES = [2, 3, 5, 8, 10, 15];

/** Bus days, bus near my stop, the word when boarding; school notices always on. As the app's notification screen, without the phone-only reminders. */
export function NotificationSettings({ copy, initial }: { copy: StudentCopy["notifications"]; initial: Preferences }) {
  const [state, action, pending] = useActionState<SettingsState, FormData>(saveNotifications, { saved: false, error: false });
  const [busNear, setBusNear] = useState(initial.busNearOn);
  const minutes = MINUTES.includes(initial.busNearMinutes) ? MINUTES : [...MINUTES, initial.busNearMinutes].sort((a, b) => a - b);

  return (
    <form action={action} className="flex flex-col gap-4">
      <fieldset className="m-0 flex flex-col gap-3 relative rounded-lg border-0 bg-surface p-5 shadow-soft">
        <Contour radius={28} inset={10} />
        <legend className="float-left mb-1 p-0 text-lg font-bold">{copy.days}</legend>
        <p className="clear-both m-0 text-sm text-muted">{copy.daysHint}</p>
        <div className="grid grid-cols-7 gap-1.5">
          {copy.dayNames.map((name, day) => (
            <label key={name} className="relative">
              <input type="checkbox" name={`day${day}`} defaultChecked={(initial.ridingDays & (1 << day)) !== 0} className="peer sr-only" />
              <span className="grid h-11 cursor-pointer place-items-center rounded-sm bg-surface-2 text-sm font-semibold text-muted peer-checked:bg-seed peer-checked:text-white peer-focus-visible:outline-3 peer-focus-visible:outline-focus">
                {name}
              </span>
            </label>
          ))}
        </div>
      </fieldset>

      <section className="flex flex-col gap-4 relative rounded-lg bg-surface p-5 shadow-soft">
        <Contour radius={28} inset={10} />
        <Switch name="busNear" label={copy.busNear} hint={copy.busNearHint} checked={busNear} onChange={(event) => setBusNear(event.target.checked)} />
        {busNear ? (
          <div role="radiogroup" aria-label={copy.busNear} className="flex flex-wrap gap-2">
            {minutes.map((m) => (
              <label key={m} className="relative">
                <input type="radio" name="busNearMinutes" value={m} defaultChecked={m === initial.busNearMinutes} className="peer sr-only" />
                <span className="inline-flex h-10 cursor-pointer items-center rounded-sm bg-surface-2 px-4 text-sm font-semibold text-muted peer-checked:bg-seed peer-checked:text-white peer-focus-visible:outline-3 peer-focus-visible:outline-focus">
                  {format(copy.minutes, { minutes: m })}
                </span>
              </label>
            ))}
          </div>
        ) : (
          <input type="hidden" name="busNearMinutes" value={initial.busNearMinutes} />
        )}
        <Switch name="boarding" label={copy.boarding} hint={copy.boardingHint} defaultChecked={initial.boardingOn} />
        <Switch label={copy.school} hint={copy.schoolHint} checked disabled readOnly />
      </section>

      <p className="m-0 text-sm text-muted">{copy.webNote}</p>
      {state.error ? <Notice tone="bad">{copy.failed}</Notice> : null}
      {state.saved && !pending ? <Notice tone="ok">{copy.saved}</Notice> : null}
      <Button type="submit" className="h-14 w-full text-base" disabled={pending}>
        {copy.save}
      </Button>
    </form>
  );
}
