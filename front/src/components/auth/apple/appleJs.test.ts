import {
  APPLE_JS_URL,
  appleServicesId,
  appleRedirectUri,
  makeNonce,
  loadAppleJs,
  signInWithApple,
  AppleJsError,
  _resetAppleJsForTests,
} from "./appleJs";

const NONCE_RE = /^[A-Za-z0-9._~-]{16,128}$/; // controllers/auth.js:457

function stubAppleId(signIn: () => Promise<any>) {
  const init = jest.fn();
  (window as any).AppleID = { auth: { init, signIn: jest.fn(signIn) } };
  return init;
}

const scripts = () => Array.from(document.querySelectorAll(`script[src="${APPLE_JS_URL}"]`)) as HTMLScriptElement[];

// CRA 5's jsdom may not have Web Crypto; the browsers we target all do.
beforeAll(() => {
  if (!(window as any).crypto || !(window as any).crypto.getRandomValues) {
    const nodeCrypto = require("crypto");
    Object.defineProperty(window, "crypto", {
      configurable: true,
      value: { getRandomValues: (a: Uint8Array) => nodeCrypto.randomFillSync(a) },
    });
  }
});

beforeEach(() => {
  _resetAppleJsForTests();
  delete (window as any).AppleID;
  scripts().forEach((s) => s.remove());
  delete process.env.REACT_APP_APPLE_SERVICES_ID;
});

describe("configuration", () => {
  it("reads the Services ID from the build env, trimmed, empty when unset", () => {
    expect(appleServicesId()).toBe("");
    process.env.REACT_APP_APPLE_SERVICES_ID = "  com.bananatalk.web \n";
    expect(appleServicesId()).toBe("com.bananatalk.web");
  });

  it("returns to /login on this origin (the URL the owner registers)", () => {
    expect(appleRedirectUri()).toBe(`${window.location.origin}/login`);
  });

  it("makes a fresh nonce the backend accepts", () => {
    const a = makeNonce();
    const b = makeNonce();
    expect(a).toMatch(NONCE_RE);
    expect(a).toHaveLength(43);
    expect(a).not.toBe(b);
  });
});

describe("loadAppleJs", () => {
  it("injects Apple's script once and resolves when it loads", async () => {
    const p1 = loadAppleJs();
    const p2 = loadAppleJs();
    expect(scripts()).toHaveLength(1);
    stubAppleId(() => Promise.resolve({}));
    scripts()[0].dispatchEvent(new Event("load"));
    await expect(p1).resolves.toBe((window as any).AppleID.auth);
    await expect(p2).resolves.toBe((window as any).AppleID.auth);
  });

  it("does not inject anything when AppleID is already on the page", async () => {
    stubAppleId(() => Promise.resolve({}));
    await loadAppleJs();
    expect(scripts()).toHaveLength(0);
  });

  it("rejects on a script error and retries on the next call", async () => {
    const p = loadAppleJs();
    scripts()[0].dispatchEvent(new Event("error"));
    await expect(p).rejects.toBeInstanceOf(AppleJsError);
    expect(scripts()).toHaveLength(0); // the dead tag is removed
    loadAppleJs();
    expect(scripts()).toHaveLength(1);
  });

  it("gives up after the timeout (Apple's CDN unreachable)", async () => {
    jest.useFakeTimers();
    const p = loadAppleJs(5000);
    jest.advanceTimersByTime(5001);
    await expect(p).rejects.toMatchObject({ kind: "failed" });
    jest.useRealTimers();
  });
});

describe("signInWithApple", () => {
  beforeEach(() => {
    process.env.REACT_APP_APPLE_SERVICES_ID = "com.bananatalk.web";
  });

  it("initialises Apple JS with the nonce, state, popup mode and name+email scope", async () => {
    const init = stubAppleId(() =>
      Promise.resolve({ authorization: { id_token: "id.tok", code: "c", state: "st-1" } })
    );
    await signInWithApple({ nonce: "n".repeat(43), state: "st-1" });
    expect(init).toHaveBeenCalledWith({
      clientId: "com.bananatalk.web",
      scope: "name email",
      redirectURI: `${window.location.origin}/login`,
      state: "st-1",
      nonce: "n".repeat(43),
      usePopup: true,
    });
  });

  it("returns the identity token and, on first consent, the name", async () => {
    stubAppleId(() =>
      Promise.resolve({
        authorization: { id_token: "id.tok", code: "c", state: "st-1" },
        user: { name: { firstName: "Ada", lastName: "Lovelace" }, email: "ada@privaterelay.appleid.com" },
      })
    );
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "st-1" })).resolves.toEqual({
      identityToken: "id.tok",
      user: { name: { firstName: "Ada", lastName: "Lovelace" }, email: "ada@privaterelay.appleid.com" },
    });
  });

  it("returns null when the user closes the popup or cancels", async () => {
    stubAppleId(() => Promise.reject({ error: "popup_closed_by_user" }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "s" })).resolves.toBe(null);
    stubAppleId(() => Promise.reject({ error: "user_cancelled_authorize" }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "s" })).resolves.toBe(null);
  });

  it("names a blocked popup", async () => {
    stubAppleId(() => Promise.reject({ error: "popup_blocked_by_browser" }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "s" })).rejects.toMatchObject({ kind: "blocked" });
  });

  it("refuses a response whose state is not ours", async () => {
    stubAppleId(() => Promise.resolve({ authorization: { id_token: "id.tok", state: "other" } }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "mine" })).rejects.toMatchObject({
      kind: "state_mismatch",
    });
  });

  it("refuses a response without an id_token", async () => {
    stubAppleId(() => Promise.resolve({ authorization: { code: "c", state: "s" } }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "s" })).rejects.toMatchObject({ kind: "no_token" });
  });

  it("wraps any other Apple failure", async () => {
    stubAppleId(() => Promise.reject({ error: "invalid_client" }));
    await expect(signInWithApple({ nonce: "n".repeat(43), state: "s" })).rejects.toMatchObject({ kind: "failed" });
  });
});
