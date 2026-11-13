import { PROOF_MAX_BYTES, PROOF_MAX_SIDE, sniffImageType } from "./subscription";

export type PreparedProof = { ok: true; blob: Blob; contentType: "image/jpeg" } | { ok: false; problem: "type" | "tooLarge" };

/**
 * Turns the photo a student picked into what the proofs bucket takes, in the browser, as the app's picker does: the
 * real type is read from the file's first bytes (not its name), the picture is shrunk to 1600 px on its longest side and
 * saved as a JPEG at quality 0.8. A photo the browser can open but the bucket would refuse (an iPhone HEIC in Safari) is
 * converted the same way; anything that is not a picture is refused.
 */
export async function prepareProof(file: File): Promise<PreparedProof> {
  const head = new Uint8Array(await file.slice(0, 16).arrayBuffer());
  const known = sniffImageType(head);
  if (!known && !file.type.startsWith("image/")) return { ok: false, problem: "type" };

  let bitmap: ImageBitmap;
  try {
    bitmap = await createImageBitmap(file, { imageOrientation: "from-image" });
  } catch {
    return { ok: false, problem: "type" };
  }
  const scale = Math.min(1, PROOF_MAX_SIDE / Math.max(bitmap.width, bitmap.height));
  const width = Math.max(1, Math.round(bitmap.width * scale));
  const height = Math.max(1, Math.round(bitmap.height * scale));
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const context = canvas.getContext("2d");
  if (!context) return { ok: false, problem: "type" };
  // A transparent PNG would turn black in a JPEG: paper white behind it.
  context.fillStyle = "#ffffff";
  context.fillRect(0, 0, width, height);
  context.drawImage(bitmap, 0, 0, width, height);
  bitmap.close();
  const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, "image/jpeg", 0.8));
  if (!blob) return { ok: false, problem: "type" };
  if (blob.size > PROOF_MAX_BYTES) return { ok: false, problem: "tooLarge" };
  return { ok: true, blob, contentType: "image/jpeg" };
}
