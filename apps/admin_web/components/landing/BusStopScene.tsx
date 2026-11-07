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

/** A limb as a thick rounded line, the way these flat characters are built: easy to bend into any pose. */
function Limb({ d, tone, w = 9 }: { d: string; tone: string; w?: number }) {
  return <path d={d} fill="none" strokeWidth={w} strokeLinecap="round" strokeLinejoin="round" className={tone} />;
}

const stroke = {
  pants: "stroke-[#243b46] dark:stroke-[#3b5a68]",
  teal: "stroke-[#0c5d6d] dark:stroke-[#17808f]",
  orange: "stroke-[#ef7611]",
  cream: "stroke-[#f3e7cc]",
  blue: "stroke-[#35709a]",
  coral: "stroke-[#e8694a]",
  navy: "stroke-[#1f3b57] dark:stroke-[#4a7396]",
};
const fill = {
  shoe: "fill-[#f6efdc] dark:fill-[#d9d2bd]",
  dark: "fill-[#1b2a30]",
  hairBlack: "fill-[#161f23]",
  hairBrown: "fill-[#5a3a24]",
  coral: "fill-[#e8694a]",
  blue: "fill-[#35709a]",
  navy: "fill-[#1f3b57] dark:fill-[#4a7396]",
};

/** The face: two eyes looking where the person looks, a brow each, and a mouth that says how they feel. */
function Face({ x, y, look = 1, mood }: { x: number; y: number; look?: 1 | -1 | 0; mood: "chat" | "laugh" | "focus" | "bored" }) {
  const dx = look * 4.5;
  const eyes: [number, number][] = [[x - 4 + dx, y], [x + 5 + dx, y]];
  return (
    <g>
      {eyes.map(([ex, ey]) => (
        <circle key={ex} cx={ex} cy={ey} r="1.7" className={fill.dark} />
      ))}
      {mood === "bored" ? (
        <>
          <path d={`M${x - 8 + dx} ${y - 6} L${x - 1 + dx} ${y - 4}`} stroke="#1b2a30" strokeWidth="1.6" strokeLinecap="round" />
          <path d={`M${x + 2 + dx} ${y - 4} L${x + 9 + dx} ${y - 6}`} stroke="#1b2a30" strokeWidth="1.6" strokeLinecap="round" />
          <path d={`M${x - 3 + dx} ${y + 8} L${x + 5 + dx} ${y + 8}`} stroke="#1b2a30" strokeWidth="1.8" strokeLinecap="round" />
        </>
      ) : (
        <>
          <path d={`M${x - 7 + dx} ${y - 5} Q ${x - 4 + dx} ${y - 7} ${x - 1 + dx} ${y - 5} M${x + 2 + dx} ${y - 5} Q ${x + 5 + dx} ${y - 7} ${x + 8 + dx} ${y - 5}`} fill="none" stroke="#1b2a30" strokeWidth="1.3" strokeLinecap="round" />
          {mood === "laugh" ? (
            <path d={`M${x - 4 + dx} ${y + 6} Q ${x + dx} ${y + 13} ${x + 5 + dx} ${y + 6} Z`} fill="#fff" stroke="#1b2a30" strokeWidth="1.3" strokeLinejoin="round" />
          ) : (
            <path d={`M${x - 4 + dx} ${y + 7} Q ${x + dx} ${y + 11} ${x + 5 + dx} ${y + 7}`} fill="none" stroke="#1b2a30" strokeWidth="1.5" strokeLinecap="round" />
          )}
          <circle cx={x - 7 + dx} cy={y + 5} r="3" fill="#ef7611" opacity="0.28" />
        </>
      )}
    </g>
  );
}

