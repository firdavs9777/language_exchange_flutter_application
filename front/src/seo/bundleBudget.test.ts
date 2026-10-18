/**
 * @jest-environment node
 */
// What a first-time visitor downloads before anything on a marketing page can
// become interactive: the main JS entrypoint plus the main stylesheet, gzipped
// the way nginx serves them. Lazy chunks are deliberately not counted -- the
// whole point of task B6 is that they are not on this path.
//
// This suite runs only when BUNDLE_BUDGET=1, which `npm run test:budget` sets
// and which the deploy script therefore sets too. A plain `npm test` skips it:
// otherwise a stale build/ lying around locally fails an unrelated test run
// with a bundle error the developer did not cause, and the useful failure --
// the one right after `react-scripts build` in `npm run deploy` -- gets
// trained away. It also skips when there is no build/ at all.
import fs from "fs";
import path from "path";
import zlib from "zlib";

const BUILD = path.join(__dirname, "..", "..", "build");
const MANIFEST = path.join(BUILD, "asset-manifest.json");
const LOCALES = path.join(__dirname, "..", "utils", "locales");

/**
 * The ceiling for the whole first-paint payload, in gzipped kilobytes.
 *
 * Still NOT the 150 KB the spec asked for, but the biggest single reason is
 * gone: task D1 moved the 17 non-English locales behind `import()`, so only
 * eng.json is inlined and a visitor downloads their own language, or none.
 * What is left in the entrypoint and does not belong to any one route:
 *
 *   - bootstrap + react-bootstrap, used by the shell, the navbar and every
 *     public page (retiring them is spec §5.6, out of scope here);
 *   - moment, iso-639-1's language table and react-icons, all pulled in by the
 *     *prerendered* /moments feed, which cannot be lazy.
 *
 * History, so the next re-baseline is a decision and not a reflex: B6's split
 * took the measured total from 724.5 KB to 559.6 KB and set the budget at
 * 559.6 + 5% = 588. Phase B's 90 marketing strings in 18 locales then added
 * ~45 KB gzipped (610.1 measured), and the budget was raised to 641 rather
 * than defended -- which is exactly why APP_BUDGET_KB below exists. D1 then
 * took 298 KB straight back out: main.js 551.6 -> 253.8 KB, total 608.0 ->
 * 310.2 KB measured, + 5% = 325.7 -> 326. D2 took the socket.io client out of
 * the entrypoint too (13.2 KB gzipped, and nothing a logged-out visitor can
 * use): main.js 262.6 -> 251.4 KB, total 320.3 -> 309.1 KB measured,
 * + 5% = 324.6 -> 325.
 *
 * Task D3 is the one re-baseline in this list that raises the number, and it
 * buys something with it: self-hosting Inter and Plus Jakarta Sans put 14
 * @font-face rules into this stylesheet -- main.css 57.6 -> 58.4 KB gzipped
 * (376.7 -> 380.7 KB raw), +0.8 KB -- and took two render-path round trips to
 * fonts.googleapis.com and fonts.gstatic.com off every prerendered page. The
 * woff2 files themselves are separate assets under static/media and are NOT
 * counted here, the same way no other image or font ever has been; each rule
 * carries a unicode-range, so a visitor fetches only the subsets their page
 * paints (latin Inter 400 is 23.1 KB, Plus Jakarta Sans 700 is 12.0 KB).
 * Total 309.1 -> 310.0 KB measured, + 5% = 325.5 -> 326.
 *
 * That headroom is now real headroom, not locale slack: with 17 locales out of
 * the entrypoint this number can only grow if app code grows, so raising it
 * again is the same decision as raising APP_BUDGET_KB and needs the same
 * justification.
 */
export const BUDGET_KB = 326;

