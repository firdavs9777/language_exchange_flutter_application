/**
 * The For You card's "why this match" chips, in the reader's language.
 *
 * GET /matching/recommendations sends English `matchReasons` (shipped app
 * builds read them) and, since backend matchReasonCodes landed, the same
 * reasons as codes. The codes become localised chips; anything the web does
 * not understand -- a code from a newer server, a cached response without
 * codes, a locale missing the key -- falls back to the English string at the
 * same position rather than to a raw key or nothing.
 */

export interface ReasonChip {
  text: string;
  /** The language match: drawn first and in the brand colour. */
  primary: boolean;
}

export interface MatchReasonCode {
  code: string;
  [param: string]: any;
}

const KNOWN = ["perfect_pair", "native_speaker", "online_now", "active_today", "same_country"];
const PRIMARY = ["perfect_pair", "native_speaker"];

export function reasonChips(
  codes: MatchReasonCode[] | undefined,
  english: string[] | undefined,
  t: (key: string, options?: any) => string
): Array<string | ReasonChip> {
  const fallback = Array.isArray(english) ? english.filter(Boolean) : [];
  if (!Array.isArray(codes)) return fallback;

  const chips: Array<string | ReasonChip> = [];
  codes.forEach((entry, index) => {
    if (!entry || KNOWN.indexOf(entry.code) === -1) {
      if (fallback[index]) chips.push(fallback[index]);
      return;
    }
    const { code, ...params } = entry;
    const key = `communityMain.reasons.${code}`;
    const translated = Object.keys(params).length ? t(key, params) : t(key);
    chips.push({
      text: translated || fallback[index] || "",
      primary: PRIMARY.indexOf(code) > -1,
    });
  });
  return chips.filter((chip) => (typeof chip === "string" ? chip : chip.text));
}