/** Two students arriving, mid-stride and mid-sentence, a step apart so they can talk. */
function WalkingPair({ x }: { x: number }) {
  return (
    <g transform={`translate(${x} 490)`}>
      {/* She talks with her hands. */}
      <g transform="translate(0 0)">
        <ellipse cx="0" cy="2" rx="30" ry="5" className={c.shadow} />
        <rect x="-27" y="-98" width="16" height="40" rx="7" className={c.teal} />
        <Limb d="M-3 -48 L-17 -25 L-25 -4" tone={stroke.pants} w={11} />
        <ellipse cx="-27" cy="-1" rx="9" ry="4.5" className={fill.shoe} />
        <Limb d="M-6 -86 L-19 -68 L-23 -52" tone={stroke.orange} w={8} />
        <circle cx="-23" cy="-49" r="4.6" className={c.skin1} />
        <rect x="-14" y="-100" width="29" height="56" rx="13" className={c.orange} />
        <rect x="-14" y="-52" width="29" height="14" rx="6" className={c.teal} />
        <Limb d="M3 -48 L15 -26 L21 -4" tone={stroke.teal} w={11} />
        <ellipse cx="24" cy="-1" rx="9" ry="4.5" className={fill.shoe} />
        <rect x="-3" y="-108" width="8" height="10" rx="3" className={c.skin1} />
        <circle cx="-11" cy="-117" r="7.5" className={fill.hairBlack} />
        <circle cx="3" cy="-116" r="13" className={c.skin1} />
        <path d="M-10 -118 C -11 -136 15 -139 17 -121 C 12 -128 0 -126 -10 -118 Z" className={fill.hairBlack} />
        <Face x={3} y={-114} look={1} mood="chat" />
        <Limb d="M9 -86 L25 -90 L33 -108" tone={stroke.orange} w={8} />
        <circle cx="33" cy="-111" r="5" className={c.skin1} />
        <path d="M30 -115 l-3 -6 M35 -116 l1 -7" stroke="#1b2a30" strokeWidth="1.8" strokeLinecap="round" opacity="0.5" />
      </g>

      {/* He laughs and looks back at her. */}
      <g transform="translate(78 0)">
        <ellipse cx="0" cy="2" rx="30" ry="5" className={c.shadow} />
        <rect x="-27" y="-96" width="16" height="38" rx="7" className={fill.coral} />
        <Limb d="M-3 -48 L-9 -25 L-13 -4" tone={stroke.pants} w={11} />
        <ellipse cx="-14" cy="-1" rx="9" ry="4.5" className={fill.shoe} />
        <Limb d="M-6 -86 L-13 -68 L-8 -52" tone={stroke.cream} w={8} />
        <circle cx="-8" cy="-49" r="4.6" className={c.skin2} />
        <rect x="-14" y="-100" width="29" height="56" rx="13" className={c.cream} />
        <rect x="-8" y="-62" width="16" height="9" rx="4" className="fill-[#e2d4b4]" />
        <Limb d="M3 -48 L19 -24 L29 -5" tone={stroke.pants} w={11} />
        <ellipse cx="32" cy="-1" rx="9" ry="4.5" className={fill.shoe} />
        <rect x="-4" y="-108" width="8" height="10" rx="3" className={c.skin2} />
        <circle cx="-1" cy="-116" r="13" className={c.skin2} />
        <path d="M-13 -117 C -14 -132 8 -134 12 -120 C 6 -123 -4 -122 -13 -117 Z" className={fill.hairBlack} />
        <Face x={-1} y={-114} look={-1} mood="laugh" />
        <Limb d="M9 -86 L17 -68 L11 -54" tone={stroke.cream} w={8} />
        <circle cx="11" cy="-51" r="4.6" className={c.skin2} />
      </g>
    </g>
  );
}

/** Waiting on the bench, head down over his phone, its light on his face. */
function SeatedWithPhone() {
  return (
    <g transform="translate(106 0)">
      <ellipse cx="22" cy="492" rx="34" ry="5" className={c.shadow} />
      <Limb d="M2 441 L36 441" tone={stroke.pants} w={12} />
      <Limb d="M36 441 L42 483" tone={stroke.pants} w={11} />
      <ellipse cx="48" cy="489" rx="10" ry="4.5" className={fill.shoe} />
      <rect x="-8" y="398" width="26" height="52" rx="12" transform="rotate(12 5 446)" className={fill.coral} />
      <Limb d="M8 414 L12 432 L32 424" tone={stroke.coral} w={8} />
      <circle cx="35" cy="423" r="4.4" className={c.skin2} />
      <rect x="31" y="406" width="12" height="20" rx="2.5" transform="rotate(-14 37 416)" className={fill.dark} />
      <rect x="33" y="408" width="8" height="15" rx="1.5" transform="rotate(-14 37 416)" fill="#bfe6f2" />
      <circle cx="38" cy="414" r="18" fill="#bfe6f2" opacity="0.14" />
      <rect x="2" y="386" width="7" height="12" rx="3" transform="rotate(14 5 392)" className={c.skin2} />
      <circle cx="17" cy="388" r="12.5" className={c.skin2} />
      <path d="M5 386 C 3 372 24 368 29 382 C 22 378 12 380 5 386 Z" className={fill.hairBlack} />
      <path d="M19 389 q 3 2 6 0 M26 389 q 3 2 6 0" fill="none" stroke="#1b2a30" strokeWidth="1.5" strokeLinecap="round" transform="translate(-3 1)" />
      <path d="M21 396 Q 25 399 29 396" fill="none" stroke="#1b2a30" strokeWidth="1.5" strokeLinecap="round" />
    </g>
  );
}

