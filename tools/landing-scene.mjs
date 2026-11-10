// Draws the landing page's bus stop scene (the town behind, the shelter, the pavement and the four students) and writes it
// as SVG markup into apps/admin_web/components/landing/scene-art.ts, with its colours in scene-art.css.
//   node tools/landing-scene.mjs                    write the two files
//   node tools/landing-scene.mjs --preview out.html  also write a page to look at it (whole scene and each person, by day and night)
//
// The way it is drawn follows flat editorial illustration: a calm, nearly single-hue background (one family of pale teals,
// a halftone of dots on a few faces), deep teal for every structure, one warm brand colour for the accents, and the people
// in saturated clothes so they read first. Everything stands on one ground line and casts a soft shadow, so nothing floats.
//
// People: a head with a skull, ear, two eyes (near and far), brows, nose and mouth, so a face can smile, laugh, focus or
// worry; hair is built over the skull (a mass behind it and a cap on it), so it always sits on the head. Limbs are single
// smooth shapes: a curve through a few points, thickened (`band`). The far arm and leg use a darker tone, and a limb that
// crosses the body casts a small shadow on it. Coordinates: x right, y down, one unit about one pixel on a desktop.
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const n = (v) => Number(v.toFixed(1));
const V = (name) => `var(--s-${name})`;

/** Every colour of the scene: [by day, by night]. Written out as CSS variables on the scene's svg. */
const PALETTE = {
  // the town and the street
  far: ["#e1eef2", "#082631"],
  far2: ["#d3e6ec", "#0b2f3c"],
  mid: ["#c9dfe6", "#0c3341"],
  mid2: ["#b6d2db", "#0f3e4e"],
  dots: ["#a9c8d2", "#164d5e"],
  win: ["#dcebf0", "#123e4d"],
  lit: ["#e9f4f7", "#ffd98f"],
  tree: ["#86b9b2", "#145154"],
  tree2: ["#6ea69f", "#0f4245"],
  bush: ["#4b858d", "#0b3a40"],
  bush2: ["#3d7880", "#08313a"],
  planter: ["#0c5d6d", "#11697a"],
  planter2: ["#094a58", "#0b5160"],
  struct: ["#163c47", "#2c6476"],
  struct2: ["#0f2e37", "#22566a"],
  roof: ["#f5951f", "#e88a17"],
  roof2: ["#d77c0e", "#c47210"],
  glass: ["#ffffff", "#bfe6f2"],
  "glass-o": ["0.42", "0.08"],
  ad: ["#fdf4e3", "#f3e6c9"],
  paver: ["#eef6f8", "#0a2d39"],
  paver2: ["#dcebef", "#0e3644"],
  curb: ["#cfe0e6", "#123f4e"],
  road: ["#c3d7de", "#071f29"],
  lane: ["#f9fcfd", "#2c5a70"],
  "glow-o": ["0", "1"],
  shadow: ["#00202a", "#000a0e"],
  "shadow-o": ["0.1", "0.38"],
  // the people
  ink: ["#22373f", "#3d5d6b"],
  ink2: ["#18282e", "#304d5a"],
  line: ["rgb(8 20 25 / 0.3)", "rgb(4 12 16 / 0.45)"],
  face: ["#1d2b31", "#172429"],
  hair: ["#1c2327", "#141b1e"],
  hair2: ["#2f383d", "#262e33"],
  "hair-b": ["#4a3021", "#3e281b"],
  "hair-b2": ["#644331", "#563a2a"],
  sole: ["#f7f1e3", "#e2dac6"],
  white: ["#fbf8f1", "#e8e2d4"],
  orange: ["#f5951f", "#e88a17"],
  orange2: ["#d77c0e", "#c47210"],
  teal: ["#0c5d6d", "#17808f"],
  teal2: ["#094a58", "#116875"],
  teal3: ["#3d8a99", "#3f9cab"],
  cream: ["#f3e7cc", "#e6d9bb"],
  cream2: ["#dccca7", "#cdbd98"],
  coral: ["#e8694a", "#dc6144"],
  coral2: ["#c95338", "#b94b32"],
  mustard: ["#f0b63c", "#e2a930"],
  mustard2: ["#d39a22", "#c3901f"],
  denim: ["#3f7099", "#4a7ea8"],
  denim2: ["#2f5b80", "#386990"],
  denim3: ["#6b97bb", "#7aa5c6"],
  skirt: ["#0c5d6d", "#17808f"],
  skirt2: ["#094a58", "#116875"],
  "skin-a": ["#8c5a3c", "#875739"],
  "skin-a2": ["#734730", "#6e452e"],
  "skin-b": ["#c4885e", "#bb8159"],
  "skin-b2": ["#a9714b", "#a06c47"],
  "skin-c": ["#6f4430", "#6b412e"],
  "skin-c2": ["#5a3524", "#573323"],
  "skin-d": ["#e8bb94", "#ddb18b"],
  "skin-d2": ["#d09f78", "#c69772"],
  blush: ["#e8694a", "#dc6144"],
  phone: ["#1d2b31", "#25363d"],
  gold: ["#e0a83a", "#d49d33"],
  sweat: ["#8fd3ea", "#8fd3ea"],
};

// ---------------------------------------------------------------- geometry

function catmull(p0, p1, p2, p3, t) {
  const t2 = t * t;
  const t3 = t2 * t;
  return [0, 1].map(
    (k) => 0.5 * (2 * p1[k] + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2 + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3),
  );
}

function sample(pts, steps = 10) {
  const out = [];
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[Math.max(0, i - 1)];
    const p3 = pts[Math.min(pts.length - 1, i + 2)];
    for (let s = 0; s < steps; s++) out.push({ p: catmull(p0, pts[i], pts[i + 1], p3, s / steps), u: i + s / steps });
  }
  out.push({ p: pts[pts.length - 1], u: pts.length - 1 });
  return out;
}

function frames(pts, widths) {
  const sm = sample(pts);
  return sm.map((s, k) => {
    const a = sm[Math.max(0, k - 1)].p;
    const b = sm[Math.min(sm.length - 1, k + 1)].p;
    const len = Math.hypot(b[0] - a[0], b[1] - a[1]) || 1;
    const t = [(b[0] - a[0]) / len, (b[1] - a[1]) / len];
    const i = Math.min(widths.length - 2, Math.floor(s.u));
    const w = (widths[i] * (1 - (s.u - i)) + widths[i + 1] * (s.u - i)) / 2;
    return { p: s.p, t, nrm: [-t[1], t[0]], w };
  });
}

const toPath = (points) => `M${points.map(([x, y]) => `${n(x)} ${n(y)}`).join("L")}Z`;

/** A limb: the outline of a smooth curve through [pts], [widths] wide at each point. Ends are flat or round. */
function band(pts, widths, { start = "flat", end = "flat" } = {}) {
  const fr = frames(pts, widths);
  const left = fr.map((f) => [f.p[0] + f.nrm[0] * f.w, f.p[1] + f.nrm[1] * f.w]);
  const right = fr.map((f) => [f.p[0] - f.nrm[0] * f.w, f.p[1] - f.nrm[1] * f.w]);
  const cap = (f, sign) => {
    const arc = [];
    for (let a = 1; a < 10; a++) {
      const ang = (Math.PI * a) / 10;
      arc.push([
        f.p[0] + f.w * (sign * Math.cos(ang) * f.nrm[0] + sign * Math.sin(ang) * f.t[0]),
        f.p[1] + f.w * (sign * Math.cos(ang) * f.nrm[1] + sign * Math.sin(ang) * f.t[1]),
      ]);
    }
    return arc;
  };
  const last = fr[fr.length - 1];
  return toPath([...left, ...(end === "round" ? cap(last, 1) : []), ...right.reverse(), ...(start === "round" ? cap(fr[0], -1) : [])]);
}

