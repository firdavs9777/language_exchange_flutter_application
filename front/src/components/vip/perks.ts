/**
 * What VIP really adds — the same list as the app (2026-10-18). Every VIP
 * surface on web (VIP page, home pricing) renders THIS, never the server's
 * plan `features`, which still advertise perks free users already have
 * (unlimited messages, profile views, waves, priority support).
 */
export interface VipPerk {
  id: "noAds" | "unlimitedTutor" | "seeAllVisitors" | "moreMatches" | "advancedPartnerFilters" | "unlimitedTranslations";
  key: string;
  fallback: string;
}

export const VIP_PERKS: VipPerk[] = [
  { id: "noAds", key: "vip.features.noAds", fallback: "No ads" },
  { id: "unlimitedTutor", key: "vip.features.unlimitedTutor", fallback: "Unlimited AI tutor and roleplay" },
  { id: "seeAllVisitors", key: "vip.features.seeAllVisitors", fallback: "See everyone who viewed you" },
  { id: "moreMatches", key: "vip.features.moreMatches", fallback: "15 daily matches instead of 6" },
  { id: "advancedPartnerFilters", key: "vip.features.advancedPartnerFilters", fallback: "Advanced partner filters (country)" },
  { id: "unlimitedTranslations", key: "vip.features.unlimitedTranslations", fallback: "Unlimited translations" },
];
