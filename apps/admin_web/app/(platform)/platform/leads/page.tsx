import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { Cancel01Icon, CheckmarkCircle02Icon, Mail01Icon, PlusSignIcon, Undo02Icon } from "@hugeicons/core-free-icons";

import { FlashToast } from "@/components/FlashToast";
import { CopyEmails } from "@/components/platform/CopyEmails";
import { LeadNote } from "@/components/platform/LeadNote";
import { Button, ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip, type ChipTone } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Pager } from "@/components/ui/Pager";
import { StickyToolbar } from "@/components/ui/StickyToolbar";
import { Tabs, type TabItem } from "@/components/ui/Tabs";
import { requirePlatformAdmin } from "@/lib/auth";
import { format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { lastPage, pageRange, parsePage, PAGE_SIZE } from "@/lib/pagination";
import { LEAD_KINDS, LEAD_STATUSES, kindFromParam, leadsHref, parseLeadCounts, parseLeads, statusFromParam, type LeadStatus } from "@/lib/platform-leads";
import { createClient } from "@/lib/supabase/server";

import { saveLeadNote, setLeadStatus } from "./actions";

export const metadata: Metadata = { title: "Leads" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ kind?: string | string[]; status?: string | string[]; page?: string | string[]; done?: string | string[]; error?: string | string[] }>;

const TONES: Record<LeadStatus, ChipTone> = { new: "accent", contacted: "info", converted: "ok", dismissed: "neutral" };
const first = (value: string | string[] | undefined) => (Array.isArray(value) ? value[0] : value);

export default function PlatformLeadsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <Leads searchParams={searchParams} />
    </Suspense>
  );
}

