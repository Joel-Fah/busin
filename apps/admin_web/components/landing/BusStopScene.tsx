import { BadgeCheckIcon, Clock01Icon, Navigation03Icon, WifiOff01Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

import { SceneMotion } from "./SceneMotion";

/** The scene's colours, day first and night after `dark:`. Each name says what it paints. */
const c = {
  hillFar: "fill-[#d3e9ef] dark:fill-[#062029]",
  hillNear: "fill-[#c2dfe6] dark:fill-[#072b38]",
  bldFar: "fill-[#bad5de] dark:fill-[#0a2d3b]",
  bldNear: "fill-[#a9c9d4] dark:fill-[#0d3646]",
  bldRoof: "fill-[#8fb5c3] dark:fill-[#10475a]",
  bldDoor: "fill-[#86aebd] dark:fill-[#0a2b38]",
  winOn: "fill-[#f6fbfc] dark:fill-[#ffd98f]",
  winOff: "fill-[#d9ecf1] dark:fill-[#12394a]",
  leaf: "fill-[#86bcae] dark:fill-[#10494d]",
  leafLight: "fill-[#a6d3c3] dark:fill-[#17595b]",
  pine: "fill-[#6ca99b] dark:fill-[#0b3e45]",
  trunk: "fill-[#9c8b78] dark:fill-[#1b3034]",
  hedge: "fill-[#79b3a3] dark:fill-[#0d4448]",
  pavement: "fill-[#eaf3f5] dark:fill-[#0b2c38]",
  curb: "fill-[#d3e3e8] dark:fill-[#103847]",
  joint: "stroke-[#d4e3e8] dark:stroke-[#12404f]",
  road: "fill-[#c9dbe2] dark:fill-[#08222e]",
  lane: "stroke-[#fbfdfd] dark:stroke-[#2c5a70]",
  grass: "fill-[#a9d6bf] dark:fill-[#0b3d40]",
  roof: "fill-[#2f7387]",
  roofEdge: "fill-[#3d8aa0]",
  post: "fill-[#52737f] dark:fill-[#7ea2b0]",
  glass: "fill-[#e6f5f8] opacity-60 dark:fill-[#9fd6e6] dark:opacity-20",
  bench: "fill-[#e3a94f]",
  benchDark: "fill-[#c98d34]",
  signBlue: "fill-[#35709a]",
  paper: "fill-[#f6ead0]",
  bin: "fill-[#5d8190] dark:fill-[#6f95a4]",
  skin1: "fill-[#c98f66]",
  skin2: "fill-[#8c5a3c]",
  skin3: "fill-[#e5b992]",
  teal: "fill-[#0c5d6d] dark:fill-[#17808f]",
  orange: "fill-[#ef7611]",
  cream: "fill-[#f3e7cc]",
  shadow: "fill-[#00202a] opacity-10 dark:opacity-30",
  lampPole: "fill-[#52737f] dark:fill-[#86a9b7]",
};

function rng(seed: number) {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 0xffffffff;
  };
}
const next = rng(77);

/** A building: body, roof edge, rows of windows (some lit), and a door. */
function Building({ x, w, h, tone, cols, rows, door = true }: { x: number; w: number; h: number; tone: "bldFar" | "bldNear"; cols: number; rows: number; door?: boolean }) {
  const top = 470 - h;
  const gx = (w - 20) / cols;
  const gy = (h - 46) / rows;
  return (
    <g>
      <rect x={x} y={top} width={w} height={h} rx="5" className={c[tone]} />
      <rect x={x - 3} y={top - 7} width={w + 6} height="10" rx="4" className={c.bldRoof} />
      {Array.from({ length: rows }).flatMap((_, r) =>
        Array.from({ length: cols }).map((__, k) => (
          <rect key={`${r}-${k}`} x={x + 10 + k * gx + 3} y={top + 18 + r * gy} width={gx - 8} height={gy - 10} rx="2.5" className={next() > 0.45 ? c.winOn : c.winOff} />
        )),
      )}
      {door ? <rect x={x + w / 2 - 9} y={448} width="18" height="22" rx="3" className={c.bldDoor} /> : null}
    </g>
  );
}

