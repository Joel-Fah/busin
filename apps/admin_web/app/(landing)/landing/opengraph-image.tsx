import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

import { ImageResponse } from "next/og";

import { BRAND_PATHS, BRAND_VIEWBOX } from "@/components/brand/paths";
import { landingCatalogues } from "@/lib/i18n/landing";

/**
 * The card shown when the landing page's link is shared: the top of the page as it looks at night, drawn at 1200 by 630
 * from the page's own words and in its own order: the logo, the headline with its marker, the tabs of the navigation
 * under it, then the paragraph, with the stars and the four stickers around; no moon. In English, since a link preview
 * has no visitor language. It is made once at build time. The fonts and stickers are in assets/og (the renderer reads
 * neither WebP nor WOFF2).
 */
export const alt = "BusIn: Your bus. On time. On your side.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

const ACCENT = "#f5951f";
const INK = "#00141a";

/** The same small seeded random as the sky on the page, so the stars never change between builds. */
function rng(seed: number) {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 0xffffffff;
  };
}

const next = rng(20261107);
const STARS = Array.from({ length: 90 }, () => ({
  x: Math.round(next() * 1200),
  y: Math.round(next() * 630),
  r: 1 + next() * 1.8,
  o: 0.25 + next() * 0.6,
}));

const STICKERS = [
  { file: "alarm-clock", left: 34, top: 128, width: 150, tilt: -13 },
  { file: "folding-phone", left: 1030, top: 132, width: 140, tilt: 11 },
  { file: "bus", left: 22, top: 430, width: 196, tilt: -6 },
  { file: "ticket", left: 996, top: 428, width: 164, tilt: 9 },
] as const;

// Each file is named with a literal address so the bundler includes it in the build.
const bytes = (url: URL) => readFile(fileURLToPath(url));
const STICKER_FILES = {
  "alarm-clock": new URL("../../../assets/og/alarm-clock.png", import.meta.url),
  "folding-phone": new URL("../../../assets/og/folding-phone.png", import.meta.url),
  bus: new URL("../../../assets/og/bus.png", import.meta.url),
  ticket: new URL("../../../assets/og/ticket.png", import.meta.url),
};
const FONT_EXTRA_BOLD = new URL("../../../assets/og/pjs-extrabold.ttf", import.meta.url);
const FONT_MEDIUM = new URL("../../../assets/og/pjs-medium.ttf", import.meta.url);
const png = async (name: keyof typeof STICKER_FILES) => `data:image/png;base64,${(await bytes(STICKER_FILES[name])).toString("base64")}`;

export default async function Image() {
  const copy = landingCatalogues.en;
  const [extraBold, medium, ...stickers] = await Promise.all([
    bytes(FONT_EXTRA_BOLD),
    bytes(FONT_MEDIUM),
    ...STICKERS.map((sticker) => png(sticker.file)),
  ]);
  // The card has room for the first two sentences of the paragraph; the rest is on the page.
  const lead = copy.hero.sub.split(/(?<=\.)\s/).slice(0, 2).join(" ");
  const tabs = [copy.nav.day, copy.nav.people, copy.nav.schools, copy.nav.faq];

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          position: "relative",
          flexDirection: "column",
          alignItems: "center",
          background: "linear-gradient(180deg, #00080c 0%, #03202a 62%, #06303c 100%)",
          fontFamily: "Plus Jakarta Sans",
          color: "#ffffff",
        }}
      >
        {STARS.map((star, i) => (
          <div
            key={i}
            style={{ position: "absolute", left: star.x, top: star.y, width: star.r * 2, height: star.r * 2, borderRadius: 9999, background: "#ffffff", opacity: star.o }}
          />
        ))}

        {STICKERS.map((sticker, i) => (
          <img
            key={sticker.file}
            src={stickers[i] as string}
            alt=""
            width={sticker.width}
            height={sticker.width}
            style={{ position: "absolute", left: sticker.left, top: sticker.top, transform: `rotate(${sticker.tilt}deg)` }}
          />
        ))}

        <svg viewBox={BRAND_VIEWBOX} width={104} height={67} fill="#ffffff" style={{ marginTop: 30 }}>
          {BRAND_PATHS.map((path, i) => (
            <path key={i} d={path.d} fillRule={path.evenodd ? "evenodd" : undefined} />
          ))}
        </svg>

        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", marginTop: 30, fontSize: 86, fontWeight: 800, letterSpacing: -3, lineHeight: 1.02 }}>
          <div style={{ display: "flex" }}>{copy.hero.line1}</div>
          <div style={{ display: "flex", position: "relative" }}>
            <div style={{ position: "absolute", left: -4, right: -4, bottom: 6, height: 20, borderRadius: 4, background: ACCENT, opacity: 0.78 }} />
            <div style={{ display: "flex", position: "relative" }}>{copy.hero.marked}</div>
          </div>
        </div>

        <div style={{ display: "flex", gap: 10, marginTop: 30 }}>
          {tabs.map((tab) => (
            <div
              key={tab}
              style={{ display: "flex", padding: "9px 18px", borderRadius: 14, background: "rgba(255,255,255,0.1)", fontSize: 20, fontWeight: 500, color: "rgba(255,255,255,0.86)" }}
            >
              {tab}
            </div>
          ))}
          <div style={{ display: "flex", padding: "9px 18px", borderRadius: 14, background: ACCENT, fontSize: 20, fontWeight: 800, color: INK }}>{copy.nav.cta}</div>
        </div>

        <div style={{ display: "flex", marginTop: 26, width: 740, textAlign: "center", fontSize: 24, fontWeight: 500, lineHeight: 1.45, color: "rgba(255,255,255,0.82)" }}>
          {lead}
        </div>
        <div style={{ display: "flex", marginTop: 12, fontSize: 21, fontWeight: 500, color: "rgba(255,255,255,0.6)" }}>{copy.hero.note}</div>
      </div>
    ),
    {
      ...size,
      fonts: [
        { name: "Plus Jakarta Sans", data: extraBold, weight: 800, style: "normal" },
        { name: "Plus Jakarta Sans", data: medium, weight: 500, style: "normal" },
      ],
    },
  );
}
