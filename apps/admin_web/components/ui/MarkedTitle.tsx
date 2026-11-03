/** A dialog title with the rough marker highlight under it. Needs <RoughFilter /> on the page. */
export function MarkedTitle({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="relative w-fit max-w-full text-2xl font-extrabold tracking-tight">
      <span aria-hidden className="texture-rough absolute inset-x-[-0.15em] bottom-[0.02em] h-[0.4em] rounded-xs bg-accent/55" />
      <span className="relative">{children}</span>
    </h2>
  );
}