function RoundTree({ cx, base, r }: { cx: number; base: number; r: number }) {
  return (
    <g>
      <rect x={cx - 5} y={base - r * 0.9} width="10" height={r * 0.9 + 4} rx="3" className={c.trunk} />
      <circle cx={cx} cy={base - r * 1.5} r={r} className={c.leaf} />
      <circle cx={cx - r * 0.75} cy={base - r * 1.05} r={r * 0.72} className={c.leaf} />
      <circle cx={cx + r * 0.75} cy={base - r * 1.05} r={r * 0.72} className={c.leaf} />
      <circle cx={cx - r * 0.25} cy={base - r * 1.8} r={r * 0.5} className={c.leafLight} />
    </g>
  );
}

function Pine({ cx, base, h }: { cx: number; base: number; h: number }) {
  const w = h * 0.34;
  return (
    <g>
      <rect x={cx - 4} y={base - 14} width="8" height="18" rx="2" className={c.trunk} />
      {[0, 1, 2].map((i) => (
        <path key={i} d={`M${cx} ${base - h + i * h * 0.24} L${cx + w - i * 5} ${base - h * 0.34 - (2 - i) * h * 0.06 + i * 4} L${cx - w + i * 5} ${base - h * 0.34 - (2 - i) * h * 0.06 + i * 4} Z`} className={c.pine} />
      ))}
    </g>
  );
}

function Lamp({ x }: { x: number }) {
  return (
    <g>
      <circle cx={x + 26} cy={338} r="90" fill="url(#lampglow)" className="opacity-0 dark:opacity-100" />
      <rect x={x} y={344} width="6" height="128" rx="3" className={c.lampPole} />
      <path d={`M${x + 3} 346 Q ${x + 3} 330 ${x + 28} 332`} fill="none" strokeWidth="5" strokeLinecap="round" className="stroke-[#52737f] dark:stroke-[#86a9b7]" />
      <rect x={x + 22} y={330} width="22" height="9" rx="4.5" className="fill-[#fff3cf] dark:fill-[#ffe9ae]" />
    </g>
  );
}

type Pt = [number, number];

/** The outline of a limb that is wider at one end than the other, from a few joint points and a width at each. */
function outline(points: Pt[], widths: number[]): string {
  const left: Pt[] = [];
  const right: Pt[] = [];
  points.forEach(([x, y], i) => {
    const [px, py] = points[Math.max(0, i - 1)];
    const [nx, ny] = points[Math.min(points.length - 1, i + 1)];
    const len = Math.hypot(nx - px, ny - py) || 1;
    const ox = (-(ny - py) / len) * (widths[i] / 2);
    const oy = ((nx - px) / len) * (widths[i] / 2);
    left.push([x + ox, y + oy]);
    right.push([x - ox, y - oy]);
  });
  const all = [...left, ...right.reverse()];
  return `M${all.map(([x, y]) => `${x.toFixed(1)} ${y.toFixed(1)}`).join(" L")} Z`;
}

