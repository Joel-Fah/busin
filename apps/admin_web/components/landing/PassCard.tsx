import type { LandingCopy } from "@/lib/i18n/landing";

/** A fixed, made-up pattern with round corner markers like the app's code. It is decoration, never a real code. */
const SIZE = 25;

function pattern(): boolean[][] {
  let seed = 20261107;
  const next = () => {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    return seed / 0xffffffff;
  };
  const grid = Array.from({ length: SIZE }, () => Array.from({ length: SIZE }, () => next() > 0.52));
  return grid;
}

const GRID = pattern();
const FINDERS: [number, number][] = [
  [0, 0],
  [SIZE - 7, 0],
  [0, SIZE - 7],
];

function inFinder(x: number, y: number) {
  return FINDERS.some(([fx, fy]) => x >= fx - 1 && x <= fx + 7 && y >= fy - 1 && y <= fy + 7);
}

/** The boarding pass as the app shows it: a teal ticket, a white sticker with the code, who and where. */
export function PassCard({ mock }: { mock: LandingCopy["hero"]["mock"] }) {
  return (
    <div className="texture-grain relative overflow-hidden rounded-lg bg-seed p-5 text-white [--grain:1] [--thread-color:color-mix(in_srgb,white_26%,transparent)]">
      <div className="flex items-center justify-between">
        <p className="text-sm font-bold tracking-wide">{mock.pass}</p>
        <span className="inline-flex items-center gap-1.5 rounded-xs bg-white/15 px-2 py-1 text-xs font-semibold">
          <span aria-hidden className="size-1.5 rounded-full bg-teal-300" />
          {mock.live}
        </span>
      </div>

      <div className="relative mx-auto mt-4 grid aspect-square w-full max-w-[13rem] place-items-center rounded-md bg-white p-3">
        <svg viewBox={`0 0 ${SIZE} ${SIZE}`} aria-hidden className="size-full text-seed" shapeRendering="crispEdges">
          {GRID.flatMap((row, y) =>
            row.map((on, x) => (on && !inFinder(x, y) ? <rect key={`${x}-${y}`} x={x} y={y} width="1" height="1" fill="currentColor" /> : null)),
          )}
          {FINDERS.map(([fx, fy]) => (
            <g key={`${fx}-${fy}`} fill="none" stroke="currentColor">
              <circle cx={fx + 3.5} cy={fy + 3.5} r="3" strokeWidth="1" />
              <circle cx={fx + 3.5} cy={fy + 3.5} r="1.35" fill="currentColor" stroke="none" />
            </g>
          ))}
        </svg>
        {/* The time left on this code, as a ring that empties every 30 seconds. */}
        <svg aria-hidden viewBox="0 0 36 36" className="absolute -right-3 -top-3 size-9 -rotate-90">
          <circle cx="18" cy="18" r="15" fill="var(--color-seed)" />
          <circle cx="18" cy="18" r="15" fill="none" stroke="rgb(255 255 255 / 0.25)" strokeWidth="3" />
          <circle cx="18" cy="18" r="15" fill="none" stroke="var(--color-orange-400)" strokeWidth="3" strokeLinecap="round" pathLength="100" strokeDasharray="100" className="landing-code-ring" />
        </svg>
      </div>

      <p className="mt-3 text-center text-xs text-white/70">{mock.refresh}</p>
      <dl className="mt-3 grid grid-cols-2 gap-3 border-t border-dashed border-white/25 pt-3 text-sm">
        <div>
          <dt className="text-xs text-white/60">{mock.riderLabel}</dt>
          <dd className="m-0 font-semibold">{mock.rider}</dd>
        </div>
        <div>
          <dt className="text-xs text-white/60">{mock.stopLabel}</dt>
          <dd className="m-0 font-semibold">{mock.stop}</dd>
        </div>
      </dl>
    </div>
  );
}
