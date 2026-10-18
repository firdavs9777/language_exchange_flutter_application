/**
 * What a message IS, read from what it says — the app's rule
 * (text_message_view.dart _isWaveSticker / _isSticker), not messageType. The
 * wave mirror stores whole sentences as 'sticker'; a plain-text emoji is a
 * sticker all the same.
 *
 * Kept out of the components on purpose: chatStyling.test.ts forbids emoji
 * characters in chat component sources, so every emoji here is an escape.
 */

// One emoji as a person sees it: a flag (two regional indicators), a keycap,
// or a pictograph with an optional VS16 / skin tone, ZWJ-joined to more.
const CLUSTER =
  "(?:\\p{Regional_Indicator}{2}" +
  "|[0-9#*]\\uFE0F?\\u20E3" +
  "|\\p{Extended_Pictographic}(?:\\uFE0F|\\p{Emoji_Modifier})?" +
  "(?:\\u200D\\p{Extended_Pictographic}(?:\\uFE0F|\\p{Emoji_Modifier})?)*)";

const EMOJI_ONLY = new RegExp(`^(?:${CLUSTER}\\s*){1,3}$`, "u");
const WAVE = new RegExp("^\\u{1F44B}\\p{Emoji_Modifier}?\\uFE0F?$", "u");

/** One to three emoji and nothing else: drawn at sticker size. */
// Direction marks an RTL keyboard (ar) slips around an emoji; never content.
const BIDI = /[\u200E\u200F\u061C\u202A-\u202E\u2066-\u2069]/g;

export function isEmojiOnly(text: string | null | undefined): boolean {
  if (typeof text !== "string") return false;
  const trimmed = text.replace(BIDI, "").trim();
  if (!trimmed || trimmed.length > 48) return false;
  return EMOJI_ONLY.test(trimmed);
}

/** A lone waving hand, any skin tone: drawn as the app's greeting card. */
export function isWaveText(text: string | null | undefined): boolean {
  if (typeof text !== "string") return false;
  return WAVE.test(text.replace(BIDI, "").trim());
}
