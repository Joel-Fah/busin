/**
 * Account lookup in the platform console (ADR 0027, slice 7): where one account stands, read safely from what
 * `platform_lookup_account` returns.
 */

export type LookedUp = {
  found: boolean;
  id: string | null;
  email: string | null;
  fullName: string | null;
  avatarUrl: string | null;
  role: "student" | "staff" | "admin" | null;
  status: "pending" | "verified" | "suspended" | null;
  schoolId: string | null;
  schoolName: string | null;
  createdAt: string | null;
  lastSignInAt: string | null;
  provider: string | null;
  joinRequestedAt: string | null;
  joinDeclinedAt: string | null;
  staffRequestedAt: string | null;
  staffRequestSchool: string | null;
  staffDeclinedAt: string | null;
  platformAdmin: boolean;
  subscriptions: Record<string, number>;
  devices: number;
  invite: { schoolId: string | null; schoolName: string | null; role: string | null; expiresAt: string | null } | null;
};

type Raw = Record<string, unknown>;
const record = (value: unknown): Raw => (value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Raw) : {});
const text = (value: unknown): string | null => (typeof value === "string" && value.trim() !== "" ? value : null);
const count = (value: unknown): number => {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : 0;
};

const ROLES = ["student", "staff", "admin"] as const;
const STATUSES = ["pending", "verified", "suspended"] as const;

export function parseLookup(value: unknown): LookedUp {
  const raw = record(value);
  const invite = raw.invite ? record(raw.invite) : null;
  const subscriptions: Record<string, number> = {};
  for (const [status, n] of Object.entries(record(raw.subscriptions))) if (count(n) > 0) subscriptions[status] = count(n);
  return {
    found: raw.found === true,
    id: text(raw.id),
    email: text(raw.email),
    fullName: text(raw.full_name),
    avatarUrl: text(raw.avatar_url),
    role: (ROLES as readonly unknown[]).includes(raw.role) ? (raw.role as LookedUp["role"]) : null,
    status: (STATUSES as readonly unknown[]).includes(raw.status) ? (raw.status as LookedUp["status"]) : null,
    schoolId: text(raw.school_id),
    schoolName: text(raw.school_name),
    createdAt: text(raw.created_at),
    lastSignInAt: text(raw.last_sign_in_at),
    provider: text(raw.provider),
    joinRequestedAt: text(raw.join_requested_at),
    joinDeclinedAt: text(raw.join_declined_at),
    staffRequestedAt: text(raw.staff_requested_at),
    staffRequestSchool: text(raw.staff_request_school),
    staffDeclinedAt: text(raw.staff_declined_at),
    platformAdmin: raw.platform_admin === true,
    subscriptions,
    devices: count(raw.devices),
    invite: invite ? { schoolId: text(invite.school_id), schoolName: text(invite.school_name), role: text(invite.role), expiresAt: text(invite.expires_at) } : null,
  };
}

export const LOOKUP_ERRORS = ["invalid_email", "too_many", "generic"] as const;
export type LookupError = (typeof LOOKUP_ERRORS)[number];

export function lookupErrorKey(message: string | null | undefined): LookupError {
  const key = (message ?? "").trim();
  return key === "invalid_email" || key === "too_many" ? key : "generic";
}
