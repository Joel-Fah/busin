/**
 * Pure helpers for preparing a school logo in the browser: what file is acceptable, where the logo's own edges are
 * (a logo saved with wide margins looks tiny in a square), and how to fit it. The canvas work itself is in the picker.
 */

export const LOGO_TYPES = ["image/png", "image/jpeg", "image/webp"] as const;
/** The largest file read from the computer. It is shrunk to a small WebP before it is sent. */
export const MAX_SOURCE_BYTES = 10 * 1024 * 1024;
/** Space kept around the logo inside the square, as a share of its side. */
export const LOGO_PADDING = 0.06;

export type LogoProblem = "type" | "big" | "unreadable";

/** Whether a file can be used as a logo, before anything is read from it. */
export function checkLogoFile(file: { type: string; size: number }): LogoProblem | null {
  if (!(LOGO_TYPES as readonly string[]).includes(file.type)) return "type";
  if (file.size === 0) return "unreadable";
  if (file.size > MAX_SOURCE_BYTES) return "big";
  return null;
}

export type Box = { x: number; y: number; width: number; height: number };

const near = (a: number, b: number, tolerance: number) => Math.abs(a - b) <= tolerance;

/**
 * The box that holds the logo itself: everything but the margin around it. The margin is either transparent or one flat
 * colour that all four corners share (a logo saved on white); the colour is compared with a small tolerance, so a
 * slightly noisy JPEG still counts. Returns null for an image that is all margin.
 */
export function contentBox(data: Uint8ClampedArray, width: number, height: number, tolerance = 24): Box | null {
  const at = (x: number, y: number) => (y * width + x) * 4;
  const corners = [at(0, 0), at(width - 1, 0), at(0, height - 1), at(width - 1, height - 1)];
  const transparent = corners.every((i) => data[i + 3] < 16);
  const reference = corners[0];
  const flat =
    !transparent &&
    corners.every((i) => near(data[i], data[reference], tolerance) && near(data[i + 1], data[reference + 1], tolerance) && near(data[i + 2], data[reference + 2], tolerance) && data[i + 3] > 240);

  const isMargin = (i: number) =>
    transparent
      ? data[i + 3] < 16
      : flat
        ? near(data[i], data[reference], tolerance) && near(data[i + 1], data[reference + 1], tolerance) && near(data[i + 2], data[reference + 2], tolerance)
        : false;

  let minX = width;
  let minY = height;
  let maxX = -1;
  let maxY = -1;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      if (isMargin(at(x, y))) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
  if (maxX < 0) return null;
  return { x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1 };
}

/** Where to draw `source` on a square of `size` so it fits, centred, with `padding` of the side kept free around it. */
export function fitInSquare(source: { width: number; height: number }, size: number, padding = LOGO_PADDING): Box {
  const room = size * (1 - 2 * padding);
  const scale = Math.min(room / source.width, room / source.height);
  const width = source.width * scale;
  const height = source.height * scale;
  return { x: (size - width) / 2, y: (size - height) / 2, width, height };
}
