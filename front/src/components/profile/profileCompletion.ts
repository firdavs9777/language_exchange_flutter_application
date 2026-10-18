import { normalizeIntents } from "./intents";

export interface ProfileCompletion {
  filled: number;
  total: number;
  /** 0-100, rounded. */
  percent: number;
}

const text = (value: any): boolean => typeof value === "string" && value.trim().length > 0;

/**
 * How complete a profile is, by the app's own rule
 * (edit_main/completion_calculator.dart): ten fields, one point each — name,
 * gender, bio, native language, learning language, CEFR level, MBTI, address,
 * at least one topic, at least one intent.
 *
 * The same ten on purpose, so a profile reads the same percentage on either
 * platform. Address is not editable in the web form, but web sign-up captures
 * it (register/resolveLocation), so it is counted from the loaded document
 * rather than dropped — dropping it would make the two numbers disagree.
 *
 * Intents are in the list for the reason the app gives: this meter is the one
 * surface that reaches people who signed up before the field existed.
 */
export function profileCompletion(source: any): ProfileCompletion {
  const user = source || {};
  const location = user.location || {};
  const checks = [
    text(user.name),
    text(user.gender),
    text(user.bio),
    text(user.native_language),
    text(user.language_to_learn),
    text(user.languageLevel),
    text(user.mbti),
    text(location.formattedAddress) || text(location.city) || text(location.country),
    Array.isArray(user.topics) && user.topics.some(text),
    normalizeIntents(user.intents).length > 0,
  ];
  const total = checks.length;
  const filled = checks.filter(Boolean).length;
  return { filled, total, percent: Math.round((filled / total) * 100) };
}
