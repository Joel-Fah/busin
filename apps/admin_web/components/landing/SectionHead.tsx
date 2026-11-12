import { Reveal } from "./motion/Reveal";

type Props = {
  id: string;
  eyebrow: string;
  title: string;
  sub: string;
  /** The section sits on the dark panel (white text). */
  dark?: boolean;
  align?: "left" | "center";
};

/** The opening of a section: a small label, a big title, one calm line. Anchors the nav links jump to. */
export function SectionHead({ id, eyebrow, title, sub, dark = false, align = "left" }: Props) {
  return (
    <Reveal as="header" className={`flex flex-col gap-4 ${align === "center" ? "items-center text-center" : ""}`}>
      <p id={id} className={`m-0 inline-flex w-fit items-center gap-2 rounded-xs px-3 py-1.5 text-sm font-semibold ${dark ? "bg-white/12 text-white" : "bg-surface-2 text-muted"}`}>
        <span aria-hidden className="size-2 rounded-full bg-accent" />
        {eyebrow}
      </p>
      <h2 className={`m-0 max-w-[40rem] text-balance text-4xl font-extrabold tracking-tight sm:text-5xl ${dark ? "text-white" : ""}`}>{title}</h2>
      <p className={`m-0 max-w-[36rem] text-pretty text-lg leading-relaxed ${dark ? "text-white/75" : "text-muted"}`}>{sub}</p>
    </Reveal>
  );
}
