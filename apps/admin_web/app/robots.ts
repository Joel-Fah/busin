import type { MetadataRoute } from "next";

import { siteUrl } from "@/lib/landing/site";

/**
 * Only the public pages are open to crawlers: the landing page (at the root, and its share image under /landing), the
 * credits, the llms.txt guide and the ARD manifest. Everything else, the portal and sign-in included, is closed by
 * default, so a page added later is private until someone decides otherwise. For a crawler the longest matching rule
 * wins, so the allowed paths beat "/".
 */
export default function robots(): MetadataRoute.Robots {
  return {
    rules: [{ userAgent: "*", allow: ["/$", "/landing", "/credits", "/llms.txt", "/.well-known/ard.json"], disallow: ["/"] }],
    sitemap: `${siteUrl()}/sitemap.xml`,
    host: siteUrl(),
  };
}
