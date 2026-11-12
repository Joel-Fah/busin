import { setLocale } from "@/lib/i18n/actions";
import type { Locale, Messages } from "@/lib/i18n/messages";

/** Two choices that save the language. A server form, so it works without client JavaScript. */
export function LanguageSwitch({ locale, t, compact = false }: { locale: Locale; t: Messages; compact?: boolean }) {
  return (
    <form action={setLocale} aria-label={t.language.label} className="inline-flex w-fit gap-1 rounded-md bg-surface-2 p-1">
      {(["en", "fr"] as const).map((code) => (
        <button
          key={code}
          type="submit"
          name="locale"
          value={code}
          aria-pressed={locale === code}
          lang={code}
          disabled={locale === code}
          aria-label={compact ? t.language[code] : undefined}
          title={compact ? t.language[code] : undefined}
          className={
            "inline-flex h-10 cursor-pointer items-center justify-center rounded-sm border-0 font-sans text-sm font-semibold " +
            (compact ? "min-w-10 px-2.5 " : "px-5 ") +
            "transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus " +
            (locale === code ? "cursor-default bg-surface text-fg shadow-soft" : "bg-transparent text-muted hover:text-fg")
          }
        >
          {compact ? code.toUpperCase() : t.language[code]}
        </button>
      ))}
    </form>
  );
}