/** One tone, as a fill and the same stroke (the stroke rounds the corners where a limb bends). */
type Tone = { f: string; s: string };
const tone = {
  pants: { f: "fill-[#243b46] dark:fill-[#3b5a68]", s: "stroke-[#243b46] dark:stroke-[#3b5a68]" },
  pantsFar: { f: "fill-[#1a2c35] dark:fill-[#2f4957]", s: "stroke-[#1a2c35] dark:stroke-[#2f4957]" },
  tealPants: { f: "fill-[#0c5d6d] dark:fill-[#17808f]", s: "stroke-[#0c5d6d] dark:stroke-[#17808f]" },
  tealPantsFar: { f: "fill-[#094a58] dark:fill-[#126a77]", s: "stroke-[#094a58] dark:stroke-[#126a77]" },
  orange: { f: "fill-[#ef7611]", s: "stroke-[#ef7611]" },
  orangeFar: { f: "fill-[#d4640a]", s: "stroke-[#d4640a]" },
  cream: { f: "fill-[#f3e7cc]", s: "stroke-[#f3e7cc]" },
  creamFar: { f: "fill-[#e0d1ad]", s: "stroke-[#e0d1ad]" },
  coral: { f: "fill-[#e8694a]", s: "stroke-[#e8694a]" },
  coralFar: { f: "fill-[#cc5236]", s: "stroke-[#cc5236]" },
  blue: { f: "fill-[#35709a]", s: "stroke-[#35709a]" },
  blueFar: { f: "fill-[#285a7e]", s: "stroke-[#285a7e]" },
  teal: { f: "fill-[#0c5d6d] dark:fill-[#17808f]", s: "stroke-[#0c5d6d] dark:stroke-[#17808f]" },
  skin1: { f: "fill-[#c98f66]", s: "stroke-[#c98f66]" },
  skin1Far: { f: "fill-[#b27a54]", s: "stroke-[#b27a54]" },
  skin2: { f: "fill-[#8c5a3c]", s: "stroke-[#8c5a3c]" },
  skin2Far: { f: "fill-[#774a30]", s: "stroke-[#774a30]" },
  skin3: { f: "fill-[#e5b992]", s: "stroke-[#e5b992]" },
  skin3Far: { f: "fill-[#cf9f78]", s: "stroke-[#cf9f78]" },
  hairBlack: { f: "fill-[#161f23]", s: "stroke-[#161f23]" },
  hairBrown: { f: "fill-[#5a3a24]", s: "stroke-[#5a3a24]" },
  shoe: { f: "fill-[#f6efdc] dark:fill-[#d9d2bd]", s: "stroke-[#f6efdc] dark:stroke-[#d9d2bd]" },
  ink: { f: "fill-[#1b2a30]", s: "stroke-[#1b2a30]" },
};

/** A limb: its outline plus a round at every joint and end, so it bends and ends softly. */
function Limb({ points, widths, t }: { points: Pt[]; widths: number[]; t: Tone }) {
  return (
    <g className={t.f}>
      <path d={outline(points, widths)} strokeWidth="1.5" strokeLinejoin="round" className={t.s} />
      {points.map(([x, y], i) => (
        <circle key={i} cx={x} cy={y} r={widths[i] / 2} />
      ))}
    </g>
  );
}

/** A sneaker at the ankle: a rounded body, a pale sole and an accent stripe. */
function Shoe({ x, y, flip = 1, tilt = 0, accent = "fill-[#ef7611]" }: { x: number; y: number; flip?: 1 | -1; tilt?: number; accent?: string }) {
  return (
    <g transform={`translate(${x} ${y}) rotate(${tilt}) scale(${flip} 1)`}>
      <path d="M-5 -7 L6 -7 Q 16 -6 19 0 Q 20 4 15 4 L-6 4 Q -9 4 -8 0 Z" className={tone.pants.f} />
      <path d="M-8 1 L19 1 L19 4.5 L-8 4.5 Z" className={tone.shoe.f} />
      <path d="M2 -5 L9 -5 L8 -1 L1 -1 Z" className={accent} />
    </g>
  );
}

function Hand({ x, y, t, r = 3.7 }: { x: number; y: number; t: Tone; r?: number }) {
  return <circle cx={x} cy={y} r={r} className={t.f} />;
}

