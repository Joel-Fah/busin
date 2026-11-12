import type { ReactNode } from "react";

type Props = {
  id: string;
  title: string;
  intro?: string;
  children: ReactNode;
};

export function Section({ id, title, intro, children }: Props) {
  return (
    <section id={id} aria-labelledby={`${id}-title`} className="scroll-mt-8 py-10">
      <h2 id={`${id}-title`} className="text-3xl font-extrabold tracking-tight">
        {title}
      </h2>
      {intro ? <p className="mt-2 max-w-2xl text-base text-muted">{intro}</p> : null}
      <div className="mt-6">{children}</div>
    </section>
  );
}

/** A short rule with a do and a do-not column, used where wording matters. */
export function Pair({ doText, dontText }: { doText: string; dontText: string }) {
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      <p className="rounded-md bg-ok-bg p-4 text-sm text-ok">
        <strong className="block">Do</strong>
        {doText}
      </p>
      <p className="rounded-md bg-bad-bg p-4 text-sm text-bad">
        <strong className="block">Do not</strong>
        {dontText}
      </p>
    </div>
  );
}
