import Image from "next/image";
import { Navigation03Icon } from "@hugeicons/core-free-icons";

import { Icon } from "@/components/ui/Icon";

import { SceneMotion } from "./SceneMotion";

/** [x, width, height]: the campus skyline, far away and faint. */
const BUILDINGS: [number, number, number][] = [
  [20, 110, 120],
  [140, 80, 170],
  [230, 130, 110],
  [380, 90, 150],
  [490, 120, 100],
  [700, 100, 140],
  [820, 140, 105],
  [1010, 90, 160],
  [1110, 120, 120],
  [1330, 130, 135],
  [1470, 110, 100],
];
const TREES: [number, number, number][] = [
  [90, 395, 34],
  [330, 405, 28],
  [640, 400, 36],
  [940, 408, 30],
  [1290, 398, 38],
  [1560, 405, 30],
];

const far = "fill-[color-mix(in_srgb,var(--fg)_7%,transparent)]";
const mid = "fill-[color-mix(in_srgb,var(--fg)_11%,transparent)]";

/**
 * The bus stop, drawn as a wide scene that runs the whole width of the page: a faint campus, trees, the pavement and the road,
 * a waiting student, the shelter, and the bus arriving. The ground fades into the page below. Mostly still; it only settles in.
 */
export function BusStopScene({ eta }: { eta: string }) {
  return (
    <SceneMotion className="relative -mt-2 h-[19rem] w-full overflow-hidden sm:h-auto sm:aspect-[16/5.4] sm:max-h-[38rem]">
      <div className="absolute left-1/2 top-0 h-full w-[max(100%,38rem)] -translate-x-1/2">
        <svg viewBox="0 0 1600 600" preserveAspectRatio="xMidYMax slice" aria-hidden className="absolute inset-0 size-full">
          <g data-scene-far className={far}>
            {BUILDINGS.map(([x, w, h]) => (
              <rect key={x} x={x} y={400 - h} width={w} height={h} rx="6" />
            ))}
            {/* The clock tower. */}
            <rect x="1215" y="190" width="54" height="210" rx="4" />
            <path d="M1204 192 L1242 140 L1280 192 Z" />
          </g>
          <g data-scene-far className={mid}>
            {TREES.map(([cx, cy, r]) => (
              <g key={cx}>
                <rect x={cx - 4} y={cy - 8} width="8" height="28" rx="3" />
                <circle cx={cx} cy={cy - 22} r={r} />
                <circle cx={cx - r * 0.7} cy={cy - 12} r={r * 0.7} />
                <circle cx={cx + r * 0.7} cy={cy - 12} r={r * 0.7} />
              </g>
            ))}
          </g>
          <g data-scene-far>
            <rect x="0" y="420" width="1600" height="50" fill="var(--surface)" />
            <rect x="0" y="470" width="1600" height="130" fill="var(--surface-2)" />
            <line x1="0" y1="548" x2="1600" y2="548" stroke="var(--line)" strokeWidth="4" strokeDasharray="46 38" strokeLinecap="round" />
          </g>
        </svg>

        {/* Fades the road into the page. */}
        <div aria-hidden className="absolute inset-x-0 bottom-0 h-1/4 bg-gradient-to-b from-transparent to-bg" />

        <Image data-scene-still src="/illustrations/waiting.webp" alt="" width={480} height={480} priority sizes="(min-width: 640px) 12vw, 90px" className="absolute bottom-[13%] left-[22%] h-auto w-[11%]" />
        <Image data-scene-still src="/illustrations/bus-stop.webp" alt="" width={480} height={480} priority sizes="(min-width: 640px) 22vw, 170px" className="absolute bottom-[12%] left-[34%] h-auto w-[21%]" />
        <Image data-scene-bus src="/illustrations/bus-large.webp" alt="" width={960} height={830} priority sizes="(min-width: 640px) 32vw, 230px" className="absolute bottom-[3%] right-[10%] h-auto w-[31%] drop-shadow-[0_14px_18px_rgb(0_20_26/0.22)]" />

        <p data-scene-chip className="absolute bottom-[58%] left-[33%] m-0 flex items-center gap-2 rounded-md bg-surface px-3 py-2 text-xs font-semibold text-fg shadow-soft sm:text-sm">
          <Icon icon={Navigation03Icon} size={16} className="text-info" />
          {eta}
        </p>
      </div>
    </SceneMotion>
  );
}