/** A head with a neck and a small face: two eyes, a hint of nose, a mouth. Eyes follow where the person looks. */
function Head({ skin, look = 1, mood = "calm", children }: { skin: { near: Tone; far: Tone }; look?: -1 | 0 | 1; mood?: "calm" | "laugh" | "bored" | "down"; children?: React.ReactNode }) {
  const e = look * 3;
  return (
    <g>
      <rect x="-3.2" y="-140" width="6.4" height="12" rx="3" className={skin.far.f} />
      <ellipse cx="1" cy="-148" rx="9.4" ry="10.4" className={skin.near.f} />
      {children}
      {mood === "down" ? (
        <path d={`M${-1 + e} -148 q 2.5 2 5 0 M${6 + e} -148 q 2.5 2 5 0`} fill="none" stroke="#1b2a30" strokeWidth="1.3" strokeLinecap="round" />
      ) : (
        <>
          <circle cx={-0.5 + e} cy={-149} r="1.25" className={tone.ink.f} />
          <circle cx={6.5 + e} cy={-149} r="1.25" className={tone.ink.f} />
        </>
      )}
      {mood === "bored" ? (
        <>
          <path d={`M${-2 + e} -153 L${2.5 + e} -151.5 M${4.5 + e} -151.5 L${9 + e} -153`} stroke="#1b2a30" strokeWidth="1.2" strokeLinecap="round" />
          <path d={`M${2 + e} -142 L${6.5 + e} -142`} stroke="#1b2a30" strokeWidth="1.4" strokeLinecap="round" />
        </>
      ) : mood === "laugh" ? (
        <path d={`M${0 + e} -143 Q ${3.5 + e} -137 ${7 + e} -143 Z`} fill="#fff" stroke="#1b2a30" strokeWidth="1.1" strokeLinejoin="round" />
      ) : (
        <path d={`M${1 + e} -142.5 q 3 2.2 6 0`} fill="none" stroke="#1b2a30" strokeWidth="1.3" strokeLinecap="round" />
      )}
    </g>
  );
}

const skin = {
  one: { near: tone.skin1, far: tone.skin1Far },
  two: { near: tone.skin2, far: tone.skin2Far },
  three: { near: tone.skin3, far: tone.skin3Far },
};

/** Two students arriving, mid-stride and mid-sentence, a step apart so they can talk. */
function WalkingPair({ x }: { x: number }) {
  return (
    <g transform={`translate(${x} 490)`}>
      {/* She talks with her hands. */}
      <g>
        <ellipse cx="-2" cy="2" rx="34" ry="5.5" className={c.shadow} />
        <rect x="-27" y="-124" width="17" height="44" rx="8" className={tone.teal.f} />
        <Limb points={[[-3, -82], [-15, -46], [-25, -10]]} widths={[13, 11, 9]} t={tone.tealPantsFar} />
        <Shoe x={-28} y={-6} tilt={-12} />
        <Limb points={[[-8, -126], [-17, -106], [-19, -88]]} widths={[8.5, 7.5, 6.5]} t={tone.orangeFar} />
        <Hand x={-19} y={-85} t={tone.skin1Far} />
        <path d="M-13 -130 Q 2 -137 15 -130 L12 -82 Q 0 -77 -11 -82 Z" className={tone.orange.f} />
        <path d="M-11 -86 L12 -86 L14 -76 L-13 -76 Z" className={tone.tealPants.f} />
        <Limb points={[[4, -82], [13, -46], [17, -10]]} widths={[13, 11.5, 9.5]} t={tone.tealPants} />
        <Shoe x={15} y={-6} />
        <Head skin={skin.one} look={1} mood="calm">
          <path d="M-8.5 -150 C -9.5 -163 12.5 -166 12 -151 C 8 -157 -2 -155 -8.5 -150 Z" className={tone.hairBlack.f} />
          <path d="M-5 -158 C -22 -161 -25 -142 -17 -131 C -14 -141 -11 -149 -3 -153 Z" className={tone.hairBlack.f} />
        </Head>
        <Limb points={[[9, -126], [24, -113], [33, -136]]} widths={[8.5, 7.5, 6.5]} t={tone.orange} />
        <Hand x={33.5} y={-139} t={tone.skin1} />
        <path d="M30 -145 l-3 -6 M36 -146 l2 -7" stroke="#1b2a30" strokeWidth="1.6" strokeLinecap="round" opacity="0.4" />
      </g>

      {/* He laughs and looks back at her. */}
      <g transform="translate(80 0)">
        <ellipse cx="0" cy="2" rx="34" ry="5.5" className={c.shadow} />
        <rect x="-27" y="-122" width="17" height="40" rx="8" className={tone.coral.f} />
        <Limb points={[[-3, -82], [-9, -46], [-13, -10]]} widths={[13, 11, 9]} t={tone.pantsFar} />
        <Shoe x={-16} y={-6} accent="fill-[#e8694a]" />
        <Limb points={[[-8, -126], [-14, -108], [-9, -92]]} widths={[8.5, 7.5, 6.5]} t={tone.creamFar} />
        <Hand x={-9} y={-89} t={tone.skin2Far} />
        <path d="M-13 -130 Q 2 -137 15 -130 L13 -82 Q 0 -77 -12 -82 Z" className={tone.cream.f} />
        <path d="M-6 -104 q 7 5 14 0" fill="none" stroke="#e0d1ad" strokeWidth="2.2" strokeLinecap="round" />
        <path d="M-12 -86 L13 -86 L15 -76 L-14 -76 Z" className={tone.pants.f} />
        <Limb points={[[4, -82], [18, -46], [27, -11]]} widths={[13, 11.5, 9.5]} t={tone.pants} />
        <Shoe x={30} y={-7} tilt={-8} accent="fill-[#e8694a]" />
        <Head skin={skin.two} look={-1} mood="laugh">
          <circle cx="-3" cy="-160" r="8.5" className={tone.hairBlack.f} />
          <circle cx="-10" cy="-154" r="6.5" className={tone.hairBlack.f} />
          <circle cx="5" cy="-158" r="7" className={tone.hairBlack.f} />
        </Head>
        <Limb points={[[9, -126], [19, -106], [28, -92]]} widths={[8.5, 7.5, 6.5]} t={tone.cream} />
        <Hand x={29} y={-89} t={tone.skin2} />
      </g>
    </g>
  );
}

