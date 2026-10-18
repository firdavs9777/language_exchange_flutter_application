// Trigger and suppression rules for the growth surfaces (promo carousel,
// download popup, sticky mobile banner).
//
// Deliberately pure and React-free: these rules decide whether a visitor is
// interrupted, they are the easiest thing here to get wrong, and they are
// painful to verify through a rendered component.

import { STORE_HOSTS } from "./storeUrls";

export type GateKey = "download-popup" | "promo-carousel" | "sticky-banner";

export interface GateContext {
  pathname: string;
  referrer: string;
  viewportWidth: number;
  /** Injected in tests; defaults to Date.now(). */
  now?: number;
}

export const SUPPRESSION_DAYS: Record<GateKey, number> = {
  "download-popup": 30,
  "promo-carousel": 7,
  "sticky-banner": 30,
};

/** Below this width the sticky banner owns the screen and the popup stands down. */
export const MOBILE_MAX_WIDTH = 768;

// The two live hostnames come from StoreLink, the one file allowed to spell
// them out; itunes.apple.com is the legacy redirect, which is not a link we
// ever emit but is still a referrer worth honouring.
const APP_STORE_HOSTS = STORE_HOSTS.concat(["itunes.apple.com"]);
const EXCLUDED_PATHS = ["/register", "/login"];
const DAY_MS = 24 * 60 * 60 * 1000;

const storageKey = (key: GateKey) => `bt.growth.${key}.dismissedAt`;

// Check if a referrer is from an app store, using hostname matching to avoid
// false positives from substrings in query parameters or lookalike domains.
function isFromAppStore(referrer: string): boolean {
  try {
    const hostname = new URL(referrer).hostname;
    return APP_STORE_HOSTS.some((host) => hostname === host || hostname.endsWith("." + host));
  } catch {
    // Empty or unparseable referrer is treated as "not from a store"
    return false;
  }
}

// Storage throws outright in some privacy modes. Every failure here means
// "we don't know", and not knowing must never crash the homepage.
function readDismissedAt(key: GateKey): number | null {
  try {
    const raw = window.localStorage.getItem(storageKey(key));
    if (!raw) return null;
    const ts = Number(raw);
    return Number.isFinite(ts) ? ts : null;
  } catch {
    return null;
  }
}

export function recordDismissal(key: GateKey, now: number = Date.now()): void {
  try {
    window.localStorage.setItem(storageKey(key), String(now));
  } catch {
    // Nothing to do — the surface simply reappears next visit.
  }
}

export function isSuppressed(key: GateKey, ctx: GateContext): boolean {
  const now = ctx.now ?? Date.now();

  if (key === "sticky-banner") {
    if (ctx.viewportWidth > MOBILE_MAX_WIDTH) return true;
  } else if (key === "download-popup") {
    if (ctx.viewportWidth <= MOBILE_MAX_WIDTH) return true;
    if (EXCLUDED_PATHS.includes(ctx.pathname)) return true;
    if (isFromAppStore(ctx.referrer)) return true;
  }

  const dismissedAt = readDismissedAt(key);
  if (dismissedAt === null) return false;
  return now - dismissedAt < SUPPRESSION_DAYS[key] * DAY_MS;
}