/** A thin line along a limb, to one side: a fold in the cloth. */
function fold(pts, widths, side = 0.45, from = 0.12, to = 0.86) {
  const fr = frames(pts, widths);
  const part = fr.slice(Math.floor(fr.length * from), Math.ceil(fr.length * to));
  return `M${part.map((f) => `${n(f.p[0] + f.nrm[0] * f.w * side)} ${n(f.p[1] + f.nrm[1] * f.w * side)}`).join("L")}`;
}

/** The point and direction of a limb some distance back from its end (for a cuff, a hem, a watch). */
function near(pts, widths, back) {
  const fr = frames(pts, widths);
  let travelled = 0;
  let k = fr.length - 1;
  while (k > 0 && travelled < back) {
    travelled += Math.hypot(fr[k].p[0] - fr[k - 1].p[0], fr[k].p[1] - fr[k - 1].p[1]);
    k--;
  }
  return fr[k];
}

/** A line across a limb near its end: a turned hem, a cuff. */
function cuff(pts, widths, back = 5) {
  const f = near(pts, widths, back);
  return `M${n(f.p[0] + f.nrm[0] * f.w)} ${n(f.p[1] + f.nrm[1] * f.w)}L${n(f.p[0] - f.nrm[0] * f.w)} ${n(f.p[1] - f.nrm[1] * f.w)}`;
}

/** A strip across a limb near its end (a rolled hem, a sleeve band, a watch strap), as a closed shape. */
function strip(pts, widths, from, to, grow = 1) {
  const a = near(pts, widths, from);
  const b = near(pts, widths, to);
  const p = (f, s) => [f.p[0] + f.nrm[0] * f.w * grow * s, f.p[1] + f.nrm[1] * f.w * grow * s];
  return toPath([p(a, 1), p(b, 1), p(b, -1), p(a, -1)]);
}

const rot = ([x, y], deg) => {
  const r = (deg * Math.PI) / 180;
  return [x * Math.cos(r) - y * Math.sin(r), x * Math.sin(r) + y * Math.cos(r)];
};

// ---------------------------------------------------------------- drawing primitives

const fill = (d, colour, extra = "") => `<path d="${d}" fill="${colour}"${extra}/>`;
const line = (d, width = 1, colour = V("line"), extra = "") =>
  `<path d="${d}" fill="none" stroke="${colour}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round"${extra}/>`;
const at = (x, y, deg, inner, flip = 1, s = 1) => `<g transform="translate(${n(x)} ${n(y)}) rotate(${n(deg)}) scale(${n(flip * s)} ${n(s)})">${inner}</g>`;
const ellipse = (cx, cy, rx, ry, colour, extra = "") => `<ellipse cx="${n(cx)}" cy="${n(cy)}" rx="${n(rx)}" ry="${n(ry)}" fill="${colour}"${extra}/>`;
const rect = (x, y, w, h, r, colour, extra = "") => `<rect x="${n(x)}" y="${n(y)}" width="${n(w)}" height="${n(h)}" rx="${n(r)}" fill="${colour}"${extra}/>`;
const shade = (d, o = 1) => fill(d, V("shadow"), ` opacity="${o === 1 ? V("shadow-o") : o}"`);
const groundShadow = (cx, cy, rx, ry = 5) => ellipse(cx, cy, rx, ry, V("shadow"), ` opacity="${V("shadow-o")}"`);

let clipCount = 0;
/** [inner], cut to the shape [d]: used for the shadow a limb casts on the body under it. */
function clipped(d, inner) {
  const id = `sc${++clipCount}`;
  return `<clipPath id="${id}"><path d="${d}"/></clipPath><g clip-path="url(#${id})">${inner}</g>`;
}
/** The shadow that the shape [d] casts on [onto]: the same shape, nudged down and back, kept inside [onto]. */
const castShadow = (onto, d, dx = -2.4, dy = 3) => clipped(onto, `<path d="${d}" transform="translate(${dx} ${dy})" fill="#00141b" opacity="0.2"/>`);

// ---------------------------------------------------------------- shoes and hands

/** Shoes. The ankle is at the origin, the toe points to +x and the sole's underside is 11 below. */
const SHOES = {
  sneaker: (c, c2 = V("sole")) =>
    fill("M-9 -8L6.6 -8C10.4 -4 17.2 -0.4 23.2 2.8C26.4 4.8 26.2 9 22.4 9.4L-8.6 9.4C-11.2 9.4-11.2 -3.4-9 -8Z", c) +
    fill("M-10.6 6.4L25.8 6.4C26.4 9 24.8 11 22.2 11L-9 11C-10.6 11-11 9-10.6 6.4Z", c2) +
    fill("M15.6 1.6C19 3.2 22.6 4.8 24.8 6.4L13.2 6.4Z", c2, ' opacity="0.55"') +
    line("M3.6 -5.2L8.8 -6.8M6.8 -2.8L11.6 -4.6M10 -0.4L14.4 -2.4", 1.1, c2) +
    line("M-10 3.6L23 3.6", 0.8, V("line")),
  high: (c, c2 = V("sole")) =>
    fill("M-9.4 -17L5.6 -17C7 -10 9.4 -4 22.4 2.6C26.2 4.6 26 9 22.2 9.4L-8.8 9.4C-11.4 9.4-11.6 -10-9.4 -17Z", c) +
    fill("M-10.6 6.4L25.6 6.4C26.2 9 24.6 11 22 11L-9 11C-10.6 11-11 9-10.6 6.4Z", c2) +
    `<circle cx="-3" cy="-4" r="3.4" fill="${c2}" opacity="0.9"/>` +
    line("M2.6 -13L7.2 -14M3.6 -8.6L8.6 -9.8M6.4 -4L11.4 -5.6", 1.1, c2),
};

/** Puts a shoe on the ground: [contact] is the toe, the heel or the whole sole, at x = [x] and ground y = 0, tilted [deg]. Returns the ankle and the markup. */
function plant(kind, colour, x, deg, contact = "flat", sole) {
  const p = contact === "toe" ? [23, 11] : contact === "heel" ? [-9, 11] : [7, 11];
  const r = rot(p, deg);
  const ankle = [x - r[0], -r[1]];
  return { ankle, svg: at(ankle[0], ankle[1], deg, SHOES[kind](colour, sole)) };
}

/** Hands. The wrist is at the origin and the fingers point to +y. */
const HANDS = {
  rest: (c) =>
    fill("M-4.8 -1.6C-6.2 4-5.6 9.8-2.9 12.6C-0.6 14.6 3.4 14.2 4.8 10.6C6 6.8 5.5 2.2 4.8 -1.6Z", c) +
    fill("M3.8 0.8C7.6 2 9.2 5.6 7.4 8.4C6 9.2 4.8 7.6 4.1 5.6Z", c) +
    line("M-1.8 9.2L-1.3 12.8M1.2 9.4L1.5 13", 0.75),
  open: (c) =>
    fill("M-4.8 -1C-6.2 4-6.6 9-5.2 13.4C-4.8 15-2.6 15-2.2 13.4L-1.6 9.8L-0.8 15.2C-0.4 16.8 1.9 16.8 2.1 15L2.3 10L3.3 14.4C3.9 16 6 15.4 5.8 13.8L5.2 8.2C5.6 4.2 5.6 1 4.8 -1Z", c) +
    fill("M4.2 1C7.8 1.6 11 4.2 11.2 7C11 8.4 9 8.4 8 7.2L4.8 4.8Z", c),
  grip: (c) =>
    fill("M-5 -1.4C-6.4 3.6-5.8 8.4-3.4 10.8C-1 12.6 3.8 12 5.2 8.8C6.2 5.6 5.8 1.8 5 -1.4Z", c) +
    fill("M-1 8.6C1.4 9.6 4.4 9 5.4 6.6", "none", ` stroke="${V("line")}" stroke-width="0.8" stroke-linecap="round"`) +
    line("M-2.6 4.6Q0.6 6 4.6 5M-3 7.6Q0.4 9 4.6 8", 0.7),
};
const hand = (kind, x, y, deg, colour, flip = 1, s = 1.08) => at(x, y, deg, HANDS[kind](colour), flip, s);

// ---------------------------------------------------------------- heads

