import { applyAdConsent, isVipUser, shouldShowAds } from "./adsGate";

describe("isVipUser", () => {
  it("is false for visitors and regular users", () => {
    expect(isVipUser(null)).toBe(false);
    expect(isVipUser(undefined)).toBe(false);
    expect(isVipUser({})).toBe(false);
    expect(isVipUser({ userMode: "regular" })).toBe(false);
    expect(isVipUser({ userMode: "regular", vipSubscription: { isActive: false } })).toBe(false);
  });

  it("is true for userMode vip or an active subscription", () => {
    expect(isVipUser({ userMode: "vip" })).toBe(true);
    expect(isVipUser({ userMode: "regular", vipSubscription: { isActive: true } })).toBe(true);
  });
});

describe("shouldShowAds", () => {
  it("hides ads only for VIP users", () => {
    expect(shouldShowAds(null)).toBe(true);
    expect(shouldShowAds({ userMode: "regular" })).toBe(true);
    expect(shouldShowAds({ userMode: "vip" })).toBe(false);
  });
});

describe("applyAdConsent", () => {
  beforeEach(() => {
    delete (window as any).adsbygoogle;
  });

  it("requests non-personalized ads when consent was declined", () => {
    applyAdConsent("denied");
    expect((window as any).adsbygoogle.requestNonPersonalizedAds).toBe(1);
  });

  it("requests personalized ads when granted or undecided", () => {
    applyAdConsent("granted");
    expect((window as any).adsbygoogle.requestNonPersonalizedAds).toBe(0);
    applyAdConsent(null);
    expect((window as any).adsbygoogle.requestNonPersonalizedAds).toBe(0);
  });

  it("keeps an existing queue and its pending pushes", () => {
    (window as any).adsbygoogle = [{}];
    applyAdConsent("denied");
    expect((window as any).adsbygoogle.length).toBe(1);
    expect((window as any).adsbygoogle.requestNonPersonalizedAds).toBe(1);
  });
});