/** His bag, left on the bench beside his friend, so he can stand. */
function BagOnBench() {
  return (
    <g transform="translate(166 0)">
      <ellipse cx="14" cy="448" rx="20" ry="3.5" className={c.shadow} />
      <path d="M6 418 Q 14 406 22 418" fill="none" stroke="#c45f0a" strokeWidth="4" strokeLinecap="round" />
      <rect x="0" y="416" width="28" height="32" rx="9" className={c.orange} />
      <rect x="5" y="430" width="18" height="14" rx="5" fill="#c45f0a" />
      <rect x="9" y="420" width="10" height="3" rx="1.5" fill="#fff" opacity="0.5" />
      <path d="M2 440 q -8 6 -4 10" fill="none" stroke="#c45f0a" strokeWidth="3.5" strokeLinecap="round" />
    </g>
  );
}

/** Standing apart, arms crossed, glancing at his watch with a foot tapping: he has been waiting a while. */
function ImpatientStudent({ x }: { x: number }) {
  return (
    <g transform={`translate(${x} 490)`}>
      <ellipse cx="0" cy="2" rx="28" ry="5" className={c.shadow} />
      <Limb d="M-5 -48 L-7 -24 L-8 -4" tone={stroke.pants} w={11} />
      <ellipse cx="-8" cy="-1" rx="9" ry="4.5" className={fill.shoe} />
      <Limb d="M5 -48 L16 -26 L25 -9" tone={stroke.pants} w={11} />
      <ellipse cx="30" cy="-8" rx="9" ry="4.5" transform="rotate(-24 30 -8)" className={fill.shoe} />
      <path d="M40 -4 q 5 -2 8 3 M42 -11 q 6 -3 10 3 M43 1 q 5 0 7 5" fill="none" stroke="#1b2a30" strokeWidth="1.8" strokeLinecap="round" opacity="0.45" />
      <rect x="-14" y="-100" width="29" height="56" rx="13" className={fill.blue} />
      <Limb d="M-9 -86 L-16 -70 L6 -64" tone={stroke.blue} w={8} />
      <Limb d="M10 -86 L17 -72 L-6 -77" tone={stroke.navy} w={8} />
      <circle cx="8" cy="-65" r="4.4" className={c.skin3} />
      <circle cx="-8" cy="-78" r="4.4" className={c.skin3} />
      <circle cx="-3" cy="-71" r="3.4" fill="#f7b552" />
      <path d="M-3 -71 l0 -2 M-3 -71 l2 1" stroke="#1b2a30" strokeWidth="1" strokeLinecap="round" />
      <rect x="-3" y="-108" width="8" height="10" rx="3" className={c.skin3} />
      <circle cx="4" cy="-116" r="13" className={c.skin3} />
      <path d="M-9 -117 C -9 -133 15 -134 17 -119 C 11 -124 0 -123 -9 -117 Z" className={fill.hairBrown} />
      <Face x={4} y={-114} look={1} mood="bored" />
    </g>
  );
}

function BusStop() {
  return (
    <g transform="translate(748 0)">
      <ellipse cx="150" cy="494" rx="170" ry="7" className={c.shadow} />
      {/* The glass back wall with two reflections, and the bench in front of it. */}
      <rect x="22" y="374" width="224" height="118" rx="4" className={c.glass} />
      <path d="M60 374 L96 374 L52 492 L22 492 Z M120 374 L132 374 L88 492 L76 492 Z" fill="white" opacity="0.28" />
      <rect x="48" y="412" width="150" height="7" rx="3" className={c.benchDark} />
      <rect x="48" y="424" width="150" height="7" rx="3" className={c.benchDark} />
      <rect x="44" y="446" width="160" height="11" rx="5" className={c.bench} />
      <rect x="60" y="456" width="7" height="34" rx="3" className={c.benchDark} />
      <rect x="180" y="456" width="7" height="34" rx="3" className={c.benchDark} />
      {/* The roof, with a lit edge. */}
      <path d="M-10 366 Q 134 322 278 366 L278 378 L-10 378 Z" className={c.roof} />
      <path d="M-10 366 Q 134 322 278 366 L278 371 Q 134 328 -10 371 Z" className={c.roofEdge} />
      <rect x="12" y="378" width="8" height="114" rx="3" className={c.post} />
      <rect x="248" y="378" width="8" height="114" rx="3" className={c.post} />
      {/* The route board inside, left. */}
      <rect x="26" y="388" width="34" height="46" rx="4" className={c.paper} />
      {[398, 406, 414, 422].map((y) => (
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
    <SceneMotion className="relative -mt-2 h-[20rem] w-full sm:-mb-14 overflow-hidden [mask-image:linear-gradient(to_bottom,#000_58%,transparent_97%)] sm:h-auto sm:aspect-[16/5.3] sm:max-h-[38rem]">
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
            <WalkingPair x={330} />
            <ImpatientStudent x={1036} />
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