/** The skull and face, looking to +x, centred on the origin: back of head at -14, face front at 13, chin at 16. */
const SKULL = "M-7 12.4C-12.2 8.6-14.4 1-13.6 -5C-12.6 -13-5.4 -16.8 1 -16.6C8.2 -16.3 13.2 -11.2 13.2 -4.2C13.4 0.8 13.4 5.6 11.8 9.8C10 13.8 6.6 16.2 2.6 16C-1.4 15.8-4.4 14.4-7 12.4Z";

/** Faces. Each returns the eyes, brows, nose and mouth (and any marks) for one mood. */
function face(mood, { female = false, glasses = false } = {}) {
  const ink = V("face");
  const eye = (cx, cy, rx, ry) => ellipse(cx, cy, rx, ry, ink);
  const shine = (cx, cy) => `<circle cx="${cx}" cy="${cy}" r="0.45" fill="#fff" opacity="0.9"/>`;
  const nose = line("M8.4 0.6C9.4 2.6 10.6 3.6 10 4.8C9.4 5.6 8.2 5.6 7.4 5.2", 0.95, ink);
  const lashes = female ? line("M1.8 -3.1L0.6 -4.2M11 -3.1L12.1 -4", 0.8, ink) : "";
  const parts = {
    smile: () =>
      eye(3.2, -1.4, 1.35, 1.8) + eye(9.8, -1.4, 1.15, 1.7) + shine(3.6, -2) +
      line("M0.8 -6.4Q3.2 -7.8 5.6 -6.8", 0.95, ink) + line("M8 -7Q10 -7.8 11.8 -6.4", 0.9, ink) +
      nose + line("M3.8 8.4Q6.6 11.2 10 8.4", 1.05, ink),
    laugh: () =>
      eye(3.2, -1.8, 1.35, 1.75) + eye(9.8, -1.8, 1.15, 1.65) + shine(3.6, -2.4) +
      line("M0.8 -7.2Q3.2 -8.8 5.6 -7.8", 0.95, ink) + line("M8 -7.9Q10 -8.8 11.8 -7.3", 0.9, ink) +
      nose +
      fill("M3.2 7.4Q6.8 6.8 10.6 7.2Q9.8 12.8 6.6 12.8Q3.6 12.4 3.2 7.4Z", ink) +
      fill("M3.7 7.7Q6.8 7.2 10 7.5L9.8 8.9Q6.8 8.6 3.9 9.1Z", "#fff") +
      fill("M5.2 11.6Q6.8 10.4 8.6 11.4Q7.6 12.6 6.4 12.5Z", V("coral"), ' opacity="0.85"'),
    chat: () =>
      eye(3.2, -1.6, 1.35, 1.75) + eye(9.8, -1.6, 1.15, 1.65) + shine(3.6, -2.2) +
      line("M0.8 -6.8Q3.2 -8.2 5.6 -7.2", 0.95, ink) + line("M8 -7.4Q10 -8.2 11.8 -6.8", 0.9, ink) +
      nose +
      fill("M3.8 8Q6.8 7.4 9.8 7.8Q9 11.4 6.6 11.4Q4.4 11.2 3.8 8Z", ink) +
      fill("M4.3 8.2Q6.8 7.8 9.3 8.1L9.1 9.1Q6.8 8.9 4.5 9.3Z", "#fff"),
    focus: () =>
      eye(3.6, -0.4, 1.3, 1.45) + eye(10, -0.4, 1.1, 1.35) +
      line("M1.6 -2.6Q3.6 -3.4 5.4 -2.6M8.6 -2.6Q10 -3.2 11.4 -2.4", 0.75, ink) +
      line("M1 -6.2Q3.4 -7.2 5.6 -6.4", 0.95, ink) + line("M8 -6.6Q10 -7.2 11.8 -6", 0.9, ink) +
      nose + line("M4.6 9.4Q6.8 10.4 9 9.4", 1, ink),
    worried: () =>
      ellipse(3.2, -1.2, 1.9, 2.3, "#fff") + ellipse(9.8, -1.2, 1.55, 2.15, "#fff") +
      eye(3.6, -1, 1.3, 1.7) + eye(10.1, -1, 1.1, 1.6) + shine(4, -1.6) +
      line("M0.4 -5.4Q2.6 -6 5.2 -8.4", 1.05, ink) + line("M7.8 -8.6Q9.6 -6.8 12 -5.8", 1, ink) +
      line("M3.6 -9.6Q4.8 -10.4 6 -9.6", 0.7, ink, ' opacity="0.6"') +
      nose + line("M4 10Q5.4 8.8 6.8 9.8Q8.2 10.8 9.6 9.4", 1.05, ink),
  };
  const blush = mood === "worried" ? "" : ellipse(1.8, 4.6, 2.6, 1.5, V("blush"), ' opacity="0.28"') + ellipse(11.2, 4.4, 1.3, 1.3, V("blush"), ' opacity="0.22"');
  const specs = glasses
    ? fill("M-0.8 -4.6L7 -4.6Q7.6 -4.6 7.6 -4L7.4 1.4Q7.3 2.6 6.2 2.6L0.4 2.6Q-0.6 2.6-0.7 1.6Z", "#fff", ' opacity="0.22"') +
      line("M-0.8 -4.6L7 -4.6Q7.6 -4.6 7.6 -4L7.4 1.4Q7.3 2.6 6.2 2.6L0.4 2.6Q-0.6 2.6-0.7 1.6ZM8.8 -4.4L12.6 -4.4L12.4 1.6Q12.2 2.6 11.4 2.6L9.2 2.6Q8.4 2.6 8.4 1.8ZM7.6 -3.4L8.6 -3.4M-0.8 -3.4L-4.6 -1.6", 1.1, ink)
    : "";
  return blush + parts[mood]() + lashes + specs;
}

/**
 * A head at (x, y), looking to +x (flip -1 looks back), tilted [tilt] degrees. [back] is hair drawn behind the skull,
 * [front] the hair drawn on it; [ear] false hides the ear (long hair over it), [extra] is drawn last (an earring, a cap).
 */
function head(x, y, { skin, skin2, mood, back = "", front = "", ear = true, extra = "", tilt = 0, flip = 1, female = false, glasses = false }) {
  const earSvg = ear ? ellipse(-3.6, 1.6, 2.9, 3.9, skin) + line("M-3.4 -0.4Q-1.8 1.4-3.2 3.6", 0.8, skin2) : "";
  const jawShade = fill("M-7 12.4C-4.4 14.4-1.4 15.8 2.6 16C-0.6 13.2-3.2 10.4-4.6 6.6C-6 7.6-6.8 9.4-7 12.4Z", skin2, ' opacity="0.55"');
  return at(x, y, tilt, back + fill(SKULL, skin) + jawShade + earSvg + face(mood, { female, glasses }) + front + extra, flip);
}

