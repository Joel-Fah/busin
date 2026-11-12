import { landingCatalogues } from "@/lib/i18n/landing";

/**
 * The text of /llms.txt: a short, plain description of the site for language models and the tools that feed them (the
 * llmstxt.org format: a title, a one-line summary, then sections of links). It is written from the landing page's own
 * English copy so the two never say different things, and it only names the public pages; the portal is private.
 */
export function buildLlmsTxt(base: string): string {
  const copy = landingCatalogues.en;
  const { sections } = copy;
  return [
    "# BusIn",
    "",
    `> ${copy.meta.description}`,
    "",
    `BusIn manages campus bus subscriptions, boarding scans and bus tracking for schools. Students use a phone app, drivers and the staff at the door use a second app, and each school's office runs it from a private web portal. ${copy.hero.note}`,
    "",
    "## Public pages",
    "",
    `- [Home](${base}/): what BusIn is, a day with it, who it helps, how it treats privacy, and answers to common questions.`,
    `- [Credits](${base}/credits): the free software, fonts and photos the site uses, and their licences.`,
    "",
    "## What it does",
    "",
    `- ${sections.day.title}: ${sections.day.sub}`,
    `- ${sections.people.title}: ${sections.people.sub}`,
    `- ${sections.private.title}: ${sections.private.sub}`,
    "",
    "## Notes",
    "",
    "- The administration portal, the sign-in page and everything behind them are private and not meant for indexing.",
    "- The site is available in English and French; the language follows the visitor's choice.",
    "",
  ].join("\n");
}
