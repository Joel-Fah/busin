import { setLocale } from "@/lib/i18n/actions";
import type { Locale, Messages } from "@/lib/i18n/messages";

/** Two small buttons that save the language. Works without client JavaScript. */
export function LanguageSwitch({ locale, t }: { locale: Locale; t: Messages }) {
  return (
    <form action={setLocale} className="row" aria-label={t.language.label}>
      {(["en", "fr"] as const).map((code) => (
        <button
          key={code}
          type="submit"
          name="locale"
          value={code}
          className="btn btn-secondary"
          aria-pressed={locale === code}
          lang={code}
          disabled={locale === code}
        >
          {t.language[code]}
        </button>
      ))}
    </form>
  );
}
