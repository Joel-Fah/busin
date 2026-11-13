import { useMemo } from "react";

import { qrArt } from "@/lib/student/qr-art";

/** The white margin around the code, in modules: the QR standard asks for four, and scanners need it. */
const QUIET = 4;

/**
 * The boarding code drawn with round dots (lib/student/qr-art.ts) in the brand's deep teal on white. The three corner
 * squares stay square: they are what a scanner looks for first, and tests with a real decoder showed that rounding them,
 * even slightly, makes codes fail to read, while round dots elsewhere read every time.
 */
export function QrDots({ code, label }: { code: string; label: string }) {
  const art = useMemo(() => qrArt(code), [code]);
  const box = art.size + QUIET * 2;
  return (
    <svg viewBox={`${-QUIET} ${-QUIET} ${box} ${box}`} role="img" aria-label={label} className="block size-full" shapeRendering="geometricPrecision">
      <rect x={-QUIET} y={-QUIET} width={box} height={box} fill="#ffffff" />
      <g fill="#002a33">
        {art.dots.map(([x, y]) => (
          <circle key={`${x}-${y}`} cx={x + 0.5} cy={y + 0.5} r={0.45} />
        ))}
        {art.finders.map(([x, y]) => (
          <g key={`f-${x}-${y}`}>
            <path fillRule="evenodd" d={`M${x},${y}h7v7h-7z M${x + 1},${y + 1}v5h5v-5z`} />
            <rect x={x + 2} y={y + 2} width={3} height={3} />
          </g>
        ))}
      </g>
    </svg>
  );
}
