import { Gathering } from "../../../store/slices/gatheringsSlice";

type T = (key: string, opts?: any) => string;

const validZone = (zone?: string | null): string | undefined => {
  if (!zone) return undefined;
  try {
    new Intl.DateTimeFormat("en", { timeZone: zone });
    return zone;
  } catch (e) {
    return undefined;
  }
};

/** "Sun, Nov 1, 7:00 PM" in the viewer's language (and a zone, for tests and the host line). */
export function formatGatheringTime(iso: string, lang: string, timeZone?: string | null): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const opts: Intl.DateTimeFormatOptions = {
    weekday: "short",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  };
  const zone = validZone(timeZone);
  if (zone) opts.timeZone = zone;
  try {
    return new Intl.DateTimeFormat(lang || "en", opts).format(d);
  } catch (e) {
    return new Intl.DateTimeFormat("en", opts).format(d);
  }
}

/** The viewer's own zone; injectable for tests. */
export function viewerZone(): string | undefined {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  } catch (e) {
    return undefined;
  }
}

/**
 * The start time in the host's zone, only when it differs from the viewer's
 * (lib/utils/gathering_time.dart does the same): "7:00 PM for the host".
 */
export function hostLocalTime(g: Gathering, lang: string, viewer?: string | null): string | null {
  const hostZone = validZone(g.hostTimezone);
  if (!hostZone) return null;
  const mine = validZone(viewer === undefined ? viewerZone() : viewer);
  if (mine && formatGatheringTime(g.startsAt, "en", mine) === formatGatheringTime(g.startsAt, "en", hostZone)) {
    return null;
  }
  return formatGatheringTime(g.startsAt, lang, hostZone);
}

export function minutesUntil(iso: string, now: Date): number {
  return Math.round((new Date(iso).getTime() - now.getTime()) / 60000);
}

/**
 * The host's "run it anyway / call it off" question. The app asks when quorum
 * is unmet and the start is <= 120 minutes away (backend HOST_DECISION_HOURS);
 * the web also requires `scheduled`, so the question goes away once answered.
 */
export function isHostDecisionDue(g: Gathering, now: Date): boolean {
  if (!g.viewerIsHost || g.status !== "scheduled") return false;
  const met = g.quorumMet !== undefined ? g.quorumMet : g.needed === 0;
  if (met) return false;
  return minutesUntil(g.startsAt, now) <= 120;
}

export function seatsLeft(g: Gathering): number {
  return Math.max(0, (g.capacity || 0) - (g.going || 0));
}

export function statusLabel(status: string, t: T): string {
  switch (status) {
    case "cancelled":
      return t("gatherings.status.cancelled") || "Cancelled";
    case "ended":
      return t("gatherings.status.ended") || "Ended";
    case "live":
      return t("gatherings.status.live") || "Happening now";
    case "confirmed":
      return t("gatherings.status.confirmed") || "Confirmed";
    default:
      return t("gatherings.status.scheduled") || "Scheduled";
  }
}

export function quorumLine(g: Gathering, t: T): string {
  if (g.status === "cancelled" || g.status === "ended") return statusLabel(g.status, t);
  const going = g.going || 0;
  const met = g.quorumMet !== undefined ? g.quorumMet : g.needed === 0;
  if (met || g.status === "confirmed") {
    return t("gatherings.quorum.confirmed", { count: going }) || `Confirmed · ${going} going`;
  }
  return (
    t("gatherings.quorum.needed", { count: g.needed, going }) ||
    `${g.needed} more needed to confirm · ${going} going`
  );
}

const TOPIC_FALLBACK: { [k: string]: string } = {
  conversation: "Conversation",
  exam_prep: "Exam prep",
  grammar: "Grammar",
  pronunciation: "Pronunciation",
  culture: "Culture",
  media: "Music, film & TV",
  games: "Games",
  business: "Business",
  travel: "Travel",
};