async function Leads({ searchParams }: { searchParams: SearchParams }) {
  await requirePlatformAdmin();
  const { locale, t } = await getMessages();
  const l = t.platform.leads;
  const query = await searchParams;
  const kind = kindFromParam(query.kind);
  const status = statusFromParam(query.status);
  const page = parsePage(query.page);
  const { from } = pageRange(page, PAGE_SIZE);
  const done = first(query.done);
  const failed = first(query.error);

  const supabase = await createClient();
  const [result, countsResult] = await Promise.all([
    supabase.rpc("platform_leads", { p_kind: kind, p_status: status ?? undefined, p_limit: PAGE_SIZE, p_offset: from }),
    supabase.rpc("platform_lead_counts"),
  ]);
  const { leads, total } = parseLeads(result.data);
  const counts = parseLeadCounts(countsResult.data);
  const here = leadsHref(kind, status, page);
  const dateOf = (iso: string) => new Intl.DateTimeFormat(locale, { day: "numeric", month: "short", year: "numeric" }).format(new Date(iso));

  const kindTabs: TabItem[] = LEAD_KINDS.map((k) => ({
    id: k,
    label: l.kinds[k],
    href: leadsHref(k, status),
    count: counts.get(k, "new") || undefined,
    tone: counts.get(k, "new") > 0 ? "accent" : undefined,
  }));
  const statusTabs: TabItem[] = [
    { id: "all", label: l.statuses.all, href: leadsHref(kind, null), count: counts.byKind[kind] },
    ...LEAD_STATUSES.map((s) => ({ id: s, label: l.statuses[s], href: leadsHref(kind, s), count: counts.get(kind, s) })),
  ];

  const statusButton = (leadId: string, to: LeadStatus, label: string, icon: typeof Mail01Icon, variant: "secondary" | "ghost" = "ghost") => (
    <form action={setLeadStatus}>
      <input type="hidden" name="lead" value={leadId} />
      <input type="hidden" name="status" value={to} />
      <input type="hidden" name="back" value={here} />
      <Button type="submit" variant={variant} icon={icon}>
        {label}
      </Button>
    </form>
  );

  return (
    <>
      {done && done in l.done ? <FlashToast message={l.done[done as keyof typeof l.done]} /> : null}
      <PageHeader
        title={l.title}
        help={{
          label: t.help.open,
          title: l.help.title,
          intro: l.help.intro,
          scenarios: Object.values(l.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
        action={kind === "notify" ? <CopyEmails emails={leads.map((lead) => lead.email)} label={l.copyEmails} copied={l.copied} /> : undefined}
      />

      <StickyToolbar>
        <Tabs label={l.kindLabel} items={kindTabs} active={kind} />
        <Tabs label={l.statusLabel} items={statusTabs} active={status ?? "all"} />
      </StickyToolbar>

      {failed ? <Notice tone="bad">{failed === "note_too_long" ? l.errors.note_too_long : l.errors.generic}</Notice> : null}

      {result.error ? (
        <Notice tone="bad">{l.loadError}</Notice>
      ) : leads.length === 0 ? (
        <EmptyState title={l.empty} />
      ) : (
        <ul className="m-0 flex list-none flex-col gap-3 p-0" data-testid="leads">
          {leads.map((lead) => (
            <li key={lead.id} data-lead={lead.id}>
              <Card className="flex flex-col gap-3 p-5!">
                <div className="flex flex-wrap items-start justify-between gap-2">
                  <div className="min-w-0">
                    <p className="m-0 truncate text-lg font-bold">{lead.kind === "school" ? (lead.organisation ?? lead.name ?? lead.email) : lead.email}</p>
                    <p className="m-0 flex flex-wrap gap-x-2 text-sm text-muted">
                      {lead.kind === "school" && lead.name ? <span>{lead.name}</span> : null}
                      {lead.kind === "school" ? (
                        <a href={`mailto:${lead.email}`} className="inline-flex items-center gap-1 font-semibold text-link no-underline">
                          <Icon icon={Mail01Icon} size={14} />
                          {lead.email}
                        </a>
                      ) : null}
                      <span>{format(l.received, { date: dateOf(lead.createdAt) })}</span>
                      <span>{l.language[lead.locale]}</span>
                    </p>
                  </div>
                  <Chip tone={TONES[lead.status]}>{l.statuses[lead.status]}</Chip>
                </div>
                {lead.message ? <p className="m-0 line-clamp-3 whitespace-pre-line text-sm">{lead.message}</p> : null}
                {lead.note ? (
                  <p className="m-0 rounded-md bg-surface-2/60 px-3 py-2 text-sm">
                    <span className="font-semibold">{l.note}: </span>
                    {lead.note}
                  </p>
                ) : null}
                {lead.schoolId && lead.schoolName ? (
                  <Link href={`/platform/schools/${lead.schoolId}`} className="text-sm font-semibold text-link no-underline">
                    {format(l.became, { school: lead.schoolName })}
                  </Link>
                ) : null}
                <div className="flex flex-wrap items-center gap-1.5">
                  {lead.kind === "school" && lead.status !== "converted" ? (
                    <ButtonLink href={`/platform/schools/new?lead=${lead.id}`} icon={PlusSignIcon}>
                      {l.createSchool}
                    </ButtonLink>
                  ) : null}
                  {lead.status === "new" ? statusButton(lead.id, "contacted", l.markContacted, CheckmarkCircle02Icon, "secondary") : null}
                  {lead.status === "new" || lead.status === "contacted" ? statusButton(lead.id, "dismissed", l.dismiss, Cancel01Icon) : null}
                  {lead.status === "dismissed" || lead.status === "contacted" ? statusButton(lead.id, "new", l.reopen, Undo02Icon) : null}
                  <LeadNote
                    leadId={lead.id}
                    status={lead.status}
                    note={lead.note}
                    back={here}
                    text={{ note: l.note, notePlaceholder: l.notePlaceholder, saveNote: l.saveNote, cancel: t.platform.onboarding.status.cancel }}
                    action={saveLeadNote}
                  />
                </div>
              </Card>
            </li>
          ))}
        </ul>
      )}

      {total > PAGE_SIZE ? (
        <Pager
          range={format(l.range, { from: from + 1, to: from + leads.length, total })}
          label={l.paginationLabel}
          previous={page > 1 ? { href: leadsHref(kind, status, page - 1), label: l.previous } : undefined}
          next={page < lastPage(total, PAGE_SIZE) ? { href: leadsHref(kind, status, page + 1), label: l.next } : undefined}
        />
      ) : null}
    </>
  );
}
