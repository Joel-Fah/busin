/**
 * The SVG filter behind the .texture-rough class (see app/theme.css). Render it once on any page
 * that uses rough edges. It draws nothing itself.
 */
export function RoughFilter() {
  return (
    <svg width="0" height="0" aria-hidden className="absolute">
      <filter id="busin-rough" x="-6%" y="-6%" width="112%" height="112%">
        <feTurbulence type="fractalNoise" baseFrequency="0.035 0.06" numOctaves="3" seed="7" result="wobble" />
        <feDisplacementMap in="SourceGraphic" in2="wobble" scale="9" xChannelSelector="R" yChannelSelector="G" />
      </filter>
    </svg>
  );
}
