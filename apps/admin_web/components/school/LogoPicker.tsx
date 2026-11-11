"use client";

import { Delete02Icon, ImageUploadIcon } from "@hugeicons/core-free-icons";
import { useRouter } from "next/navigation";
import { useRef, useState, useTransition } from "react";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { useToast } from "@/components/ui/Toast";
import type { LogoResult } from "@/app/(admin)/school/actions";
import { LOGO_SIZE } from "@/lib/school";

type Copy = { choose: string; remove: string; none: string; uploading: string; saved: string; removed: string; failed: string };

type Props = {
  url: string | null;
  schoolName: string;
  copy: Copy;
  upload: (form: FormData) => Promise<LogoResult>;
  remove: () => Promise<LogoResult>;
};

/** Draws the picked image centred on a transparent square of LOGO_SIZE pixels and returns it as WebP. */
async function toSquareWebp(file: File): Promise<Blob | null> {
  const bitmap = await createImageBitmap(file);
  const canvas = document.createElement("canvas");
  canvas.width = LOGO_SIZE;
  canvas.height = LOGO_SIZE;
  const context = canvas.getContext("2d");
  if (!context) return null;
  const scale = Math.min(LOGO_SIZE / bitmap.width, LOGO_SIZE / bitmap.height);
  const width = bitmap.width * scale;
  const height = bitmap.height * scale;
  context.imageSmoothingQuality = "high";
  context.drawImage(bitmap, (LOGO_SIZE - width) / 2, (LOGO_SIZE - height) / 2, width, height);
  bitmap.close();
  return new Promise((resolve) => canvas.toBlob((blob) => resolve(blob), "image/webp", 0.9));
}

/**
 * The school logo: the current one (or a placeholder), a button to pick a new image and one to remove it. The image is
 * shrunk in the browser to a 512 px WebP before it is sent, so uploads stay small whatever the admin picks.
 */
export function LogoPicker({ url, schoolName, copy, upload, remove }: Props) {
  const input = useRef<HTMLInputElement>(null);
  const toast = useToast();
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [preview, setPreview] = useState<string | null>(url);

  const report = (result: LogoResult) => {
    toast(result === "failed" ? copy.failed : result === "removed" ? copy.removed : copy.saved, { tone: result === "failed" ? "bad" : "ok" });
    if (result !== "failed") router.refresh();
  };

  const pick = (file: File | undefined) => {
    if (!file) return;
    startTransition(async () => {
      const blob = await toSquareWebp(file).catch(() => null);
      if (!blob) return report("failed");
      const form = new FormData();
      form.set("logo", blob, "logo.webp");
      const result = await upload(form);
      if (result === "saved") setPreview(URL.createObjectURL(blob));
      report(result);
    });
  };

  return (
    <div className="flex flex-wrap items-center gap-5">
      <div className="grid size-28 shrink-0 place-items-center overflow-hidden rounded-lg bg-surface-2 p-2">
        {preview ? (
          // eslint-disable-next-line @next/next/no-img-element -- a public file or a local preview, already small
          <img src={preview} alt={schoolName} className="size-full object-contain" />
        ) : (
          <span className="px-2 text-center text-xs font-semibold text-muted">{copy.none}</span>
        )}
      </div>
      <div className="flex flex-wrap gap-3">
        <input
          ref={input}
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="sr-only"
          tabIndex={-1}
          aria-hidden
          onChange={(event) => {
            pick(event.target.files?.[0]);
            event.target.value = "";
          }}
        />
        <Button type="button" variant="secondary" icon={ImageUploadIcon} disabled={pending} onClick={() => input.current?.click()}>
          {pending ? copy.uploading : copy.choose}
        </Button>
        {preview ? (
          <Button
            type="button"
            variant="ghost"
            icon={Delete02Icon}
            disabled={pending}
            onClick={() =>
              startTransition(async () => {
                const result = await remove();
                if (result === "removed") setPreview(null);
                report(result);
              })
            }
          >
            {copy.remove}
          </Button>
        ) : null}
      </div>
      {pending ? <Icon icon={ImageUploadIcon} size={18} className="animate-pulse text-muted" /> : null}
    </div>
  );
}
