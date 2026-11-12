import {
  ArrowRight01Icon,
  BlockGameIcon,
  Building03Icon,
  City03Icon,
  Flag02Icon,
  Globe02Icon,
  Location01Icon,
  Mail01Icon,
  SmartPhone01Icon,
  Tag01Icon,
  TextIcon,
} from "@hugeicons/core-free-icons";
import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { FlashToast } from "@/components/FlashToast";
import { LogoPicker } from "@/components/school/LogoPicker";
import { OpenSignupFields } from "@/components/school/OpenSignupFields";
import { Accordion } from "@/components/ui/Accordion";
import { BackLink } from "@/components/ui/BackLink";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
import { Switch } from "@/components/ui/Choice";
import { Input } from "@/components/ui/Input";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Textarea } from "@/components/ui/Textarea";
import { requireAdmin } from "@/lib/auth";
import { supabaseConfig } from "@/lib/env";
import { format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { schoolTerms } from "@/lib/legal/school-terms";
import { first } from "@/lib/pagination";
import { SCHOOL_LIMITS, SCHOOL_TERMS_VERSION, logoUrl, type SchoolSaveError } from "@/lib/school";
import { createClient } from "@/lib/supabase/server";

import { acceptSchoolTerms, removeSchoolLogo, saveFieldTrips, saveSchoolProfile, uploadSchoolLogo } from "./actions";

export const metadata: Metadata = { title: "School profile" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

const ERRORS: readonly SchoolSaveError[] = ["name", "shortName", "website", "contactEmail", "phone", "address", "city", "country", "about", "openDomains", "terms_first", "generic"];

export default function SchoolPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={4} />}>
      <School searchParams={searchParams} />
    </Suspense>
  );
}