/** Hair, in head coordinates. Each style has a mass behind the skull and a cap on it whose edge runs inside the skull. */
const HAIR = {
  // Long box braids falling down the back, parted on the side, swept behind the ear.
  braids: (c, c2) => ({
    back:
      fill("M-10.6 -12.6C-17.6 -6-19.8 6-19.4 20C-19 34-20 48-17 58C-14 64-5.4 64-3.4 56.4C-4.8 44-5.6 31-4.6 19C-4 11-6 5-6.4 -1Z", c) +
      [-16.4, -13, -9.6, -6.8]
        .map((bx, i) => line(`M${bx} ${4 + i}C${bx - 1} 22 ${bx - 1.4} 40 ${bx + 0.6} ${58 - i * 2}`, 0.75, c2))
        .join("") +
      [10, 20, 30, 40, 50].map((by) => line(`M-17.6 ${by}l1.6 1.6l1.6 -1.6l1.7 1.6l1.6 -1.6l1.7 1.6l1.6 -1.6`, 0.6, c2, ' opacity="0.8"')).join(""),
    front:
      fill("M-14 4.4C-16.4 -8.4-8.6 -18.8 1.4 -18.6C9.8 -18.4 15.2 -12.6 14 -5.6C11.4 -9 7.6 -10.4 3.8 -10C1.6 -12 -1.4 -11.6 -3 -10C-5.6 -6.4-6.6 -2-7.4 2C-8.2 5.2-9.6 6.8-11 6.8C-12.4 6.8-13.6 6-14 4.4Z", c) +
      line("M1.4 -18.4Q0 -14.4-2.6 -10.4", 0.9, c2) +
      line("M-11 -10Q-8 -14.6-2 -16.4M-12.6 -4Q-10.6 -10-5 -13.4", 0.75, c2),
  }),
  // Short twists on top, faded at the sides.
  twists: (c, c2) => ({
    back: "",
    front:
      fill("M-14.6 3C-18.4 -6-14.8 -20.2 0 -20.8C11.8 -21.2 16.6 -13.8 14.8 -6.6C12.8 -9.8 9 -11 5.2 -10.2C1.6 -9.6-2.2 -7.6-4.4 -3.6C-5.4 -1.2-6 1.6-7.4 4C-10 5.6-13.2 5-14.6 3Z", c) +
      [[-9, -14], [-4, -17], [2, -18], [8, -16], [-12, -8], [-7, -10], [-1, -13], [5, -13], [10, -12], [-11, -2]]
        .map(([cx, cy]) => line(`M${cx - 1.6} ${cy + 0.8}q1.6 -2.4 3.2 0`, 0.8, c2))
        .join(""),
  }),
  // Short and tidy with a lifted front, for the one in glasses.
  tidy: (c, c2) => ({
    back: "",
    front:
      fill("M-13.8 2.8C-16 -8-9.6 -19.2 1 -19.6C8 -19.8 12.8 -17.2 14.2 -12.2C15 -9.6 14.2 -7.4 13.4 -6.6C11.2 -10.4 6.8 -11.6 2.6 -11C-0.6 -10.4-3.4 -8.6-4.6 -5.4C-5.6 -2.8-5.8 0.4-7 3.2C-9.4 4.8-12.4 4.6-13.8 2.8Z", c) +
      line("M-9 -13.4Q-2 -18.6 8 -17.2M-12 -6.6Q-7 -13.4 1 -14.6M2.6 -11Q8 -13.6 13.4 -10.6", 0.8, c2),
  }),
  // Short hair under a cap worn forward (the cap is drawn as [extra]).
  capped: (c) => ({
    back: "",
    front: fill("M-13.8 2.4C-14.8 -3.6-12.8 -8-9 -9.2L-5.4 -7C-6.6 -3.6-6.8 0-7.2 3.6C-9.6 5.2-12.6 4.6-13.8 2.4Z", c),
  }),
};

const CAP = (c, c2) =>
  fill("M-14.2 -3.2C-15.2 -14-7.2 -20.4 1 -20.2C8.6 -20 14 -14.8 13.6 -7.4C4 -6.6-5.2 -5-14.2 -3.2Z", c) +
  fill("M7.8 -9.2C14 -10.4 20.4 -10 25 -7.8C25.6 -6.6 24.4 -5.6 22.2 -5.4C17 -5 11 -5.6 6.8 -6.4Z", c2) +
  line("M1 -20.2Q-2 -12-3.4 -5.6M1 -20.2Q8 -15.4 10.6 -7.6", 0.8, c2) +
  `<circle cx="1" cy="-20.4" r="1.3" fill="${c2}"/>`;

// ---------------------------------------------------------------- the people (each stands on y = 0)

/** He walks a step ahead and looks back at her, laughing, a thumb hooked on his backpack strap. Cap, tee, jeans, backpack. */
function laugher() {
  const skin = V("skin-a");
  const skin2 = V("skin-a2");
  const front = plant("sneaker", V("coral"), 33, -10, "heel");
  const back = plant("sneaker", V("coral"), -12, 26, "toe");
  const farLeg = [[5, -94], [17, -54], front.ankle];
  const nearLeg = [[-3, -94], [-8, -52], back.ankle];
  const legW = [21, 19, 16.5];
  const torso = "M-14.4 -150C-9.6 -155.6 9 -156.6 14.8 -150C17.4 -136 17 -118 15.4 -100L-14.2 -100C-16.4 -118-17.6 -136-14.4 -150Z";
  const farArm = [[9, -146], [16, -122], [17, -98]];
  const nearArm = [[-4, -147], [-1, -118], [-8, -128]];
  const nearUpper = [[-4, -147], [-2, -128]];
  const out = [];
  out.push(groundShadow(6, 1.5, 40));
  // far side first
  out.push(front.svg);
  out.push(fill(band(farLeg, legW), V("denim2")) + fill(strip(farLeg, legW, 0, 5.5, 1.04), V("denim3")) + line(fold(farLeg, legW, 0.4), 0.9));
  out.push(fill(band(farArm, [10.6, 8.8, 8], { start: "round", end: "round" }), skin2));
  out.push(fill(band([[9, -146], [14, -131]], [12.6, 11.2], { start: "round" }), V("cream2")));
  out.push(hand("rest", 17.2, -99, -6, skin2));
  // backpack
  out.push(fill("M-12.6 -148C-25 -149.4-31.6 -140-31.6 -126L-30.6 -104C-30.4 -96.4-23.6 -93.6-12.6 -95Z", V("teal")));
  out.push(fill("M-30.4 -121L-15 -121L-15 -101C-21.6 -99.4-29.6 -100-30.2 -106Z", V("teal2")));
  out.push(line("M-28 -132Q-22 -134-16 -132", 1.2, V("teal3")) + rect(-23.6, -128, 4.4, 2.6, 1.2, V("cream")));
  // near leg with its rolled hem and bare ankle
  out.push(back.svg);
  out.push(fill(band([[-3, -94], [-8, -52], back.ankle], legW), V("denim")) + fill(strip(nearLeg, legW, 0, 5.5, 1.04), V("denim3")) + line(fold(nearLeg, legW, 0.42), 0.95));
  out.push(fill("M-14.6 -104L15.6 -104L17 -86L-15.6 -86Z", V("denim")));
  out.push(line("M2 -103.6L2.6 -88M-8 -96Q-4 -92.6 0.6 -94", 0.9));
  // tee
  out.push(fill(torso, V("cream")));
  out.push(line("M-6 -153Q1 -148.4 8.4 -153.6", 1.2, V("cream2")) + line("M-12 -112Q0 -108 13 -112", 0.9));
  out.push(castShadow(torso, band(nearArm, [10.4, 9, 8], { start: "round", end: "round" })));
  out.push(line("M-8.4 -151Q-13 -138-13.2 -110", 3.4, V("teal2")));
  // near arm bent, the hand hooked on the strap
  out.push(fill(band(nearArm, [10.4, 9, 8], { start: "round", end: "round" }), skin));
  out.push(fill(band(nearUpper, [13.2, 11.8], { start: "round" }), V("cream")) + line(cuff(nearUpper, [13.2, 11.8], 1.8), 0.9));
  out.push(hand("grip", -9.4, -127, 150, skin));
  out.push(line("M-11.6 -136Q-12.4 -130-12.6 -124", 3.4, V("teal2")));
  // neck and head
  out.push(fill("M-2.6 -164L5.4 -164L6 -152L-3.2 -152Z", skin2));
  out.push(head(4, -177, { skin, skin2, mood: "laugh", tilt: 4, flip: -1, ...HAIR.capped(V("hair")), extra: CAP(V("orange"), V("orange2")) }));
  return out.join("");
}

