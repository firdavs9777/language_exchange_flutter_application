export type Consent = "granted" | "denied";

const KEY = "bt.consent";

// Duplicated from ga.ts on purpose. ga.ts imports this module (`gaEvent` has
// to know the current decision), so importing the id back from there would be
// a cycle. It is a build-time env value, so both reads see the same string.
const GA_ID: string = process.env.REACT_APP_GA_MEASUREMENT_ID || "";

type ConsentListener = (value: Consent | null) => void;
const listeners = new Set<ConsentListener>();
const managerListeners = new Set<() => void>();

/** null = undecided. Storage that throws (private modes) reads as undecided. */
export function readConsent(): Consent | null {
  try {
    const v = window.localStorage.getItem(KEY);
    return v === "granted" || v === "denied" ? v : null;
  } catch {
    return null;
  }
}

export function writeConsent(value: Consent): void {
  try {
    window.localStorage.setItem(KEY, value);
  } catch {
    // The bar will show again next visit. Acceptable.
  }
  announce(value);
}

/** Back to undecided: the bar asks again on the next visit. */
export function clearConsent(): void {
  try {
    window.localStorage.removeItem(KEY);
  } catch {
    // Already effectively undecided if storage is unavailable.
  }
  announce(null);
}

/**
 * Called by anything that wants to follow the decision without polling — the
 * settings row and the consent manager both render the current choice, and
 * either can change it. Returns its own unsubscribe.
 */
export function subscribeConsent(cb: ConsentListener): () => void {
  listeners.add(cb);
  return () => {
    listeners.delete(cb);
  };
}

function announce(value: Consent | null): void {
  listeners.forEach((l) => l(value));
}

/**
 * gtag's own kill switch: with `window["ga-disable-<ID>"]` true, an already
 * injected gtag.js stops collecting without being unloaded. That is what makes
 * withdrawal work mid-session — the script cannot be taken back out of the
 * page, but it can be told to stop, and told to start again on a re-accept.
 */
export function gaDisableFlag(id: string = GA_ID): string {
  return `ga-disable-${id}`;
}

export function isGaDisabled(id: string = GA_ID): boolean {
  if (typeof window === "undefined" || !id) return false;
  return (window as any)[gaDisableFlag(id)] === true;
}

export function setGaDisabled(disabled: boolean, id: string = GA_ID): void {
  if (typeof window === "undefined" || !id) return;
  (window as any)[gaDisableFlag(id)] = disabled;
}

// GA4's first-party cookies: `_ga` (client id) and one `_ga_<STREAM>` per
// stream. Withdrawing consent and leaving the identifier on the device would
// be a withdrawal in name only.
function expireGaCookies(): void {
  if (typeof document === "undefined") return;
  let names: string[] = [];
  try {
    names = document.cookie
      .split(";")
      .map((c) => c.split("=")[0].trim())
      .filter((n) => n === "_ga" || n.indexOf("_ga_") === 0);
  } catch {
    return;
  }
  if (!names.length) return;

  // GA sets the cookie on the registrable domain, so `www.banatalk.com` has to
  // clear it as `banatalk.com` too; the host-only variant covers a cookie
  // written without a domain attribute at all (localhost, previews).
  const host = (typeof window !== "undefined" && window.location && window.location.hostname) || "";
  const parts = host ? host.split(".") : [];
  const domains: string[] = ["", host];
  if (parts.length > 2) domains.push(parts.slice(1).join("."));

  names.forEach((name) => {
    domains.forEach((domain) => {
      try {
        document.cookie =
          `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; max-age=0; path=/` +
          (domain ? `; domain=${domain}` : "");
      } catch {
        // A cookie we may not write is a cookie we did not set.
      }
    });
  });
}

/**
 * The whole of "no, actually": record the refusal, stop the tag that is
 * already on the page, and delete what it stored.
 */
export function withdrawConsent(id: string = GA_ID): void {
  writeConsent("denied");
  setGaDisabled(true, id);
  expireGaCookies();
}

// A two-line event bus rather than a context: the footer link, the settings
// row and the policy page all need to open the manager, and none of them is
// anywhere near ConsentBar in the tree. With no measurement id nothing
// subscribes, so the call is a no-op — which is the behaviour we want.
export function openConsentManager(): void {
  managerListeners.forEach((l) => l());
}

export function subscribeConsentManager(cb: () => void): () => void {
  managerListeners.add(cb);
  return () => {
    managerListeners.delete(cb);
  };
}
