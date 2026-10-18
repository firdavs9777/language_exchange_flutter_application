/**
 * @jest-environment node
 */
// Task D3: the two brand families are served from this origin, not from
// fonts.googleapis.com. Three things have to stay true for that to hold, and
// none of them is visible in a component test:
//
//   1. public/index.html asks Google for nothing (no stylesheet, no noscript
//      copy, no preconnect) -- a single stray <link> puts a third-party round
//      trip back on the critical path of every prerendered page;
//   2. src/index.tsx imports ./fonts.css BEFORE ./index.css, so the @font-face
//      rules precede the rules that use the families;
//   3. src/fonts.css imports exactly the weight/subset files the app renders,
//      and every one of them exists in node_modules -- a typo in a fontsource
//      path is a build error, but a *correct* path to a weight nothing uses is
//      silent dead weight in main.css.
import fs from "fs";
import path from "path";

const ROOT = path.join(__dirname, "..");
const read = (p: string) => fs.readFileSync(path.join(ROOT, p), "utf8");

/**
 * The allowed set, and the reasoning behind it.
 *
 * Inter carries everything the UI renders: 400 (body), 500 (140 `font-medium`),
 * 600 (177 `font-semibold`), 700 (123 `font-bold`), 800 (54 `font-extrabold`).
 * Weight 300 is dropped -- the Google request carried it for
 * src/assets/styles/typography.css, whose `.font-light` class is gone, and the
 * only remaining 300 declarations are bootstrap's unused `.display-1..6`.
 *
 * Plus Jakarta Sans is the display face and is only ever set at 700 (h1-h6,
 * .bt-eyebrow, the navbar/footer/community headings) and 800 (the wordmark and
 * the footer brand). 600 is dropped: no rule in src/ sets the display family
 * at 600.
 *
 * Two subsets each: latin, plus latin-ext for the Turkish, Vietnamese-adjacent
 * and accented European copy in the 18 locale files. Each file's unicode-range
 * means a visitor downloads only the subsets their page actually paints.
 */
const ALLOWED = [
  "@fontsource/inter/latin-400.css",
  "@fontsource/inter/latin-500.css",
  "@fontsource/inter/latin-600.css",
  "@fontsource/inter/latin-700.css",
  "@fontsource/inter/latin-800.css",
  "@fontsource/inter/latin-ext-400.css",
  "@fontsource/inter/latin-ext-500.css",
  "@fontsource/inter/latin-ext-600.css",
  "@fontsource/inter/latin-ext-700.css",
  "@fontsource/inter/latin-ext-800.css",
  "@fontsource/plus-jakarta-sans/latin-700.css",
  "@fontsource/plus-jakarta-sans/latin-800.css",
  "@fontsource/plus-jakarta-sans/latin-ext-700.css",
  "@fontsource/plus-jakarta-sans/latin-ext-800.css",
];

describe("self-hosted fonts", () => {
  it("asks Google for no fonts from the entry HTML", () => {
    const html = read("public/index.html");
    expect(html).not.toContain("fonts.googleapis.com");
    expect(html).not.toContain("fonts.gstatic.com");
  });

  it("imports the font CSS once from the entrypoint, before index.css", () => {
    const entry = read("src/index.tsx");
    const fontsImports = entry.match(/^import "\.\/fonts\.css";$/gm) || [];
    expect(fontsImports).toHaveLength(1);
    const fontsAt = entry.indexOf('import "./fonts.css"');
    const indexAt = entry.indexOf('import "./index.css"');
    expect(fontsAt).toBeGreaterThanOrEqual(0);
    expect(indexAt).toBeGreaterThanOrEqual(0);
    expect(fontsAt).toBeLessThan(indexAt);
  });

  it("imports exactly the allowed weight/subset files", () => {
    const css = read("src/fonts.css");
    const imported = (css.match(/@import "([^"]+)";/g) || []).map((line) =>
      line.replace(/@import "([^"]+)";/, "$1")
    );
    expect(imported.slice().sort()).toEqual(ALLOWED.slice().sort());
  });

  it("resolves every imported file in node_modules", () => {
    for (const spec of ALLOWED) {
      const file = path.join(ROOT, "node_modules", spec);
      expect(fs.existsSync(file)).toBe(true);
      // And the woff2 the rule points at, which is the byte the visitor pays
      // for: fontsource ships the CSS and the files/ directory separately.
      const rule = fs.readFileSync(file, "utf8");
      const woff2 = (rule.match(/url\(\.\/(files\/[^)]+\.woff2)\)/) || [])[1];
      expect(woff2).toBeTruthy();
      expect(fs.existsSync(path.join(path.dirname(file), woff2 as string))).toBe(true);
    }
  });

  it("keeps font-display: swap on every face", () => {
    for (const spec of ALLOWED) {
      const rule = fs.readFileSync(path.join(ROOT, "node_modules", spec), "utf8");
      expect(rule).toContain("font-display: swap");
    }
  });

  it("resets the negative tracking for scripts that must not be tightened", () => {
    const css = read("src/index.css");
    // The variables exist and are what the type rules actually use.
    expect(css).toMatch(/--bt-track-tight:/);
    expect(css).toMatch(/--bt-track-display:/);
    expect(css).toMatch(/letter-spacing: var\(--bt-track-tight\)/);
    expect(css).toMatch(/letter-spacing: var\(--bt-track-display\)/);
    // No raw negative letter-spacing left in the type system.
    const negatives = css.match(/letter-spacing:\s*-[0-9.]+em/g) || [];
    expect(negatives).toEqual([]);
    // Every script whose glyphs must never be tightened is reset.
    for (const lang of ["ko", "ja", "zh", "zh-TW", "th", "ar", "hi"]) {
      expect(css).toContain(`html:lang(${lang})`);
    }
  });
});