export function topicLabel(topic: string | null | undefined, t: T): string {
  if (!topic) return "";
  const fallback = TOPIC_FALLBACK[topic];
  if (!fallback) return topic;
  return t(`gatherings.topics.${topic}`) || fallback;
}

const pad = (n: number) => (n < 10 ? `0${n}` : String(n));

/** ISO -> the `YYYY-MM-DDTHH:mm` a datetime-local input shows, in the viewer's zone. */
export function toLocalInputValue(iso: string): string {
  const d = new Date(iso);
  if (!iso || Number.isNaN(d.getTime())) return "";
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** datetime-local value (viewer's wall time) -> UTC ISO, as the app sends `startsAt`. */
export function fromLocalInputValue(value: string): string {
  if (!value) return "";
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? "" : d.toISOString();
}

export function personId(p: any): string {
  if (!p) return "";
  if (typeof p === "string") return p;
  return p._id ? String(p._id) : "";
}

export function personName(p: any): string {
  if (!p || typeof p === "string") return "";
  if (p.name) return p.name;
  return p.username ? `@${p.username}` : "";
}

export type RsvpState = "host" | "going" | "pending" | "full" | "closed" | "join" | "request";

export function rsvpState(g: Gathering): RsvpState {
  if (g.viewerIsHost) return "host";
  if (g.status === "cancelled" || g.status === "ended") return "closed";
  if (g.viewerIsAttending) return "going";
  if (g.viewerRequestPending || g.pending) return "pending";
  if (seatsLeft(g) === 0) return "full";
  return g.joinMode === "approval" ? "request" : "join";
}

/** Backend refusal -> a sentence for a toast or an inline error. Never raw server text. */
export function gatheringErrorText(err: any, t: T): string {
  if (err && err.status === "FETCH_ERROR") {
    return t("gatherings.errors.offline") || "You're offline. Check your connection.";
  }
  const raw: string = (err && err.data && (err.data.error || err.data.message)) || "";
  const capacity = raw.match(/^Capacity cannot be lower than the (\d+) already going/);
  if (capacity) {
    const count = Number(capacity[1]);
    return t("gatherings.errors.capacityBelowGoing", { count }) || `Capacity can't be lower than the ${count} people already going.`;
  }
  const known: { [k: string]: [string, string] } = {
    "This gathering is full": ["full", "This gathering is full."],
    "You are already going": ["alreadyGoing", "You're already going."],
    "This gathering was cancelled": ["cancelled", "This gathering was cancelled."],
    "This gathering has ended": ["ended", "This gathering has ended."],
    "This gathering has already started": ["started", "This gathering has already started."],
    "Your request is waiting for the host to approve it": ["pending", "Your request is waiting for the host."],
    "Cancel the gathering instead of leaving it": ["hostCannotLeave", "As the host, cancel the gathering instead of leaving it."],
    "A gathering must start in the future": ["pastStart", "Pick a start time in the future."],
    "You have cancelled or missed too many of your own gatherings to host a new one": [
      "hostBlocked",
      "You can't host right now: too many of your gatherings were cancelled or missed.",
    ],
    "Join the club before hosting for it": ["joinClubFirst", "Join the club before hosting for it."],
    "A gathering cannot end before it starts": ["endBeforeStart", "You can end the gathering once it has started."],
    "The owner cannot leave their own club": ["ownerCannotLeave", "As the owner, you can delete the club but not leave it."],
    "That club is archived": ["clubArchived", "This club is archived."],
    "This club is archived": ["clubArchived", "This club is archived."],
    "Gathering not found": ["gatheringGone", "This gathering isn't available."],
    "Club not found": ["clubGone", "This club isn't available."],
  };
  const hit = known[raw];
  if (hit) return t(`gatherings.errors.${hit[0]}`) || hit[1];
  return t("gatherings.errors.generic") || "Something went wrong. Try again.";
}
