import ISO6391 from "iso-639-1";

export interface LanguageOption {
  /** ISO 639-1 code: what a moment stores and the server filters on. */
  value: string;
  /** In the reader's UI language. */
  label: string;
}

/**
 * Every ISO 639-1 language, labelled in the reader's language through the
 * browser's own ICU data (the countries.ts approach), with the library's
 * English name as the fallback.
 */
export function languageOptions(rawLocale: string = "en"): LanguageOption[] {
  const locale = (rawLocale || "en").replace(/_/g, "-");
  let names: any = null;
  try {
    names = new (Intl as any).DisplayNames([locale], { type: "language" });
  } catch (e) {
    names = null;
  }
  const options = ISO6391.getAllCodes().map((code) => {
    let label: string | undefined;
    try {
      label = names ? names.of(code) : undefined;
    } catch (e) {
      label = undefined;
    }
    return { value: code, label: label && label !== code ? label : ISO6391.getName(code) || code };
  });
  let collator: Intl.Collator;
  try {
    collator = new Intl.Collator(locale);
  } catch (e) {
    collator = new Intl.Collator("en");
  }
  return options.sort((a, b) => collator.compare(a.label, b.label));
}
