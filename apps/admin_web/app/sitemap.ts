import type { MetadataRoute } from "next";

import { siteUrl } from "@/lib/landing/site";

/** The public pages only. `lastModified` is left out on purpose: a made-up date is worse than none. */
export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: `${siteUrl()}/`, changeFrequency: "monthly", priority: 1 },
    { url: `${siteUrl()}/credits`, changeFrequency: "yearly", priority: 0.2 },
  ];
}
