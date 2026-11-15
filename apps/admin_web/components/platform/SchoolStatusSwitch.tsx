"use client";

import { useState } from "react";
import { PowerSocket01Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { format } from "@/lib/i18n/format";
import type { Messages } from "@/lib/i18n/messages";

type Props = {
  schoolId: string;
  schoolName: string;
  active: boolean;
  text: Messages["platform"]["onboarding"]["status"];
  action: (formData: FormData) => Promise<void>;
};

/** Switches a school off (or back on) after a confirmation that says what it changes. */
export function SchoolStatusSwitch({ schoolId, schoolName, active, text, action }: Props) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <Button variant={active ? "ghost" : "secondary"} icon={PowerSocket01Icon} onClick={() => setOpen(true)} className={active ? "-ml-3" : ""}>
        {active ? text.off : text.on}
      </Button>
      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title={format(active ? text.offTitle : text.onTitle, { school: schoolName })}
        description={active ? text.offBody : text.onBody}
        actions={
          <>
            <Button variant="ghost" onClick={() => setOpen(false)}>
              {text.cancel}
            </Button>
            <form action={action}>
              <input type="hidden" name="school" value={schoolId} />
              <input type="hidden" name="active" value={active ? "false" : "true"} />
              <Button type="submit" variant={active ? "danger" : "primary"} icon={PowerSocket01Icon}>
                {active ? text.off : text.on}
              </Button>
            </form>
          </>
        }
      />
    </>
  );
}
