import type { MetadataRoute } from "next";

import { siteUrl } from "@/lib/landing/site";

/** The landing page may be indexed; the portal and its sign-in never are. */
export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: ["/$", "/landing"],
        disallow: ["/login", "/auth", "/dev", "/no-access", "/profile", "/people", "/subscriptions", "/trips", "/scans", "/stops", "/buses", "/semesters", "/academics", "/styleguide"],
      },
    ],
    sitemap: `${siteUrl()}/sitemap.xml`,
  };
}
