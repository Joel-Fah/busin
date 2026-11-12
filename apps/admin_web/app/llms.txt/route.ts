import { buildLlmsTxt } from "@/lib/landing/llms";
import { siteUrl } from "@/lib/landing/site";

/** A plain-text guide to the public site for language models (https://llmstxt.org). */
export function GET() {
  return new Response(buildLlmsTxt(siteUrl()), {
    headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "public, max-age=3600" },
  });
}
