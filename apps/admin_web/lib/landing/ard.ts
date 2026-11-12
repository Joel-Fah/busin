import { landingCatalogues } from "@/lib/i18n/landing";

/**
 * The Agentic Resource Discovery manifest of the public site (ARD v0.91, agenticresourcediscovery.org/spec), served at
 * /.well-known/ard.json. A manifest is `{ entries: [...] }`; each entry needs an `identifier` (`urn:air:<domain>:<name>`),
 * a `displayName`, a `type` (a media type) and exactly one of `url` or `data`.
 *
 * BusIn publishes no agents, tools or APIs, so the only resource listed is the plain-text guide to the public pages
 * (llms.txt). Nothing is claimed that does not exist. The domain in the identifier comes from the site's address.
 */
export type ArdEntry = {
  identifier: string;
  displayName: string;
  type: string;
  url: string;
  description: string;
  representativeQueries: string[];
};

export function buildArdManifest(base: string): { entries: ArdEntry[] } {
  const publisher = new URL(base).hostname;
  const copy = landingCatalogues.en;
  return {
    entries: [
      {
        identifier: `urn:air:${publisher}:site-guide`,
        displayName: "BusIn site guide",
        type: "text/markdown",
        url: `${base}/llms.txt`,
        description: copy.meta.description,
        representativeQueries: [
          "what is BusIn and who is it for",
          "how does a student ride the campus bus with BusIn",
          "does BusIn track my phone",
        ],
      },
    ],
  };
}