/** She walks a step behind him, telling him something, a hand open in front of her. Braids, mustard top, teal midi skirt, tote, coffee. */
function chatter() {
  const skin = V("skin-c");
  const skin2 = V("skin-c2");
  const front = plant("sneaker", V("white"), 28, -8, "heel", V("teal"));
  const back = plant("sneaker", V("white"), -14, 26, "toe", V("teal"));
  const farLeg = [[5, -94], [-3, -52], back.ankle];
  const nearLeg = [[-2, -94], [10, -52], front.ankle];
  const calfW = [13, 11.2, 8.4];
  const torso = "M-12.8 -150C-8.6 -155 8.6 -156 13.4 -150C16.8 -142 17.2 -132 14.6 -124C13.2 -118 13.6 -110 14.2 -102L-12.6 -102C-14.4 -118-15.4 -136-12.8 -150Z";
  const farArm = [[8, -146], [15, -124], [18, -106]];
  const nearUpper = [[-4, -146], [-1, -121]];
  const nearFore = [[-1, -121], [12, -121], [26, -130]];
  const out = [];
  out.push(groundShadow(6, 1.5, 38));
  out.push(back.svg);
  out.push(fill(band(farLeg, calfW), skin2));
  // far arm forward, holding a takeaway coffee
  out.push(fill(band(farArm, [10, 8.6, 7.4], { start: "round" }), V("mustard2")) + line(cuff(farArm, [10, 8.6, 7.4], 3.2), 0.9));
  out.push(fill("M16.4 -104.4L27.6 -104.4L25.8 -86.6Q25.6 -85.2 24.2 -85.2L19.8 -85.2Q18.4 -85.2 18.2 -86.6Z", V("white")) + rect(15.6, -107, 12.8, 3.4, 1.4, V("teal")) + fill("M17.2 -99L26.8 -99L26.2 -92.4L17.8 -92.4Z", V("orange")));
  out.push(hand("grip", 19, -105, -70, skin2));
  out.push(front.svg);
  out.push(fill(band(nearLeg, calfW), skin));
  // skirt, flared by the stride
  const skirt = "M-13.4 -106L14.4 -106C17.6 -86 26 -62 31 -44C20 -39.6 3 -38.6-22.6 -42.4C-19.6 -62-15.6 -86-13.4 -106Z";
  out.push(fill(skirt, V("skirt")));
  out.push(line("M2 -100Q4 -70 6 -40.6M-6 -98Q-11 -72-14 -41.6M10 -98Q18 -72 22 -42", 1, V("skirt2")));
  out.push(fill("M-13.6 -108L14.6 -108L14.8 -102L-13.8 -102Z", V("skirt2")));
  // top
  out.push(fill(torso, V("mustard")));
  out.push(line("M-5.6 -153Q1 -148 8 -153.4", 1.2, V("mustard2")) + line("M-11 -116Q1 -112 13 -115", 0.9));
  // tote on her near shoulder, hanging at her hip
  out.push(line("M-6 -152Q-17 -134-19 -112M-2 -152Q-9 -132-8 -112", 2.2, V("cream2")));
  out.push(fill("M-24 -114L-2 -114L-0.4 -86Q-0.4 -83-3.4 -83L-23.4 -83Q-26.4 -83-26.2 -86Z", V("cream")));
  out.push(fill("M-25.4 -101L-1.2 -101L-1 -95L-25.8 -95Z", V("orange")) + line("M-23.8 -110L-2.4 -110", 0.8));
  out.push(castShadow(torso, band(nearFore, [9.6, 8.6, 7.6], { start: "round" })));
  out.push(fill(band(nearFore, [9.6, 8.6, 7.6], { start: "round" }), V("mustard")) + line(cuff(nearFore, [9.6, 8.6, 7.6], 3), 0.9));
  out.push(fill(band(nearUpper, [11, 10], { start: "round", end: "round" }), V("mustard")));
  out.push(hand("open", 26.6, -131, -116, skin));
  out.push(fill("M-2.2 -164L5 -164L5.6 -152L-2.8 -152Z", skin2));
  out.push(
    head(2.6, -177, {
      skin,
      skin2,
      mood: "chat",
      female: true,
      tilt: -2,
      ...HAIR.braids(V("hair"), V("hair2")),
      extra: `<circle cx="-3.4" cy="7.6" r="1.9" fill="none" stroke="${V("gold")}" stroke-width="1"/>`,
    }),
  );
  return out.join("");
}

/**
 * On the bench, leaning forward, elbows on his knees, looking down at his phone held in both hands (we see its back).
 * Twists, teal hoodie, headphones round his neck. The origin is on the seat under his hip; the ground is 62 below.
 */
function phoner() {
  const skin = V("skin-b");
  const skin2 = V("skin-b2");
  const g = 62;
  const farThigh = [[2, -10], [28, -18], [50, -19]];
  const farShin = [[50, -19], [56, 16], [60, g - 13]];
  const nearThigh = [[-2, -8], [22, -12], [42, -12]];
  const nearShin = [[42, -12], [42, 20], [40, g - 13]];
  const torso = "M-14 -2C-15.6 -20-7 -40 5 -52C11.6 -57.4 23.6 -56.6 27.8 -49C30 -38 24 -18 16 -2Z";
  const out = [];
  out.push(groundShadow(30, g + 1.5, 46));
  // far leg
  out.push(at(62, g - 11, 0, SHOES.high(V("orange"))));
  out.push(fill(band(farShin, [17, 16, 14.6]), V("ink2")) + fill(strip(farShin, [17, 16, 14.6], 0, 5, 0.98), V("ink")) + fill(band(farThigh, [21, 20, 18], { end: "round" }), V("ink2")));
  // far arm (mostly hidden behind)
  out.push(fill(band([[22, -48], [42, -24], [52, -38]], [11, 9.4, 8.2], { start: "round" }), V("teal2")));
  out.push(fill(torso, V("teal")));
  out.push(fill("M-4 -24L16 -26L16 -10L-3 -8Z", V("teal2"), ' opacity="0.65"') + line("M-12 -6Q2 -3 15 -6", 1.1, V("teal2")));
  out.push(line("M14 -53L12 -42M18 -53L17.6 -43", 1, V("cream")));
  // near leg
  out.push(at(42, g - 11, 0, SHOES.high(V("orange"))));
  out.push(fill(band(nearShin, [18, 16.6, 15]), V("ink")) + fill(strip(nearShin, [18, 16.6, 15], 0, 5, 0.98), V("ink2")));
  out.push(fill(band(nearThigh, [22, 21, 19], { end: "round" }), V("ink")) + line(fold(nearThigh, [22, 21, 19], -0.35), 0.9));
  // phone, back to us, held in both hands
  out.push(at(55, -47, -58, rect(-5, -9.6, 10, 19.2, 2.2, V("phone")) + rect(-3, -7.6, 3.2, 3.2, 1, "#4a5d66") + `<circle cx="2.4" cy="-6" r="0.9" fill="#4a5d66"/>`));
  out.push(hand("grip", 53.4, -40.6, -134, skin2));
  // near arm, elbow on the knee
  const nearArm = [[10, -48], [36, -18], [50, -34]];
  out.push(castShadow(torso, band(nearArm, [12, 10.4, 9], { start: "round" })));
  out.push(fill(band(nearArm, [12, 10.4, 9], { start: "round" }), V("teal")) + line(cuff(nearArm, [12, 10.4, 9], 3.6), 1));
  out.push(hand("grip", 50.6, -36, -142, skin));
  // headphones round the neck
  out.push(fill("M17 -64L24 -64L25.2 -53L16 -53Z", skin2));
  out.push(line("M11 -58Q21 -50 29 -56", 2.6, V("ink2")) + ellipse(12, -56, 3.4, 4.6, V("ink2")) + ellipse(28.4, -55, 3, 4.2, V("ink")));
  out.push(head(27, -75, { skin, skin2, mood: "focus", tilt: 28, ...HAIR.twists(V("hair"), V("hair2")) }));
  return out.join("");
}

