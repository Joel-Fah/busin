// Draws the people of the landing page's bus stop scene and writes them as SVG markup into
// apps/admin_web/components/landing/scene-people.ts. Run: node tools/landing-people.mjs
//
// The figures follow the way flat editorial illustration builds people: small heads, long bodies, wide flowing
// trousers with a turned hem, big shoes and hands, hair as one solid shape that sits on the head, and limbs as single
// smooth shapes (never segments joined at a knob). A limb is described by a few points and a width at each; a smooth
// curve is run through them and thickened. Everything else (torso, head, hair, hands, shoes) is a hand-written path.
//
// Colours are CSS variables (set on the scene, with night values), so the same drawing works in both themes.
// Coordinates: x to the right, y down, the ground under the feet at y = 0, one unit about one pixel on a desktop.
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const n = (v) => Number(v.toFixed(1));
const V = (name) => `var(--p-${name})`;

/** Every colour the people use: [by day, by night]. Written out as CSS variables on the scene. */
const PALETTE = {
  ink: ["#22373f", "#3f5f6e"],
  ink2: ["#192a31", "#34515e"],
  line: ["rgb(6 18 23 / 0.34)", "rgb(4 14 18 / 0.5)"],
  mark: ["rgb(6 18 23 / 0.4)", "rgb(255 255 255 / 0.4)"],
  face: ["#1b2a30", "#16242a"],
  hair: ["#161f23", "#10181c"],
  "hair-b": ["#5a3a24", "#4d3220"],
  sole: ["#f6efdc", "#ddd5c0"],
  orange: ["#ef7611", "#e56f0f"],
  orange2: ["#d1630a", "#c25b09"],
  teal: ["#0c5d6d", "#17808f"],
  teal2: ["#094a58", "#116875"],
  cream: ["#f3e7cc", "#e6d9bb"],
  cream2: ["#dfd0ab", "#cfc09b"],
  coral: ["#e8694a", "#dc6144"],
  coral2: ["#c95338", "#b94b32"],
  blue: ["#35709a", "#3f7da9"],
  blue2: ["#285a7e", "#2f668d"],
  "skin-a": ["#c98f66", "#c08860"],
  "skin-a2": ["#b27a54", "#a8734f"],
  "skin-b": ["#8c5a3c", "#875739"],
  "skin-b2": ["#774a30", "#72472e"],
  "skin-c": ["#a56a45", "#9f6642"],
  "skin-c2": ["#8e5838", "#885435"],
  "skin-d": ["#e5b992", "#dab08a"],
  "skin-d2": ["#cf9f78", "#c59771"],
  shadow: ["#00202a", "#000a0e"],
  "shadow-o": ["0.1", "0.35"],
};

// ---------------------------------------------------------------- geometry

function catmull(p0, p1, p2, p3, t) {
  const t2 = t * t;
  const t3 = t2 * t;
  return [0, 1].map(
    (k) => 0.5 * (2 * p1[k] + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2 + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3),
  );
}

