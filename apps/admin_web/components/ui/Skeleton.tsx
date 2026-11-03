type Props = {
  className?: string;
};

/**
 * A shimmering placeholder. Give it the size and shape of the thing it stands in for, so the
 * page does not jump when the real content arrives.
 */
export function Skeleton({ className = "" }: Props) {
  return (
    <span
      aria-hidden
      className={
        "block rounded-sm bg-surface-2 " +
        "bg-[linear-gradient(90deg,transparent_25%,color-mix(in_srgb,var(--fg)_8%,transparent)_50%,transparent_75%)] " +
        "bg-[length:200%_100%] animate-[shimmer_1.6s_linear_infinite] motion-reduce:animate-none " +
        className
      }
    />
  );
}
