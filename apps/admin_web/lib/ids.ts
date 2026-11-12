const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** True for a well-formed uuid. Used to refuse malformed ids before they reach the database. */
export function isUuid(value: unknown): value is string {
  return typeof value === "string" && UUID.test(value);
}
