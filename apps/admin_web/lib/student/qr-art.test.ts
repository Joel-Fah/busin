import QRCode from "qrcode";
import { describe, expect, it } from "vitest";

import { qrArt } from "./qr-art";

describe("the drawn boarding code", () => {
  const code = "busin2.a1000000-0000-4000-8000-000000000001.57000000.cef45af39487cc9ba62e";

  it("keeps every dark module outside the corner squares as a dot", () => {
    const { modules } = QRCode.create(code, { errorCorrectionLevel: "Q" });
    const art = qrArt(code);
    let dark = 0;
    for (let r = 0; r < modules.size; r++) for (let c = 0; c < modules.size; c++) if (modules.get(r, c)) dark++;
    // Each finder pattern has 33 dark modules (outer ring 24, eye 9).
    expect(art.dots.length).toBe(dark - 3 * 33);
    expect(art.size).toBe(modules.size);
  });

  it("puts the three finder patterns in their corners", () => {
    const art = qrArt(code);
    expect(art.finders).toEqual([[0, 0], [art.size - 7, 0], [0, art.size - 7]]);
  });
});
