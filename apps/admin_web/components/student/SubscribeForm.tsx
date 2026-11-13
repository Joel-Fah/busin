"use client";

import { ArrowRight01Icon, Camera01Icon, Location01Icon, LockIcon, Search01Icon } from "@hugeicons/core-free-icons";
import { useRouter } from "next/navigation";
import { useEffect, useId, useMemo, useRef, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import type { StudentCopy } from "@/lib/i18n/student";
import { prepareProof } from "@/lib/student/proof-image";
import { proofPath, subscribeProblem, uploadProblem, type SubscribeProblem } from "@/lib/student/subscription";
import { browserClient } from "@/lib/supabase/browser";

export type StopOption = { id: string; name: string };

function plain(text: string): string {
  return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}

function randomHex(bytes: number): string {
  return Array.from(crypto.getRandomValues(new Uint8Array(bytes)), (b) => b.toString(16).padStart(2, "0")).join("");
}

/** A field-like button: what was chosen, or what to choose. */
function PickerField({ label, value, placeholder, icon, onClick, disabled }: { label: string; value: string | null; placeholder: string; icon: typeof Location01Icon; onClick: () => void; disabled?: boolean }) {
  const id = useId();
  return (
    <div className="flex flex-col gap-1.5">
      <span id={id} className="text-sm font-semibold">
        {label}
      </span>
      <button
        type="button"
        aria-labelledby={id}
        aria-describedby={`${id}-value`}
        onClick={onClick}
        disabled={disabled}
        className="flex min-h-14 w-full cursor-pointer items-center gap-3 rounded-sm border border-line bg-surface px-4 text-left font-sans text-base text-fg transition-colors duration-(--dur-fast) hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus disabled:cursor-default disabled:opacity-60"
      >
        <Icon icon={icon} size={20} className="text-muted" />
        <span id={`${id}-value`} className={`min-w-0 flex-1 truncate ${value ? "font-semibold" : "text-muted"}`}>
          {value ?? placeholder}
        </span>
        <Icon icon={ArrowRight01Icon} size={18} className="text-muted" />
      </button>
    </div>
  );
}

/**
 * The request form, as in the app: a stop, a photo of the payment receipt, and Send. Nothing is sent until both are
 * chosen. The photo goes straight from the browser to the student's own folder in the private bucket, then the request
 * names it; the server checks the rest (the semester is open, the photo exists, one live request per semester).
 */
export function SubscribeForm({ copy, semesterId, schoolId, studentId, stops }: { copy: StudentCopy["subscription"]; semesterId: string; schoolId: string; studentId: string; stops: StopOption[] }) {
  const router = useRouter();
  const fileInput = useRef<HTMLInputElement>(null);
  const [stop, setStop] = useState<StopOption | null>(null);
  const [picking, setPicking] = useState(false);
  const [query, setQuery] = useState("");
  const [proof, setProof] = useState<{ blob: Blob; url: string } | null>(null);
  const [problem, setProblem] = useState<SubscribeProblem | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => () => (proof ? URL.revokeObjectURL(proof.url) : undefined), [proof]);

  const shown = useMemo(() => {
    const q = plain(query.trim());
    return q ? stops.filter((s) => plain(s.name).includes(q)) : stops;
  }, [query, stops]);

  const choosePhoto = async (file: File | undefined) => {
    if (!file) return;
    setProblem(null);
    const prepared = await prepareProof(file);
    if (!prepared.ok) {
      setProblem(prepared.problem);
      return;
    }
    setProof({ blob: prepared.blob, url: URL.createObjectURL(prepared.blob) });
  };

  const submit = async () => {
    if (!stop || !proof) return;
    if (!navigator.onLine) {
      setProblem("offline");
      return;
    }
    setBusy(true);
    setProblem(null);
    const supabase = browserClient();
    const path = proofPath(schoolId, studentId, randomHex(16), "image/jpeg");
    const upload = await supabase.storage.from("proofs").upload(path, proof.blob, { contentType: "image/jpeg", upsert: false });
    if (upload.error) {
      setBusy(false);
      setProblem(uploadProblem(upload.error as { statusCode?: string; message: string }));
      return;
    }
    const insert = await supabase.from("subscriptions").insert({ school_id: schoolId, student_id: studentId, semester_id: semesterId, stop_id: stop.id, proof_path: path });
    if (insert.error) {
      setBusy(false);
      setProblem(subscribeProblem(insert.error));
      return;
    }
    router.replace("/app/subscription");
    router.refresh();
  };

  return (
    <section className="flex flex-col gap-4 rounded-lg bg-surface p-5 shadow-soft" aria-labelledby="subscribe-intro">
      <p id="subscribe-intro" className="m-0 text-muted">
        {copy.intro}
      </p>
      <PickerField label={copy.stopLabel} value={stop?.name ?? null} placeholder={copy.stopHint} icon={Location01Icon} onClick={() => setPicking(true)} disabled={busy} />
      <div className="flex flex-col gap-2">
        <PickerField label={copy.proofLabel} value={proof ? copy.proofAdded : null} placeholder={copy.proofHint} icon={Camera01Icon} onClick={() => fileInput.current?.click()} disabled={busy} />
        <input
          ref={fileInput}
          type="file"
          accept="image/jpeg,image/png,image/webp,image/*"
          className="sr-only"
          tabIndex={-1}
          aria-hidden
          data-testid="proof-input"
          onChange={(event) => {
            void choosePhoto(event.target.files?.[0]);
            event.target.value = "";
          }}
        />
        {proof ? (
          // A local preview of the picked photo (a blob address), never uploaded until Send.
          // eslint-disable-next-line @next/next/no-img-element
          <img src={proof.url} alt={copy.proofLabel} className="max-h-48 w-full rounded-sm object-cover" />
        ) : null}
        <p className="m-0 flex items-center gap-2 text-sm text-muted">
          <Icon icon={LockIcon} size={16} />
          {copy.proofPrivacy}
        </p>
      </div>
      {problem ? <Notice tone="bad">{copy.errors[problem]}</Notice> : null}
      <Button type="button" className="h-14 w-full text-base" disabled={!stop || !proof || busy} onClick={submit}>
        {busy ? copy.sending : copy.submit}
      </Button>

      <Modal
        open={picking}
        onClose={() => setPicking(false)}
        title={copy.stopLabel}
        actions={
          <Button type="button" variant="ghost" onClick={() => setPicking(false)}>
            {copy.close}
          </Button>
        }
      >
        <div className="flex flex-col gap-3">
          <Input id="stop-search" type="search" label={copy.stopSearch} icon={Search01Icon} value={query} onChange={(event) => setQuery(event.target.value)} autoComplete="off" />
          {shown.length === 0 ? (
            <p className="m-0 text-sm text-muted">{copy.stopNone}</p>
          ) : (
            <ul className="m-0 grid max-h-[50dvh] list-none gap-1 overflow-y-auto p-0" aria-label={copy.stopLabel}>
              {shown.map((option) => (
                <li key={option.id}>
                  <button
                    type="button"
                    aria-pressed={stop?.id === option.id}
                    onClick={() => {
                      setStop(option);
                      setPicking(false);
                    }}
                    className={
                      "flex w-full cursor-pointer items-center gap-3 rounded-sm border-0 px-3 py-3 text-left font-sans text-base text-fg focus-visible:outline-3 focus-visible:outline-focus " +
                      (stop?.id === option.id ? "bg-surface-2 font-bold" : "bg-transparent hover:bg-surface-2")
                    }
                  >
                    <Icon icon={Location01Icon} size={18} className="text-muted" />
                    {option.name}
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      </Modal>
    </section>
  );
}
