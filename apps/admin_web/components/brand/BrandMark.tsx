import { BRAND_PATHS, BRAND_VIEWBOX } from "./paths";

type Props = {
  className?: string;
  /** Accessible name. Leave empty when the mark sits next to text that already says "BusIn". */
  label?: string;
};

/** The wordmark in the current text colour, so it follows the theme. */
export function BrandMark({ className, label }: Props) {
  return (
    <svg
      viewBox={BRAND_VIEWBOX}
      fill="currentColor"
      className={className}
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      {BRAND_PATHS.map((path, index) => (
        <path key={index} d={path.d} fillRule={path.evenodd ? "evenodd" : undefined} />
      ))}
    </svg>
  );
}
