"use client";

import { ReceiptTextIcon } from "@hugeicons/core-free-icons";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Notice } from "@/components/ui/Notice";
import type { StudentCopy } from "@/lib/i18n/student";
import { prepareProof } from "@/lib/student/proof-image";
import { proofPath } from "@/lib/student/subscription";
import { browserClient } from "@/lib/supabase/browser";

function randomHex(bytes: number): string {
  return Array.from(crypto.getRandomValues(new Uint8Array(bytes)), (b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * For a request made to pay by mobile money that was not paid: a photo of a receipt instead, as the request form takes
 * it (the student's own folder of the private bucket). The server then turns the request into one paid by receipt, which
 * waits for the school like any other (`attach_subscription_proof`).
 */
export function ReceiptInstead({ copy, subscriptionId, schoolId, studentId }: { copy: StudentCopy["subscription"]["pay"]; subscriptionId: string; schoolId: string; studentId: string }) {
  const router = useRouter();
  const input = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<{ tone: "ok" | "bad"; text: string } | null>(null);

  const send = async (file: File | undefined) => {
    if (!file) return;
    setBusy(true);
    setMessage(null);
    const prepared = await prepareProof(file);
    if (!prepared.ok) {
      setBusy(false);
      setMessage({ tone: "bad", text: copy.receiptFailed });
      return;
    }
    const supabase = browserClient();
    const path = proofPath(schoolId, studentId, randomHex(16), "image/jpeg");
    const upload = await supabase.storage.from("proofs").upload(path, prepared.blob, { contentType: "image/jpeg", upsert: false });
    const { error } = upload.error ? upload : await supabase.rpc("attach_subscription_proof", { p_subscription: subscriptionId, p_path: path });
    setBusy(false);
    if (error) {
      setMessage({ tone: "bad", text: error.message?.includes("payment_in_progress") ? copy.errors.payment_in_progress : copy.receiptFailed });
      return;
    }
    setMessage({ tone: "ok", text: copy.receiptSent });
    router.refresh();
  };

  return (
    <div className="flex flex-col gap-2">
      <Button variant="secondary" icon={ReceiptTextIcon} disabled={busy} onClick={() => input.current?.click()}>
        {busy ? copy.receiptSending : copy.receiptInstead}
      </Button>
      <input
        ref={input}
        type="file"
        accept="image/jpeg,image/png,image/webp,image/*"
        className="sr-only"
        tabIndex={-1}
        aria-hidden
        data-testid="receipt-instead-input"
        onChange={(event) => {
          void send(event.target.files?.[0]);
          event.target.value = "";
        }}
      />
      {message ? <Notice tone={message.tone}>{message.text}</Notice> : null}
    </div>
  );
}
