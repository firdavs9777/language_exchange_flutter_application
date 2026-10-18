import { BASE_URL, ANALYTICS_EVENTS_URL } from "../constants";

export type EventName = "page_view" | "store_tap" | "cta_tap";

export interface EventData {
  path?: string;
  placement?: string;
  platform?: "ios" | "android" | "web";
  referrer?: string;
  language?: string;
}

// First-party events: POST /api/v1/analytics/events (controllers/webEvents.js).
// Independent of GA and of consent: the payload carries a per-tab session id
// and nothing that identifies a person. Fire-and-forget, one retry, never throws.

const SESSION_KEY = "bt.sid";
let memoSession: string | null = null;

function randomId(): string {
  const bytes = new Uint8Array(16);
  if (typeof crypto !== "undefined" && crypto.getRandomValues) crypto.getRandomValues(bytes);
  else for (let i = 0; i < bytes.length; i++) bytes[i] = Math.floor(Math.random() * 256);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

export function sessionId(): string {
  try {
    const existing = window.sessionStorage.getItem(SESSION_KEY);
    if (existing) return existing;
    const id = randomId();
    window.sessionStorage.setItem(SESSION_KEY, id);
    return id;
  } catch {
    if (!memoSession) memoSession = randomId();
    return memoSession;
  }
}

export function buildPayload(name: EventName, data: EventData) {
  return {
    name,
    path: data.path || window.location.pathname,
    placement: data.placement || null,
    platform: data.platform || null,
    referrer: data.referrer || document.referrer || null,
    language: data.language || navigator.language || null,
    sessionId: sessionId(),
  };
}

async function post(body: string): Promise<Response | null> {
  try {
    return await fetch(`${BASE_URL}${ANALYTICS_EVENTS_URL}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
      keepalive: true,
    });
  } catch {
    return null; // network error: worth one retry
  }
}

// A 4xx means the request itself was rejected (bad payload, validation) --
// retrying sends the same bad request again, so it's treated as final. A
// network failure or a 5xx is worth the one retry.
function shouldRetry(res: Response | null): boolean {
  if (res === null) return true;
  if (res.ok) return false;
  return !(res.status >= 400 && res.status < 500);
}

export function trackEvent(name: EventName, data: EventData = {}): void {
  if (typeof window === "undefined") return; // prerender: nothing to measure
  let body: string;
  try {
    body = JSON.stringify(buildPayload(name, data));
  } catch {
    return;
  }
  void (async () => {
    const first = await post(body);
    if (shouldRetry(first)) await post(body);
  })();
}
