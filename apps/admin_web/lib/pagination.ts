/** Pure helpers for paginated list pages. Kept separate so they are unit tested. */

export const PAGE_SIZE = 20;
export const MAX_PAGE = 10_000;

/** The first value of a query parameter that may be repeated. */
export function first(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

/** A 1-based page number, clamped to a sensible range. */
export function parsePage(value: string | string[] | undefined): number {
  const parsed = Number.parseInt(first(value) ?? "", 10);
  if (!Number.isFinite(parsed) || parsed < 1) return 1;
  return Math.min(parsed, MAX_PAGE);
}

/** Inclusive row range for PostgREST `range(from, to)`. */
export function pageRange(page: number, size: number = PAGE_SIZE): { from: number; to: number } {
  const from = (page - 1) * size;
  return { from, to: from + size - 1 };
}

/** Number of pages for `total` rows, never less than one. */
export function lastPage(total: number, size: number = PAGE_SIZE): number {
  return Math.max(1, Math.ceil(total / size));
}
