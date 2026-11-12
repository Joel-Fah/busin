type Props = {
  name: string;
  url: string | null;
  /** Pixel size of the square. */
  size?: number;
  className?: string;
};

export function initials(name: string): string {
  const letters = name
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => word[0]);
  return letters.join("").toUpperCase() || "?";
}

/** A profile picture, or the person's initials when there is none. */
export function Avatar({ name, url, size = 40, className = "" }: Props) {
  const box = { width: size, height: size };
  return url ? (
    // The picture comes from the sign-in provider or storage; the host is not fixed, so it is not optimised.
    // eslint-disable-next-line @next/next/no-img-element
    <img src={url} alt="" referrerPolicy="no-referrer" style={box} className={`aspect-square shrink-0 rounded-sm object-cover ${className}`} />
  ) : (
    <span
      aria-hidden
      style={{ ...box, fontSize: size * 0.38 }}
      className={`inline-flex aspect-square shrink-0 items-center justify-center rounded-sm bg-surface-2 font-bold text-fg ${className}`}
    >
      {initials(name)}
    </span>
  );
}
