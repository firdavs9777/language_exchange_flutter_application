import en from "../utils/locales/eng.json";

/** Reads a dotted key from a locale object; "" when absent or not a string. */
export function getByPath(obj: any, key: string): string {
  const value = key.split(".").reduce((acc, part) => (acc == null ? undefined : acc[part]), obj);
  return typeof value === "string" ? value : "";
}

/** The English string for a key, for the `t(key) || englishFallback(key)` idiom. */
export function englishFallback(key: string): string {
  return getByPath(en, key);
}
