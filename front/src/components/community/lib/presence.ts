/**
 * What a stranger may learn about someone's activity on their profile:
 * "online" when online now, "today" when active in the last 24h, otherwise
 * nothing — never an exact "last seen 3h ago". Nothing at all when the person
 * turned off privacySettings.showOnlineStatus.
 */
export type PresenceLabel = "online" | "today" | null;

const DAY_MS = 24 * 60 * 60 * 1000;

export function presenceForStranger(
  member: {
    isOnline?: boolean;
    lastActive?: string;
    lastSeen?: string;
    privacySettings?: { showOnlineStatus?: boolean };
  },
  now: number = Date.now()
): PresenceLabel {
  if (!member) return null;
  if (member.privacySettings?.showOnlineStatus === false) return null;
  if (member.isOnline) return "online";
  const last = member.lastActive || member.lastSeen;
  if (!last) return null;
  const ts = new Date(last).getTime();
  if (Number.isNaN(ts)) return null;
  return now - ts < DAY_MS ? "today" : null;
}

/** Each side learns what the other speaks natively. */
export function isMutualExchange(
  them: { native_language?: string; language_to_learn?: string },
  me: { native_language?: string; language_to_learn?: string } | undefined
): boolean {
  if (!me || !them) return false;
  const norm = (s?: string) => (s || "").trim().toLowerCase();
  const a = norm(them.native_language);
  const b = norm(them.language_to_learn);
  return !!a && !!b && a === norm(me.language_to_learn) && b === norm(me.native_language);
}
