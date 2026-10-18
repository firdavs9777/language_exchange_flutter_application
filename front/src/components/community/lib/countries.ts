/**
 * The country picker's options.
 *
 * The filter was a free-text box, matched by substring on the server, so
 * "Korea" found both Koreas and "Niger" found Nigeria. It is a list now, of
 * real ISO 3166-1 regions:
 *
 *   - `label` is in the reader's UI language, from the browser's own ICU data
 *     (Intl.DisplayNames) -- no table to maintain, and 18 locales for free.
 *   - `value` is always the ENGLISH name. That is what the server stores
 *     (lib/countryNames.js normalises location.country to English on write)
 *     and what its filter resolves to a country and matches exactly.
 */

/** ISO 3166-1 alpha-2 codes for countries and inhabited territories. */
export const COUNTRY_CODES = [
  "AD", "AE", "AF", "AG", "AI", "AL", "AM", "AO", "AR", "AS", "AT", "AU", "AW", "AX", "AZ",
  "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BL", "BM", "BN", "BO", "BQ", "BR",
  "BS", "BT", "BW", "BY", "BZ", "CA", "CC", "CD", "CF", "CG", "CH", "CI", "CK", "CL", "CM",
  "CN", "CO", "CR", "CU", "CV", "CW", "CX", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ",
  "EC", "EE", "EG", "EH", "ER", "ES", "ET", "FI", "FJ", "FK", "FM", "FO", "FR", "GA", "GB",
  "GD", "GE", "GF", "GG", "GH", "GI", "GL", "GM", "GN", "GP", "GQ", "GR", "GT", "GU", "GW",
  "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IM", "IN", "IQ", "IR", "IS", "IT",
  "JE", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KP", "KR", "KW", "KY", "KZ",
  "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "LY", "MA", "MC", "MD", "ME",
  "MF", "MG", "MH", "MK", "ML", "MM", "MN", "MO", "MP", "MQ", "MR", "MS", "MT", "MU", "MV",
  "MW", "MX", "MY", "MZ", "NA", "NC", "NE", "NF", "NG", "NI", "NL", "NO", "NP", "NR", "NU",
  "NZ", "OM", "PA", "PE", "PF", "PG", "PH", "PK", "PL", "PM", "PN", "PR", "PS", "PT", "PW",
  "PY", "QA", "RE", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SD", "SE", "SG", "SH", "SI",
  "SK", "SL", "SM", "SN", "SO", "SR", "SS", "ST", "SV", "SX", "SY", "SZ", "TC", "TD", "TG",
  "TH", "TJ", "TK", "TL", "TM", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US",
  "UY", "UZ", "VA", "VC", "VE", "VG", "VI", "VN", "VU", "WF", "WS", "XK", "YE", "YT", "ZA",
  "ZM", "ZW",
];

export interface CountryOption {
  code: string;
  /** In the reader's language. */
  label: string;
  /** Always English: what the server stores and matches. */
  value: string;
}

function displayNames(locale: string): ((code: string) => string | undefined) | null {
  try {
    const names = new (Intl as any).DisplayNames([locale], { type: "region" });
    return (code: string) => names.of(code);
  } catch (e) {
    return null;
  }
}

/** Every country, labelled in `locale` and sorted the way that locale sorts. */
export function countryOptions(rawLocale: string = "en"): CountryOption[] {
  // The app's locale ids are i18next's (`zh_TW`); Intl wants BCP 47 (`zh-TW`)
  // and throws on the underscore, which would leave Traditional Chinese
  // readers with English labels.
  const locale = (rawLocale || "en").replace(/_/g, "-");
  const english = displayNames("en");
  const local = displayNames(locale) || english;
  if (!english || !local) return [];
  const options = COUNTRY_CODES.map((code) => {
    const value = english(code) || code;
    return { code, value, label: local(code) || value };
  });
  let collator: Intl.Collator;
  try {
    collator = new Intl.Collator(locale);
  } catch (e) {
    collator = new Intl.Collator("en");
  }
  return options.sort((a, b) => collator.compare(a.label, b.label));
}
