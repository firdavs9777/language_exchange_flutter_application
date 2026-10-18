export type WebTarget = { kind: "external"; href: string } | { kind: "internal"; path: string } | null;

const ROUTES: Array<[RegExp, (m: RegExpMatchArray) => string]> = [
  [/^moments?\/([^/?#]+)$/, (m) => `/moment/${m[1]}`],
  [/^profile\/([^/?#]+)$/, (m) => `/profile/${m[1]}`],
  [/^community\/([^/?#]+)$/, (m) => `/community/${m[1]}`],
  [/^i\/([^/?#]+)$/, (m) => `/i/${m[1]}`],
  [/^announcement\/([^/?#]+)$/, (m) => `/announcement/${m[1]}`],
];

/** Where an announcement button goes on the website; null hides the button. */
export function webTargetFor(buttonUrl: string | null | undefined): WebTarget {
  const url = (buttonUrl || "").trim();
  if (/^https?:\/\/[^\s/?#]+/i.test(url)) return { kind: "external", href: url };
  const m = /^bananatalk:\/\/(.+)$/i.exec(url);
  if (!m) return null;
  for (const [re, to] of ROUTES) {
    const hit = m[1].match(re);
    if (hit) return { kind: "internal", path: to(hit) };
  }
  return null;
}
