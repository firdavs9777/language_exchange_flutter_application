/**
 * The words a call-history message shows, from the viewer's side.
 *
 * One message is shared by both people (backend services/callMessageService.js);
 * each side words it from `media.callData.outcome` and whether the viewer
 * placed the call. Case for case the app's CallLabels
 * (lib/models/call_outcome.dart), so a call reads the same on web and phone.
 */
export type CallOutcome = "completed" | "no_answer" | "cancelled" | "declined" | "busy";

export interface CallData {
  callId?: string;
  /** A bare id string as written today; tolerated populated. */
  initiator?: string | { _id?: string } | null;
  /** "audio" | "video" */
  type?: string;
  /** Whole seconds. */
  duration?: number;
  /** Legacy (pre-outcome) status: ended | answered | missed | rejected | busy. */
  status?: string;
  outcome?: string;
  startTime?: string;
}

export interface CallLabel {
  outcome: CallOutcome;
  key: string;
  fallback: string;
  params: { [key: string]: any };
  isVideo: boolean;
  direction: "outgoing" | "incoming";
  /** Missed in the app's sense: the viewer was called and did not pick up. */
  missed: boolean;
  /** Drawn red: missed, or declined by either side. */
  negative: boolean;
  /** "m:ss" for a completed call, otherwise null. */
  duration: string | null;
}

const KNOWN: CallOutcome[] = ["completed", "no_answer", "cancelled", "declined", "busy"];

const LEGACY: { [status: string]: CallOutcome } = {
  ended: "completed",
  answered: "completed",
  missed: "no_answer",
  rejected: "declined",
  busy: "busy",
};

export function outcomeOf(data: CallData | null | undefined): CallOutcome {
  if (data && data.outcome && KNOWN.indexOf(data.outcome as CallOutcome) !== -1) {
    return data.outcome as CallOutcome;
  }
  if (data && data.status && LEGACY[data.status]) return LEGACY[data.status];
  return "completed";
}

export function formatCallDuration(seconds: number): string {
  const whole = typeof seconds === "number" && isFinite(seconds) && seconds > 0 ? Math.floor(seconds) : 0;
  const h = Math.floor(whole / 3600);
  const m = Math.floor((whole % 3600) / 60);
  const s = whole % 60;
  const pad = (n: number): string => (n < 10 ? `0${n}` : String(n));
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
}

function initiatorId(data: CallData): string {
  const initiator = data.initiator;
  if (!initiator) return "";
  if (typeof initiator === "string") return initiator;
  return initiator._id ? String(initiator._id) : "";
}

export function callLabel(
  data: CallData | null | undefined,
  viewerId: string,
  isSentFallback: boolean,
  otherName: string
): CallLabel {
  const record: CallData = data || {};
  const outcome = outcomeOf(record);
  const isVideo = record.type === "video";
  const kind = isVideo ? "Video" : "Voice";
  const lower = isVideo ? "video" : "voice";
  const initiator = initiatorId(record);
  const viewerIsCaller = initiator ? initiator === viewerId : isSentFallback;

  let key: string;
  let fallback: string;
  const params: { [key: string]: any } = {};
  switch (outcome) {
    case "no_answer":
      key = viewerIsCaller ? `chatPage.call.noAnswer${kind}` : `chatPage.call.missed${kind}`;
      fallback = viewerIsCaller ? `${kind} call · No answer` : `Missed ${lower} call`;
      break;
    case "cancelled":
      key = viewerIsCaller ? `chatPage.call.cancelled${kind}` : `chatPage.call.missed${kind}`;
      fallback = viewerIsCaller ? `Cancelled ${lower} call` : `Missed ${lower} call`;
      break;
    case "declined":
      key = viewerIsCaller ? `chatPage.call.declinedOutgoing${kind}` : `chatPage.call.declinedIncoming${kind}`;
      fallback = viewerIsCaller ? `${kind} call declined` : `Declined ${lower} call`;
      break;
    case "busy":
      if (viewerIsCaller) {
        key = "chatPage.call.busy";
        params.name = otherName;
        fallback = `${otherName} was on another call`;
      } else {
        key = `chatPage.call.missed${kind}`;
        fallback = `Missed ${lower} call`;
      }
      break;
    default:
      key = viewerIsCaller ? `chatPage.call.outgoing${kind}` : `chatPage.call.incoming${kind}`;
      fallback = `${viewerIsCaller ? "Outgoing" : "Incoming"} ${lower} call`;
  }

  const missed =
    !viewerIsCaller && (outcome === "no_answer" || outcome === "cancelled" || outcome === "busy");

  return {
    outcome: outcome,
    key: key,
    fallback: fallback,
    params: params,
    isVideo: isVideo,
    direction: viewerIsCaller ? "outgoing" : "incoming",
    missed: missed,
    negative: missed || outcome === "declined",
    duration: outcome === "completed" ? formatCallDuration(Number(record.duration) || 0) : null,
  };
}

/** The conversation-list line for a call, as the app's callPreviewText words it (minus the icon). */
export function callPreviewText(
  t: (key: string, options?: any) => string,
  data: CallData | null | undefined,
  viewerId: string,
  isSent: boolean,
  otherName: string
): string {
  const label = callLabel(data, viewerId, isSent, otherName);
  const text = t(label.key, label.params) || label.fallback;
  return label.duration ? `${text} · ${label.duration}` : text;
}