/** Waiting on the bench: legs stretched out and crossed at the ankle, head down over his phone, its light on his face. */
function SeatedWithPhone() {
  return (
    <g transform="translate(104 0)">
      <ellipse cx="34" cy="492" rx="46" ry="5.5" className={c.shadow} />
      <Limb points={[[-2, 440], [32, 438], [50, 486]]} widths={[14, 11.5, 9]} t={tone.pantsFar} />
      <Shoe x={53} y={489} tilt={8} accent="fill-[#e8694a]" />
      <path d="M-14 400 Q -2 392 12 398 L14 442 Q 0 446 -14 442 Z" className={tone.coral.f} />
      <path d="M-14 420 q 14 6 28 0" fill="none" stroke="#cc5236" strokeWidth="2" strokeLinecap="round" />
      <Limb points={[[4, 442], [40, 432], [62, 480]]} widths={[14, 12, 9.5]} t={tone.pants} />
      <Shoe x={66} y={486} tilt={6} accent="fill-[#e8694a]" />
      <Limb points={[[-6, 402], [2, 424], [24, 421]]} widths={[8.5, 7.5, 6.5]} t={tone.coralFar} />
      <Limb points={[[8, 402], [16, 426], [36, 418]]} widths={[8.5, 7.5, 6.5]} t={tone.coral} />
      <rect x="31" y="402" width="12" height="21" rx="2.6" transform="rotate(-16 37 412)" className={tone.ink.f} />
      <rect x="33" y="404" width="8" height="16" rx="1.6" transform="rotate(-16 37 412)" fill="#bfe6f2" />
      <circle cx="40" cy="414" r="22" fill="#bfe6f2" opacity="0.13" />
      <Hand x={35} y={420} t={tone.skin2} />
      <g transform="translate(2 536) rotate(22 0 -140)">
        <Head skin={skin.two} look={1} mood="down">
          <path d="M-9.5 -151 C -10 -166 13 -168 12 -152 C 8 -157 -2 -156 -9.5 -151 Z" className={tone.coral.f} />
          <rect x="-10.5" y="-157" width="23" height="5" rx="2.5" className={tone.coralFar.f} />
        </Head>
      </g>
    </g>
  );
}

/** His bag, left on the bench beside his friend, so he can stand. */
function BagOnBench() {
  return (
    <g transform="translate(176 0)">
      <ellipse cx="14" cy="448" rx="20" ry="3.5" className={c.shadow} />
      <path d="M6 418 Q 14 406 22 418" fill="none" stroke="#c45f0a" strokeWidth="4" strokeLinecap="round" />
      <rect x="0" y="416" width="28" height="32" rx="9" className={tone.orange.f} />
      <rect x="5" y="430" width="18" height="14" rx="5" className={tone.orangeFar.f} />
      <rect x="9" y="420" width="10" height="3" rx="1.5" fill="#fff" opacity="0.5" />
      <path d="M2 440 q -8 6 -4 10" fill="none" stroke="#c45f0a" strokeWidth="3.5" strokeLinecap="round" />
    </g>
  );
}

