import { COUNTRY_CODES } from "../lib/countries";
import { DailyMatchUser } from "./types";

// Moved to utils so every surface resolves photos the same way; re-exported
// so existing imports keep working.
export { photoUrl } from "../../../utils/photoUrl";

/**
 * Why this person is in today's batch, in the reader's language. The codes
 * come from lib/dailyMatches.js structuredReasons; one the web does not know
 * renders nothing -- there is no English string to fall back to, and a raw
 * code is never shown.
 */
export function reasonChips(
  reasons: string[] | undefined,
  user: DailyMatchUser,
  t: (key: string, options?: any) => string
): string[] {
  const chips: string[] = [];
  (reasons || []).forEach((code) => {
    if (code === "reciprocal_pair") chips.push(t("communityMain.today.reasonReciprocal"));
    else if (code === "same_target_language") {
      chips.push(t("communityMain.today.reasonSameTarget", { language: user.language_to_learn || "" }));
    } else if (code === "active_today") chips.push(t("communityMain.today.reasonActiveToday"));
    else if (code === "same_city") chips.push(t("communityMain.today.reasonSameCity"));
    else if (code.indexOf("shared_topic:") === 0) {
      const id = code.slice("shared_topic:".length);
      // defaultValue, not `|| id`: a missing key returns the key itself, so an
      // `||` would print "profile.topics.<id>".
      const topic = t(`profile.topics.${id}`, { defaultValue: id });
      chips.push(t("communityMain.today.reasonSharedTopic", { topic }));
    }
  });
  return chips.filter(Boolean);
}

/** The app's threshold (match_card.dart): 70% of first messages answered. */
export function repliesFast(rate: number | null | undefined): boolean {
  return typeof rate === "number" && rate >= 0.7;
}

let byEnglishName: Record<string, string> | null = null;

/** 🇰🇷 for "South Korea": the stored country is an English name (lib/countryNames). */
export function countryFlag(country: string | undefined): string {
  if (!country) return "";
  if (!byEnglishName) {
    byEnglishName = {};
    try {
      const names = new (Intl as any).DisplayNames(["en"], { type: "region" });
      COUNTRY_CODES.forEach((code) => {
        const name = names.of(code);
        if (name) (byEnglishName as Record<string, string>)[name.toLowerCase()] = code;
      });
    } catch (e) {
      // No Intl.DisplayNames: no flags, nothing else lost.
    }
  }
  const code = byEnglishName[country.trim().toLowerCase()];
  if (!code) return "";
  return String.fromCodePoint(...code.split("").map((c) => 0x1f1e6 + c.charCodeAt(0) - 65));
}

/** "9:00 AM" -- when the batch refreshes, in the reader's own clock. */
export function refreshTimeLabel(nextRefreshAt: string | undefined, locale: string): string | null {
  if (!nextRefreshAt) return null;
  const when = new Date(nextRefreshAt);
  if (isNaN(when.getTime())) return null;
  try {
    return new Intl.DateTimeFormat((locale || "en").replace(/_/g, "-"), { hour: "numeric", minute: "2-digit" }).format(when);
  } catch (e) {
    return new Intl.DateTimeFormat("en", { hour: "numeric", minute: "2-digit" }).format(when);
  }
}
