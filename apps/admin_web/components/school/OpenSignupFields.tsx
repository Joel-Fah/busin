"use client";

import { useState } from "react";

import { Switch } from "@/components/ui/Choice";
import { DomainsTagInput } from "@/components/ui/TagInput";

type Copy = { open: string; openHint: string; allowed: string; allowedHint: string; allowedPlaceholder: string; allowedInvalid: string; remove: string };

/** "Also accept students with other email addresses", and, while it is on, which domains (none means any). */
export function OpenSignupFields({ accepts, domains, copy }: { accepts: boolean; domains: readonly string[]; copy: Copy }) {
  const [on, setOn] = useState(accepts);
  return (
    <>
      <Switch name="accepts_open_signup" label={copy.open} hint={copy.openHint} defaultChecked={accepts} onChange={(event) => setOn(event.currentTarget.checked)} />
      {on ? (
        <div className="sm:pl-15">
          <DomainsTagInput
            id="open_signup_domains"
            name="open_signup_domains"
            label={copy.allowed}
            hint={copy.allowedHint}
            placeholder={copy.allowedPlaceholder}
            defaultValue={domains}
            invalidHint={copy.allowedInvalid}
            removeLabel={copy.remove}
          />
        </div>
      ) : (
        // Kept when the switch is off, so turning it off and on again does not lose the list.
        <input type="hidden" name="open_signup_domains" value={domains.join(",")} />
      )}
    </>
  );
}