/** Standing apart, arms crossed, glancing at his watch with a foot tapping: he has been waiting a while. */
function ImpatientStudent({ x }: { x: number }) {
  return (
    <g transform={`translate(${x} 490)`}>
      <ellipse cx="6" cy="2" rx="32" ry="5.5" className={c.shadow} />
      <Limb points={[[-3, -82], [-5, -46], [-6, -10]]} widths={[13, 11.5, 10]} t={tone.pantsFar} />
      <Shoe x={-8} y={-6} />
      <Limb points={[[4, -82], [14, -50], [25, -22]]} widths={[13, 11.5, 9.5]} t={tone.pants} />
      <Shoe x={27} y={-18} tilt={-26} />
      <path d="M44 -10 q 5 -3 9 2 M45 -19 q 7 -3 11 3 M44 -1 q 5 0 8 5" fill="none" stroke="#1b2a30" strokeWidth="1.7" strokeLinecap="round" opacity="0.4" />
      <path d="M-13 -130 Q 2 -137 15 -130 L12 -82 Q 0 -77 -11 -82 Z" className={tone.blue.f} />
      <path d="M-5 -127 q 6 5 12 0" fill="none" stroke="#285a7e" strokeWidth="2.4" strokeLinecap="round" />
      <Limb points={[[-8, -126], [-15, -106], [9, -108]]} widths={[8.5, 7.5, 6.5]} t={tone.blueFar} />
      <Hand x={11} y={-108} t={tone.skin3Far} />
      <Limb points={[[9, -126], [16, -104], [-8, -112]]} widths={[8.5, 7.5, 6.5]} t={tone.blue} />
      <Hand x={-10} y={-113} t={tone.skin3} />
      <circle cx="0" cy="-109" r="3.4" fill="#f7b552" />
      <path d="M0 -109 l0 -2 M0 -109 l2 1" stroke="#1b2a30" strokeWidth="1" strokeLinecap="round" />
      <Head skin={skin.three} look={1} mood="bored">
        <path d="M-8.5 -150 C -9.5 -163 12 -164 11 -150 C 6 -155 -2 -153 -8.5 -150 Z" className={tone.hairBrown.f} />
      </Head>
    </g>
  );
}

function BusStop() {
  return (
    <g transform="translate(748 0)">
      <ellipse cx="150" cy="494" rx="170" ry="7" className={c.shadow} />
      {/* The glass back wall with two reflections, and the bench in front of it. */}
      <rect x="22" y="346" width="224" height="146" rx="4" className={c.glass} />
      <path d="M60 346 L96 346 L52 492 L22 492 Z M120 346 L132 346 L88 492 L76 492 Z" fill="white" opacity="0.28" />
      <rect x="48" y="412" width="150" height="7" rx="3" className={c.benchDark} />
      <rect x="48" y="424" width="150" height="7" rx="3" className={c.benchDark} />
      <rect x="44" y="446" width="160" height="11" rx="5" className={c.bench} />
      <rect x="60" y="456" width="7" height="34" rx="3" className={c.benchDark} />
      <rect x="180" y="456" width="7" height="34" rx="3" className={c.benchDark} />
      {/* The roof, with a lit edge. */}
      <path d="M-10 338 Q 134 294 278 338 L278 350 L-10 350 Z" className={c.roof} />
      <path d="M-10 338 Q 134 294 278 338 L278 343 Q 134 300 -10 343 Z" className={c.roofEdge} />
      <rect x="12" y="350" width="8" height="142" rx="3" className={c.post} />
      <rect x="248" y="350" width="8" height="142" rx="3" className={c.post} />
      {/* The route board inside, left. */}
      <rect x="26" y="364" width="34" height="46" rx="4" className={c.paper} />
      {[374, 382, 390, 398].map((y) => (
        <rect key={y} x="31" y={y} width="24" height="3" rx="1.5" className="fill-[#9a8f78]" />
      ))}
      {/* The stop sign on its pole. */}
      <rect x="318" y="296" width="7" height="196" rx="3.5" className={c.post} />
      <rect x="296" y="278" width="52" height="58" rx="8" className={c.signBlue} />
      <rect x="305" y="287" width="34" height="26" rx="5" fill="white" />
      <rect x="309" y="291" width="11" height="10" rx="2" className={c.signBlue} />
      <rect x="323" y="291" width="11" height="10" rx="2" className={c.signBlue} />
      <circle cx="313" cy="316" r="3" fill="white" />
      <circle cx="331" cy="316" r="3" fill="white" />
      <rect x="302" y="342" width="40" height="22" rx="4" className={c.paper} />
      <rect x="307" y="348" width="30" height="3" rx="1.5" className="fill-[#9a8f78]" />
      <rect x="307" y="355" width="22" height="3" rx="1.5" className="fill-[#9a8f78]" />
      {/* A bin, and a small bush with flowers. */}
      <rect x="360" y="448" width="26" height="44" rx="5" className={c.bin} />
      <rect x="357" y="443" width="32" height="8" rx="4" className="fill-[#4a6a78] dark:fill-[#86a9b7]" />
      <circle cx="-34" cy="478" r="15" className={c.hedge} />
      <circle cx="-18" cy="482" r="12" className={c.hedge} />
      {[
        [-38, 472],
        [-26, 478],
        [-20, 470],
      ].map(([fx, fy]) => (
        <circle key={fx} cx={fx} cy={fy} r="2.6" fill="#f7b552" />
      ))}
      <SeatedWithPhone />
      <BagOnBench />
    </g>
  );
}

