/**
 * How long a mute lasts. The backend takes `duration` in ms and stores
 * mutedUntil = now + duration; no duration means until unmuted, which is what
 * the app sends today.
 */
export interface MuteDuration {
  id: "1h" | "8h" | "1w" | "always";
  ms: number | null;
  key: string;
  fallback: string;
}

const HOUR = 60 * 60 * 1000;

export const MUTE_DURATIONS: MuteDuration[] = [
  { id: "1h", ms: HOUR, key: "chatPage.mute.oneHour", fallback: "For 1 hour" },
  { id: "8h", ms: 8 * HOUR, key: "chatPage.mute.eightHours", fallback: "For 8 hours" },
  { id: "1w", ms: 7 * 24 * HOUR, key: "chatPage.mute.oneWeek", fallback: "For 1 week" },
  { id: "always", ms: null, key: "chatPage.mute.always", fallback: "Until I turn it back on" },
];

export function muteArgs(conversationId: string, ms: number | null): { conversationId: string; duration?: number } {
  return ms ? { conversationId: conversationId, duration: ms } : { conversationId: conversationId };
}