/**
 * The ceiling for everything that is NOT locale JSON, in gzipped kilobytes.
 *
 * The load-bearing half of this test. A single whole-entrypoint number is
 * trivially re-baselined: 18 locales grow, the total grows, someone bumps the
 * constant, and route code that crept back into main.js rides along invisibly.
 * Subtracting the locale weight leaves the number that actually tracks the
 * split, so a group collapsing back into the entrypoint fails here even while
 * the total still fits.
 *
 * Measured when it was set: 607.4 KB total − 305.8 KB of locale JSON = 301.5 KB
 * of app code, + 5% = 316.6 → 317. Same rule as BUDGET_KB, applied to the part
 * that is under this repo's control.
 *
 * Deliberately NOT re-baselined by task D1: no app code moved, and the number
 * it guards barely did (310.2 − 15.3 = 294.9 KB measured now, against 301.5
 * before). The subtraction has simply got much smaller -- eng.json alone
 * instead of all 18 files -- so this and BUDGET_KB now sit only ~15 KB apart
 * and the two assertions largely agree, which is the point: after D1 there is
 * almost no locale weight left for app growth to hide behind.
 *
 * Task D2 DOES re-baseline it, because this time app code is exactly what
 * moved: socket.io-client is `import()`ed from the provider's effect, so the
 * client ships as its own chunk and the entrypoint lost 11.2 KB of it (the
 * rest is webpack's loader plumbing). 309.1 − 18.4 = 290.7 KB measured,
 * + 5% = 305.2 → 306. Measured on a tree that also carried task D4's consent
 * UI in progress, so a KB or so of that 290.7 is D4's, not the shell's --
 * which only makes this ceiling tighter, never looser.
 *
 * Task D3 re-baselines it by exactly the @font-face delta and nothing else:
 * the font rules live in main.css, main.css is inside this subtraction, and
 * main.js did not move (251.5 -> 251.6 KB). 310.0 − 18.5 = 291.5 KB measured,
 * + 5% = 306.1 → 307. The 0.8 KB is the whole of the change; if a future
 * measurement here has grown by more than that, it is app code, not fonts.
 */
export const APP_BUDGET_KB = 307;