/** The backpack he left on the bench. The origin is on the seat under its middle. */
function bag() {
  return (
    groundShadow(0, 1, 20, 3.4) +
    line("M-8 -36Q0 -50 8 -36", 4, V("coral2")) +
    fill("M-16 -4C-17 -22-13.6 -38 0 -39C13.6 -38 17 -22 16 -4C16 -1 12.6 0 9 0L-9 0C-12.6 0-16 -1-16 -4Z", V("coral")) +
    fill("M-11 -3C-12 -12-9 -18 0 -18C9 -18 12 -12 11 -3C10.8 -1.4 9.2 -0.8 7.6 -0.8L-7.6 -0.8C-9.2 -0.8-10.8 -1.4-11 -3Z", V("coral2")) +
    line("M-6 -29L6 -29", 2, V("cream")) +
    line("M-4 -10L4 -10", 1.2, V("cream"), ' opacity="0.8"') +
    line("M-15 -8Q-24 -1-19 8", 3.4, V("coral2"))
  );
}

/**
 * Pacing near the sign, worried: a step, a hand at his chin, his phone in the other hand, looking down the road for a bus
 * that should be here by now. Glasses, an orange overshirt over a white tee, dark chinos. His bag is on the bench.
 */
function worrier() {
  const skin = V("skin-d");
  const skin2 = V("skin-d2");
  const front = plant("sneaker", V("teal"), 30, -8, "heel");
  const back = plant("sneaker", V("teal"), -14, 24, "toe");
  const farLeg = [[5, -94], [-3, -52], back.ankle];
  const nearLeg = [[-2, -94], [12, -54], front.ankle];
  const legW = [20, 18, 16];
  const torso = "M-14.2 -150C-9.4 -155.6 9 -156.6 14.6 -150C17.2 -136 16.8 -118 15.2 -100L-14 -100C-16.2 -118-17.4 -136-14.2 -150Z";
  const farArm = [[9, -146], [17, -122], [19, -102]];
  const nearUpper = [[-4, -146], [-1, -120]];
  const nearFore = [[-1, -120], [12, -136], [17, -151]];
  const out = [];
  out.push(groundShadow(6, 1.5, 38));
  out.push(back.svg);
  out.push(fill(band(farLeg, legW), V("ink2")) + line(fold(farLeg, legW, 0.4), 0.9) + line(cuff(farLeg, legW, 5), 1));
  // far arm, phone in hand
  out.push(fill(band(farArm, [11, 9.6, 8.6], { start: "round" }), V("orange2")) + line(cuff(farArm, [11, 9.6, 8.6], 3), 0.9));
  out.push(at(21, -94, 8, rect(-4.4, -2, 8.8, 15, 2, V("phone"))));
  out.push(hand("grip", 19.4, -102, -10, skin2));
  out.push(front.svg);
  out.push(fill(band(nearLeg, legW), V("ink")) + line(fold(nearLeg, legW, 0.42), 0.95) + line(cuff(nearLeg, legW, 5), 1));
  out.push(fill("M-14.4 -104L15.4 -104L17 -86L-15.4 -86Z", V("ink")));
  // tee and the open overshirt
  out.push(fill(torso, V("white")));
  out.push(fill("M-14.2 -150C-9.4 -155.6 0 -156 2 -155L-2 -100L-14 -100C-16.2 -118-17.4 -136-14.2 -150Z", V("orange")));
  out.push(fill("M9.4 -154.6C11.6 -154 13.4 -152.4 14.6 -150C17.2 -136 16.8 -118 15.2 -100L10.6 -100C11.4 -118 12 -136 9.4 -154.6Z", V("orange2")));
  out.push(line("M-13 -138L1 -138M-13.6 -124L-0.4 -124M-13.4 -110L-1 -110M-8 -152L-8.6 -101", 0.7, V("orange2"), ' opacity="0.9"'));
  out.push(line("M-0.6 -154L-4.6 -144L0.4 -138", 1, V("orange2")));
  out.push(castShadow(torso, band(nearFore, [9.8, 8.6, 7.6], { start: "round" })));
  // near arm up, hand at his chin
  out.push(fill(band(nearUpper, [12.4, 11], { start: "round", end: "round" }), V("orange")));
  out.push(fill(band(nearFore, [9.8, 8.6, 7.6], { start: "round" }), V("orange")) + line(cuff(nearFore, [9.8, 8.6, 7.6], 3), 0.9));
  out.push(fill("M-2.6 -164L5.4 -164L6 -152L-3.2 -152Z", skin2));
  out.push(head(4, -177, { skin, skin2, mood: "worried", tilt: -6, glasses: true, ...HAIR.tidy(V("hair-b"), V("hair-b2")) }));
  out.push(hand("rest", 17.4, -151, 166, skin));
  // a drop of sweat and two small worry marks
  out.push(fill("M21.4 -192.6C23.6 -189.4 24.4 -187.4 23.4 -186C22.4 -184.8 20.4 -185 19.8 -186.4C19.2 -187.8 20 -189.8 21.4 -192.6Z", V("sweat")));
  out.push(line("M24 -203Q27 -205 28.6 -201.4M28.8 -197Q32 -198 32.6 -194.4", 1.3, V("face"), ' opacity="0.55"'));
  return out.join("");
}

// ---------------------------------------------------------------- the town and the street

const GROUND = 506; // where the people and the front of the shelter stand
const P = 1.18; // the people are drawn about 196 tall and placed a little larger
const BASE = 470; // where the buildings stand
let seed = 31;
const rand = () => {
  seed = (seed * 1664525 + 1013904223) >>> 0;
  return seed / 0xffffffff;
};

/** A tower of the far skyline: one pale tone with lighter window strips, the way a background stays quiet. */
function farTower(x, w, h, kind = 0) {
  const top = BASE - h;
  let s = rect(x, top, w, h + 2, 2, V("far"));
  if (kind === 0) {
    for (let k = x + 7; k < x + w - 8; k += 11) s += rect(k, top + 12, 5, h - 22, 1.5, V("far2"));
  } else {
    for (let r = top + 12; r < BASE - 16; r += 15) for (let k = x + 7; k < x + w - 10; k += 14) s += rect(k, r, 8, 8, 1.5, V("far2"));
  }
  return s;
}

/** A building of the campus, one step nearer: a body, a parapet, a halftone side, rows of windows (a few lit at night). */
function campus(x, w, h, cols, rows, { side = 18, dots = true } = {}) {
  const top = BASE - h;
  let s = rect(x, top, w, h + 2, 2, V("mid")) + rect(x + w, top + 6, side, h - 4, 1, V("mid2"));
  if (dots) s += rect(x + w, top + 6, side, h - 4, 1, "url(#s-dots)");
  s += rect(x - 4, top - 8, w + 8, 10, 2, V("mid2"));
  const gx = (w - 16) / cols;
  const gy = (h - 40) / rows;
  for (let r = 0; r < rows; r++) for (let k = 0; k < cols; k++) s += rect(x + 8 + k * gx + 3, top + 14 + r * gy, gx - 7, gy - 8, 1.5, rand() > 0.55 ? V("lit") : V("win"));
  return s;
}

/** A round tree in two tones, its trunk set into the ground. */
function tree(cx, r, h = r * 1.4) {
  const top = BASE - h;
  return (
    rect(cx - 3.5, top, 7, h + 2, 2, V("struct"), ' opacity="0.55"') +
    `<circle cx="${cx}" cy="${top - r * 0.2}" r="${r}" fill="${V("tree")}"/>` +
    `<circle cx="${cx - r * 0.7}" cy="${top + r * 0.35}" r="${r * 0.62}" fill="${V("tree")}"/>` +
    `<circle cx="${cx + r * 0.72}" cy="${top + r * 0.3}" r="${r * 0.66}" fill="${V("tree2")}"/>` +
    `<path d="M${cx + r * 0.2} ${top - r * 0.9}A${r} ${r} 0 0 1 ${cx + r} ${top - r * 0.2}A${r * 0.66} ${r * 0.66} 0 0 1 ${cx + r * 1.38} ${top + r * 0.3}" fill="none" stroke="${V("tree2")}" stroke-width="0"/>`
  );
}