/** The school profile: logo, details, who may join, whether the school is shown publicly, and the terms for schools. */
async function School({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const s = t.school;
  const query = await searchParams;
  const done = first(query.done);
  const errorParam = first(query.error);
  const error = ERRORS.find((key) => key === errorParam) ?? null;

  const supabase = await createClient();
  const [{ data: school }, { data: domains }] = await Promise.all([
    supabase
      .from("schools")
      .select("name, short_name, website, contact_email, phone, address, city, country, about, logo_path, accepts_open_signup, open_signup_domains, public_listing, allow_field_trips, terms_version, terms_accepted_at")
      .eq("id", admin.schoolId)
      .maybeSingle(),
    supabase.from("school_domains").select("domain").eq("school_id", admin.schoolId).order("domain").limit(20),
  ]);
  if (!school) return <Notice tone="bad">{s.errors.generic}</Notice>;

  const accepted = Boolean(school.terms_accepted_at);
  const outdated = accepted && school.terms_version !== SCHOOL_TERMS_VERSION;
  const terms = schoolTerms[locale];
  const acceptedOn = school.terms_accepted_at
    ? new Intl.DateTimeFormat(locale, { dateStyle: "long", timeZone: admin.schoolTimezone }).format(new Date(school.terms_accepted_at))
    : "";

  return (
    <>
      <BackLink href="/profile">{s.back}</BackLink>
      <PageHeader title={s.title} subtitle={s.subtitle} />

      {done === "saved" ? <FlashToast message={s.saved} /> : done === "terms" ? <FlashToast message={s.terms.done} /> : done === "field_trips" ? <FlashToast message={s.fieldTrips.done} /> : null}
      {error ? <Notice tone="bad">{s.errors[error]}</Notice> : null}

      <Card className="flex flex-col gap-4">
        <h2 className="text-xl font-bold">{s.logo.title}</h2>
        <p className="-mt-2 text-sm text-muted">{s.logo.hint}</p>
        <LogoPicker url={logoUrl(school.logo_path, supabaseConfig().url)} schoolName={school.name} copy={s.logo} upload={uploadSchoolLogo} remove={removeSchoolLogo} />
      </Card>

      <Link href="/academics" className="group block no-underline">
        <Card className="flex items-center gap-4 transition-transform duration-(--dur) ease-soft group-hover:-translate-y-0.5 motion-reduce:transition-none">
          <span className="grid size-11 shrink-0 place-items-center rounded-md bg-surface-2 text-fg">
            <Icon icon={BlockGameIcon} size={22} />
          </span>
          <span className="flex min-w-0 flex-1 flex-col">
            <span className="text-lg font-bold text-fg">{s.academics.title}</span>
            <span className="text-sm text-muted">{s.academics.body}</span>
          </span>
          <span className="hidden text-sm font-semibold text-fg sm:inline">{s.academics.open}</span>
          <Icon icon={ArrowRight01Icon} size={20} className="shrink-0 text-muted" />
        </Card>
      </Link>

      <form action={saveSchoolProfile} className="flex flex-col gap-6">
        <Card className="flex flex-col gap-5">
          <div>
            <h2 className="text-xl font-bold">{s.details.title}</h2>
            <p className="mt-1 text-sm text-muted">{s.details.hint}</p>
          </div>
          <div className="grid gap-5 md:grid-cols-2">
            <Input id="name" name="name" label={s.fields.name} icon={Building03Icon} required maxLength={SCHOOL_LIMITS.name} defaultValue={school.name} placeholder={s.placeholders.name} />
            <Input
              id="short_name"
              name="short_name"
              label={s.fields.shortName}
              icon={Tag01Icon}
              maxLength={SCHOOL_LIMITS.shortName}
              defaultValue={school.short_name ?? ""}
              placeholder={s.placeholders.shortName}
              hint={s.fields.shortNameHint}
            />
            <Input id="website" name="website" type="url" label={s.fields.website} icon={Globe02Icon} maxLength={SCHOOL_LIMITS.website} defaultValue={school.website ?? ""} placeholder={s.placeholders.website} />
            <Input
              id="contact_email"
              name="contact_email"
              type="email"
              label={s.fields.contactEmail}
              icon={Mail01Icon}
              maxLength={SCHOOL_LIMITS.email}
              defaultValue={school.contact_email ?? ""}
              placeholder={s.placeholders.contactEmail}
            />
            <Input id="phone" name="phone" type="tel" label={s.fields.phone} icon={SmartPhone01Icon} maxLength={SCHOOL_LIMITS.phone} defaultValue={school.phone ?? ""} placeholder={s.placeholders.phone} />
            <Input id="address" name="address" label={s.fields.address} icon={Location01Icon} maxLength={SCHOOL_LIMITS.address} defaultValue={school.address ?? ""} placeholder={s.placeholders.address} />
            <Input id="city" name="city" label={s.fields.city} icon={City03Icon} maxLength={SCHOOL_LIMITS.city} defaultValue={school.city ?? ""} placeholder={s.placeholders.city} />
            <Input id="country" name="country" label={s.fields.country} icon={Flag02Icon} maxLength={SCHOOL_LIMITS.country} defaultValue={school.country ?? ""} placeholder={s.placeholders.country} />
          </div>
          <Textarea id="about" name="about" label={s.fields.about} icon={TextIcon} maxLength={SCHOOL_LIMITS.about} rows={3} defaultValue={school.about ?? ""} placeholder={s.placeholders.about} hint={s.fields.aboutHint} />
        </Card>

        <Card className="flex flex-col gap-4">
          <h2 className="text-xl font-bold">{s.joining.title}</h2>
          {domains && domains.length > 0 ? (
            <div className="flex flex-col gap-2">
              <p className="text-sm text-muted">{s.joining.domains}</p>
              <ul className="m-0 flex list-none flex-wrap gap-2 p-0">
                {domains.map((row) => (
                  <li key={row.domain} className="rounded-xs bg-surface-2 px-2.5 py-1 font-mono text-sm">
                    @{row.domain}
                  </li>
                ))}
              </ul>
            </div>
          ) : (
            <p className="text-sm text-muted">{s.joining.noDomains}</p>
          )}
          <OpenSignupFields
            accepts={school.accepts_open_signup}
            domains={school.open_signup_domains}
            copy={{ ...s.joining, remove: s.logo.remove }}
          />
          <Switch name="public_listing" label={s.listing.title} hint={accepted ? s.listing.hint : s.listing.needsTerms} defaultChecked={school.public_listing} disabled={!accepted} />
        </Card>

        <div>
          <Button type="submit">{s.save}</Button>
        </div>
      </form>

      <form action={saveFieldTrips}>
        <Card className="flex flex-col gap-4">
          <h2 className="text-xl font-bold">{s.fieldTrips.title}</h2>
          <Switch name="allow_field_trips" label={s.fieldTrips.label} hint={s.fieldTrips.hint} defaultChecked={school.allow_field_trips} />
          <div>
            <Button type="submit" variant="secondary">
              {s.fieldTrips.save}
            </Button>
          </div>
        </Card>
      </form>

      <Card className="flex flex-col gap-4">
        <h2 className="text-xl font-bold">{s.terms.title}</h2>
        <p className="text-sm text-muted">{accepted ? format(s.terms.accepted, { date: acceptedOn, version: school.terms_version ?? "" }) : s.terms.notAccepted}</p>
        {outdated ? <Notice tone="warn">{s.terms.newVersion}</Notice> : null}
        <p className="text-sm">{terms.summary}</p>
        <Accordion summary={<span className="font-semibold">{s.terms.read}</span>}>
          <div className="flex flex-col gap-4">
            {terms.sections.map((section) => (
              <div key={section.title}>
                <h3 className="text-base font-bold">{section.title}</h3>
                <p className="mt-1 text-sm leading-relaxed text-muted">{section.body}</p>
              </div>
            ))}
          </div>
        </Accordion>
        {!accepted || outdated ? (
          <form action={acceptSchoolTerms} className="flex flex-col items-start gap-2">
            <p className="text-sm text-muted">{s.terms.acceptHint}</p>
            <Button type="submit">{s.terms.accept}</Button>
          </form>
        ) : null}
      </Card>
    </>
  );
}