const readGzipKb = (assetPath: string): number => {
  const file = path.join(BUILD, assetPath.replace(/^\//, ""));
  return zlib.gzipSync(fs.readFileSync(file)).length / 1024;
};

/**
 * The gzipped weight of the locale JSON that is *in the entrypoint*.
 *
 * Since task D1 that is eng.json and nothing else: the other 17 files are
 * `import()`ed by src/utils/i18nLazyBackend.ts and ship as their own chunks,
 * which this budget never counted and still does not. Measuring all 18 here
 * would subtract ~306 KB that main.js no longer carries and hand app code a
 * 290 KB blind spot.
 *
 * Still an approximation on purpose, and an honest one: what ships is the JSON
 * inlined into main.js as a minified object literal, which no manifest entry
 * isolates, so the only way to weigh it exactly would be to parse the bundle.
 * Gzipping the source is within a few percent of that and, more to the point,
 * it moves with the English copy -- which is all this subtraction needs.
 */
const localesGzipKb = (): number =>
  zlib.gzipSync(fs.readFileSync(path.join(LOCALES, "eng.json"))).length / 1024;

const enabled = process.env.BUNDLE_BUDGET === "1";
const hasBuild = fs.existsSync(MANIFEST);
const describeIfBuilt = enabled && hasBuild ? describe : describe.skip;

if (!enabled) {
  // eslint-disable-next-line no-console
  console.log("[bundleBudget] BUNDLE_BUDGET is not 1; skipping. Run `npm run test:budget`.");
} else if (!hasBuild) {
  // eslint-disable-next-line no-console
  console.log("[bundleBudget] no build/asset-manifest.json; skipping. Run `npm run build` first.");
}

describeIfBuilt("marketing bundle budget", () => {
  const manifest = hasBuild ? JSON.parse(fs.readFileSync(MANIFEST, "utf8")) : { files: {}, entrypoints: [] };
  const entrypoints: string[] = manifest.entrypoints || [];

  it("ships exactly one main JS chunk and one main stylesheet", () => {
    expect(entrypoints.filter((f) => f.endsWith(".js")).length).toBe(1);
    expect(entrypoints.filter((f) => f.endsWith(".css")).length).toBe(1);
  });

  it("keeps app code and the whole first-paint payload inside their budgets", () => {
    const js = entrypoints.filter((f) => f.endsWith(".js")).map(readGzipKb);
    const css = entrypoints.filter((f) => f.endsWith(".css")).map(readGzipKb);
    const total = js.concat(css).reduce((a, b) => a + b, 0);
    const locales = localesGzipKb();
    const appCode = total - locales;
    /* eslint-disable no-console */
    console.log(
      `[bundleBudget] main.js ${js[0].toFixed(1)} KB + main.css ${css[0].toFixed(1)} KB` +
        ` = ${total.toFixed(1)} KB gzipped (budget ${BUDGET_KB} KB)`
    );
    console.log(
      `[bundleBudget] app code ${appCode.toFixed(1)} KB gzipped` +
        ` (budget ${APP_BUDGET_KB} KB) = total − ${locales.toFixed(1)} KB of locale JSON`
    );
    /* eslint-enable no-console */
    // App code first: it is the assertion that means something. The total is
    // still asserted, so the two together cannot both drift.
    expect(appCode).toBeLessThanOrEqual(APP_BUDGET_KB);
    expect(total).toBeLessThanOrEqual(BUDGET_KB);
  });

  it("splits the authenticated app out of the entrypoint", () => {
    // Lazy route groups: auth, profile, moments composer, chat, stories,
    // settings, community-authenticated, courses, admin. If this collapses,
    // something eager started importing a lazy module and dragged its whole
    // group back into main.js.
    //
    // The floor is 35 against 47 measured, not the 9 groups: webpack emits a
    // chunk per split point plus its shared vendor chunks, so a single group
    // folding back into main.js costs several chunks at once and a floor near
    // the real number is the only one that notices. Twelve chunks of slack
    // absorbs the ordinary churn -- a lazy page added or merged -- without
    // absorbing a whole group.
    //
    // Still 47 measured after task D1 added 17 locale chunks, and not by luck:
    // those carry a `webpackChunkName`, so the manifest keys them by that name
    // ("locale-ko.js") rather than by an output path, and this key-shaped
    // filter never sees them. That is the behaviour we want -- a padded count
    // would let a whole route group fold back into main.js unnoticed -- so the
    // locale chunks get their own assertion below instead.
    const lazyChunks = Object.keys(manifest.files || {}).filter((f) => /^static\/js\/.*\.chunk\.js$/.test(f));
    expect(lazyChunks.length).toBeGreaterThanOrEqual(35);
  });

  it("ships the socket client as its own chunk, absent from the entrypoint", () => {
    // Task D2. Named "socketio" (no dot, no hyphen) so that the grep below --
    // the check a human runs by hand -- cannot be answered by webpack's own
    // chunk-name map, which lives inside main.js and names every named chunk.
    const key = Object.keys(manifest.files || {}).filter((f) => /^socketio\.js$/.test(f));
    expect(key).toEqual(["socketio.js"]);
    expect(fs.existsSync(path.join(BUILD, (manifest.files["socketio.js"] as string).replace(/^\//, "")))).toBe(
      true
    );

    // And the client itself is not in the entrypoint: engine.io's transport
    // strings are the part of the package that survives minification.
    const entryJs = entrypoints.filter((f) => f.endsWith(".js"))[0];
    const main = fs.readFileSync(path.join(BUILD, entryJs.replace(/^\//, "")), "utf8");
    expect(main).not.toContain("socket.io");
    expect(main).not.toContain("engine.io");

    const chunk = fs.readFileSync(
      path.join(BUILD, (manifest.files["socketio.js"] as string).replace(/^\//, "")),
      "utf8"
    );
    expect(chunk).toContain("engine.io");
  });

  it("emits one chunk per lazy locale and loads none of them up front", () => {
    // The other side of the split. Without this, `resources` quietly shrinking
    // to English with no working backend would read as a 290 KB win here and
    // as 17 untranslated languages in production.
    // Keyed by their `webpackChunkName`, one per language (see above).
    const localeChunks = Object.keys(manifest.files || {}).filter((f) => /^locale-.+\.js$/.test(f));
    expect(localeChunks.sort()).toEqual(
      ["ar", "de", "es", "fr", "hi", "id", "it", "ja", "ko", "pt", "ru", "th", "tl", "tr", "vi", "zh", "zh-TW"]
        .map((c) => `locale-${c}.js`)
        .sort()
    );
    for (const key of localeChunks) {
      expect(fs.existsSync(path.join(BUILD, (manifest.files[key] as string).replace(/^\//, "")))).toBe(true);
    }

    // eng.json is inlined, so no chunk for it, and nothing preloads the rest:
    // the entry HTML must reference only the entrypoint.
    const html = fs.readFileSync(path.join(BUILD, "index.html"), "utf8");
    expect(html).not.toMatch(/locale-/);
  });
});
