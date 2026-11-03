import { HugeiconsIcon, type IconSvgElement } from "@hugeicons/react";

type Props = {
  icon: IconSvgElement;
  /** Pixel size. Icons are decorative unless a label is given. */
  size?: number;
  label?: string;
  className?: string;
};

/** The single door to Hugeicons, so size and stroke stay consistent across the portal. */
export function Icon({ icon, size = 20, label, className }: Props) {
  return (
    <HugeiconsIcon
      icon={icon}
      size={size}
      strokeWidth={1.8}
      className={className}
      aria-hidden={label ? undefined : true}
      aria-label={label}
      role={label ? "img" : undefined}
    />
  );
}