/** A long low planter at the back of the pavement, with a hedge in it: it ties the town to the street. */
function planter(x, w) {
  let bush = "";
  for (let k = x + 8; k < x + w - 4; k += 22) {
    const r = 13 + ((k * 7) % 6);
    bush += `<circle cx="${k}" cy="${BASE + 4 - r * 0.4}" r="${r}" fill="${V("bush")}"/>`;
    bush += `<circle cx="${k + 9}" cy="${BASE + 6 - r * 0.2}" r="${r * 0.7}" fill="${V("bush2")}"/>`;
  }
  return (
    clipped(`M${x - 4} ${BASE - 60}H${x + w + 4}V${BASE + 8}H${x - 4}Z`, bush) +
    rect(x, BASE + 4, w, 24, 2, V("planter")) +
    rect(x - 3, BASE + 2, w + 6, 6, 2, V("planter2")) +
    rect(x, BASE + 22, w, 6, 0, V("planter2"))
  );
}

/** A street lamp standing on the pavement, glowing at night. */
function lamp(x) {
  return (
    `<circle cx="${x + 24}" cy="${GROUND - 168}" r="96" fill="url(#s-glow)" opacity="${V("glow-o")}"/>` +
    rect(x - 4, GROUND - 6, 14, 7, 2, V("struct")) +
    rect(x, GROUND - 166, 6, 162, 3, V("struct")) +
    `<path d="M${x + 3} ${GROUND - 164}Q${x + 3} ${GROUND - 180} ${x + 26} ${GROUND - 178}" fill="none" stroke="${V("struct")}" stroke-width="5" stroke-linecap="round"/>` +
    rect(x + 16, GROUND - 182, 24, 8, 4, V("struct")) +
    rect(x + 19, GROUND - 175, 18, 4, 2, V("lit"))
  );
}

/** The shelter, drawn in depth: back posts and glass, the bench, the side panels, the front posts and the roof. */
function shelter(x0) {
  const L = x0;
  const R = x0 + 320;
  const back = GROUND - 14; // the back of the shelter stands a little further away
  const roofY = GROUND - 292;
  const s = [];
  s.push(groundShadow(L + 160, GROUND + 1, 190, 9));
  // back wall: two posts and the glass between them
  s.push(rect(L + 34, roofY + 30, 9, back - roofY - 30, 2, V("struct2")) + rect(R - 43, roofY + 30, 9, back - roofY - 30, 2, V("struct2")));
  s.push(rect(L + 43, roofY + 60, R - L - 86, back - roofY - 74, 1, V("glass"), ` opacity="${V("glass-o")}"`));
  s.push(fill(`M${L + 70} ${roofY + 60}L${L + 104} ${roofY + 60}L${L + 54} ${back - 14}L${L + 43} ${back - 14}L${L + 43} ${back - 50}Z`, "#fff", ' opacity="0.25"'));
  s.push(fill(`M${L + 126} ${roofY + 60}L${L + 138} ${roofY + 60}L${L + 92} ${back - 14}L${L + 80} ${back - 14}Z`, "#fff", ' opacity="0.2"'));
  s.push(rect(L + 43, back - 16, R - L - 86, 4, 1, V("struct2")) + rect(L + 43, roofY + 58, R - L - 86, 4, 1, V("struct2")));
  // the route board on the back wall
  s.push(rect(L + 52, roofY + 74, 40, 52, 3, V("ad")) + [0, 1, 2, 3, 4].map((i) => rect(L + 58, roofY + 84 + i * 8, i % 2 ? 20 : 28, 3, 1.5, V("cream2"))).join(""));
  // bench: backrest slats, seat, legs (the seat top is at GROUND - 60)
  const seat = GROUND - Math.round(62 * P);
  s.push(rect(L + 66, seat - 50, 188, 9, 2, V("struct")) + rect(L + 66, seat - 34, 188, 9, 2, V("struct")));
  s.push(rect(L + 76, seat - 52, 6, 52, 2, V("struct2")) + rect(L + 238, seat - 52, 6, 52, 2, V("struct2")));
  s.push(rect(L + 74, seat + 8, 7, GROUND - seat - 12, 2, V("struct2")) + rect(L + 239, seat + 8, 7, GROUND - seat - 12, 2, V("struct2")));
  s.push(rect(L + 70, GROUND - 6, 15, 5, 2, V("struct2")) + rect(L + 235, GROUND - 6, 15, 5, 2, V("struct2")));
  s.push(rect(L + 60, seat, 200, 7, 2, V("roof")) + rect(L + 62, seat + 6, 196, 4, 1, V("roof2")));
  return { before: s.join(""), seat, roofY, L, R };
}

function shelterFront({ L, R, roofY }) {
  const s = [];
  // side glass panel on the left, an advert on the right
  s.push(fill(`M${L + 8} ${roofY + 40}L${L + 36} ${roofY + 58}L${L + 36} ${GROUND - 66}L${L + 8} ${GROUND - 44}Z`, V("glass"), ` opacity="${V("glass-o")}"`));
  s.push(fill(`M${R - 8} ${roofY + 40}L${R - 36} ${roofY + 58}L${R - 36} ${GROUND - 66}L${R - 8} ${GROUND - 44}Z`, V("struct2")));
  s.push(fill(`M${R - 12} ${roofY + 48}L${R - 32} ${roofY + 61}L${R - 32} ${GROUND - 70}L${R - 12} ${GROUND - 52}Z`, V("ad")));
  s.push(fill(`M${R - 14} ${roofY + 78}L${R - 30} ${roofY + 88}L${R - 30} ${roofY + 128}L${R - 14} ${roofY + 120}Z`, V("roof"), ' opacity="0.9"'));
  s.push(fill(`M${R - 15} ${roofY + 138}L${R - 29} ${roofY + 146}L${R - 29} ${roofY + 150}L${R - 15} ${roofY + 142}Z`, V("struct"), ' opacity="0.5"'));
  // front posts with their feet, and the roof
  s.push(rect(L, roofY + 22, 11, GROUND - roofY - 24, 2, V("struct")) + rect(R - 11, roofY + 22, 11, GROUND - roofY - 24, 2, V("struct")));
  s.push(rect(L - 5, GROUND - 7, 21, 7, 2, V("struct")) + rect(R - 16, GROUND - 7, 21, 7, 2, V("struct")));
  s.push(fill(`M${L - 22} ${roofY + 26}L${L - 6} ${roofY + 2}Q${(L + R) / 2} ${roofY - 18} ${R + 6} ${roofY + 2}L${R + 22} ${roofY + 26}Z`, V("roof")));
  s.push(fill(`M${L - 22} ${roofY + 26}L${R + 22} ${roofY + 26}L${R + 16} ${roofY + 36}L${L - 16} ${roofY + 36}Z`, V("struct")));
  s.push(fill(`M${L + 96} ${roofY - 6}L${L + 112} ${roofY - 8}L${L + 104} ${roofY + 26}L${L + 86} ${roofY + 26}Z M${R - 112} ${roofY - 8}L${R - 96} ${roofY - 6}L${R - 86} ${roofY + 26}L${R - 104} ${roofY + 26}Z`, V("roof2")));
  s.push(fill(`M${L - 6} ${roofY + 2}Q${(L + R) / 2} ${roofY - 18} ${R + 6} ${roofY + 2}L${R + 8} ${roofY + 6}Q${(L + R) / 2} ${roofY - 12} ${L - 8} ${roofY + 6}Z`, "#fff", ' opacity="0.25"'));
  return s.join("");
}

/** The stop sign: a bus on a plate, a timetable under it, a pole set in a foot. */
function sign(x) {
  const top = GROUND - 280;
  return (
    groundShadow(x + 5, GROUND + 1, 16, 3) +
    rect(x - 4, GROUND - 7, 18, 7, 2, V("struct")) +
    rect(x, top + 40, 10, GROUND - top - 46, 3, V("struct")) +
    rect(x - 26, top, 62, 62, 8, V("struct")) +
    rect(x - 21, top + 5, 52, 52, 5, V("roof")) +
    // the bus pictogram
    rect(x - 10, top + 13, 30, 30, 6, V("struct")) +
    rect(x - 6, top + 18, 22, 11, 2, V("roof")) +
    rect(x - 7, top + 33, 6, 4, 2, V("roof")) +
    rect(x + 11, top + 33, 6, 4, 2, V("roof")) +
    rect(x - 7, top + 43, 5, 5, 1.5, V("struct")) +
    rect(x + 12, top + 43, 5, 5, 1.5, V("struct")) +
    // the timetable, with the times nobody trusts
    rect(x - 18, top + 76, 46, 58, 4, V("ad")) +
    rect(x - 18, top + 76, 46, 9, 4, V("struct")) +
    [0, 1, 2, 3, 4].map((i) => rect(x - 12, top + 92 + i * 8, i % 2 ? 26 : 34, 3, 1.5, V("cream2"))).join("") +
    line(`M${x + 15} ${top + 106}l8 8M${x + 23} ${top + 106}l-8 8`, 1.6, V("coral"))
  );
}

