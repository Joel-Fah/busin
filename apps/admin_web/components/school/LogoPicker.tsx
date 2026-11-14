"use client";

import { Delete02Icon, ImageUploadIcon } from "@hugeicons/core-free-icons";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, useTransition, type DragEvent } from "react";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { useToast } from "@/components/ui/Toast";
import type { LogoResult } from "@/app/(admin)/school/actions";
import { checkLogoFile, contentBox, fitWithin, LOGO_TYPES } from "@/lib/logo-image";
import { LOGO_SIZE } from "@/lib/school";

type Copy = {
  choose: string;
  remove: string;
  none: string;
  uploading: string;
  saved: string;
  removed: string;
  failed: string;
  drop: string;
  dropIdle: string;
  wrongType: string;
  tooBig: string;
  unreadable: string;
};

type Props = {
  url: string | null;
  schoolName: string;
  copy: Copy;
  upload: (form: FormData) => Promise<LogoResult>;
  remove: () => Promise<LogoResult>;
};

/**
 * Returns the logo as WebP in its own proportions, its longest side LOGO_SIZE pixels. The empty margin around it
 * (transparent, or one flat colour such as white) is cut away first; nothing else is cut, stretched or padded.
 */
async function toLogoWebp(file: File): Promise<Blob | null> {
  const bitmap = await createImageBitmap(file);
  try {
    // Look at the image at a size that is cheap to scan, then cut the same box from the full image.
    const scan = Math.min(1, 256 / Math.max(bitmap.width, bitmap.height));
    const sw = Math.max(1, Math.round(bitmap.width * scan));
    const sh = Math.max(1, Math.round(bitmap.height * scan));
    const probe = document.createElement("canvas");
    probe.width = sw;
    probe.height = sh;
    const probeContext = probe.getContext("2d", { willReadFrequently: true });
    if (!probeContext) return null;
    probeContext.drawImage(bitmap, 0, 0, sw, sh);
    const found = contentBox(probeContext.getImageData(0, 0, sw, sh).data, sw, sh);
    const crop = found
      ? { x: found.x / scan, y: found.y / scan, width: found.width / scan, height: found.height / scan }
      : { x: 0, y: 0, width: bitmap.width, height: bitmap.height };

    // The logo keeps its own shape: wide stays wide, tall stays tall. Only the empty margin is cut.
    const size = fitWithin(crop, LOGO_SIZE);
    const canvas = document.createElement("canvas");
    canvas.width = size.width;
    canvas.height = size.height;
    const context = canvas.getContext("2d");
    if (!context) return null;
    context.imageSmoothingQuality = "high";
    context.drawImage(bitmap, crop.x, crop.y, crop.width, crop.height, 0, 0, size.width, size.height);
    return await new Promise((resolve) => canvas.toBlob((blob) => resolve(blob), "image/webp", 0.9));
  } finally {
    bitmap.close();
  }
}

/** Whether a drag carries files (and not, say, selected text), so only files light up the drop zone. */
const carriesFiles = (event: DragEvent) => Array.from(event.dataTransfer?.types ?? []).includes("Files");

/**
 * The school logo: the current one (or a placeholder) in a square that shows it whole, a button to choose a new image
 * and one to remove it, and a drop zone: an image dragged over lights the zone up and is saved when dropped. The image is
 * trimmed and shrunk in the browser to a 512 px WebP before it is sent, so uploads stay small whatever is picked, and
 * each thing that can go wrong has its own message.
 */
export function LogoPicker({ url, schoolName, copy, upload, remove }: Props) {
  const input = useRef<HTMLInputElement>(null);
  const toast = useToast();
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [preview, setPreview] = useState<string | null>(url);
  const [over, setOver] = useState(false);
  // Drag events fire for every element crossed, so count entries and exits to know when the drag really left.
  const depth = useRef(0);
  // A preview made here is a blob address that holds memory until it is given back.
  const made = useRef<string | null>(null);
  useEffect(() => () => {
    if (made.current) URL.revokeObjectURL(made.current);
  }, []);

  const report = (result: LogoResult) => {
    toast(result === "failed" ? copy.failed : result === "removed" ? copy.removed : copy.saved, { tone: result === "failed" ? "bad" : "ok" });
    if (result !== "failed") router.refresh();
  };

  const pick = (file: File | undefined) => {
    if (!file) return;
    const problem = checkLogoFile(file);
    if (problem) {
      toast(problem === "type" ? copy.wrongType : problem === "big" ? copy.tooBig : copy.unreadable, { tone: "bad" });
      return;
    }
    startTransition(async () => {
      const blob = await toLogoWebp(file).catch(() => null);
      if (!blob) {
        toast(copy.unreadable, { tone: "bad" });
        return;
      }
      const form = new FormData();
      form.set("logo", blob, "logo.webp");
      const result = await upload(form);
      if (result === "saved") {
        if (made.current) URL.revokeObjectURL(made.current);
        made.current = URL.createObjectURL(blob);
        setPreview(made.current);
      }
      report(result);
    });
  };

  const onDragEnter = (event: DragEvent) => {
    if (!carriesFiles(event) || pending) return;
    event.preventDefault();
    depth.current += 1;
    setOver(true);
  };
  const onDragOver = (event: DragEvent) => {
    if (!carriesFiles(event) || pending) return;
    // Without this the browser would open the file instead of dropping it here.
    event.preventDefault();
    event.dataTransfer.dropEffect = "copy";
  };
  const onDragLeave = () => {
    depth.current = Math.max(0, depth.current - 1);
    if (depth.current === 0) setOver(false);
  };
  const onDrop = (event: DragEvent) => {
    if (!carriesFiles(event)) return;
    event.preventDefault();
    depth.current = 0;
    setOver(false);
    if (!pending) pick(event.dataTransfer.files[0]);
  };

  return (
    <div
      data-dropzone
      data-over={over ? "true" : undefined}
      onDragEnter={onDragEnter}
      onDragOver={onDragOver}
      onDragLeave={onDragLeave}
      onDrop={onDrop}
      className={
        "flex flex-wrap items-center gap-5 rounded-lg border-2 border-dashed p-4 transition-[border-color,background-color,box-shadow] duration-(--dur-fast) " +
        (over ? "border-accent bg-[color-mix(in_srgb,var(--accent)_14%,transparent)] shadow-[0_0_0_4px_color-mix(in_srgb,var(--accent)_25%,transparent)]" : "border-line")
      }
    >
      {/* The logo as it is: a box of fixed height and up to twice as wide, the logo centred inside, never cut. */}
      <div className="relative grid h-32 w-32 shrink-0 place-items-center rounded-lg bg-surface-2 p-3 sm:w-64">
        {preview ? (
          // eslint-disable-next-line @next/next/no-img-element -- a public file or a local preview, already small
          <img src={preview} alt={schoolName} className="max-h-full max-w-full object-contain" />
        ) : (
          <span className="px-2 text-center text-xs font-semibold text-muted">{copy.none}</span>
        )}
      </div>
      <div className="flex min-w-0 flex-1 flex-col gap-3">
        <p aria-live="polite" className={`m-0 text-sm font-semibold ${over ? "text-fg" : "text-muted"}`}>
          {over ? copy.drop : copy.dropIdle}
        </p>
        <div className="flex flex-wrap items-center gap-3">
          <input
            ref={input}
            type="file"
            accept={LOGO_TYPES.join(",")}
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
          {pending ? <Icon icon={ImageUploadIcon} size={18} className="animate-pulse text-muted" /> : null}
        </div>
      </div>
    </div>
  );
}
