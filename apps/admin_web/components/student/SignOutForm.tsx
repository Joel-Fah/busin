"use client";

import { Logout01Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { signOutStudent } from "@/lib/student/actions";

/** Signs out, after telling the service worker to forget the pages it saved for this person. */
export function SignOutForm({ label }: { label: string }) {
  return (
    <form
      action={signOutStudent}
      onSubmit={() => {
        navigator.serviceWorker?.controller?.postMessage("clear");
      }}
    >
      <Button type="submit" variant="secondary" icon={Logout01Icon}>
        {label}
      </Button>
    </form>
  );
}
