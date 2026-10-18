import { stripVariant, toBaseIso6391 } from "../../../utils/languages";

/** One row of GET /api/v1/languages (models/Language.js). */
export interface CatalogLanguage {
  code?: string;
  name?: string;
  nativeName?: string;
}

export interface LanguageOption {
  /** English base name — what the server stores and matches. */
  value: string;
  /** Shown to the reader, in their UI language. */
  label: string;
}

function languageNamer(locale: string): ((code: string) => string | undefined) | null {
  try {
    const names = new (Intl as any).DisplayNames([locale], { type: "language" });
    return (code: string) => {
      try {
        return names.of(code);
      } catch (e) {
        return undefined;
      }
    };
  } catch (e) {
    return null;
  }
}

/**
 * The filter's language list, built from the shared catalog the app uses
 * (filter_languages_section.dart reads the same GET /languages).
 *
 * - Variants fold into their base ("Arabic (Egypt)" -> "Arabic"): the server
 *   matches the base name against every variant, and four Arabics in a
 *   dropdown answer a question nobody asked.
 * - The value is always the English name (what users store); the label is
 *   the language's name in the reader's locale via Intl.DisplayNames. A code
 *   with no hyphen is looked up as is ("fil" is Filipino, not Tagalog); a
 *   hyphenated variant by its base. When Intl has no name it echoes the
 *   code, and the English name is used instead.
 */
export function languageOptions(
  catalog: CatalogLanguage[] | undefined | null,
  rawLocale: string = "en"
): LanguageOption[] {
  // i18next ids use underscores (zh_TW); Intl throws on them.
  const locale = (rawLocale || "en").replace(/_/g, "-");
  const named = languageNamer(locale);
  const seen: Record<string, boolean> = {};
  const options: LanguageOption[] = [];

  (Array.isArray(catalog) ? catalog : []).forEach((entry) => {
    const name = entry && typeof entry.name === "string" ? entry.name.trim() : "";
    if (!name) return;
    const value = stripVariant(name);
    if (!value || seen[value]) return;
    seen[value] = true;

    const code = entry && typeof entry.code === "string" ? entry.code.trim() : "";
    const lookup = code.indexOf("-") > 0 ? toBaseIso6391(code) : code;
    const local = lookup && named ? named(lookup) : undefined;
    const label =
      local && local.toLowerCase() !== String(lookup).toLowerCase() ? local : value;
    options.push({ value, label });
  });

  // Intl folds some codes into one name (ICU aliases "tl" to Filipino), so
  // two catalog rows can come back with the same label. A dropdown with two
  // identical entries is a guess for the reader: those fall back to their
  // English names, keeping any row whose label already is its own name.
  const labelCount: Record<string, number> = {};
  options.forEach((option) => {
    labelCount[option.label] = (labelCount[option.label] || 0) + 1;
  });
  options.forEach((option) => {
    if (labelCount[option.label] > 1 && option.label !== option.value) {
      option.label = option.value;
    }
  });

  let collator: Intl.Collator;
  try {
    collator = new Intl.Collator(locale);
  } catch (e) {
    collator = new Intl.Collator("en");
  }
  return options.sort((a, b) => collator.compare(a.label, b.label));
}
