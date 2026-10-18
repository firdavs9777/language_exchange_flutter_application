import { isEmojiOnly, isWaveText } from "./messageKinds";

/**
 * The app sizes a message by what it says, not by its messageType
 * (text_message_view.dart _isWaveSticker / _isSticker): the wave mirror
 * stores whole sentences as 'sticker', and a plain-text "😂" is a sticker
 * too. Emoji are written as escapes so this file reads the same everywhere.
 */
const WAVE = "\u{1F44B}";
const WAVE_DARK = "\u{1F44B}\u{1F3FF}";
const LAUGH = "\u{1F602}";
const HEART = "❤️";
const FAMILY = "\u{1F468}‍\u{1F469}‍\u{1F467}";
const FLAG_KR = "\u{1F1F0}\u{1F1F7}";
const KEYCAP_ONE = "1️⃣";

describe("isWaveText", () => {
  it("is a wave hand, with or without a skin tone", () => {
    expect(isWaveText(WAVE)).toBe(true);
    expect(isWaveText(` ${WAVE_DARK} `)).toBe(true);
  });
  it("is not a sentence that starts with one, or two hands", () => {
    expect(isWaveText(`${WAVE} Hi, I'm learning Korean!`)).toBe(false);
    expect(isWaveText(WAVE + WAVE)).toBe(false);
    expect(isWaveText("")).toBe(false);
    expect(isWaveText(undefined)).toBe(false);
  });
});

describe("isEmojiOnly", () => {
  it("accepts one to three emoji, ZWJ families, flags, keycaps and hearts included", () => {
    expect(isEmojiOnly(LAUGH)).toBe(true);
    expect(isEmojiOnly(LAUGH + LAUGH + LAUGH)).toBe(true);
    expect(isEmojiOnly(`${LAUGH} ${HEART}`)).toBe(true);
    expect(isEmojiOnly(FAMILY)).toBe(true);
    expect(isEmojiOnly(FLAG_KR)).toBe(true);
    expect(isEmojiOnly(KEYCAP_ONE)).toBe(true);
  });
  it("refuses four or more, any letters, digits, or nothing", () => {
    expect(isEmojiOnly(LAUGH + LAUGH + LAUGH + LAUGH)).toBe(false);
    expect(isEmojiOnly(`${LAUGH} ok`)).toBe(false);
    expect(isEmojiOnly("123")).toBe(false);
    expect(isEmojiOnly("Hi, I'm learning Korean and want to practise with you")).toBe(false);
    expect(isEmojiOnly("   ")).toBe(false);
    expect(isEmojiOnly(null)).toBe(false);
  });
});

describe("bidi marks (RTL keyboards insert them)", () => {
  it("ignores LRM/RLM around emoji and a wave", () => {
    expect(isEmojiOnly("\u200F" + LAUGH + "\u200E")).toBe(true);
    expect(isWaveText("\u200F" + WAVE)).toBe(true);
    expect(isEmojiOnly("\u200F")).toBe(false);
  });
});
