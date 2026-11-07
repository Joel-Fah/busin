/** A small seeded random, so the stars and clouds are the same on every visit and on the server and the browser. */
function rng(seed: number) {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 0xffffffff;
  };
}

const next = rng(20261107);
const STARS = Array.from({ length: 150 }, (_, i) => ({
  x: next() * 1600,
  y: next() * 640,
  r: 0.6 + next() * 1.5,
  o: 0.3 + next() * 0.6,
  twinkle: i % 3 === 0,
  dur: 4 + next() * 7,
  delay: -next() * 10,
}));

/** A few streaks that cross the night sky now and then, each on its own slow schedule. */
const SHOOTING = [
  { x: 140, y: 90, dur: 17, delay: -4 },
  { x: 760, y: 40, dur: 23, delay: -13 },
  { x: 1180, y: 190, dur: 29, delay: -21 },
];

const CLOUDS = [
  { y: 70, s: 1.0, o: 0.85, dur: 210, delay: -30 },
  { y: 210, s: 1.5, o: 0.7, dur: 260, delay: -150 },
  { y: 120, s: 0.7, o: 0.8, dur: 180, delay: -95 },
  { y: 300, s: 1.1, o: 0.55, dur: 240, delay: -60 },
  { y: 40, s: 0.55, o: 0.7, dur: 200, delay: -170 },
  { y: 370, s: 0.9, o: 0.45, dur: 280, delay: -210 },
];

function Cloud({ y, s, o }: { y: number; s: number; o: number }) {
  return (
    <g transform={`translate(0 ${y}) scale(${s})`} opacity={o} fill="white">
      <ellipse cx="0" cy="26" rx="120" ry="26" />
      <circle cx="-44" cy="14" r="30" />
      <circle cx="6" cy="-2" r="42" />
      <circle cx="58" cy="12" r="30" />
    </g>
  );
}

/**
 * The sky behind the top of the page. By day: soft clouds drifting very slowly across, never stopping, and a pale sun. By
 * night: a field of stars, some fading in and out, a few shooting stars now and then, and a thin moon. Decoration only; it
 * fades in. The page's colours decide which one shows, and a visitor who asked for less motion gets it still.
 */
export function Sky() {
  return (
    <div
      aria-hidden
      className="landing-fade pointer-events-none absolute inset-x-0 top-0 z-0 h-[72rem] overflow-hidden bg-gradient-to-b from-[#b4dce9] via-[#e2f2f6] to-bg dark:from-[#00080c] dark:via-[#03202a] dark:to-bg"
    >
      {/* Day */}
      <svg viewBox="0 0 1600 700" preserveAspectRatio="xMidYMin slice" className="absolute inset-x-0 top-0 h-[46rem] w-full dark:hidden">
        <defs>
          <radialGradient id="sun">
            <stop offset="0" stopColor="#fff4c9" stopOpacity="0.95" />
            <stop offset="0.35" stopColor="#fff4c9" stopOpacity="0.45" />
            <stop offset="1" stopColor="#fff4c9" stopOpacity="0" />
          </radialGradient>
        </defs>
        <circle cx="1240" cy="170" r="300" fill="url(#sun)" />
        {CLOUDS.map(({ dur, delay, ...cloud }, index) => (
          <g key={index} className="landing-drift" style={{ animationDuration: `${dur}s`, animationDelay: `${delay}s`, ["--rest" as string]: `${300 + index * 230}px` }}>
            <Cloud {...cloud} />
          </g>
        ))}
      </svg>

      {/* Night */}
      <svg viewBox="0 0 1600 700" preserveAspectRatio="xMidYMin slice" className="absolute inset-x-0 top-0 hidden h-[46rem] w-full dark:block">
        <defs>
          <radialGradient id="moonglow">
            <stop offset="0" stopColor="#dfeaf2" stopOpacity="0.35" />
            <stop offset="1" stopColor="#dfeaf2" stopOpacity="0" />
          </radialGradient>
          <linearGradient id="streak" x1="1" y1="1" x2="0" y2="0">
            <stop offset="0" stopColor="#fff" stopOpacity="0.95" />
            <stop offset="1" stopColor="#fff" stopOpacity="0" />
          </linearGradient>
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
            style={star.twinkle ? { animationDuration: `${star.dur}s`, animationDelay: `${star.delay}s` } : undefined}
          />
        ))}
        {SHOOTING.map((star, index) => (
          <g key={index} transform={`translate(${star.x} ${star.y})`}>
            <g className="landing-shoot" style={{ animationDuration: `${star.dur}s`, animationDelay: `${star.delay}s` }}>
              <line x1="0" y1="0" x2="-110" y2="-46" stroke="url(#streak)" strokeWidth="1.8" strokeLinecap="round" />
              <circle r="1.8" fill="#fff" />
            </g>
          </g>
        ))}
        <circle cx="1240" cy="170" r="160" fill="url(#moonglow)" />
        <rect width="1600" height="700" fill="#f1efe0" mask="url(#crescent)" />
      </svg>
    </div>
  );
}