function scene() {
  clipCount = 0;
  seed = 31;
  const layers = [];

  // 1. The far town: one continuous pale skyline.
  let far = "";
  [
    [0, 70, 210, 0], [64, 60, 150, 1], [120, 54, 250, 0], [168, 90, 170, 1], [252, 48, 280, 0], [296, 80, 190, 1],
    [372, 60, 140, 0], [430, 70, 230, 1], [496, 56, 160, 0], [548, 84, 200, 1], [628, 60, 260, 0], [684, 76, 170, 1],
    [756, 66, 140, 0], [818, 58, 220, 1], [872, 80, 160, 0], [948, 62, 250, 1], [1006, 70, 180, 0], [1072, 56, 140, 1],
    [1124, 84, 230, 0], [1204, 60, 170, 1], [1260, 72, 270, 0], [1328, 66, 160, 1], [1390, 84, 210, 0], [1470, 56, 150, 1],
    [1522, 78, 240, 0],
  ].forEach(([x, w, h, k]) => (far += farTower(x, w, h, k)));
  layers.push(far);

  // 2. The campus, a step nearer, and its clock tower, with trees in front.
  let mid = campus(36, 170, 150, 5, 4) + campus(300, 120, 112, 4, 3) + campus(1110, 150, 130, 5, 3) + campus(1380, 180, 166, 6, 4);
  mid += rect(1300, BASE - 268, 56, 270, 2, V("mid")) + fill(`M1290 ${BASE - 266}L1328 ${BASE - 318}L1366 ${BASE - 266}Z`, V("mid2"));
  mid += `<circle cx="1328" cy="${BASE - 232}" r="17" fill="${V("lit")}"/>` + line(`M1328 ${BASE - 232}V${BASE - 243}M1328 ${BASE - 232}L1337 ${BASE - 227}`, 2.6, V("struct"));
  for (let i = 0; i < 4; i++) mid += rect(1320, BASE - 190 + i * 44, 16, 22, 2, i % 2 ? V("lit") : V("win"));
  mid += tree(250, 30) + tree(470, 26) + tree(600, 34, 46) + tree(1080, 28) + tree(1270, 32) + tree(1590, 30);
  layers.push(mid);

  // 3. The street: planters, the pavement, the curb and the road melting into the page.
  let street = planter(-10, 280) + planter(500, 170) + planter(1180, 220) + planter(1440, 180);
  street += rect(0, BASE + 28, 1600, 52, 0, V("paver"));
  street += line(`M0 ${BASE + 28}H1600`, 1.2, V("struct"), ' opacity="0.35"');
  for (let k = 26; k < 1600; k += 64) street += line(`M${k} ${BASE + 30}L${k - 10} ${BASE + 80}`, 1.4, V("paver2"));
  street += line(`M0 ${BASE + 54}H1600`, 1.4, V("paver2"));
  street += rect(0, BASE + 80, 1600, 10, 0, V("curb")) + line(`M0 ${BASE + 80}H1600`, 1.2, V("struct"), ' opacity="0.4"');
  street += rect(0, BASE + 90, 1600, 90, 0, V("road"));
  street += line(`M0 ${BASE + 130}H1600`, 5, V("lane"), ' stroke-dasharray="50 40"');
  street += rect(0, BASE + 98, 1600, 82, 0, "url(#s-fade)");
  street += lamp(260) + lamp(1300);
  layers.push(street);

  // 4. The shelter with the student on the bench and the bag.
  const sh = shelter(690);
  let stop = sh.before;
  stop += `<g transform="translate(${sh.L + 100} ${sh.seat}) scale(${P})">${phoner()}</g>`;
  stop += shelterFront(sh);
  stop += `<g transform="translate(${sh.L + 226} ${sh.seat}) scale(${P})">${bag()}</g>`;
  stop += sign(1070);
  layers.push(stop);

  // 5. The pair arriving, and the one pacing by the sign.
  const put = (x, svg) => `<g transform="translate(${x} ${GROUND}) scale(${P})">${svg}</g>`;
  layers.push(put(372, chatter()) + put(478, laugher()) + put(1172, worrier()));

  const defs =
    `<defs>` +
    `<pattern id="s-dots" width="6" height="6" patternUnits="userSpaceOnUse"><circle cx="1.5" cy="1.5" r="1.1" fill="${V("dots")}"/></pattern>` +
    `<radialGradient id="s-glow"><stop offset="0" stop-color="#ffd98f" stop-opacity="0.55"/><stop offset="0.45" stop-color="#ffd98f" stop-opacity="0.18"/><stop offset="1" stop-color="#ffd98f" stop-opacity="0"/></radialGradient>` +
    `<linearGradient id="s-fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" style="stop-color:var(--bg);stop-opacity:0"/><stop offset="1" style="stop-color:var(--bg);stop-opacity:1"/></linearGradient>` +
    `</defs>`;
  return defs + layers.map((l) => `<g data-scene-layer>${l}</g>`).join("");
}

// ---------------------------------------------------------------- output

const art = scene();
const here = dirname(fileURLToPath(import.meta.url));
const dir = join(here, "..", "apps", "admin_web", "components", "landing");
writeFileSync(
  join(dir, "scene-art.ts"),
  `// Generated by tools/landing-scene.mjs. Do not edit by hand: change the drawing there and run it again.\n// The bus stop scene as SVG markup (defs and layers). Colours are the --s-* variables in scene-art.css.\nexport const SCENE_ART =\n  '${art.replace(/'/g, "\\'")}';\n`,
);

const block = (k, pad = "  ") =>
  Object.entries(PALETTE)
    .map(([name, pair]) => `${pad}--s-${name}: ${pair[k]};`)
    .join("\n");
writeFileSync(
  join(dir, "scene-art.css"),
  `/* Generated by tools/landing-scene.mjs. Do not edit by hand. */\n[data-scene-art] {\n${block(0)}\n}\n\n[data-theme="dark"] [data-scene-art] {\n${block(1)}\n}\n\n@media (prefers-color-scheme: dark) {\n  :root:not([data-theme="light"]) [data-scene-art] {\n${block(1, "    ")}\n  }\n}\n`,
);

const flag = process.argv.indexOf("--preview");
if (flag > 0) {
  const vars = (dark) => Object.entries(PALETTE).map(([k, [light, night]]) => `--s-${k}:${dark ? night : light}`).join(";") + `;--bg:${dark ? "#00232b" : "#f6fafb"}`;
  const whole = (dark) => `<svg viewBox="0 110 1600 530" width="1600" height="530" style="${vars(dark)};display:block;background:${dark ? "#00232b" : "#f6fafb"}">${art}</svg>`;
  const solo = (dark) => {
    clipCount = 1000;
    const people = [chatter(), laugher(), `<g transform="translate(0 -62)">${phoner()}</g>`, worrier()];
    return `<svg viewBox="-50 -230 640 250" width="1600" height="625" style="${vars(dark)};display:block;background:${dark ? "#00232b" : "#f6fafb"}">${people.map((p, i) => `<g transform="translate(${i * 150} 0)">${p}</g>`).join("")}</svg>`;
  };
  writeFileSync(process.argv[flag + 1], `<!doctype html><body style="margin:0">${solo(false)}${whole(false)}${whole(true)}${solo(true)}</body>`);
}
