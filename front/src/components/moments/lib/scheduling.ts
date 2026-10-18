/**
 * Scheduled moments: a moment whose `scheduledFor` is ahead is visible only
 * to its author until then (enforced by the server behind
 * MOMENT_SCHEDULING_ENFORCED, which /app-config reports).
 */
const parse = (value: unknown): number => {
  if (!value) return NaN;
  return new Date(value as string).getTime();
};

export function isScheduledLater(moment: { scheduledFor?: string | null }, now: number = Date.now()): boolean {
  const at = parse(moment && moment.scheduledFor);
  return !isNaN(at) && at > now;
}

/** A `datetime-local` value (the reader's local time) as an ISO instant. */
export function localInputToIso(value: string): string | null {
  const at = parse(value);
  return isNaN(at) ? null : new Date(at).toISOString();
}

const pad = (n: number) => String(n).padStart(2, "0");

/** A local time as a `datetime-local` value. */
export function toLocalInput(at: number | string | Date): string {
  const d = new Date(at);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** The earliest pickable value: the next whole minute, in local time. */
export function minScheduleInput(now: number = Date.now()): string {
  return toLocalInput(Math.floor(now / 60000) * 60000 + 60000);
}

export function isFutureInput(value: string, now: number = Date.now()): boolean {
  const at = parse(value);
  return !isNaN(at) && at > now;
}
