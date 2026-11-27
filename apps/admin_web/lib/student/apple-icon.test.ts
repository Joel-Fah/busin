import { readFileSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

import { APPLE_TOUCH_ICON_180 } from "./apple-icon";

const file = (path: string) => readFileSync(join(__dirname, "../../public", path));

describe("the iPhone Home Screen icon", () => {
  it("is inline, the same bytes as the 180 px file, and a 180 by 180 PNG", () => {
    const [head, data] = APPLE_TOUCH_ICON_180.split(",");
    expect(head).toBe("data:image/png;base64");
    const inline = Buffer.from(data, "base64");
    expect(inline.equals(file("app-icons/apple-touch-180.png"))).toBe(true);
    expect(inline.subarray(1, 4).toString()).toBe("PNG");
    expect(inline.readUInt32BE(16)).toBe(180);
    expect(inline.readUInt32BE(20)).toBe(180);
  });

  it("is also where iOS looks for it on its own, at the root and under /app", () => {
    const icon = file("app-icons/apple-touch-180.png");
    for (const path of ["apple-touch-icon.png", "apple-touch-icon-precomposed.png", "app/apple-touch-icon.png", "app/apple-touch-icon-precomposed.png"]) {
      expect(file(path).equals(icon)).toBe(true);
    }
  });
});
