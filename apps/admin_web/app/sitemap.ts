import type { MetadataRoute } from "next";

import { siteUrl } from "@/lib/landing/site";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: `${siteUrl()}/`, changeFrequency: "monthly", priority: 1 },
    { url: `${siteUrl()}/credits`, changeFrequency: "yearly", priority: 0.2 },
  ];
}
