/**
 * Leads from the landing page in the platform console (ADR 0027, slice 5): schools that want BusIn and people who asked
 * to be told when the apps are out. What the database returns, read safely, and the filters in the address.
 */

/** "deletion": someone who cannot sign in asked for their account's deletion (ADR 0028). */
export const LEAD_KINDS = ["school", "notify", "deletion"] as const;
export type LeadKind = (typeof LEAD_KINDS)[number];
export const LEAD_STATUSES = ["new", "contacted", "converted", "dismissed"] as const;
export type LeadStatus = (typeof LEAD_STATUSES)[number];

export type Lead = {
  id: string;
  kind: LeadKind;
  name: string | null;
  organisation: string | null;
  email: string;
  message: string | null;
  locale: "en" | "fr";
  createdAt: string;
  status: LeadStatus;
  handledAt: string | null;
  note: string | null;
  schoolId: string | null;
  schoolName: string | null;
};

type Raw = Record<string, unknown>;
const record = (value: unknown): Raw => (value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Raw) : {});
const text = (value: unknown): string | null => (typeof value === "string" && value.trim() !== "" ? value : null);
const first = (value: string | string[] | undefined) => (Array.isArray(value) ? value[0] : value);

export function isLeadKind(value: unknown): value is LeadKind {
  return typeof value === "string" && (LEAD_KINDS as readonly string[]).includes(value);
}

export function isLeadStatus(value: unknown): value is LeadStatus {
  return typeof value === "string" && (LEAD_STATUSES as readonly string[]).includes(value);
}

/** The kind in the address; school leads by default, since they are the ones to act on. */
export function kindFromParam(value: string | string[] | undefined): LeadKind {
  const kind = first(value);
  return isLeadKind(kind) ? kind : "school";
}

/** The status in the address, or every status. */
export function statusFromParam(value: string | string[] | undefined): LeadStatus | null {
  const status = first(value);
  return isLeadStatus(status) ? status : null;
}

/** The page of leads and the total for the pager. Rows the console cannot read are left out. */
export function parseLeads(value: unknown): { leads: Lead[]; total: number } {
  const rows = (Array.isArray(value) ? value : []).map(record);
  const leads = rows
    .filter((r) => text(r.id) && isLeadKind(r.kind) && text(r.email) && text(r.created_at))
    .map(
      (r): Lead => ({
        id: r.id as string,
        kind: r.kind as LeadKind,
        name: text(r.name),
        organisation: text(r.organisation),
        email: r.email as string,
        message: text(r.message),
        locale: r.locale === "fr" ? "fr" : "en",
        createdAt: r.created_at as string,
        status: isLeadStatus(r.status) ? r.status : "new",
        handledAt: text(r.handled_at),
        note: text(r.note),
        schoolId: text(r.school_id),
        schoolName: text(r.school_name),
      }),
    );
  const total = Number(rows[0]?.total ?? 0);
  return { leads, total: Number.isFinite(total) ? total : leads.length };
}

/** {"school:new": 3, ...} as counts by kind, and by kind and status. */
export function parseLeadCounts(value: unknown): { byKind: Record<LeadKind, number>; get: (kind: LeadKind, status: LeadStatus) => number } {
  const raw = record(value);
  const n = (key: string) => {
    const v = Number(raw[key]);
    return Number.isFinite(v) && v > 0 ? v : 0;
  };
  const byKind = { school: 0, notify: 0, deletion: 0 } as Record<LeadKind, number>;
  for (const kind of LEAD_KINDS) for (const status of LEAD_STATUSES) byKind[kind] += n(`${kind}:${status}`);
  return { byKind, get: (kind, status) => n(`${kind}:${status}`) };
}

/** The leads list's address with these filters (the first page unless one is given). */
export function leadsHref(kind: LeadKind, status: LeadStatus | null, page = 1): string {
  const params = new URLSearchParams({ kind });
  if (status) params.set("status", status);
  if (page > 1) params.set("page", String(page));
  return `/platform/leads?${params.toString()}`;
}