const CHIPS: { icon: IconSvgElement; tone: string; pos: string }[] = [
  { icon: Navigation03Icon, tone: "text-info", pos: "left-[33%] bottom-[66%] sm:left-[45%] sm:bottom-[64%]" },
  { icon: BadgeCheckIcon, tone: "text-ok", pos: "hidden sm:flex left-[6%] bottom-[77%]" },
  { icon: WifiOff01Icon, tone: "text-warn", pos: "left-[22%] bottom-[50%] sm:left-[22%] sm:bottom-[62%]" },
  { icon: Clock01Icon, tone: "text-fg", pos: "hidden sm:flex left-[78%] bottom-[82%]" },
];

/**
 * The bus stop at the start of the day, drawn to run the whole width of the page: hills, a campus with lit windows, trees,
 * street lamps, the shelter with its bench and sign, students waiting, the pavement and the road. Colours follow the theme
 * (the lamps glow at night). A few small messages hang over it. The ground melts into the page below. Mostly still; the
 * layers only settle in, once.
 */
export function BusStopScene({ chips }: { chips: LandingCopy["hero"]["chips"] }) {
  return (
    <SceneMotion className="relative -mt-2 h-[20rem] w-full sm:-mb-14 overflow-hidden [mask-image:linear-gradient(to_bottom,#000_80%,transparent_99%)] sm:h-auto sm:aspect-[16/5.3] sm:max-h-[38rem]">
      <div className="absolute left-1/2 top-0 h-full w-[max(100%,40rem)] -translate-x-1/2">
        <svg viewBox="0 110 1600 530" preserveAspectRatio="xMidYMax slice" aria-hidden className="absolute inset-0 size-full">
          <defs>
            <radialGradient id="lampglow">
              <stop offset="0" stopColor="#ffd98f" stopOpacity="0.55" />
              <stop offset="0.45" stopColor="#ffd98f" stopOpacity="0.18" />
              <stop offset="1" stopColor="#ffd98f" stopOpacity="0" />
            </radialGradient>
            <linearGradient id="ground-fade" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="var(--bg)" stopOpacity="0" />
              <stop offset="1" stopColor="var(--bg)" stopOpacity="1" />
            </linearGradient>
          </defs>

          <g data-scene-layer>
            <path d="M0 360 C 160 300 340 330 520 350 S 880 290 1100 330 S 1460 300 1600 340 L1600 480 L0 480 Z" className={c.hillFar} />
            <path d="M0 410 C 220 360 420 400 640 390 S 1040 350 1260 390 S 1500 380 1600 400 L1600 480 L0 480 Z" className={c.hillNear} />
          </g>

          <g data-scene-layer>
            <Building x={40} w={120} h={150} tone="bldFar" cols={3} rows={4} />
            <Building x={180} w={90} h={110} tone="bldFar" cols={2} rows={3} />
            <Building x={300} w={140} h={175} tone="bldNear" cols={4} rows={4} />
            <Building x={470} w={100} h={120} tone="bldFar" cols={3} rows={3} />
            <Building x={1060} w={120} h={130} tone="bldFar" cols={3} rows={3} />
            <Building x={1340} w={150} h={165} tone="bldNear" cols={4} rows={4} />
            <Building x={1500} w={100} h={120} tone="bldFar" cols={3} rows={3} />
            {/* The clock tower. */}
            <rect x="1215" y="196" width="58" height="274" rx="4" className={c.bldNear} />
            <path d="M1204 200 L1244 140 L1284 200 Z" className={c.bldRoof} />
            <circle cx="1244" cy="236" r="19" className="fill-[#f6fbfc] dark:fill-[#ffe8b0]" />
            <path d="M1244 236 L1244 224 M1244 236 L1254 241" stroke="#35709a" strokeWidth="3" strokeLinecap="round" fill="none" />
            {Array.from({ length: 4 }).map((_, i) => (
              <rect key={i} x="1236" y={282 + i * 44} width="16" height="22" rx="3" className={next() > 0.4 ? c.winOn : c.winOff} />
            ))}
          </g>

          <g data-scene-layer>
            <RoundTree cx={70} base={470} r={30} />
            <Pine cx={250} base={470} h={120} />
            <RoundTree cx={460} base={470} r={26} />
            <Pine cx={640} base={470} h={100} />
            <RoundTree cx={1130} base={470} r={32} />
            <Pine cx={1190} base={470} h={130} />
            <RoundTree cx={1380} base={470} r={28} />
            <Pine cx={1560} base={470} h={110} />
            <Lamp x={585} />
            <Lamp x={1262} />
          </g>

          <g data-scene-layer>
            {/* A long low hedge behind the pavement. */}
            {Array.from({ length: 36 }).map((_, i) => (
              <circle key={i} cx={i * 46 + 10} cy={466} r={14 + ((i * 7) % 5)} className={c.hedge} />
            ))}
            <rect x="0" y="470" width="1600" height="50" className={c.pavement} />
            <rect x="0" y="514" width="1600" height="12" className={c.curb} />
            {Array.from({ length: 32 }).map((_, i) => (
              <line key={i} x1={i * 52 + 14} y1="472" x2={i * 52 + 14} y2="512" strokeWidth="2" className={c.joint} />
            ))}
            <rect x="0" y="526" width="1600" height="150" className={c.road} />
            <line x1="0" y1="586" x2="1600" y2="586" strokeWidth="5" strokeDasharray="50 40" strokeLinecap="round" className={c.lane} />
            {/* Grass tufts along the curb. */}
            {[120, 330, 540, 980, 1180, 1420].map((gx) => (
              <path key={gx} d={`M${gx} 516 l-4 -12 M${gx + 5} 516 l1 -14 M${gx + 10} 516 l5 -11`} stroke="#79b3a3" strokeWidth="2.4" strokeLinecap="round" fill="none" />
            ))}
            <rect x="0" y="548" width="1600" height="92" fill="url(#ground-fade)" />
          </g>

          <g data-scene-layer>
            <BusStop />
            <WalkingPair x={310} />
            <ImpatientStudent x={1046} />
          </g>
        </svg>

        {CHIPS.map((chip, index) => (
          <p
            key={chip.pos}
            data-scene-chip
            className={`absolute m-0 items-center gap-2 rounded-md bg-surface px-3 py-2 text-xs font-semibold text-fg shadow-soft sm:text-sm ${chip.pos.includes("hidden") ? "" : "flex"} ${chip.pos}`}
          >
            <Icon icon={chip.icon} size={16} className={chip.tone} />
            {chips[index]}
          </p>
        ))}
      </div>
    </SceneMotion>
  );
}
