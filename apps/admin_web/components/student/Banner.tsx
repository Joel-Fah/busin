import Image from "next/image";

import { Contour } from "@/components/ui/Contour";

/**
 * The deep teal greeting at the top of the subscription tab, as the app's banner: the seed teal in both themes, the
 * stitched thread in soft white, the date, a hello with the student's first name and a marker under it, the semester, and
 * an illustration that says where the request stands.
 */
export function Banner({ eyebrow, title, lines, art }: { eyebrow: string; title: string; lines: string[]; art: string }) {
  return (
    <section className="texture-grain relative flex min-h-44 items-end gap-4 overflow-hidden rounded-xl bg-seed p-7 text-white shadow-soft [--grain:0.8] [--thread-color:rgb(255_255_255/0.26)]">
      <Contour radius={36} inset={12} />
      <div className="relative z-10 flex min-w-0 flex-1 flex-col gap-1">
        <p className="m-0 text-sm font-semibold text-white/70">{eyebrow}</p>
        <h1 className="relative m-0 w-fit text-3xl leading-tight font-extrabold tracking-tight">
          <span aria-hidden className="texture-rough absolute inset-x-[-0.1em] bottom-[0.06em] h-[0.32em] rounded-xs bg-accent/70" />
          <span className="relative">{title}</span>
        </h1>
        {lines.map((line) => (
          <p key={line} className="m-0 text-white/85">
            {line}
          </p>
        ))}
      </div>
      <Image src={`/illustrations/${art}.webp`} alt="" width={112} height={112} className="relative z-0 -mr-2 size-24 shrink-0 self-center object-contain sm:size-28" />
    </section>
  );
}
