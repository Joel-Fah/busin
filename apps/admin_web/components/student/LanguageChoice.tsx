import { setLocale } from "@/lib/i18n/actions";
import type { Locale } from "@/lib/i18n/messages";

/** English or French, saved in the same cookie as the portal's choice. A server form, so it works without JavaScript. */
export function LanguageChoice({ locale, label }: { locale: Locale; label: string }) {
  const names: Record<Locale, string> = { en: "English", fr: "Français" };
  return (
    <form action={setLocale} aria-label={label} className="inline-flex w-fit gap-1 rounded-md bg-surface-2 p-1">
      {(["en", "fr"] as const).map((code) => (
        <button
          key={code}
          type="submit"
          name="locale"
          value={code}
          lang={code}
          aria-pressed={locale === code}
          disabled={locale === code}
          className={
            "inline-flex h-10 cursor-pointer items-center justify-center rounded-sm border-0 px-5 font-sans text-sm font-semibold transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus " +
            (locale === code ? "cursor-default bg-surface text-fg shadow-soft" : "bg-transparent text-muted hover:text-fg")
          }
        >
          {names[code]}
        </button>
      ))}
    </form>
  );
}
