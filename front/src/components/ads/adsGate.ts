// The two rules that decide whether a visitor sees ads at all, kept as pure
// functions so AdUnit, the auto-ads bootstrap and the tests share one answer.
//
// 1. VIP users never see ads: "ad-free" is a benefit the app sells, and the
//    web reads the same user document (`userMode === "vip"`, or an active
//    `vipSubscription`), so a subscription bought in the app is honoured here.
// 2. A visitor who declined the consent bar still sees ads, but
//    non-personalized ones: AdSense reads `requestNonPersonalizedAds` from the
//    queue object before the first request. This is the site's own bar;
//    Google's certified GDPR message (Privacy & messaging in AdSense) sits on
//    top of it for EU visitors and needs no code.
import { Consent } from "../../analytics/consent";

export interface AdsUser {
  userMode?: string;
  vipSubscription?: { isActive?: boolean } | null;
}

export function isVipUser(user: AdsUser | null | undefined): boolean {
  if (!user) return false;
  if (user.userMode === "vip") return true;
  return !!(user.vipSubscription && user.vipSubscription.isActive);
}

export function shouldShowAds(user: AdsUser | null | undefined): boolean {
  return !isVipUser(user);
}

interface AdsQueue extends Array<unknown> {
  requestNonPersonalizedAds?: number;
  pauseAdRequests?: number;
}

/**
 * Mirror the consent decision onto the AdSense queue. Safe to call before the
 * script loads (the script reads the flag when it arrives) and again after a
 * change: AdSense applies it to the next ad request.
 */
export function applyAdConsent(consent: Consent | null): void {
  if (typeof window === "undefined") return;
  const w = window as any;
  const queue: AdsQueue = (w.adsbygoogle = w.adsbygoogle || []);
  queue.requestNonPersonalizedAds = consent === "denied" ? 1 : 0;
}
