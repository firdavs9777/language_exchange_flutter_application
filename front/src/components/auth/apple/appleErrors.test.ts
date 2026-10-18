import { appleErrorKind, appleErrorText } from "./appleErrors";
import { AppleJsError } from "./appleJs";

const t = () => "";

it.each([
  [{ status: 404, data: { code: "feature_disabled" } }, "disabled"],
  [{ status: 404, data: {} }, "failed"],
  [{ status: 503, data: { error: "Sign in with Apple is not available right now" } }, "unavailable"],
  [{ status: 403, data: { error: "This account has been permanently suspended" } }, "banned"],
  [{ status: 429, data: {} }, "rate_limited"],
  [{ status: 400, data: { error: "A valid nonce is required" } }, "failed"],
  [{ status: 401, data: {} }, "failed"],
  [{ status: "FETCH_ERROR", error: "TypeError: Failed to fetch" }, "failed"],
  [new AppleJsError("blocked"), "blocked"],
  [new AppleJsError("state_mismatch"), "failed"],
  [undefined, "failed"],
])("%j -> %s", (err, kind) => {
  expect(appleErrorKind(err)).toBe(kind);
});

it("has an English line for every kind and never shows the backend's raw text", () => {
  expect(appleErrorText("disabled", t)).toBe("Sign in with Apple isn't available on the website yet.");
  expect(appleErrorText("unavailable", t)).toBe("Sign in with Apple isn't available right now. Try again later.");
  expect(appleErrorText("banned", t)).toBe("This account has been suspended.");
  expect(appleErrorText("rate_limited", t)).toBe("Too many sign-in attempts. Wait a minute and try again.");
  expect(appleErrorText("blocked", t)).toBe("Your browser blocked the Apple window. Allow pop-ups for banatalk.com and try again.");
  expect(appleErrorText("failed", t)).toBe("Couldn't sign in with Apple. Try again.");
});

it("uses the translation when there is one", () => {
  const tr = (k: string) => (k === "auth.apple.errors.failed" ? "Échec" : "");
  expect(appleErrorText("failed", tr)).toBe("Échec");
});
