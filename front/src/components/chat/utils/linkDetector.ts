/**
 * Link detection for chat messages.
 *
 * Every pattern below is BUILT PER CALL. The previous version kept `/g`
 * regexes at module scope and called `.test()` on them, so `lastIndex`
 * survived between calls and the same string answered true, then false, then
 * true. A detector on a message list's render path cannot have memory.
 */

// A URL that carries its own scheme.
const SCHEME_URL = "https?:\\/\\/[^\\s<>]+";
// Scheme-less but unmistakable.
const WWW_URL = "www\\.[^\\s<>]+";
// A bare domain is only a link when its last label is one of these. Without
// the list, "I went.Then" and "etc.Also" become links.
const TLDS =
  "com|net|org|io|dev|app|co|me|ai|info|xyz|edu|gov|tv|blog|site|online|shop|kr|jp|uz|ru|uk|de|fr|es|it|br|in|cn";
const BARE_URL =
  "[a-z0-9][a-z0-9-]*(?:\\.[a-z0-9-]+)*\\.(?:" + TLDS + ")(?:[/?#][^\\s<>]*)?";

const urlPattern = (): RegExp =>
  new RegExp("(?:" + SCHEME_URL + ")|(?:" + WWW_URL + ")|(?:" + BARE_URL + ")", "gi");

export interface DetectedLink {
  /** The URL exactly as the person typed it. */
  text: string;
  /** An absolute href — a scheme is added when the typed text had none. */
  url: string;
  /** Hostname without `www.`, for the card's heading. */
  host: string;
}

const CLOSERS: { [closer: string]: string } = { ")": "(", "]": "[", "}": "{" };

const countOf = (text: string, char: string): number => text.split(char).length - 1;

/**
 * Sentence punctuation that trails a URL is part of the sentence, not the
 * link — except a bracket the URL itself opened
 * (`…/wiki/Kimchi_(food)` keeps its pair).
 */
const trimTrailingPunctuation = (raw: string): string => {
  let out = raw;
  while (out.length > 0) {
    const last = out.charAt(out.length - 1);
    if (".,!?;:'\"".indexOf(last) >= 0) {
      out = out.slice(0, -1);
      continue;
    }
    const opener = CLOSERS[last];
    if (opener && countOf(out, last) > countOf(out, opener)) {
      out = out.slice(0, -1);
      continue;
    }
    break;
  }
  return out;
};

const toHref = (text: string): string =>
  /^https?:\/\//i.test(text) ? text : "https://" + text;

/**
 * A link starts at the start of the message or after whitespace or an opening
 * bracket — nothing else. The test used to be the other way round, rejecting a
 * match preceded by an ASCII word character, and any non-ASCII letter then read
 * as a boundary: "besuche munchen.de" with the real umlaut carded `nchen.de`,
 * a DIFFERENT domain from the one in the text. A positive class cannot do that.
 *
 * The cost is that a true IDN host (`日本.jp`, `привет.рф`) is not detected at
 * all, which is a miss rather than a misdirection, and the message text still
 * shows the address in full.
 */
const OPENS_A_LINK = /[\s("'[<]/;

const isStandalone = (text: string, index: number): boolean => {
  if (index === 0) return true;
  return OPENS_A_LINK.test(text.charAt(index - 1));
};

/**
 * The first URL in a message, or null. A message bubble renders a card for it;
 * nothing is fetched, so only what the text itself says can be shown.
 */
export const firstLink = (text: string): DetectedLink | null => {
  if (!text) return null;
  const pattern = urlPattern();
  let match = pattern.exec(text);
  while (match !== null) {
    if (isStandalone(text, match.index)) {
      const typed = trimTrailingPunctuation(match[0]);
      if (typed) {
        const url = toHref(typed);
        let host: string;
        try {
          host = new URL(url).hostname.replace(/^www\./, "");
        } catch (e) {
          host = typed;
        }
        return { text: typed, url, host };
      }
    }
    match = pattern.exec(text);
  }
  return null;
};
