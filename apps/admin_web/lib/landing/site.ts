/**
 * The public address of the site, for the sitemap, the canonical link and share cards. A server-only setting
 * (`SITE_URL`). On Vercel, without it, the project's own production address (which Vercel provides without a scheme)
 * is used, so share links work before a custom domain exists. The local default keeps development working. No
 * trailing slash.
 */
export function siteUrl(): string {
  const configured = process.env.SITE_URL?.trim();
  const vercel = process.env.VERCEL_PROJECT_PRODUCTION_URL?.trim();
  return (configured || (vercel ? `https://${vercel}` : "http://localhost:3000")).replace(/\/+$/, "");
}

/** The year shown in the footer. A constant: the page is rendered ahead of time, so it must not read the clock. */
export const FOOTER_YEAR = 2026;
