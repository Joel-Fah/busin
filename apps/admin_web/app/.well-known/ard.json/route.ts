import { buildArdManifest } from "@/lib/landing/ard";
import { siteUrl } from "@/lib/landing/site";

/** The ARD manifest of the public site. Public and read-only, so any origin may read it. */
export function GET() {
  return new Response(JSON.stringify(buildArdManifest(siteUrl()), null, 2), {
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "public, max-age=3600",
      "access-control-allow-origin": "*",
    },
  });
}
