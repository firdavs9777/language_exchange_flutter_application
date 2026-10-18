import { AppleJsError } from "./appleJs";

export type AppleErrorKind = "disabled" | "unavailable" | "banned" | "rate_limited" | "blocked" | "failed";

type Translate = (key: string) => string;

/** RTK Query error, AppleJsError, or anything else -> one of six things to tell the user. */
export function appleErrorKind(err: any): AppleErrorKind {
  if (err instanceof AppleJsError) return err.kind === "blocked" ? "blocked" : "failed";
  if (!err || typeof err !== "object") return "failed";
  const data = err.data || {};
  if (err.status === 404 && data.code === "feature_disabled") return "disabled";
  if (err.status === 503) return "unavailable";
  if (err.status === 403) return "banned";
  if (err.status === 429) return "rate_limited";
  return "failed";
}

const ENGLISH: { [k in AppleErrorKind]: string } = {
  disabled: "Sign in with Apple isn't available on the website yet.",
  unavailable: "Sign in with Apple isn't available right now. Try again later.",
  banned: "This account has been suspended.",
  rate_limited: "Too many sign-in attempts. Wait a minute and try again.",
  blocked: "Your browser blocked the Apple window. Allow pop-ups for banatalk.com and try again.",
  failed: "Couldn't sign in with Apple. Try again.",
};

export function appleErrorText(kind: AppleErrorKind, t: Translate): string {
  return t(`auth.apple.errors.${kind}`) || ENGLISH[kind];
}
