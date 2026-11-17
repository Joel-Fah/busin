// How the payments function answers a refusal from the database (ADR 0029): the database raises a short code with a
// Postgres error code; the apps get the code and an HTTP status, and show their own words for it.

const STATUS_BY_SQLSTATE: Record<string, number> = {
  "42501": 403, // not allowed
  P0002: 404, // not found
  "22023": 400, // bad input
  "55000": 409, // not payable now, payment in progress, mobile money off, fees not set
  "54000": 429, // too many attempts
};

export function refusal(error: { code?: string; message?: string } | null): { status: number; code: string } {
  const code = /^[a-z_]{3,40}$/.test(error?.message ?? "") ? error!.message! : "payment_error";
  return { status: STATUS_BY_SQLSTATE[error?.code ?? ""] ?? 500, code };
}
