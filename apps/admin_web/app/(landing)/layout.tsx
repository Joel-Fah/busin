import { Analytics } from "@vercel/analytics/next";
import { SpeedInsights } from "@vercel/speed-insights/next";

/**
 * Measurement for the public pages only (the landing page and credits): anonymous page views and page speed, with no
 * cookies. The portal is deliberately left out: its addresses carry the ids of people and subscriptions, and they never
 * need to leave the site.
 */
export default function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      <Analytics />
      <SpeedInsights />
    </>
  );
}
