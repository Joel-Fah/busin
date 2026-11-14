"use client";

import { ReceiptTextIcon } from "@hugeicons/core-free-icons";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { formatAmount, type InstallmentRow } from "@/lib/billing";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import { prepareProof } from "@/lib/student/proof-image";
import { proofPath } from "@/lib/student/subscription";
import { browserClient } from "@/lib/supabase/browser";

const TONE = { due: "neutral", submitted: "warn", paid: "ok", rejected: "bad" } as const;

function randomHex(bytes: number): string {
  return Array.from(crypto.getRandomValues(new Uint8Array(bytes)), (b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * The parts of a subscription paid in installments (ADR 0022), as the app's: each with its amount, due date and where it
 * stands, Late when its day has passed, and a way to send the proof of a later part. The photo goes to the student's own
 * folder, then the server is told which part it pays.
 */
export function InstallmentParts({
  copy,
  parts,
  today,
  locale,
  currency,
  schoolId,
  studentId,
  canSend,
}: {
  copy: StudentCopy["subscription"]["parts"];
  parts: InstallmentRow[];
  today: string;
  locale: string;
  currency: string;
  schoolId: string;
  studentId: string;
  canSend: boolean;
}) {
  const router = useRouter();
  const input = useRef<HTMLInputElement>(null);
  const [target, setTarget] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<{ tone: "ok" | "bad"; text: string } | null>(null);
  const day = (iso: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: "UTC" }).format(new Date(`${iso}T00:00:00Z`));

  const send = async (file: File | undefined) => {
    const part = target;
    if (!file || !part) return;
    setBusy(part);
    setMessage(null);
    const prepared = await prepareProof(file);
    if (!prepared.ok) {
      setBusy(null);
      setMessage({ tone: "bad", text: copy.failed });
      return;
    }
    const supabase = browserClient();
    const path = proofPath(schoolId, studentId, randomHex(16), "image/jpeg");
    const upload = await supabase.storage.from("proofs").upload(path, prepared.blob, { contentType: "image/jpeg", upsert: false });
    const { error } = upload.error ? upload : await supabase.rpc("submit_installment_proof", { p_installment: part, p_path: path });
    setBusy(null);
    if (error) {
      setMessage({ tone: "bad", text: copy.failed });
      return;
    }
    setMessage({ tone: "ok", text: copy.sent });
    router.refresh();
  };

  return (
    <div className="flex flex-col gap-2" data-testid="parts">
      <h3 className="m-0 text-base font-bold">{copy.title}</h3>
      <ol className="m-0 flex list-none flex-col gap-2 p-0">
        {parts.map((part) => {
          const open = part.seq > 1 && (part.status === "due" || part.status === "rejected");
          const late = open && part.due_date <= today;
          const status = part.status as keyof typeof TONE;
          return (
            <li key={part.id} className="flex flex-col gap-2 rounded-md bg-surface-2 p-4" data-testid={`part-${part.seq}`}>
              <div className="flex flex-wrap items-center justify-between gap-2">
                <p className="m-0 font-bold">
                  {format(copy.part, { n: part.seq })} · {formatAmount(part.amount_xaf, locale, currency)}
                </p>
                <span className="flex flex-wrap gap-1.5">
                  <Chip tone={TONE[status] ?? "neutral"}>{copy.status[status]}</Chip>
                  {late ? <Chip tone="bad">{copy.late}</Chip> : null}
                </span>
              </div>
              <p className="m-0 text-sm text-muted">{format(copy.due, { date: day(part.due_date) })}</p>
              {part.status === "rejected" && part.review_note ? <p className="m-0 text-sm">{part.review_note}</p> : null}
              {open && canSend ? (
                <Button
                  variant="secondary"
                  icon={ReceiptTextIcon}
                  disabled={busy !== null}
                  onClick={() => {
                    setTarget(part.id);
                    input.current?.click();
                  }}
                >
                  {busy === part.id ? copy.sending : copy.send}
                </Button>
              ) : null}
            </li>
          );
        })}
      </ol>
      <input
        ref={input}
        type="file"
        accept="image/jpeg,image/png,image/webp,image/*"
        className="sr-only"
        tabIndex={-1}
        aria-hidden
        data-testid="part-proof-input"
        onChange={(event) => {
          void send(event.target.files?.[0]);
          event.target.value = "";
        }}
      />
      {message ? (
        <p role={message.tone === "bad" ? "alert" : "status"} className={`m-0 rounded-md px-4 py-3 text-sm ${message.tone === "bad" ? "bg-bad-bg text-bad" : "bg-ok-bg font-semibold text-ok"}`}>
          {message.text}
        </p>
      ) : null}
    </div>
  );
}
