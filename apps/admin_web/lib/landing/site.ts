/**
 * The public address of the site, for the sitemap, the canonical link and share cards. A server-only setting
 * (`SITE_URL`); the local default keeps development working without it. No trailing slash.
 */
export function siteUrl(): string {
  const configured = process.env.SITE_URL?.trim();
  return (configured || "http://localhost:3000").replace(/\/+$/, "");
}

/** The year shown in the footer. A constant: the page is rendered ahead of time, so it must not read the clock. */
export const FOOTER_YEAR = 2026;
