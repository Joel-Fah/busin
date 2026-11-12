import { describe, expect, it } from "vitest";

import { checkLogoFile, contentBox, fitInSquare, MAX_SOURCE_BYTES } from "./logo-image";

/** An image of `width` x `height` pixels, all `background`, with a solid `ink` block at `box`. */
function image(width: number, height: number, background: [number, number, number, number], box: { x: number; y: number; w: number; h: number }) {
  const data = new Uint8ClampedArray(width * height * 4);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4;
      const inside = x >= box.x && x < box.x + box.w && y >= box.y && y < box.y + box.h;
      const colour = inside ? [200, 30, 30, 255] : background;
      data.set(colour, i);
    }
  }
  return data;
}

describe("checkLogoFile", () => {
  it("accepts PNG, JPEG and WebP up to 10 MB and says what is wrong otherwise", () => {
    expect(checkLogoFile({ type: "image/png", size: 1000 })).toBeNull();
    expect(checkLogoFile({ type: "image/jpeg", size: MAX_SOURCE_BYTES })).toBeNull();
    expect(checkLogoFile({ type: "image/gif", size: 1000 })).toBe("type");
    expect(checkLogoFile({ type: "application/pdf", size: 1000 })).toBe("type");
    expect(checkLogoFile({ type: "image/webp", size: MAX_SOURCE_BYTES + 1 })).toBe("big");
    expect(checkLogoFile({ type: "image/png", size: 0 })).toBe("unreadable");
  });
});

describe("contentBox", () => {
  it("finds the logo inside transparent margins", () => {
    const data = image(100, 60, [0, 0, 0, 0], { x: 20, y: 10, w: 50, h: 30 });
    expect(contentBox(data, 100, 60)).toEqual({ x: 20, y: 10, width: 50, height: 30 });
  });

  it("finds the logo inside a flat white margin, even a slightly noisy one", () => {
    const data = image(100, 60, [255, 255, 255, 255], { x: 30, y: 20, w: 40, h: 20 });
    expect(contentBox(data, 100, 60)).toEqual({ x: 30, y: 20, width: 40, height: 20 });
    data.set([250, 252, 255, 255], (5 * 100 + 5) * 4); // a stray off-white pixel in the margin
    expect(contentBox(data, 100, 60)).toEqual({ x: 30, y: 20, width: 40, height: 20 });
  });

  it("leaves a picture that has no flat margin alone, and reports an empty one", () => {
    // Corners of different colours: not a margin, so the whole image counts as the logo.
    const data = image(10, 10, [0, 0, 0, 255], { x: 3, y: 3, w: 4, h: 4 });
    data.set([255, 0, 0, 255], 0);
    data.set([0, 255, 0, 255], 9 * 4);
    data.set([0, 0, 255, 255], 90 * 4);
    data.set([255, 255, 0, 255], 99 * 4);
    expect(contentBox(data, 10, 10)).toEqual({ x: 0, y: 0, width: 10, height: 10 });
    expect(contentBox(new Uint8ClampedArray(10 * 10 * 4), 10, 10)).toBeNull();
  });
});

describe("fitInSquare", () => {
  it("centres a wide logo and keeps its proportions inside the padding", () => {
    const box = fitInSquare({ width: 200, height: 100 }, 512, 0.06);
    expect(box.width / box.height).toBeCloseTo(2);
    expect(box.width).toBeCloseTo(512 * 0.88);
    expect(box.x).toBeCloseTo((512 - box.width) / 2);
    expect(box.y).toBeCloseTo((512 - box.height) / 2);
  });

  it("scales a tall logo by its height and a small one up to fill", () => {
    const tall = fitInSquare({ width: 50, height: 200 }, 512, 0.06);
    expect(tall.height).toBeCloseTo(512 * 0.88);
    const small = fitInSquare({ width: 10, height: 10 }, 512, 0.06);
    expect(small.width).toBeCloseTo(512 * 0.88);
  });
});
