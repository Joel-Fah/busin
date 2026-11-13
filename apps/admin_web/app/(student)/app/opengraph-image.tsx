import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

import { ImageResponse } from "next/og";

import { BRAND_PATHS, BRAND_VIEWBOX } from "@/components/brand/paths";
import { siteUrl } from "@/lib/landing/site";

/**
 * The card shown when a link to the student web app (/app, ADR 0021) is shared: the night sky of the landing, the logo,
 * what it is in one line with its marker, a browser address bar with the app's address, and three stickers (the face scan
 * for the boarding code, the bus, the ticket). In English, since a link preview has no visitor language. Made once at
 * build time; the fonts and stickers are PNG and TTF in assets/og (the renderer reads neither WebP nor WOFF2).
 */
export const alt = "BusIn in your browser: subscribe, show your boarding code and follow your bus.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

const ACCENT = "#f5951f";

function rng(seed: number) {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 0xffffffff;
  };
}
const next = rng(20261113);
const STARS = Array.from({ length: 80 }, () => ({ x: Math.round(next() * 1200), y: Math.round(next() * 630), r: 1 + next() * 1.6, o: 0.2 + next() * 0.55 }));

const STICKERS = [
  { file: "face-scan", left: 70, top: 300, width: 190, tilt: -12 },
  { file: "bus", left: 930, top: 300, width: 230, tilt: 6 },
  { file: "ticket", left: 960, top: 70, width: 150, tilt: 14 },
] as const;

const bytes = (url: URL) => readFile(fileURLToPath(url));
const STICKER_FILES = {
  "face-scan": new URL("../../../assets/og/face-scan.png", import.meta.url),
  bus: new URL("../../../assets/og/bus.png", import.meta.url),
  ticket: new URL("../../../assets/og/ticket.png", import.meta.url),
};
const FONT_EXTRA_BOLD = new URL("../../../assets/og/pjs-extrabold.ttf", import.meta.url);
const FONT_MEDIUM = new URL("../../../assets/og/pjs-medium.ttf", import.meta.url);
const png = async (name: keyof typeof STICKER_FILES) => `data:image/png;base64,${(await bytes(STICKER_FILES[name])).toString("base64")}`;

export default async function Image() {
  const [extraBold, medium, ...stickers] = await Promise.all([bytes(FONT_EXTRA_BOLD), bytes(FONT_MEDIUM), ...STICKERS.map((s) => png(s.file))]);
  const host = new URL(siteUrl()).host;

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
          <div key={i} style={{ position: "absolute", left: star.x, top: star.y, width: star.r * 2, height: star.r * 2, borderRadius: 9999, background: "#ffffff", opacity: star.o }} />
        ))}
        {STICKERS.map((sticker, i) => (
          <img key={sticker.file} src={stickers[i] as string} alt="" width={sticker.width} height={sticker.width} style={{ position: "absolute", left: sticker.left, top: sticker.top, transform: `rotate(${sticker.tilt}deg)` }} />
        ))}

        <svg viewBox={BRAND_VIEWBOX} width={110} height={68} fill="#ffffff" style={{ marginTop: 60 }}>
          {BRAND_PATHS.map((path, i) => (
            <path key={i} d={path.d} fillRule={path.evenodd ? "evenodd" : undefined} />
          ))}
        </svg>

        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", marginTop: 34, fontSize: 78, fontWeight: 800, letterSpacing: -3, lineHeight: 1.04 }}>
          <div style={{ display: "flex" }}>BusIn, right in</div>
          <div style={{ display: "flex", position: "relative" }}>
            <div style={{ position: "absolute", left: -4, right: -4, bottom: 6, height: 18, borderRadius: 4, background: ACCENT, opacity: 0.78 }} />
            <div style={{ display: "flex", position: "relative" }}>your browser.</div>
          </div>
        </div>

        <div style={{ display: "flex", marginTop: 26, fontSize: 26, fontWeight: 500, color: "rgba(255,255,255,0.82)", maxWidth: 640, textAlign: "center" }}>
          Subscribe, show your boarding code and follow your bus. No download.
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 12, marginTop: 34, padding: "12px 26px", borderRadius: 9999, background: "rgba(255,255,255,0.12)", fontSize: 24, fontWeight: 500 }}>
          <div style={{ display: "flex", width: 12, height: 12, borderRadius: 9999, background: "#4cc38a" }} />
          {`${host}/app`}
        </div>
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
