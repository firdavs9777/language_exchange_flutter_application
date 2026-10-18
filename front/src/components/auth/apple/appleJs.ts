/**
 * Sign in with Apple on the website, through Apple JS (appleid.auth.js).
 *
 * Nothing here runs until a visitor reaches for the Apple button: the script
 * is injected on the first hover/focus/click, never on page load, and never
 * while the button is hidden (flag off or no Services ID configured).
 *
 * The nonce goes to Apple verbatim and to POST /auth/apple/web verbatim: Apple
 * JS copies it into the id_token's `nonce` claim as given, and the backend's
 * jsonwebtoken check compares it as is (be controllers/auth.js:297-303). No
 * SHA-256 -- that is the native iOS convention, not Apple JS.
 */

export const APPLE_JS_URL =
  "https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js";

export interface AppleIdAuth {
  init(config: {
    clientId: string;
    scope: string;
    redirectURI: string;
    state: string;
    nonce: string;
    usePopup: boolean;
  }): void;
  signIn(): Promise<any>;
}

export interface AppleSignInResult {
  identityToken: string;
  user?: { name?: { firstName?: string; lastName?: string }; email?: string };
}

export class AppleJsError extends Error {
  kind: string;
  constructor(kind: "blocked" | "state_mismatch" | "no_token" | "failed", message?: string) {
    super(message || kind);
    this.kind = kind;
    // TS 3.7 targeting es6 keeps the prototype, but be explicit for Babel's class transform.
    Object.setPrototypeOf(this, AppleJsError.prototype);
  }
}

/** Read per call (not at import): CRA inlines it at build, tests set it at run time. */
export function appleServicesId(): string {
  return String(process.env.REACT_APP_APPLE_SERVICES_ID || "").trim();
}

/** Must match a return URL registered on the Services ID exactly (owner step). */
export function appleRedirectUri(): string {
  return `${window.location.origin}/login`;
}

/** 32 random bytes as base64url: 43 chars of [A-Za-z0-9_-]. */
export function makeNonce(): string {
  const bytes = new Uint8Array(32);
  if (!window.crypto || !window.crypto.getRandomValues) throw new AppleJsError("failed", "no Web Crypto");
  window.crypto.getRandomValues(bytes);
  let bin = "";
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return window.btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

let loader: Promise<AppleIdAuth> | null = null;

export function _resetAppleJsForTests(): void {
  loader = null;
}

function appleAuth(): AppleIdAuth | null {
  const w = window as any;
  return w.AppleID && w.AppleID.auth ? (w.AppleID.auth as AppleIdAuth) : null;
}

export function loadAppleJs(timeoutMs: number = 15000): Promise<AppleIdAuth> {
  const ready = appleAuth();
  if (ready) return Promise.resolve(ready);
  if (loader) return loader;

  loader = new Promise<AppleIdAuth>((resolve, reject) => {
    const script = document.createElement("script");
    script.src = APPLE_JS_URL;
    script.async = true;
    let settled = false;
    const fail = () => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      script.remove();
      loader = null; // the next click retries
      reject(new AppleJsError("failed", "Apple JS could not be loaded"));
    };
    const timer = setTimeout(fail, timeoutMs);
    script.onload = () => {
      if (settled) return;
      const auth = appleAuth();
      if (!auth) {
        fail();
        return;
      }
      settled = true;
      clearTimeout(timer);
      resolve(auth);
    };
    script.onerror = fail;
    document.head.appendChild(script);
  });
  return loader;
}

const CANCELLED = ["popup_closed_by_user", "user_cancelled_authorize"];

export async function signInWithApple(opts: { nonce: string; state: string }): Promise<AppleSignInResult | null> {
  const auth = await loadAppleJs();
  auth.init({
    clientId: appleServicesId(),
    scope: "name email",
    redirectURI: appleRedirectUri(),
    state: opts.state,
    nonce: opts.nonce,
    usePopup: true,
  });

  let response: any;
  try {
    response = await auth.signIn();
  } catch (err) {
    const code = err && typeof err === "object" ? String((err as any).error || "") : "";
    if (CANCELLED.indexOf(code) !== -1) return null;
    if (code === "popup_blocked_by_browser") throw new AppleJsError("blocked", code);
    throw new AppleJsError("failed", code || "apple_sign_in_failed");
  }

  const authorization = (response && response.authorization) || {};
  if (authorization.state !== undefined && authorization.state !== opts.state) {
    throw new AppleJsError("state_mismatch");
  }
  if (typeof authorization.id_token !== "string" || !authorization.id_token) {
    throw new AppleJsError("no_token");
  }
  const result: AppleSignInResult = { identityToken: authorization.id_token };
  if (response.user && typeof response.user === "object") result.user = response.user;
  return result;
}
