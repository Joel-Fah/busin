import type { ReactNode } from "react";

/** The plate's height, and how wide a logo may grow beside it (two and a half times the height). */
const SIZES = {
  sm: "h-12 min-w-12 max-w-30 rounded-sm p-1.5",
  md: "h-16 min-w-16 max-w-40 rounded-md p-2",
  lg: "h-20 min-w-20 max-w-48 rounded-md p-2",
} as const;

/**
 * A school's logo on a white plate. The logo is the school's own: it keeps its shape (wide, tall or square), fitted in
 * the plate's height and centred, never cropped or stretched. Without one, `fallback` (initials or an icon) fills a
 * square plate.
 */
export function SchoolLogo({ url, size = "sm", fallback, className = "" }: { url: string | null | undefined; size?: keyof typeof SIZES; fallback: ReactNode; className?: string }) {
  return (
    <span className={`inline-grid shrink-0 place-items-center bg-white ${SIZES[size]} ${className}`} data-testid="school-logo">
      {url ? (
        // A public logo file (a Supabase host or a local preview); already small.
        // eslint-disable-next-line @next/next/no-img-element
        <img src={url} alt="" className="max-h-full max-w-full object-contain" />
      ) : (
        fallback
      )}
    </span>
  );
}