/** Points along a smooth curve through [pts], each with how far along it is (in segments). */
function sample(pts, steps = 9) {
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

/** A limb: the outline of a smooth curve through [pts], [widths] wide at each point. Ends are flat (a hem) or round. */
function band(pts, widths, { start = "flat", end = "flat" } = {}) {
  const fr = frames(pts, widths);
  const left = fr.map((f) => [f.p[0] + f.nrm[0] * f.w, f.p[1] + f.nrm[1] * f.w]);
  const right = fr.map((f) => [f.p[0] - f.nrm[0] * f.w, f.p[1] - f.nrm[1] * f.w]);
  const cap = (f, sign) => {
    const arc = [];
    for (let a = 1; a < 8; a++) {
      const ang = (Math.PI * a) / 8;
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

/** A thin line that runs along a limb, a little to one side: a fold in the cloth. */
function fold(pts, widths, side = 0.45, from = 0.12, to = 0.86) {
  const fr = frames(pts, widths);
  const part = fr.slice(Math.floor(fr.length * from), Math.ceil(fr.length * to));
  return `M${part.map((f) => `${n(f.p[0] + f.nrm[0] * f.w * side)} ${n(f.p[1] + f.nrm[1] * f.w * side)}`).join("L")}`;
}

/** A line across a limb near its end: the turned hem of trousers, the cuff of a sleeve. */
function cuff(pts, widths, back = 5) {
  const fr = frames(pts, widths);
  let travelled = 0;
  let k = fr.length - 1;
  while (k > 0 && travelled < back) {
    travelled += Math.hypot(fr[k].p[0] - fr[k - 1].p[0], fr[k].p[1] - fr[k - 1].p[1]);
    k--;
  }
  const f = fr[k];
  return `M${n(f.p[0] + f.nrm[0] * f.w)} ${n(f.p[1] + f.nrm[1] * f.w)}L${n(f.p[0] - f.nrm[0] * f.w)} ${n(f.p[1] - f.nrm[1] * f.w)}`;
}

// ---------------------------------------------------------------- pieces

const fill = (d, colour, extra = "") => `<path d="${d}" fill="${colour}"${extra}/>`;
const line = (d, width = 1, colour = V("line"), extra = "") =>
  `<path d="${d}" fill="none" stroke="${colour}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round"${extra}/>`;
const at = (x, y, rot, inner, flip = 1) => `<g transform="translate(${n(x)} ${n(y)}) rotate(${rot}) scale(${flip} 1)">${inner}</g>`;

/** A trouser leg with its fold and turned hem. */
function leg(pts, widths, colour) {
  return fill(band(pts, widths), colour) + line(fold(pts, widths, 0.42), 0.9) + line(cuff(pts, widths, 5.5), 1.1);
}

/** A sleeve (flat cuff) or a bare arm (round end). */
function arm(pts, widths, colour, { bare = false, cuffLine = true } = {}) {
  return fill(band(pts, widths, { start: "round", end: bare ? "round" : "flat" }), colour) + (bare || !cuffLine ? "" : line(cuff(pts, widths, 3.4), 0.9));
}

/** A sneaker. The ankle is at the origin, the toe points to +x, the sole is 9.8 below. */
function shoe(x, y, rot, colour, flip = 1) {
  return at(
    x,
    y,
    rot,
    fill("M-8.6 -7.4L7.4 -7.4C10 -3.2 16.6 0.4 21.8 3.4C24.6 5.2 24.2 8.8 21 8.8L-8 8.8C-10.4 8.8-10.4-3.2-8.6-7.4Z", colour) +
      fill("M15 0.6C18 2.4 21.4 4 23.4 5.6L23.8 6.4L13.6 6.4Z", V("sole"), ' opacity="0.75"') +
      fill("M-9.8 6.2L24 6.2C24.6 8.4 23.4 9.8 21.4 9.8L-8.4 9.8C-9.8 9.8-10.2 8-9.8 6.2Z", V("sole")) +
      line("M5.4 -4.4L9.8 -6M8 -2.4L12.2 -4.2M10.8 -0.4L14.6 -2.4", 1, V("sole")),
    flip,
  );
}

/** A hand: palm and fingers as one soft shape with a thumb. The wrist is at the origin and the fingers point to +y. */
function hand(x, y, rot, colour, flip = 1) {
  return at(
    x,
    y,
    rot,
    fill("M-4.3 -1.4C-5.4 3.4-5 8.6-2.6 11.2C-0.6 13 3 12.6 4.3 9.4C5.4 6 4.9 2 4.3 -1.4Z", colour) +
      fill("M3.4 0.8C6.6 1.8 8 5 6.4 7.4C5.2 8 4.2 6.6 3.6 5Z", colour) +
      line("M-1.6 8.2L-1.2 11.4M1 8.4L1.3 11.6", 0.7),
    flip,
  );
}

/** Hair shapes, drawn over a head that looks to +x and is centred on the origin. Each overlaps the skull, so it sits on it. */
const HAIR = {
  ponytail: (c) =>
    fill("M-8.6 -8.4C-17.6 -11.6-21.4 0.6-16.6 13.4C-14.6 7-13 1.6-8.4 -1.6Z", c) +
    fill("M-10.3 2C-12.8 -8-7 -15.2 1.6 -14.6C8.2 -14.2 11.6 -9.4 10.7 -4.6C7.6 -8.4 2 -9.2-3 -7.4C-5.6 -4-5.2 0.6-6.4 4.8C-8.6 5.4-9.9 3.8-10.3 2Z", c),
  curls: (c) =>
    [
      [-6.4, -8.6, 6.6],
      [0.2, -11.6, 7],
      [6.6, -9.4, 5.6],
      [-9.6, -2.4, 5],
      [-8.4, 3.4, 3.6],
    ]
      .map(([cx, cy, r]) => `<circle cx="${cx}" cy="${cy}" r="${r}" fill="${c}"/>`)
      .join(""),
  short: (c) =>
    fill("M-10 2.4C-12.2 -7-7.6 -14.4 1 -14.4C7.2 -14.4 12.4 -11.6 11.6 -6.2C9 -9 5 -8.8 1.4 -7.4C-2.6 -6-5.6 -3.2-6.2 1.6C-6.6 3.8-8.8 4.2-10 2.4Z", c),
  beanie: (c, c2, hair) =>
    fill("M-9.8 -0.6C-10.6 3-9.6 5.6-7.8 6.6L-6.6 0.4Z", hair) +
    fill("M-10.6 -3C-11.6 -12.4-4 -17 2 -16.2C8.6 -15.4 11.8 -9.8 11 -5Z", c) +
    fill("M-11.3 -4L11.2 -6.6L11.7 -2.6L-10.9 0.4Z", c2) +
    line("M-5 -3.4L-4.8 -0.4M1 -4.2L1.2 -1.2M7 -5L7.2 -2", 0.7),
};

/**
 * A head: skull, ear, nose, one eye with its brow and a mouth, then the hair. Centred on (x, y), looking to +x
 * (flip -1 looks back), tilted by [tilt] degrees.
 */
function head(x, y, { skin, far, hair, mood = "smile", tilt = 0, flip = 1 }) {
  const mouth = {
    smile: line("M4.4 5.8Q6.6 7.5 8.8 5.5", 0.95, V("face")),
    laugh: fill("M3.8 4.8C4.8 8.6 8.2 8.4 9 4.4Z", "#fff", ` stroke="${V("face")}" stroke-width="0.7" stroke-linejoin="round"`),
    flat: line("M5 6.4L8.6 6", 1, V("face")),
  }[mood === "down" ? "smile" : mood];
  const eye =
    mood === "down"
      ? line("M3.6 -1.4Q5.1 -0.1 6.6 -1.3", 0.95, V("face"))
      : mood === "laugh"
        ? line("M3.6 -1.6Q5.1 -3.1 6.6 -1.8", 0.95, V("face"))
        : `<circle cx="5.2" cy="-1.8" r="1.05" fill="${V("face")}"/>`;
  const brow = mood === "flat" ? line("M2.8 -5.8L8.2 -4", 0.95, V("face")) : line("M2.8 -4.6Q5.4 -6 8 -4.8", 0.85, V("face"));
  return at(
    x,
    y,
    tilt,
    fill("M-9.3 -1C-9.6 -9-4 -12.2 1 -12C7 -11.8 10 -7 9.8 -1.5C9.6 3 9.5 5 8 8C6.5 10.8 3 11.6 0 11.4C-5 11-9 6-9.3 -1Z", skin) +
      fill("M9.2 -2.6C11.4 0 12.3 2.2 11.6 3C10.8 3.7 9.6 3.4 9 3Z", skin) +
      `<ellipse cx="-5.4" cy="1.2" rx="2.2" ry="3" fill="${far}"/>` +
      eye +
      brow +
      mouth +
      hair,
    flip,
  );
}

const shadow = (cx, rx) => `<ellipse cx="${cx}" cy="1.5" rx="${rx}" ry="5" fill="${V("shadow")}" opacity="${V("shadow-o")}"/>`;

/** The body from shoulders to waist, standing: a soft bell that is a little wider at the chest. */
const TORSO = "M-13.6 -148C-9 -153.4 8 -154.4 13.6 -148C16.6 -134 16.2 -114 14.2 -97L-13.2 -97C-15.6 -114-16.6 -134-13.6 -148Z";
const PELVIS = "M-13.6 -101L14.6 -101L16 -82L-15 -82Z";
const NECK = "M-2.4 -160L4.6 -160L5.2 -150L-2.8 -150Z";

/** A backpack worn on the back of someone who looks to +x, with its strap over the shoulder. */
const pack = (c, c2) =>
  fill("M-12 -147C-23 -148-29 -140-29 -128L-28 -109C-28 -102-22 -99-12 -100Z", c) +
  fill("M-27.6 -122L-13 -122L-13 -106C-19 -104-27 -105-27.6 -111Z", c2);
const strap = (c2) => line("M-4.6 -151C-9.8 -140-11.2 -126-11 -110", 3, c2);

// ---------------------------------------------------------------- the people

/** Two students arriving, mid-stride. She explains something with her hand; he walks a step ahead and laughs back at her. */
function walkingPair() {
  const her = { skin: V("skin-a"), far: V("skin-a2") };
  const him = { skin: V("skin-b"), far: V("skin-b2") };

  const herBack = [[-4, -90], [-13, -52], [-26, -20]];
  const herFront = [[5, -90], [15, -52], [20, -14]];
  const herFar = [[9, -144], [24, -127], [35, -144]];
  const herNear = [[-7, -144], [-13, -122], [-3, -106]];
  const woman =
    shadow(-2, 36) +
    shoe(-28, -17, 22, V("teal")) +
    leg(herBack, [20, 18.5, 17.5], V("ink2")) +
    arm(herFar, [9.6, 8.6, 8], V("orange2")) +
    hand(36, -146.5, 196, her.far) +
    line("M33 -165l-2.4 -5.6M38.6 -165.6l1.8 -6", 1.2, V("mark")) +
    pack(V("teal"), V("teal2")) +
    shoe(18, -9.8, 0, V("teal")) +
    fill(PELVIS, V("ink")) +
    leg(herFront, [21, 20, 19], V("ink")) +
    fill(TORSO, V("orange")) +
    line("M-6 -132l3 -1.6M4 -126l3 1.4M-3 -116l3 -1.4M7 -138l2.6 1.2M-8 -108l2.8 1M6 -108l2.6 -1.4", 0.9, V("cream"), ' opacity="0.8"') +
    strap(V("teal2")) +
    arm(herNear, [10, 9, 8.2], V("orange")) +
    hand(-2, -104.5, -52, her.skin) +
    fill(NECK, her.far) +
    head(3, -169, { ...her, hair: HAIR.ponytail(V("hair")), mood: "smile" });

  const hisFar = [[5, -90], [16, -53], [21, -14]];
  const hisNear = [[-4, -90], [-12, -52], [-24, -20]];
  const hisFarArm = [[10, -144], [21, -123], [29, -106]];
  const hisNearArm = [[-6, -144], [-11, -123], [4, -128]];
  const man =
    shadow(0, 36) +
    shoe(19, -9.8, 0, V("coral")) +
    leg(hisFar, [20, 18.5, 17.5], V("ink2")) +
    arm(hisFarArm, [9.6, 8.6, 8], V("cream2")) +
    hand(30, -104.5, -22, him.far) +
    pack(V("coral"), V("coral2")) +
    shoe(-26, -17, 22, V("coral")) +
    fill(PELVIS, V("ink")) +
    leg(hisNear, [21, 20, 19], V("ink")) +
    fill("M-13.4 -146.6C-19.4 -152.6-14 -158.6-5.6 -156.4L1.4 -150.6Z", V("cream2")) +
    fill(TORSO, V("cream")) +
    line("M-7 -113Q0.4 -108.6 8 -113", 1.1, V("cream2")) +
    strap(V("coral2")) +
    arm(hisNearArm, [10, 9, 8.2], V("cream")) +
    hand(5.6, -128.6, -84, him.skin) +
    fill(NECK, him.far) +
    head(1, -169, { ...him, hair: HAIR.curls(V("hair")), mood: "laugh", flip: -1 });

  return `<g>${woman}</g><g transform="translate(76 0)">${man}</g>`;
}

/**
 * Sitting on the bench, bent over his phone, legs stretched out and crossed at the ankle. The origin is on the seat,
 * under his hip; the ground is 44 below.
 */
function seated() {
  const s = { skin: V("skin-c"), far: V("skin-c2") };
  const farLeg = [[0, -9], [29, -10], [40, 30]];
  const nearLeg = [[2, -9], [36, -12], [57, 29]];
  const farSleeve = [[11, -50], [17, -39]];
  const farArm = [[17, -40], [22, -27], [35, -35]];
  const nearSleeve = [[2, -50], [4, -37]];
  const nearArm = [[4, -38], [9, -21], [29, -29]];
  return (
    `<ellipse cx="38" cy="45" rx="48" ry="5" fill="${V("shadow")}" opacity="${V("shadow-o")}"/>` +
    shoe(38, 34.2, 0, V("orange")) +
    leg(farLeg, [20, 18, 16.5], V("ink2")) +
    fill(band(farSleeve, [10.4, 9.8], { start: "round" }), V("coral2")) +
    fill(band(farArm, [7.6, 7, 6.6], { start: "round", end: "round" }), s.far) +
    shoe(56, 33.4, -10, V("orange")) +
    leg(nearLeg, [20.5, 18.5, 17], V("ink")) +
    fill("M-11.6 -1C-13.6 -22-10.6 -42-3.4 -54C2 -58.4 12.4 -57.4 16.4 -52C18.4 -36 16.2 -16 13.4 -1Z", V("coral")) +
    line("M-9 -20Q1 -15 13 -21", 1, V("coral2")) +
    `<g transform="rotate(-17 37 -45)"><rect x="32" y="-55" width="10.4" height="19" rx="2.4" fill="${V("face")}"/><rect x="33.6" y="-53.2" width="7.2" height="14.6" rx="1.4" fill="#bfe6f2"/></g>` +
    `<circle cx="38" cy="-46" r="20" fill="#bfe6f2" opacity="0.13"/>` +
    fill(band(nearSleeve, [11.4, 10.6], { start: "round" }), V("coral")) +
    line(cuff(nearSleeve, [11.4, 10.6], 1.6), 0.9) +
    fill(band(nearArm, [8.2, 7.6, 7], { start: "round", end: "round" }), s.skin) +
    hand(30.4, -30, -104, s.skin) +
    fill("M5.4 -60L12.4 -60L13 -50L4.6 -50Z", s.far) +
    head(13, -71, { ...s, hair: HAIR.beanie(V("orange"), V("orange2"), V("hair")), mood: "down", tilt: 20 })
  );
}

/** The bag he left on the bench. The origin is on the seat, under its middle. */
function bag() {
  return (
    `<ellipse cx="0" cy="1" rx="19" ry="3.4" fill="${V("shadow")}" opacity="${V("shadow-o")}"/>` +
    line("M-7 -29Q0 -41 7 -29", 3.6, V("teal2")) +
    fill("M-14 -4C-15 -18-12 -31 0 -32C12 -31 15 -18 14 -4C14 -1 11 0 8 0L-8 0C-11 0-14 -1-14 -4Z", V("teal")) +
    fill("M-9.6 -3C-10.4 -11-8 -16 0 -16C8 -16 10.4 -11 9.6 -3C9.4 -1.6 8 -1 6.6 -1L-6.6 -1C-8 -1-9.4 -1.6-9.6 -3Z", V("teal2")) +
    line("M-5 -24L5 -24", 2, V("cream")) +
    line("M-13 -6Q-21 0-17 8", 3.2, V("teal2"))
  );
}

/** Standing apart, a hand on his hip, the other wrist raised to check his watch, one foot tapping. He looks to +x. */
function impatient() {
  const s = { skin: V("skin-d"), far: V("skin-d2") };
  const standLeg = [[4, -90], [6, -52], [5, -14]];
  const tapLeg = [[-3, -90], [5, -53], [17, -19]];
  const hipArm = [[-7, -144], [-23, -124], [-10, -106]];
  const watchUpper = [[10, -144], [24, -125]];
  const watchFore = [[24, -126], [20, -134], [9, -140]];
  return (
    shadow(6, 34) +
    shoe(3, -9.8, 0, V("orange")) +
    leg(standLeg, [19, 17.5, 16.5], V("ink2")) +
    fill(band(watchUpper, [9.8, 9], { start: "round", end: "round" }), V("blue2")) +
    shoe(19, -14.6, -24, V("orange")) +
    line("M42 -12q4.6 -3.4 8.6 1.6M43 -21q6.4 -3.6 10.6 2.4M42 -3q4.8 -0.6 7.6 4.4", 1.2, V("mark")) +
    fill(PELVIS, V("ink")) +
    leg(tapLeg, [20, 18.5, 17.5], V("ink")) +
    fill(TORSO, V("blue")) +
    line("M-4.6 -151.4L1.6 -143L7.4 -151.6", 1.2, V("blue2")) +
    line("M1.6 -143L2 -100", 0.9, V("blue2")) +
    arm(hipArm, [10, 9.2, 8.4], V("blue")) +
    hand(-9.4, -104.6, -58, s.skin) +
    fill(band(watchFore, [9, 8.4, 7.8], { start: "round" }), V("blue2")) +
    hand(7.6, -140.6, 104, s.far) +
    `<rect x="9.4" y="-144.6" width="3.4" height="8.6" rx="1.4" transform="rotate(14 11 -140)" fill="${V("face")}"/>` +
    `<circle cx="11.4" cy="-140.4" r="2.5" fill="${V("orange")}"/>` +
    fill(NECK, s.far) +
    head(4, -168, { ...s, hair: HAIR.short(V("hair-b")), mood: "flat", tilt: 12 })
  );
}

// ---------------------------------------------------------------- output

const people = { walkingPair: walkingPair(), seated: seated(), bag: bag(), impatient: impatient() };

const here = dirname(fileURLToPath(import.meta.url));
const target = join(here, "..", "apps", "admin_web", "components", "landing", "scene-people.ts");
const body = Object.entries(people)
  .map(([name, markup]) => `  ${name}:\n    '${markup.replace(/'/g, "\\'")}',`)
  .join("\n");
writeFileSync(
  target,
  `// Generated by tools/landing-people.mjs. Do not edit by hand: change the drawing there and run it again.\n// SVG markup for the people of the bus stop scene. Colours are the --p-* variables set on the scene.\nexport const SCENE_PEOPLE = {\n${body}\n} as const;\n`,
);

// The colours, as variables on the scene: by day, by night when the theme is forced, and by night when it follows the device.
const block = (k) =>
  Object.entries(PALETTE)
    .map(([name, pair]) => `  --p-${name}: ${pair[k]};`)
    .join("\n");
writeFileSync(
  join(here, "..", "apps", "admin_web", "components", "landing", "scene-people.css"),
  `/* Generated by tools/landing-people.mjs. Do not edit by hand. */\n[data-scene-people] {\n${block(0)}\n}\n\n[data-theme="dark"] [data-scene-people] {\n${block(1)}\n}\n\n@media (prefers-color-scheme: dark) {\n  :root:not([data-theme="light"]) [data-scene-people] {\n${block(1).replace(/^/gm, "  ")}\n  }\n}\n`,
);

// A page to look at the drawing on its own: node tools/landing-people.mjs --preview out.html
const flag = process.argv.indexOf("--preview");
if (flag > 0) {
  const vars = (dark) =>
    Object.entries(PALETTE)
      .map(([k, [light, night]]) => `--p-${k}:${dark ? night : light}`)
      .join(";");
  const scene = (dark) =>
    `<svg viewBox="-60 -200 520 260" width="1560" height="780" style="${vars(dark)};background:${dark ? "#0b2c38" : "#eaf3f5"}">` +
    `<g>${people.walkingPair}</g><g transform="translate(210 -44)"><rect x="-30" y="0" width="150" height="10" rx="5" fill="#e3a94f"/>${people.seated}<g transform="translate(86 0)">${people.bag}</g></g>` +
    `<g transform="translate(410 0) scale(-1 1)">${people.impatient}</g></svg>`;
  writeFileSync(process.argv[flag + 1], `<!doctype html><body style="margin:0">${scene(false)}${scene(true)}</body>`);
}
