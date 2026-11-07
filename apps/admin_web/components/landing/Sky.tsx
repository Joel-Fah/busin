/** A small seeded random, so the stars and clouds are the same on every visit and on the server and the browser. */
function rng(seed: number) {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 0xffffffff;
  };
}

const next = rng(20261107);
const STARS = Array.from({ length: 110 }, (_, i) => ({
  x: next() * 1600,
  y: next() * 620,
  r: 0.7 + next() * 1.5,
  o: 0.35 + next() * 0.55,
  twinkle: i % 14 === 0,
  delay: next() * 6,
}));

const CLOUDS = [
  { x: 120, y: 120, s: 1.1, o: 0.85 },
  { x: 520, y: 70, s: 0.7, o: 0.7 },
  { x: 860, y: 190, s: 1.3, o: 0.8 },
  { x: 1290, y: 90, s: 0.9, o: 0.75 },
  { x: 1450, y: 250, s: 0.65, o: 0.6 },
  { x: 300, y: 300, s: 0.8, o: 0.55 },
];

function Cloud({ x, y, s, o }: { x: number; y: number; s: number; o: number }) {
  return (
    <g transform={`translate(${x} ${y}) scale(${s})`} opacity={o} fill="white">
      <ellipse cx="0" cy="26" rx="120" ry="26" />
      <circle cx="-44" cy="14" r="30" />
      <circle cx="6" cy="-2" r="42" />
      <circle cx="58" cy="12" r="30" />
    </g>
  );
}

/**
 * The sky behind the top of the page: soft clouds and a pale sun by day, a quiet field of stars and a thin moon by night.
 * Decoration only, drawn once and still; it fades in. The page's colours decide which one shows.
 */
export function Sky() {
  return (
    <div
      aria-hidden
      className="landing-fade pointer-events-none absolute inset-x-0 top-0 z-0 h-[70rem] overflow-hidden bg-gradient-to-b from-[#b4dce9] via-[#e2f2f6] to-bg dark:from-[#00080c] dark:via-[#03202a] dark:to-bg"
    >
      {/* Day */}
      <svg viewBox="0 0 1600 700" preserveAspectRatio="xMidYMin slice" className="absolute inset-x-0 top-0 h-[44rem] w-full dark:hidden">
        <defs>
          <radialGradient id="sun">
            <stop offset="0" stopColor="#fff4c9" stopOpacity="0.95" />
            <stop offset="0.35" stopColor="#fff4c9" stopOpacity="0.45" />
            <stop offset="1" stopColor="#fff4c9" stopOpacity="0" />
          </radialGradient>
        </defs>
        <circle cx="1240" cy="170" r="300" fill="url(#sun)" />
        {CLOUDS.map((cloud, index) => (
          <Cloud key={index} {...cloud} />
        ))}
      </svg>

      {/* Night */}
      <svg viewBox="0 0 1600 700" preserveAspectRatio="xMidYMin slice" className="absolute inset-x-0 top-0 hidden h-[44rem] w-full dark:block">
        <defs>
          <radialGradient id="moonglow">
            <stop offset="0" stopColor="#dfeaf2" stopOpacity="0.35" />
            <stop offset="1" stopColor="#dfeaf2" stopOpacity="0" />
          </radialGradient>
          <mask id="crescent">
            <rect width="1600" height="700" fill="black" />
            <circle cx="1240" cy="170" r="34" fill="white" />
            <circle cx="1254" cy="160" r="30" fill="black" />
          </mask>
        </defs>
        {STARS.map((star, index) => (
          <circle
            key={index}
            cx={star.x}
            cy={star.y}
            r={star.r}
            fill="#e8f3f7"
            opacity={star.o}
            className={star.twinkle ? "landing-twinkle" : undefined}
            style={star.twinkle ? { animationDelay: `${star.delay}s` } : undefined}
          />
        ))}
        <circle cx="1240" cy="170" r="160" fill="url(#moonglow)" />
        <rect width="1600" height="700" fill="#f1efe0" mask="url(#crescent)" />
      </svg>
    </div>
  );
}
