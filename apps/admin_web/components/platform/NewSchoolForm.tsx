"use client";

import { useActionState } from "react";
import { Building03Icon, Clock01Icon, Location01Icon, Mail01Icon, PlusSignIcon, TextIcon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { CountrySelect } from "@/components/ui/CountrySelect";
import { Input } from "@/components/ui/Input";
import { Notice } from "@/components/ui/Notice";
import { DomainsTagInput } from "@/components/ui/TagInput";
import type { Messages } from "@/lib/i18n/messages";
import type { CreateSchoolState } from "@/app/(platform)/platform/schools/new/actions";

type Props = {
  action: (state: CreateSchoolState, formData: FormData) => Promise<CreateSchoolState>;
  text: Messages["platform"]["onboarding"];
  locale: "en" | "fr";
  timeZones: string[];
  /** Prefilled values (for example from a lead), all optional. */
  initial?: { name?: string; adminEmail?: string };
};

/**
 * The new school form: the school (name, short name, country, city, time zone, student email domains) and its first
 * administrator. Everything else is set up by that administrator in the school's portal. A refused form keeps what was
 * typed and says what to fix.
 */
export function NewSchoolForm({ action, text, locale, timeZones, initial }: Props) {
  const [state, formAction, pending] = useActionState(action, { error: null });
  const error = state.error;
  const typed = state.typed;
  const on = (...keys: string[]) => (error && keys.includes(error) ? text.errors[error as keyof typeof text.errors] : undefined);

  return (
    <form action={formAction} className="flex flex-col gap-6" noValidate>
      {error && !on("bad_name", "name_taken", "bad_short_name", "bad_timezone", "bad_city", "bad_country", "bad_domain", "too_many_domains", "domain_taken", "invalid_email", "other_school") ? (
        <Notice tone="bad">{text.errors[error]}</Notice>
      ) : null}

      <Card className="flex flex-col gap-4">
        <h2 className="text-xl font-bold">{text.school}</h2>
        <div className="grid gap-4 sm:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
          <Input id="name" name="name" label={text.name} icon={Building03Icon} required maxLength={120} defaultValue={typed?.name ?? initial?.name} error={on("bad_name", "name_taken")} />
          <Input id="short_name" name="short_name" label={text.shortName} icon={TextIcon} maxLength={20} hint={text.shortNameHint} defaultValue={typed?.shortName} error={on("bad_short_name")} />
        </div>
        <div className="grid gap-4 sm:grid-cols-3">
          <CountrySelect id="country" name="country" label={text.country} locale={locale} defaultValue={typed?.country || null} error={on("bad_country")} />
          <Input id="city" name="city" label={text.city} icon={Location01Icon} maxLength={80} defaultValue={typed?.city} error={on("bad_city")} />
          <div>
            <Input
              id="timezone"
              name="timezone"
              label={text.timezone}
              icon={Clock01Icon}
              list="timezones"
              autoComplete="off"
              required
              defaultValue={typed?.timezone}
              hint={text.timezoneHint}
              error={on("bad_timezone")}
            />
            <datalist id="timezones">
              {timeZones.map((zone) => (
                <option key={zone} value={zone} />
              ))}
            </datalist>
          </div>
        </div>
        <DomainsTagInput
          id="domains"
          name="domains"
          label={text.domains}
          hint={on("bad_domain", "too_many_domains", "domain_taken") ?? text.domainsHint}
          placeholder={text.domainsPlaceholder}
          removeLabel={text.removeDomain}
        />
      </Card>

      <Card className="flex flex-col gap-4">
        <h2 className="text-xl font-bold">{text.admin}</h2>
        <Input
          id="admin_email"
          name="admin_email"
          type="email"
          label={text.adminEmail}
          icon={Mail01Icon}
          maxLength={254}
          defaultValue={typed?.adminEmail ?? initial?.adminEmail}
          hint={text.adminHint}
          error={on("invalid_email", "other_school")}
        />
      </Card>

      <div>
        <Button type="submit" icon={PlusSignIcon} disabled={pending}>
          {text.create}
        </Button>
      </div>
    </form>
  );
}
