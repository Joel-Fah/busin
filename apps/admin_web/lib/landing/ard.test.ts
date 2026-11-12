import { describe, expect, it } from "vitest";

import { buildArdManifest } from "./ard";

// The rules of the ARD entry schema (ard-entry.schema.json, v0.91), written out.
const IDENTIFIER = /^urn:air:[a-zA-Z0-9.-]+(:[a-zA-Z0-9._-]+)+$/;

describe("ARD manifest", () => {
  const manifest = buildArdManifest("https://busin.example");

  it("is an entries array, as the spec requires", () => {
    expect(Array.isArray(manifest.entries)).toBe(true);
    expect(manifest.entries.length).toBeGreaterThan(0);
  });

  it.each(buildArdManifest("https://busin.example").entries)("entry $identifier meets the entry schema", (entry) => {
    expect(entry.identifier).toMatch(IDENTIFIER);
    expect(entry.displayName.length).toBeGreaterThan(0);
    expect(entry.type).toMatch(/^[\w.+-]+\/[\w.+-]+/);
    // Exactly one of url or data; here a url, and an absolute one.
    expect("data" in entry).toBe(false);
    expect(new URL(entry.url).protocol).toBe("https:");
    // The conformance check wants two to five example queries.
    expect(entry.representativeQueries.length).toBeGreaterThanOrEqual(2);
    expect(entry.representativeQueries.length).toBeLessThanOrEqual(5);
  });

  it("names the site's own domain as the publisher, whatever the port", () => {
    expect(manifest.entries[0].identifier).toBe("urn:air:busin.example:site-guide");
    expect(buildArdManifest("http://localhost:3000").entries[0].identifier).toBe("urn:air:localhost:site-guide");
  });
});
