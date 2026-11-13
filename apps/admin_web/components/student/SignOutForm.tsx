"use client";

import { Logout01Icon } from "@hugeicons/core-free-icons";
import { useTransition } from "react";

import { Button } from "@/components/ui/Button";
import { clearKeys } from "@/lib/student/key-store";
import { disablePush } from "@/lib/student/push";
import { signOutStudent } from "@/lib/student/actions";

/**
 * Signs out after forgetting what this browser kept for the person: the boarding-code key, the push token (the server
 * stops sending to this browser), and the pages the service worker saved for offline use. Then the server ends the session.
 */
export function SignOutForm({ label }: { label: string }) {
  const [pending, start] = useTransition();
  return (
    <Button
      type="button"
      variant="secondary"
      icon={Logout01Icon}
      disabled={pending}
      onClick={() =>
        start(async () => {
          await clearKeys();
          await disablePush().catch(() => undefined);
          navigator.serviceWorker?.controller?.postMessage("clear");
          await signOutStudent();
        })
      }
    >
      {label}
    </Button>
  );
}
