import { describe, expect, it } from "vitest";

import { dayKey, generateCode, importSecret, mac, secondsRemaining, toHex, windowFor } from "./qr";

// The test vector of docs/guides/qr-code-format.md, also checked by the database test and the Dart test.
const secret = Buffer.from(Array.from({ length: 32 }, (_, i) => i)).toString("base64");
const student = "a1000000-0000-4000-8000-000000000001";
const window = 57000000;

describe("the boarding code", () => {
  it("derives the documented day key", async () => {
    const key = await importSecret(secret);
    expect(toHex(await dayKey(key, "2024-03-09"))).toBe("dbe88e73a71c3914cdff93d45b3f2f989831796a69b9b00f5ccfaf0b2dfb29a5");
  });

  it("signs the documented window", async () => {
    const key = await importSecret(secret);
    expect(await mac(await dayKey(key, "2024-03-09"), student, window)).toBe("cef45af39487cc9ba62e");
  });

  it("makes the documented code at the school's time", async () => {
    const key = await importSecret(secret);
    const at = window * 30 * 1000 + 12_000;
    expect(await generateCode(key, student, at, "Africa/Douala")).toBe(`busin2.${student}.${window}.cef45af39487cc9ba62e`);
  });

  it("keeps the secret unreadable", async () => {
    const key = await importSecret(secret);
    expect(key.extractable).toBe(false);
    await expect(crypto.subtle.exportKey("raw", key)).rejects.toThrow();
  });

  it("refuses a secret of the wrong size", async () => {
    await expect(importSecret(Buffer.from([1, 2, 3]).toString("base64"))).rejects.toThrow("32 bytes");
  });

  it("counts windows of 30 seconds", () => {
    expect(windowFor(window * 30_000)).toBe(window);
    expect(secondsRemaining(window * 30_000)).toBe(30);
    expect(secondsRemaining(window * 30_000 + 29_500)).toBe(1);
  });
});
