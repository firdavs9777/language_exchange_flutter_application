import ISO6391 from "iso-639-1";

/**
 * A room's language (an ISO-style code such as "ko" or "yue") in the
 * reader's UI language, via the browser's ICU data, with the library's
 * English name and finally the bare code as fallbacks.
 */
export function roomLanguageName(code: string, rawLocale: string = "en"): string {
  const c = String(code || "").trim();
  if (!c) return "";
  const locale = (rawLocale || "en").replace(/_/g, "-");
  try {
    const name = new (Intl as any).DisplayNames([locale], { type: "language" }).of(c);
    if (name && String(name).toLowerCase() !== c.toLowerCase()) return String(name);
  } catch (e) {
    // no Intl.DisplayNames, or an unknown code
  }
  return ISO6391.getName(c) || c;
}
