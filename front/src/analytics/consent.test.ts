import {
  readConsent,
  writeConsent,
  withdrawConsent,
  clearConsent,
  subscribeConsent,
  subscribeConsentManager,
  openConsentManager,
  isGaDisabled,
  setGaDisabled,
  Consent,
} from "./consent";

beforeEach(() => window.localStorage.clear());

it("is undecided by default and round-trips a decision", () => {
  expect(readConsent()).toBeNull();
  writeConsent("granted");
  expect(readConsent()).toBe("granted");
  writeConsent("denied");
  expect(readConsent()).toBe("denied");
});

it("treats junk and throwing storage as undecided", () => {
  window.localStorage.setItem("bt.consent", "maybe");
  expect(readConsent()).toBeNull();
  const spy = jest.spyOn(Storage.prototype, "getItem").mockImplementation(() => { throw new Error("blocked"); });
  expect(readConsent()).toBeNull();
  spy.mockRestore();
});

describe("withdrawal", () => {
  const ID = "G-TEST123";

  beforeEach(() => {
    delete (window as any)[`ga-disable-${ID}`];
    document.cookie = "_ga=GA1.1.1234.5678; path=/";
    document.cookie = "_ga_TEST123=GS1.1.abc; path=/";
    document.cookie = "keep=me; path=/";
  });

  it("writes denied, sets the ga-disable flag and expires the _ga cookies", () => {
    withdrawConsent(ID);
    expect(readConsent()).toBe("denied");
    expect((window as any)[`ga-disable-${ID}`]).toBe(true);
    expect(isGaDisabled(ID)).toBe(true);
    expect(document.cookie).not.toContain("_ga=");
    expect(document.cookie).not.toContain("_ga_TEST123=");
    expect(document.cookie).toContain("keep=me");
  });

  it("re-enabling clears the flag so gtag starts collecting again", () => {
    withdrawConsent(ID);
    setGaDisabled(false, ID);
    expect(isGaDisabled(ID)).toBe(false);
    expect((window as any)[`ga-disable-${ID}`]).toBe(false);
  });

  it("clearConsent puts the decision back to undecided", () => {
    writeConsent("granted");
    clearConsent();
    expect(readConsent()).toBeNull();
  });
});

describe("subscriptions", () => {
  it("notifies subscribers of every decision until they unsubscribe", () => {
    const seen: (Consent | null)[] = [];
    const off = subscribeConsent((v) => seen.push(v));
    writeConsent("granted");
    withdrawConsent("G-SUB");
    clearConsent();
    off();
    writeConsent("granted");
    expect(seen).toEqual(["granted", "denied", null]);
  });

  it("openConsentManager reaches the mounted manager and no one else", () => {
    let opened = 0;
    const off = subscribeConsentManager(() => { opened += 1; });
    openConsentManager();
    openConsentManager();
    off();
    openConsentManager();
    expect(opened).toBe(2);
  });
});
