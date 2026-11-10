import { Calendar03Icon, HourglassIcon, Invoice01Icon, Navigation03Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

import { SCENE_PEOPLE } from "./scene-people";
import "./scene-people.css";
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

/**
 * One of the scene's people. They are drawn by `tools/landing-people.mjs` (smooth limbs need a little geometry) and kept as
 * SVG markup in `scene-people.ts`; this places one. The markup is ours and fixed, never anything a visitor typed.
 */
function Figure({ name, x, y, flip = false }: { name: keyof typeof SCENE_PEOPLE; x: number; y: number; flip?: boolean }) {
  return <g transform={`translate(${x} ${y})${flip ? " scale(-1 1)" : ""}`} dangerouslySetInnerHTML={{ __html: SCENE_PEOPLE[name] }} />;
}

function BusStop() {
  return (
    <g transform="translate(748 0)">
      <ellipse cx="150" cy="494" rx="170" ry="7" className={c.shadow} />
      {/* The glass back wall with two reflections, and the bench in front of it. */}
      <rect x="22" y="306" width="224" height="186" rx="4" className={c.glass} />
      <path d="M68 306 L104 306 L50 492 L22 492 Z M128 306 L140 306 L86 492 L74 492 Z" fill="white" opacity="0.28" />
      <rect x="48" y="412" width="150" height="7" rx="3" className={c.benchDark} />
      <rect x="48" y="424" width="150" height="7" rx="3" className={c.benchDark} />
      <rect x="44" y="446" width="160" height="11" rx="5" className={c.bench} />
      <rect x="60" y="456" width="7" height="34" rx="3" className={c.benchDark} />
      <rect x="180" y="456" width="7" height="34" rx="3" className={c.benchDark} />
      {/* The roof, with a lit edge. */}
      <path d="M-10 298 Q 134 254 278 298 L278 310 L-10 310 Z" className={c.roof} />
      <path d="M-10 298 Q 134 254 278 298 L278 303 Q 134 260 -10 303 Z" className={c.roofEdge} />
      <rect x="12" y="310" width="8" height="182" rx="3" className={c.post} />
      <rect x="248" y="310" width="8" height="182" rx="3" className={c.post} />
      {/* The route board inside, left. */}
      <rect x="26" y="334" width="34" height="46" rx="4" className={c.paper} />
      {[344, 352, 360, 368].map((y) => (
        <rect key={y} x="31" y={y} width="24" height="3" rx="1.5" className="fill-[#9a8f78]" />
      ))}
      {/* The stop sign on its pole. */}
      <rect x="318" y="262" width="7" height="230" rx="3.5" className={c.post} />
      <rect x="296" y="244" width="52" height="58" rx="8" className={c.signBlue} />
      <rect x="305" y="253" width="34" height="26" rx="5" fill="white" />
      <rect x="309" y="257" width="11" height="10" rx="2" className={c.signBlue} />
      <rect x="323" y="257" width="11" height="10" rx="2" className={c.signBlue} />
      <circle cx="313" cy="282" r="3" fill="white" />
      <circle cx="331" cy="282" r="3" fill="white" />
      <rect x="302" y="308" width="40" height="22" rx="4" className={c.paper} />
      <rect x="307" y="314" width="30" height="3" rx="1.5" className="fill-[#9a8f78]" />
      <rect x="307" y="321" width="22" height="3" rx="1.5" className="fill-[#9a8f78]" />
      {/* A bin, and a small bush with flowers. */}
      <rect x="430" y="448" width="26" height="44" rx="5" className={c.bin} />
      <rect x="427" y="443" width="32" height="8" rx="4" className="fill-[#4a6a78] dark:fill-[#86a9b7]" />
      <circle cx="-34" cy="478" r="15" className={c.hedge} />
      <circle cx="-18" cy="482" r="12" className={c.hedge} />
      {[
        [-38, 472],
        [-26, 478],
        [-20, 470],
      ].map(([fx, fy]) => (
        <circle key={fx} cx={fx} cy={fy} r="2.6" fill="#f7b552" />
      ))}
      <Figure name="seated" x={104} y={446} />
      <Figure name="bag" x={186} y={446} />
    </g>
  );
}

/**
 * The small messages over the scene. Three are what students mutter at a bus stop (each sits by the person who would say
 * it); one is BusIn answering, in the brand colour. On a phone only the answer and one grumble show.
 */
const CHIPS: { key: keyof LandingCopy["hero"]["chips"]; icon: IconSvgElement; pos: string; answer?: boolean }[] = [
  { key: "receipt", icon: Invoice01Icon, pos: "hidden sm:flex left-[9%] bottom-[73%]" },
  { key: "timetable", icon: Calendar03Icon, pos: "hidden sm:flex left-[25%] bottom-[49%]" },
  { key: "waiting", icon: HourglassIcon, pos: "flex left-[22%] bottom-[88%] sm:left-[69%] sm:bottom-[67%]" },
  { key: "busin", icon: Navigation03Icon, pos: "flex left-[36%] bottom-[75%] sm:left-[47%] sm:bottom-[83%]", answer: true },
];

/**
 * The bus stop at the start of the day, drawn to run the whole width of the page: hills, a campus with lit windows, trees,
 * street lamps, the shelter with its bench and sign, students waiting, the pavement and the road. Colours follow the theme
 * (the lamps glow at night). A few small messages hang over it. The ground melts into the page below. Mostly still; the
 * layers only settle in, once.
 */
export function BusStopScene({ chips }: { chips: LandingCopy["hero"]["chips"] }) {
  return (
    <SceneMotion className="relative -mt-2 h-[22rem] w-full sm:-mb-14 overflow-hidden [mask-image:linear-gradient(to_bottom,#000_80%,transparent_99%)] sm:h-auto sm:aspect-[16/5.3] sm:max-h-[38rem]">
      <div className="absolute left-1/2 top-0 h-full w-[max(100%,40rem)] -translate-x-1/2">
        <svg viewBox="0 110 1600 530" preserveAspectRatio="xMidYMax slice" aria-hidden data-scene-people className="absolute inset-0 size-full">
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
            <Figure name="walkingPair" x={300} y={490} />
            <Figure name="impatient" x={1134} y={490} flip />
          </g>
        </svg>

        {CHIPS.map((chip) => (
          <p
            key={chip.key}
            data-scene-chip
            className={`absolute m-0 items-center gap-2 rounded-md px-3 py-2 text-xs font-semibold shadow-soft sm:text-sm ${chip.pos} ${
              chip.answer ? "bg-accent text-on-accent" : "bg-surface text-fg"
            }`}
          >
            <Icon icon={chip.icon} size={16} className={chip.answer ? "" : "text-muted"} />
            {chips[chip.key]}
          </p>
        ))}
      </div>
    </SceneMotion>
  );
}
