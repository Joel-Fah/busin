import { HelpSheet, type HelpContent } from "./HelpSheet";

type Props = {
  title: string;
  subtitle?: string;
  /** When given, a help button beside the headline opens a side sheet with worked examples. */
  help?: HelpContent;
};

export function PageHeader({ title, subtitle, help }: Props) {
  return (
    <header>
      <div className="flex items-center gap-3">
        <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">{title}</h1>
        {help ? <HelpSheet {...help} /> : null}
      </div>
      {subtitle ? <p className="mt-2 max-w-2xl text-base text-muted">{subtitle}</p> : null}
    </header>
  );
}
