"use client";

import { Copy01Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { useToast } from "@/components/ui/Toast";
import { format } from "@/lib/i18n/format";

/** Copies the emails shown, one per line, for the message announcing an app (sent from the owner's own email). */
export function CopyEmails({ emails, label, copied }: { emails: string[]; label: string; copied: string }) {
  const toast = useToast();
  if (emails.length === 0) return null;
  return (
    <Button
      variant="secondary"
      icon={Copy01Icon}
      onClick={async () => {
        try {
          await navigator.clipboard.writeText(emails.join("\n"));
          toast(format(copied, { n: emails.length }), { tone: "ok" });
        } catch {
          // Clipboard refused (an old browser, no permission): nothing to show beyond the list itself.
        }
      }}
    >
      {label}
    </Button>
  );
}
