/** Offset of `timeZone` from UTC at the instant `at`, in milliseconds (east is positive). */
export function zoneOffsetMs(timeZone: string, at: Date): number {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).formatToParts(at);
  const value = (type: string) => Number(parts.find((part) => part.type === type)?.value);
  const asUtc = Date.UTC(
    value("year"),
    value("month") - 1,
    value("day"),
    value("hour"),
    value("minute"),
    value("second"),
  );
  return asUtc - Math.floor(at.getTime() / 1000) * 1000;
}

/**
 * The instant at which the calendar day containing `now` began in `timeZone`.
 * Used to count "today" in the school's own timezone rather than the server's.
 */
export function startOfDayInTimeZone(timeZone: string, now: Date): Date {
  const ymd = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  const [year, month, day] = ymd.split("-").map(Number);

  const localMidnightAsUtc = Date.UTC(year, month - 1, day);
  const first = localMidnightAsUtc - zoneOffsetMs(timeZone, new Date(localMidnightAsUtc));
  // The offset can differ at the corrected instant on a daylight saving change day.
  const second = localMidnightAsUtc - zoneOffsetMs(timeZone, new Date(first));
  return new Date(second);
}
