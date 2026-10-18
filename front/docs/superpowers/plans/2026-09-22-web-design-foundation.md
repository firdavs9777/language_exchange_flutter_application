# Web Design Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the web the app's visual vocabulary as additive Tailwind tokens plus six shared primitives, so Community, Moments, Profile and Notifications can each consume tested pieces instead of re-inventing them.

**Architecture:** Tokens are added to `tailwind.config.js` under brand-specific names (`brand`, `banana`, `rounded-card`, `shadow-card`) and override none of Tailwind's defaults — the spec measured that overriding `colors.teal` alone would silently kill 327 class usages. Primitives live in a new `src/design/` directory, each one pure, presentational and tested in isolation. The language data that three of them depend on is **generated** from the backend's own catalog by a committed script, not hand-authored.

**Tech Stack:** React 18.3 + TypeScript (strict), Create React App (`react-scripts` 5.0.1), Tailwind CSS 3.4.17, Jest + `@testing-library/react` 14.3, RTK Query (`@reduxjs/toolkit`).

**Spec:** `docs/superpowers/specs/2026-09-22-web-design-foundation-design.md`

## Global Constraints

- **Branch:** `feat/next-feature`, already created off `main`. Do not create another.
- **Additive tokens only.** Never override a Tailwind default key (`colors.teal`, `borderRadius.lg/xl`, `boxShadow.sm/md/lg`). Task 1 adds a test that fails if someone does.
- **No new Bootstrap markup**, global-CSS classes (`d-flex`, `btn btn-*`, `text-muted`) or `react-bootstrap` imports, in any file this plan touches.
- **Opacity is always an arbitrary modifier:** `bg-brand/[0.09]`, never `bg-brand/9`. Tailwind v3 emits **no rule at all** for an opacity step absent from `theme.opacity`, with no build error.
- **Every primitive ships its `dark:` variants in the same commit that creates it.** `darkMode` stays at Tailwind's default `'media'` — do not add a `darkMode` key.
- **No surface is converted by this plan.** `MemberCard`, `ProfileHeader`, `SingleMoment` and `LanguagesCard` keep their markup. The only exception is Task 5's import swap, which changes their language *data source* and nothing else.
- **Test style matches the codebase:** each test file starts with `import "@testing-library/jest-dom";`, uses flat `it(...)` blocks and `data-testid` queries. There is no `setupTests` file — the import goes in every test file.
- **Test command:** `CI=true npx react-scripts test --testPathPattern=<pattern>`. `CI=true` makes it run once and exit instead of entering watch mode.
- **No snapshot tests.** Four sub-projects are about to reshape this markup.

---

### Task 1: Tailwind brand tokens

**Files:**
- Modify: `tailwind.config.js` (whole file, currently 8 lines)
- Create: `src/design/tokens.test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces: the class names every later task uses — `bg-brand`, `bg-brand/[0.09]`, `text-brand-dark`, `bg-banana/[0.28]`, `text-banana-dark`, `bg-surface`, `dark:bg-cardbg-dark`, `rounded-card`, `rounded-chip`, `shadow-card`, `shadow-raised`, `shadow-float`, `shadow-brand`.

- [ ] **Step 1: Write the failing test**

Create `src/design/tokens.test.ts`:

```ts
import path from "path";
import resolveConfig from "tailwindcss/resolveConfig";

// require() with an absolute path, not a relative import: CRA's webpack
// ModuleScopePlugin forbids importing from outside src/, and while Jest does
// not enforce that, keeping it a runtime require avoids the rule entirely.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const tailwindConfig = require(path.resolve(__dirname, "../../tailwind.config.js"));
const theme = (resolveConfig(tailwindConfig) as any).theme;

it("exposes the app's brand palette", () => {
  expect(theme.colors.brand.DEFAULT).toBe("#00BFA5");
  expect(theme.colors.brand.light).toBe("#5DF2D6");
  expect(theme.colors.brand.dark).toBe("#008E76");
  expect(theme.colors.banana.DEFAULT).toBe("#FFD54F");
  expect(theme.colors.banana.dark).toBe("#C9A415");
});

it("exposes the app's surface colours in both themes", () => {
  expect(theme.colors.surface.DEFAULT).toBe("#FFFFFF");
  expect(theme.colors.surface.dark).toBe("#1E1E1E");
  expect(theme.colors.canvas.DEFAULT).toBe("#F8F9FA");
  expect(theme.colors.cardbg.dark).toBe("#2C2C2C");
});

it("exposes the app's radii and shadows", () => {
  expect(theme.borderRadius.card).toBe("20px");
  expect(theme.borderRadius.chip).toBe("12px");
  expect(theme.borderRadius.sheet).toBe("24px");
  expect(theme.boxShadow.card).toBe("0 1px 4px rgba(0,0,0,0.04)");
  expect(theme.boxShadow.raised).toBe("0 2px 8px rgba(0,0,0,0.06)");
  expect(theme.boxShadow.float).toBe("0 4px 16px rgba(0,0,0,0.08)");
  expect(theme.boxShadow.brand).toBe("0 6px 16px rgba(0,191,165,0.30)");
});

// The guard. Overriding colors.teal replaces Tailwind's whole scale rather
// than merging into it, which would stop 327 teal-N usages across 49 files
// from emitting any CSS -- silently, with no build error. Same class of
// problem for the radius and shadow scales.
it("leaves Tailwind's own scales untouched", () => {
  expect(theme.colors.teal["500"]).toBe("#14b8a6");
  expect(theme.colors.teal["50"]).toBeDefined();
  expect(theme.colors.teal["900"]).toBeDefined();
  expect(theme.borderRadius.xl).toBe("0.75rem");
  expect(theme.borderRadius.lg).toBe("0.5rem");
  expect(theme.boxShadow.lg).toContain("10px 15px");
  expect(theme.colors.gray["500"]).toBe("#6b7280");
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=design/tokens`
Expected: FAIL — `Cannot read properties of undefined (reading 'DEFAULT')`, because `theme.colors.brand` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

Replace the whole of `tailwind.config.js`:

```js
// tailwind.config.js
//
// Tokens ported from the Flutter app's lib/core/theme/app_theme.dart so the
// two products share one visual vocabulary.
//
// These are ADDITIVE and brand-named on purpose. An earlier draft overrode
// `teal`, `borderRadius` and `boxShadow` so that reaching for a Tailwind
// default produced the app's value. Measured against this codebase that would
// have broken 327 `teal-N` usages across 49 files (Tailwind REPLACES a colour
// scale rather than merging it), moved 232 radius call sites and re-weighted
// 102 shadows, including in Chat and Learning which no current sub-project
// touches. src/design/tokens.test.ts guards against reintroducing that.
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        brand: { DEFAULT: "#00BFA5", light: "#5DF2D6", dark: "#008E76" }, // AppColors.primary
        banana: { DEFAULT: "#FFD54F", light: "#FFFF81", dark: "#C9A415" }, // AppColors.secondary
        surface: { DEFAULT: "#FFFFFF", dark: "#1E1E1E" },
        canvas: { DEFAULT: "#F8F9FA", dark: "#121212" },
        cardbg: { DEFAULT: "#FFFFFF", dark: "#2C2C2C" },
      },
      borderRadius: {
        card: "20px",  // AppRadius.xl
        chip: "12px",  // AppRadius.md
        sheet: "24px", // AppRadius.xxl
      },
      boxShadow: {
        card: "0 1px 4px rgba(0,0,0,0.04)",       // AppShadows.sm
        raised: "0 2px 8px rgba(0,0,0,0.06)",     // AppShadows.md
        float: "0 4px 16px rgba(0,0,0,0.08)",     // AppShadows.lg
        brand: "0 6px 16px rgba(0,191,165,0.30)", // AppShadows.colored
      },
    },
  },
  plugins: [],
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=design/tokens`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add tailwind.config.js src/design/tokens.test.ts
git commit -m "feat(design): add the app's brand tokens to Tailwind

Ported from app_theme.dart under brand-specific names. Additive only --
a test asserts teal-500, rounded-xl, rounded-lg and shadow-lg still
resolve to Tailwind's defaults, because overriding colors.teal would
silently stop 327 class usages from emitting CSS."
```

---

### Task 2: Generate the language data from the backend catalog

**Files:**
- Create: `scripts/generate-language-data.js`
- Create: `src/utils/languages.data.ts` (generated output, committed)

**Interfaces:**
- Consumes: nothing from earlier tasks. Reads the sibling backend repo at generation time only.
- Produces, from `src/utils/languages.data.ts`:
  - `CATALOG_NAME_TO_FLAG: Record<string, string>` — lowercased full catalog name → flag, 137 entries (`"chinese (traditional)"` → `"🇹🇼"`)
  - `NAME_TO_ISO: Record<string, string>` — lowercased language name → base ISO code, 134 entries (`"persian"` → `"fa"`)
  - `CODE_TO_FLAG: Record<string, string>` — base ISO code → flag, 115 entries (`"fa"` → `"🇮🇷"`, `"zh"` → `"🇨🇳"`)

**Context the implementer needs:** the backend repo sits beside this one at `../language_exchange_backend_application`. `seeds/languages.js` exports `{ languages }` (137 entries of `{ code, name, nativeName, flag }`) and `utils/languageCodes.js` exports `{ NAME_TO_ISO }` (134 name keys → 115 distinct codes). Requiring both is side-effect free — verified, no DB connection. The spec's §3.2.2 rule is *transcribe, do not author*: the catalog has already decided Frisian is 🇳🇱, Hawaiian is 🇺🇸 and Esperanto is 🌐, and re-deciding 115 of those by hand in a second place is how the two drift apart.

- [ ] **Step 1: Write the generator**

Create `scripts/generate-language-data.js`:

```js
#!/usr/bin/env node
/**
 * Transcribes the backend's language catalog into src/utils/languages.data.ts.
 *
 *   node scripts/generate-language-data.js [path-to-backend-repo]
 *
 * Defaults to ../language_exchange_backend_application. The output is
 * committed, so this runs only when the backend catalog changes -- the web
 * build has no cross-repo dependency.
 *
 * Why generated: seeds/languages.js already carries a flag for all 137
 * languages and has already settled every judgment call (Frisian -> NL,
 * Hawaiian -> US, Esperanto -> globe). Hand-authoring 115 of those again
 * would guarantee the two copies drift.
 */
const fs = require("fs");
const path = require("path");

const backend = path.resolve(
  process.argv[2] || path.join(__dirname, "..", "..", "language_exchange_backend_application")
);

const { languages } = require(path.join(backend, "seeds", "languages.js"));
const { NAME_TO_ISO } = require(path.join(backend, "utils", "languageCodes.js"));

// The one base code the catalog has no row for: it carries zh-CN, zh-TW and
// zh-HK but no plain `zh`. CN is chosen because that is what plain "Chinese"
// renders today, so this preserves current behaviour rather than changing it.
// Traditional Chinese and Cantonese keep their own flags via the catalog-name
// lookup in languageFlag() -- they are NOT collapsed into CN.
const BASE_FLAG_OVERRIDES = { zh: "🇨🇳" };

const byCode = new Map(languages.map((l) => [l.code, l]));

const catalogNameToFlag = {};
for (const l of languages) catalogNameToFlag[l.name.toLowerCase()] = l.flag;

const codeToFlag = {};
const missing = [];
for (const code of new Set(Object.values(NAME_TO_ISO))) {
  const row = byCode.get(code);
  if (row) codeToFlag[code] = row.flag;
  else if (BASE_FLAG_OVERRIDES[code]) codeToFlag[code] = BASE_FLAG_OVERRIDES[code];
  else missing.push(code);
}

// Fail loudly. A silently missing base code renders the globe for every
// speaker of that language, which is exactly the failure this file exists to
// end -- it must not be possible to reintroduce it by updating the catalog.
if (missing.length) {
  console.error(
    `No flag for base code(s): ${missing.join(", ")}.\n` +
      `Add a row to seeds/languages.js, or add a BASE_FLAG_OVERRIDES entry here.`
  );
  process.exit(1);
}

const lit = (obj) =>
  Object.entries(obj)
    .map(([k, v]) => `  ${JSON.stringify(k)}: ${JSON.stringify(v)},`)
    .join("\n");

const out = `// GENERATED FILE -- DO NOT EDIT BY HAND.
// Regenerate with: node scripts/generate-language-data.js
// Source: language_exchange_backend_application seeds/languages.js
//         and utils/languageCodes.js (the same catalog the API validates against).

/** Lowercased full catalog name -> flag. Preserves regional variants. */
export const CATALOG_NAME_TO_FLAG: Record<string, string> = {
${lit(catalogNameToFlag)}
};

/** Lowercased language name -> base ISO 639-1 code. */
export const NAME_TO_ISO: Record<string, string> = {
${lit(NAME_TO_ISO)}
};

/** Base ISO 639-1 code -> flag. */
export const CODE_TO_FLAG: Record<string, string> = {
${lit(codeToFlag)}
};
`;

const dest = path.join(__dirname, "..", "src", "utils", "languages.data.ts");
fs.writeFileSync(dest, out, "utf8");
console.log(
  `Wrote ${dest}\n` +
    `  ${Object.keys(catalogNameToFlag).length} catalog names\n` +
    `  ${Object.keys(NAME_TO_ISO).length} name->iso entries\n` +
    `  ${Object.keys(codeToFlag).length} code->flag entries`
);
```

- [ ] **Step 2: Run it**

Run: `node scripts/generate-language-data.js`
Expected: exit 0, and output reporting `137 catalog names`, `134 name->iso entries`, `115 code->flag entries`.

If it exits 1 with "No flag for base code(s)", the backend catalog has changed since this plan was written — add the missing row upstream or an override, do not weaken the check.

- [ ] **Step 3: Verify the generated file spot-checks correctly**

Run:

```bash
node -e "
const s = require('fs').readFileSync('src/utils/languages.data.ts','utf8');
for (const t of ['\"chinese (traditional)\": \"🇹🇼\"','\"cantonese\": \"🇭🇰\"','\"estonian\": \"🇪🇪\"','\"frisian\": \"🇳🇱\"','\"esperanto\": \"🌐\"','\"zh\": \"🇨🇳\"','\"fa\": \"🇮🇷\"','\"tl\": \"🇵🇭\"'])
  if (!s.includes(t)) { console.error('MISSING', t); process.exit(1); }
console.log('all spot-checks present');
"
```

Expected: `all spot-checks present`.

- [ ] **Step 4: Commit**

```bash
git add scripts/generate-language-data.js src/utils/languages.data.ts
git commit -m "feat(utils): generate language data from the backend catalog

The catalog already carries a flag for all 137 languages and has settled
every judgment call a hand-written table would stall on. Transcribing it
by script keeps the two from drifting; the generator fails loudly rather
than emitting a globe if a base code ever loses its row."
```

---

### Task 3: `displayCode` — the pill's label, mirroring the app verbatim

**Files:**
- Create: `src/utils/languages.ts`
- Create: `src/utils/languages.test.ts`

**Interfaces:**
- Consumes: nothing (Task 4 adds the data imports to the same file).
- Produces:
  - `stripVariant(name: string): string`
  - `toBaseIso6391(code: string): string | null`
  - `displayCode(language: string): string`

**Context the implementer needs:** this is a verbatim port of `LanguageCodes.displayCode` at `bananatalk_app/lib/utils/language_codes.dart:36-77`. It deliberately reproduces two quirks — `japanese → JP` is a country code rather than ISO `ja`, and `cantonese → YUE` is three letters — and a fall-through that renders Persian as `PE`. **These are not bugs to fix.** The pill exists so the two products say the same thing about the same person; a web pill reading `JA` beside an app pill reading `JP` defeats its only purpose. The tests below pin the quirks so nobody "corrects" them.

Order matters twice: the name map is matched with `includes` and first hit wins, so it must stay an ordered array, not an object; and `toBaseIso6391`'s special cases must run before the two-letter check.

- [ ] **Step 1: Write the failing test**

Create `src/utils/languages.test.ts`:

```ts
import { displayCode, stripVariant, toBaseIso6391 } from "./languages";

it("strips a trailing regional parenthetical", () => {
  expect(stripVariant("Chinese (Traditional)")).toBe("Chinese");
  expect(stripVariant("Portuguese (Brazil)")).toBe("Portuguese");
  expect(stripVariant("Haitian Creole")).toBe("Haitian Creole");
});

it("maps names through the app's table", () => {
  expect(displayCode("Korean")).toBe("KO");
  expect(displayCode("English")).toBe("EN");
  expect(displayCode("Chinese (Traditional)")).toBe("ZH");
  expect(displayCode("korean")).toBe("KO");
});

// Deliberate parity quirks -- see the spec, section 3.2.1. The app's own
// doc comment claims "ISO-style, not country-style" and then returns JP for
// Japanese and YUE for Cantonese. The web mirrors that so the two products
// never disagree about the same person. If the app is fixed, these fail by
// design and must be updated in step.
it("reproduces the app's non-ISO codes exactly", () => {
  expect(displayCode("Japanese")).toBe("JP");
  expect(displayCode("Cantonese")).toBe("YUE");
});

it("falls through to a two-letter slice for unmapped names, as the app does", () => {
  expect(displayCode("Persian")).toBe("PE");
});

it("resolves three-letter bases before the two-letter check", () => {
  // Without the fil -> tl branch this returns "FI" -- Finnish, a different
  // language. That is the exact bug this module exists to end.
  expect(displayCode("fil")).toBe("TL");
  expect(displayCode("prs")).toBe("FA");
  expect(displayCode("Filipino")).toBe("TL");
});

it("returns an empty string for empty input", () => {
  expect(displayCode("")).toBe("");
  expect(displayCode("   ")).toBe("");
});

it("resolves untaggable codes to nothing rather than guessing", () => {
  expect(toBaseIso6391("ase")).toBeNull();
  expect(toBaseIso6391("haw")).toBeNull();
  expect(toBaseIso6391("pt-BR")).toBe("pt");
  expect(toBaseIso6391("en")).toBe("en");
  expect(toBaseIso6391("persian")).toBeNull();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=utils/languages`
Expected: FAIL — `Cannot find module './languages'`.

- [ ] **Step 3: Write minimal implementation**

Create `src/utils/languages.ts`:

```ts
// One language module for the whole app.
//
// Before this, the code/flag mapping lived in four places -- community/type.ts
// (two tables, one name-keyed and one code-keyed), community/utils.ts (a third,
// name-keyed, used by CommunityDetail) and tandem/LanguageFlagChip.tsx (a
// fourth, thirteen entries where the others had ten). They had already drifted.

/** "Portuguese (Brazil)" -> "Portuguese". Names without a parenthetical pass through. */
export function stripVariant(name: string): string {
  return name.replace(/\s*\([^)]*\)\s*$/, "").trim();
}

// Catalog codes with no usable ISO 639-1 base: sign languages, and Hawaiian
// (639-2 only). Ported from language_codes.dart:20.
const UNTAGGABLE = new Set(["ase", "bfi", "jsl", "kvk", "haw"]);

// 639-3/legacy codes that DO have a sensible 639-1 base. Dropping these sends
// "fil" to the two-letter slice below and yields "fi" -- Finnish.
const THREE_LETTER_BASES: Record<string, string> = { fil: "tl", prs: "fa" };

/**
 * Base ISO 639-1 code for a catalog code, or null when it cannot be
 * represented. 'pt-BR' -> 'pt', 'fil' -> 'tl', 'ase' -> null.
 */
export function toBaseIso6391(code: string): string | null {
  const trimmed = code.trim().toLowerCase();
  if (!trimmed) return null;
  if (UNTAGGABLE.has(trimmed)) return null;

  const mapped = THREE_LETTER_BASES[trimmed];
  if (mapped) return mapped;

  const hyphen = trimmed.indexOf("-");
  const base = hyphen > 0 ? trimmed.slice(0, hyphen) : trimmed;
  return base.length === 2 ? base : null;
}

// An ORDERED list, not an object: matching is `includes` and first hit wins,
// so insertion order is behaviour. Ported verbatim from language_codes.dart:61.
const DISPLAY_BY_NAME: ReadonlyArray<readonly [string, string]> = [
  ["japanese", "JP"], ["english", "EN"], ["korean", "KO"], ["chinese", "ZH"],
  ["spanish", "ES"], ["french", "FR"], ["german", "DE"], ["italian", "IT"],
  ["portuguese", "PT"], ["russian", "RU"], ["arabic", "AR"], ["hindi", "HI"],
  ["tajik", "TG"], ["vietnamese", "VI"], ["thai", "TH"], ["indonesian", "ID"],
  ["turkish", "TR"], ["filipino", "TL"], ["cantonese", "YUE"],
];

/**
 * Two-letter display code for a language NAME, uppercased.
 *
 * Mirrors LanguageCodes.displayCode in the Flutter app EXACTLY, including two
 * quirks it does not admit to: 'japanese' -> 'JP' is a country code, and
 * 'cantonese' -> 'YUE' is three letters. Anything outside the 19-name table
 * falls through to a two-letter slice, so 'Persian' -> 'PE', not 'FA'.
 *
 * Parity is the point. A web pill reading JA beside an app pill reading JP
 * would defeat the only reason the pill exists.
 */
export function displayCode(language: string): string {
  const lower = stripVariant(language).toLowerCase().trim();
  if (!lower) return "";

  for (const [name, code] of DISPLAY_BY_NAME) {
    if (lower.includes(name)) return code;
  }

  const iso = toBaseIso6391(lower);
  if (iso) return iso.toUpperCase();

  return language.toUpperCase().slice(0, language.length > 2 ? 2 : language.length);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=utils/languages`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add src/utils/languages.ts src/utils/languages.test.ts
git commit -m "feat(utils): port displayCode from the app, quirks included

Mirrors LanguageCodes.displayCode verbatim: JP for Japanese, YUE for
Cantonese, PE for Persian. Tests pin all three so nobody corrects them
into ISO -- the pill exists so both products say the same thing about
the same person."
```

---

### Task 4: `languageFlag` — variant-aware, and it must not flatten zh-TW

**Files:**
- Modify: `src/utils/languages.ts` (append)
- Modify: `src/utils/languages.test.ts` (append)

**Interfaces:**
- Consumes: `stripVariant`, `toBaseIso6391` from Task 3; `CATALOG_NAME_TO_FLAG`, `NAME_TO_ISO`, `CODE_TO_FLAG` from Task 2.
- Produces: `languageFlag(language: string): string` — always returns a string, `"🌐"` when unresolvable.

**Context the implementer needs:** the old ten-key flag table failed two different ways. Where a `substring(0, 2)` slice happened to land on one of its keys the user saw a **confidently wrong country** — Estonian renders 🇪🇸 Spain today. Where it did not, the flag fell back to 🌐. Correct name→code resolution alone fixes only the first kind, which is why Task 2 widened the table.

The resolution order matters and is the whole reason this function is not a one-liner. Matching the **full, unstripped** name first is what keeps Traditional Chinese on 🇹🇼 and Cantonese on 🇭🇰 instead of collapsing both into 🇨🇳. `displayCode` still strips the variant: the label names the language, the flag names the variant the user actually chose.

- [ ] **Step 1: Write the failing test**

Append to `src/utils/languages.test.ts`:

```ts
import { languageFlag } from "./languages";

// The visible half of the old bug: a slice that lands on one of the ten old
// flag keys renders a confidently wrong country.
it("fixes the collisions that rendered the wrong country", () => {
  expect(languageFlag("Estonian")).toBe("🇪🇪");
  expect(languageFlag("Estonian")).not.toBe("🇪🇸");
  expect(languageFlag("Frisian")).toBe("🇳🇱");
  expect(languageFlag("Frisian")).not.toBe("🇫🇷");
});

// The quiet half: these used to return the globe under both the old and the
// new code, so the widened table from Task 2 is what actually moves them.
it("resolves languages the old ten-key table had no flag for", () => {
  expect(languageFlag("Persian")).toBe("🇮🇷");
  expect(languageFlag("Filipino")).toBe("🇵🇭");
});

// The politically load-bearing case. A naive base-code collapse renders the
// PRC flag for every Traditional Chinese and Cantonese speaker.
it("preserves regional variants instead of collapsing them", () => {
  expect(languageFlag("Chinese (Traditional)")).toBe("🇹🇼");
  expect(languageFlag("Cantonese")).toBe("🇭🇰");
  expect(languageFlag("Portuguese (Brazil)")).toBe("🇧🇷");
  expect(languageFlag("English (UK)")).toBe("🇬🇧");
});

it("resolves a plain base name to its designated flag", () => {
  // `zh` is the one code with no base catalog row; CN is what plain
  // "Chinese" renders today, so this preserves existing behaviour.
  expect(languageFlag("Chinese")).toBe("🇨🇳");
  expect(languageFlag("Korean")).toBe("🇰🇷");
});

it("accepts a bare ISO code", () => {
  expect(languageFlag("en")).toBe("🇺🇸");
  expect(languageFlag("ko")).toBe("🇰🇷");
});

it("returns the globe rather than guessing", () => {
  expect(languageFlag("Esperanto")).toBe("🌐"); // the catalog's own answer
  expect(languageFlag("Klingon")).toBe("🌐");
  expect(languageFlag("")).toBe("🌐");
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=utils/languages`
Expected: FAIL — `languageFlag is not a function` (the import resolves, the export does not exist).

- [ ] **Step 3: Write minimal implementation**

Append to `src/utils/languages.ts`:

```ts
import {
  CATALOG_NAME_TO_FLAG,
  NAME_TO_ISO,
  CODE_TO_FLAG,
} from "./languages.data";

/**
 * Flag for a language NAME (or a bare ISO code).
 *
 * Resolution order is behaviour, not preference:
 *
 *   1. the FULL, unstripped catalog name -- this is what keeps
 *      "Chinese (Traditional)" on the Taiwanese flag and "Cantonese" on the
 *      Hong Kong one. Collapsing them to base `zh` would render the PRC flag
 *      for every speaker of either.
 *   2. the stripped name through NAME_TO_ISO, for names the catalog spells
 *      differently ("Tagalog" and "Filipino" both reach `tl`).
 *   3. a bare ISO code ('en', 'pt-BR').
 *
 * Unlike displayCode, this does NOT mirror the app's quirks: a wrong flag is
 * a wrong picture, and there is no parity argument for showing one.
 */
export function languageFlag(language: string): string {
  const raw = (language || "").trim().toLowerCase();
  if (!raw) return "🌐";

  const exact = CATALOG_NAME_TO_FLAG[raw];
  if (exact) return exact;

  const base = NAME_TO_ISO[stripVariant(raw)];
  if (base && CODE_TO_FLAG[base]) return CODE_TO_FLAG[base];

  const iso = toBaseIso6391(raw);
  if (iso && CODE_TO_FLAG[iso]) return CODE_TO_FLAG[iso];

  return "🌐";
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=utils/languages`
Expected: PASS, 13 tests total in the file.

- [ ] **Step 5: Commit**

```bash
git add src/utils/languages.ts src/utils/languages.test.ts
git commit -m "feat(utils): variant-aware language flags

Matches the full catalog name before stripping the variant, so
zh-TW keeps the Taiwanese flag and zh-HK the Hong Kong one rather than
collapsing both into the PRC flag. Also ends the collisions: Estonian
rendered the Spanish flag, Frisian the French one."
```

---

### Task 5: Retire the four legacy language maps

**Files:**
- Modify: `src/components/community/type.ts:30-38` (replace both tables with re-exports)
- Modify: `src/components/community/utils.ts:5-8` and its `getLanguageFlag` (delete the inline map)
- Modify: `src/components/community/tandem/LanguageFlagChip.tsx:20-36` (delete the `codes` object and `getCode`)
- Modify: `src/components/community/MemberCard.tsx:38-48` (delete the local helpers)

**Interfaces:**
- Consumes: `displayCode`, `languageFlag` from Tasks 3–4.
- Produces: nothing new. This task deletes duplicates.

**Context the implementer needs:** this is the one task in the plan that changes what users see, and it does so in two directions — wrong flags become right (`Estonian` 🇪🇸 → 🇪🇪) and globes become real flags across the widened table. Both are the fix.

`community/utils.ts` needs the most care: its `getLanguageFlag` is keyed by language **name** while `type.ts`'s `LANGUAGE_FLAGS` is keyed by **code**, so they are not interchangeable. The new `languageFlag(language)` takes a name, which is what `utils.ts`'s callers already pass. `CommunityDetail.tsx:23` imports it and renders it at `:37` and `:43` — do not miss that screen. `utils.ts` also exports `generateRandomStats` and `useDebounce`, which have nothing to do with languages and must stay exactly as they are.

Do **not** restyle any of these components. Markup, class names and `data-testid` attributes stay byte-identical; only the language helpers change.

- [ ] **Step 1: Write the failing test**

Create `src/components/community/languageMigration.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import MemberCard, { CommunityMemberCard } from "./MemberCard";
import { getLanguageFlag } from "./utils";

const member: CommunityMemberCard = {
  _id: "1",
  name: "Kertu",
  native_language: "Estonian",
  language_to_learn: "Persian",
  imageUrls: [],
};

it("MemberCard renders the corrected flag, not the collision", () => {
  render(<MemberCard user={member} onWave={() => {}} onOpen={() => {}} />);
  // The avatar corner carries the native-language flag.
  expect(screen.getByTitle("Estonian")).toHaveTextContent("🇪🇪");
  expect(screen.getByTitle("Estonian")).not.toHaveTextContent("🇪🇸");
});

it("community/utils getLanguageFlag resolves through the shared module", () => {
  expect(getLanguageFlag("Estonian")).toBe("🇪🇪");
  expect(getLanguageFlag("Persian")).toBe("🇮🇷");
  expect(getLanguageFlag("Chinese (Traditional)")).toBe("🇹🇼");
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=community/languageMigration`
Expected: FAIL — `getLanguageFlag("Estonian")` returns `"🌐"` (its inline map is keyed by name and has no Estonian), and the MemberCard assertion finds `"🇪🇸"`.

- [ ] **Step 3: Write minimal implementation**

In `src/components/community/type.ts`, delete the `LANGUAGE_FLAGS` and `LANGUAGE_CODES` object literals and re-export instead, keeping the names so no consumer breaks:

```ts
// Both tables now live in src/utils/languages.ts, generated from the backend
// catalog. Re-exported here so existing imports keep working; prefer importing
// displayCode/languageFlag directly in new code.
export { CODE_TO_FLAG as LANGUAGE_FLAGS, NAME_TO_ISO as LANGUAGE_CODES } from "../../utils/languages.data";
```

In `src/components/community/utils.ts`, replace both language helpers (keep `generateRandomStats` and `useDebounce` untouched):

```ts
import { displayCode, languageFlag } from "../../utils/languages";

export const getLanguageCode = (language: string): string =>
  displayCode(language).toLowerCase();

export const getLanguageFlag = (language: string): string => languageFlag(language);
```

In `src/components/community/tandem/LanguageFlagChip.tsx`, delete the local `codes` object and the `getCode` function, and replace the two lines that used them:

```tsx
import { languageFlag } from "../../../utils/languages";
// ...
const flag = languageFlag(language);
```

In `src/components/community/MemberCard.tsx`, delete `getLanguageCode` and `getFlag` (lines 38–48) and replace their two call sites:

```tsx
import { languageFlag } from "../../utils/languages";
// ...
const nativeFlag = languageFlag(user.native_language);
const learningFlag = languageFlag(user.language_to_learn);
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `CI=true npx react-scripts test --testPathPattern="community|utils/languages"`
Expected: PASS. The pre-existing `MemberCard.test.tsx` and `WaveSheet.test.tsx` must also still pass — if `MemberCard.test.tsx` fails on a flag assertion, read it: an expectation of the *old wrong* flag is a test to update, an expectation about layout is a regression to fix.

- [ ] **Step 5: Verify the whole suite is still green**

Run: `CI=true npx react-scripts test`
Expected: PASS across all existing test files.

- [ ] **Step 6: Commit**

```bash
git add src/components/community src/utils
git commit -m "refactor(community): one language module, four maps deleted

type.ts, utils.ts, LanguageFlagChip and MemberCard each carried their own
copy and had drifted -- LanguageFlagChip held thirteen entries where the
others held ten, and utils.ts was keyed by name where type.ts was keyed by
code. Markup is untouched; only the language source changes.

User-visible: Estonian stops rendering the Spanish flag, and languages
outside the old ten-key table get a real flag instead of a globe."
```

---

### Task 6: `LanguageExchangePill`

**Files:**
- Create: `src/design/LanguageExchangePill.tsx`
- Create: `src/design/LanguageExchangePill.test.tsx`

**Interfaces:**
- Consumes: `displayCode` from Task 3; the `brand` tokens from Task 1.
- Produces:
  - `dotsForLevel(level?: string | null): number | null`
  - `default export LanguageExchangePill` with props `{ nativeLanguage: string; learningLanguage: string; languageLevel?: string | null; dense?: boolean }`
  - `data-testid`s: `language-pill`, `language-pill-native`, `language-pill-learning`, `language-pill-dot` (one node per dot, filled or not)

**Context the implementer needs:** the single rule this component exists for is that **`null` renders no dots at all** — not three empty ones. `models/User.js:744` defines `languageLevel` with `default: null`, so every user who never set a level carries null; three empty dots would mislabel most of the user base as beginners. The app shipped the opposite mistake — five dots with a hardcoded `index < 3`, identical for a beginner and a C2 speaker, on every card in the feed.

No dots on the native side: they would be three-of-three for everybody, varying for nobody.

- [ ] **Step 1: Write the failing test**

Create `src/design/LanguageExchangePill.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import LanguageExchangePill, { dotsForLevel } from "./LanguageExchangePill";

it("maps CEFR bands to dot counts", () => {
  expect(dotsForLevel("A1")).toBe(1);
  expect(dotsForLevel("a2")).toBe(1);
  expect(dotsForLevel("B1")).toBe(2);
  expect(dotsForLevel("B2")).toBe(2);
  expect(dotsForLevel("C1")).toBe(3);
  expect(dotsForLevel("C2")).toBe(3);
});

// Absent is not zero. languageLevel defaults to null on the backend, so this
// is the COMMON path, not an edge case.
it("returns null for an unknown level rather than zero", () => {
  expect(dotsForLevel(null)).toBeNull();
  expect(dotsForLevel(undefined)).toBeNull();
  expect(dotsForLevel("")).toBeNull();
  expect(dotsForLevel("fluent")).toBeNull();
});

it("renders both language codes", () => {
  render(<LanguageExchangePill nativeLanguage="Korean" learningLanguage="English" />);
  expect(screen.getByTestId("language-pill-native")).toHaveTextContent("KO");
  expect(screen.getByTestId("language-pill-learning")).toHaveTextContent("EN");
});

it("renders exactly three dots when the level is known", () => {
  render(
    <LanguageExchangePill nativeLanguage="Korean" learningLanguage="English" languageLevel="B1" />
  );
  expect(screen.getAllByTestId("language-pill-dot")).toHaveLength(3);
});

// The guard this component exists for.
it("renders NO dots when the level is unknown", () => {
  render(<LanguageExchangePill nativeLanguage="Korean" learningLanguage="English" />);
  expect(screen.queryAllByTestId("language-pill-dot")).toHaveLength(0);

  render(
    <LanguageExchangePill
      nativeLanguage="Korean"
      learningLanguage="English"
      languageLevel={null}
    />
  );
  expect(screen.queryAllByTestId("language-pill-dot")).toHaveLength(0);
});

it("still renders when a code cannot be resolved", () => {
  render(<LanguageExchangePill nativeLanguage="" learningLanguage="English" />);
  expect(screen.getByTestId("language-pill")).toBeInTheDocument();
  expect(screen.getByTestId("language-pill-learning")).toHaveTextContent("EN");
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=design/LanguageExchangePill`
Expected: FAIL — `Cannot find module './LanguageExchangePill'`.

- [ ] **Step 3: Write minimal implementation**

Create `src/design/LanguageExchangePill.tsx`:

```tsx
import React from "react";
import { ArrowLeftRight } from "lucide-react";
import { displayCode } from "../utils/languages";

/**
 * Dots to fill for a CEFR level, or null when we do not know the level.
 *
 * Null is not zero. `languageLevel` defaults to null on the backend
 * (models/User.js:744), so a profile with no level renders NO dots rather
 * than three empty ones -- an empty indicator reads as "beginner", a claim
 * the data has not made.
 */
export function dotsForLevel(level?: string | null): number | null {
  switch ((level || "").trim().toUpperCase()) {
    case "A1":
    case "A2":
      return 1;
    case "B1":
    case "B2":
      return 2;
    case "C1":
    case "C2":
      return 3;
    default:
      return null;
  }
}

export interface LanguageExchangePillProps {
  nativeLanguage: string;
  learningLanguage: string;
  /** The candidate's CEFR level in `learningLanguage`. Null renders no dots. */
  languageLevel?: string | null;
  /** Smaller type and tighter padding, for the moment card header. */
  dense?: boolean;
}

const LanguageExchangePill: React.FC<LanguageExchangePillProps> = ({
  nativeLanguage,
  learningLanguage,
  languageLevel,
  dense = false,
}) => {
  const filled = dotsForLevel(languageLevel);
  const native = displayCode(nativeLanguage);
  const learning = displayCode(learningLanguage);

  const text = dense ? "text-[10px]" : "text-[11px]";
  const pad = dense ? "px-2 py-0.5" : "px-2.5 py-1";

  return (
    <span
      data-testid="language-pill"
      className={`inline-flex items-center rounded-full bg-brand/[0.09] dark:bg-brand/[0.18] ${pad}`}
    >
      {/* No dots on the native side: always three-of-three, so they varied
          for nobody and cost width the moment header could not spare. */}
      <span
        data-testid="language-pill-native"
        className={`font-extrabold text-brand-dark dark:text-brand-light ${text}`}
      >
        {native}
      </span>

      <ArrowLeftRight className="mx-1.5 h-3 w-3 shrink-0 text-brand" aria-hidden />

      <span
        data-testid="language-pill-learning"
        className={`font-extrabold text-brand-dark dark:text-brand-light ${text}`}
      >
        {learning}
      </span>

      {filled !== null && (
        <span className="ml-1 flex items-center gap-0.5">
          {[0, 1, 2].map((i) => (
            <span
              key={i}
              data-testid="language-pill-dot"
              className={`block h-1 w-1 rounded-full ${
                i < filled ? "bg-brand" : "bg-brand/[0.28]"
              }`}
            />
          ))}
        </span>
      )}
    </span>
  );
};

export default LanguageExchangePill;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=design/LanguageExchangePill`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add src/design/LanguageExchangePill.tsx src/design/LanguageExchangePill.test.tsx
git commit -m "feat(design): add LanguageExchangePill

KO <-> EN in one brand pill with proficiency dots. An unknown level
renders no dots at all rather than three empty ones -- languageLevel
defaults to null on the backend, so that is the common path, and empty
dots would mislabel most of the user base as beginners."
```

---

### Task 7: `Avatar`

**Files:**
- Create: `src/design/Avatar.tsx`
- Create: `src/design/Avatar.test.tsx`

**Interfaces:**
- Consumes: Task 1 tokens.
- Produces: `default export Avatar` with props `{ src?: string; name: string; size?: 40 | 54 | 72 | 80; hasStory?: boolean; isOnline?: boolean; flag?: string }`; `data-testid`s `avatar`, `avatar-image`, `avatar-initials`, `avatar-story-ring`, `avatar-online-dot`, `avatar-flag`.

**Context the implementer needs:** this replaces three implementations — `MemberCard.tsx` (story ring, flag, online dot), `ProfileHeader.tsx:20` (ring, online dot, initials) and `SingleMoment.tsx:318` (a bare `<img>`). Only one of the three has an initials fallback, which is why a user with no photo currently renders as a broken image in the moments feed. The fallback belongs on the primitive.

`hasStory` is an explicit prop rather than something derived from a user object, because the three callers source it from two different controllers — `users.js:390`/`:443` for Community and Profile, `moments.js:33`/`:45` for the feed. It is live on all three payloads; nothing here turns an existing ring off.

- [ ] **Step 1: Write the failing test**

Create `src/design/Avatar.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import Avatar from "./Avatar";

it("renders the image when a src is given", () => {
  render(<Avatar src="https://example.test/a.jpg" name="Yeonwoo" />);
  expect(screen.getByTestId("avatar-image")).toHaveAttribute(
    "src",
    "https://example.test/a.jpg"
  );
  expect(screen.queryByTestId("avatar-initials")).not.toBeInTheDocument();
});

// The behaviour two of the three current implementations forgot.
it("falls back to an initial when there is no photo", () => {
  render(<Avatar name="yeonwoo" />);
  expect(screen.getByTestId("avatar-initials")).toHaveTextContent("Y");
  expect(screen.queryByTestId("avatar-image")).not.toBeInTheDocument();
});

it("renders a placeholder initial for a nameless user", () => {
  render(<Avatar name="" />);
  expect(screen.getByTestId("avatar-initials")).toHaveTextContent("?");
});

it("shows the story ring only when hasStory is true", () => {
  const { rerender } = render(<Avatar name="Yeonwoo" />);
  expect(screen.queryByTestId("avatar-story-ring")).not.toBeInTheDocument();

  rerender(<Avatar name="Yeonwoo" hasStory />);
  expect(screen.getByTestId("avatar-story-ring")).toBeInTheDocument();
});

it("shows the online dot only when isOnline is true", () => {
  const { rerender } = render(<Avatar name="Yeonwoo" />);
  expect(screen.queryByTestId("avatar-online-dot")).not.toBeInTheDocument();

  rerender(<Avatar name="Yeonwoo" isOnline />);
  expect(screen.getByTestId("avatar-online-dot")).toBeInTheDocument();
});

it("shows the flag only when one is given", () => {
  const { rerender } = render(<Avatar name="Yeonwoo" />);
  expect(screen.queryByTestId("avatar-flag")).not.toBeInTheDocument();

  rerender(<Avatar name="Yeonwoo" flag="🇰🇷" />);
  expect(screen.getByTestId("avatar-flag")).toHaveTextContent("🇰🇷");
});

it("applies the requested size", () => {
  render(<Avatar name="Yeonwoo" size={72} />);
  expect(screen.getByTestId("avatar")).toHaveStyle({ width: "72px", height: "72px" });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=design/Avatar`
Expected: FAIL — `Cannot find module './Avatar'`.

- [ ] **Step 3: Write minimal implementation**

Create `src/design/Avatar.tsx`:

```tsx
import React from "react";

export interface AvatarProps {
  src?: string;
  /** Drives the initials fallback. */
  name: string;
  size?: 40 | 54 | 72 | 80;
  /**
   * Explicit, never derived from a user object: Community and Profile get
   * this field from controllers/users.js and Moments from
   * controllers/moments.js, so a primitive that reached into a user shape
   * would have to know which one it was holding.
   */
  hasStory?: boolean;
  isOnline?: boolean;
  /** Native-language flag, rendered bottom-left. */
  flag?: string;
}

const Avatar: React.FC<AvatarProps> = ({
  src,
  name,
  size = 54,
  hasStory = false,
  isOnline = false,
  flag,
}) => {
  const initial = (name || "").trim().charAt(0).toUpperCase() || "?";
  const dot = size >= 72 ? "h-4 w-4" : "h-3 w-3";

  const face = src ? (
    <img
      data-testid="avatar-image"
      src={src}
      alt={name}
      className="h-full w-full rounded-full object-cover"
    />
  ) : (
    <div
      data-testid="avatar-initials"
      className="flex h-full w-full items-center justify-center rounded-full bg-gradient-to-br from-brand-light to-banana-light font-bold text-brand-dark"
      style={{ fontSize: Math.round(size / 2.7) }}
    >
      {initial}
    </div>
  );

  return (
    <div
      data-testid="avatar"
      className="relative shrink-0"
      style={{ width: size, height: size }}
    >
      {hasStory ? (
        <div
          data-testid="avatar-story-ring"
          className="h-full w-full rounded-full bg-gradient-to-tr from-brand via-banana to-brand-light p-[3px]"
        >
          <div className="h-full w-full rounded-full bg-surface p-[2px] dark:bg-cardbg-dark">
            {face}
          </div>
        </div>
      ) : (
        face
      )}

      {flag && (
        <span
          data-testid="avatar-flag"
          aria-hidden
          className="absolute -bottom-0.5 -left-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-surface text-[11px] leading-none shadow-card dark:bg-cardbg-dark"
        >
          {flag}
        </span>
      )}

      {isOnline && (
        <span
          data-testid="avatar-online-dot"
          aria-label="Online"
          className={`absolute -bottom-0.5 -right-0.5 ${dot} rounded-full border-2 border-surface bg-[#4CAF50] dark:border-cardbg-dark`}
        />
      )}
    </div>
  );
};

export default Avatar;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=design/Avatar`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add src/design/Avatar.tsx src/design/Avatar.test.tsx
git commit -m "feat(design): add Avatar, replacing three implementations

Story ring, online dot, flag corner and -- the part two of the three
current copies forgot -- an initials fallback, so a user with no photo
stops rendering as a broken image. hasStory stays an explicit prop
because its callers source it from two different controllers."
```

---

### Task 8: `SurfaceCard`

**Files:**
- Create: `src/design/SurfaceCard.tsx`
- Create: `src/design/SurfaceCard.test.tsx`

**Interfaces:**
- Consumes: Task 1 tokens.
- Produces: `default export SurfaceCard` with props `{ children: React.ReactNode; padding?: "sm" | "md" | "lg"; interactive?: boolean; className?: string; onClick?: () => void }`; `data-testid` `surface-card`.

**Context the implementer needs:** dark mode **drops** the shadow rather than darkening it, matching `community_card.dart:90` (`boxShadow: context.isDarkMode ? [] : AppShadows.sm`). A shadow on a dark surface reads as grime.

- [ ] **Step 1: Write the failing test**

Create `src/design/SurfaceCard.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import SurfaceCard from "./SurfaceCard";

it("renders its children", () => {
  render(<SurfaceCard>hello</SurfaceCard>);
  expect(screen.getByTestId("surface-card")).toHaveTextContent("hello");
});

it("carries the app's card radius and elevation", () => {
  render(<SurfaceCard>x</SurfaceCard>);
  const el = screen.getByTestId("surface-card");
  expect(el.className).toContain("rounded-card");
  expect(el.className).toContain("shadow-card");
  expect(el.className).toContain("bg-surface");
});

// A shadow on a dark surface reads as grime; the app drops it outright.
it("drops the shadow in dark mode", () => {
  render(<SurfaceCard>x</SurfaceCard>);
  expect(screen.getByTestId("surface-card").className).toContain("dark:shadow-none");
});

it("applies the requested padding", () => {
  const { rerender } = render(<SurfaceCard padding="sm">x</SurfaceCard>);
  expect(screen.getByTestId("surface-card").className).toContain("p-2.5");

  rerender(<SurfaceCard padding="lg">x</SurfaceCard>);
  expect(screen.getByTestId("surface-card").className).toContain("p-5");
});

it("adds hover and press affordances only when interactive", () => {
  const { rerender } = render(<SurfaceCard>x</SurfaceCard>);
  expect(screen.getByTestId("surface-card").className).not.toContain("cursor-pointer");

  rerender(<SurfaceCard interactive>x</SurfaceCard>);
  const el = screen.getByTestId("surface-card");
  expect(el.className).toContain("cursor-pointer");
  expect(el.className).toContain("hover:shadow-raised");
});

it("calls onClick when clicked", () => {
  const onClick = jest.fn();
  render(
    <SurfaceCard interactive onClick={onClick}>
      x
    </SurfaceCard>
  );
  fireEvent.click(screen.getByTestId("surface-card"));
  expect(onClick).toHaveBeenCalledTimes(1);
});

it("merges an extra className", () => {
  render(<SurfaceCard className="mb-2">x</SurfaceCard>);
  expect(screen.getByTestId("surface-card").className).toContain("mb-2");
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=design/SurfaceCard`
Expected: FAIL — `Cannot find module './SurfaceCard'`.

- [ ] **Step 3: Write minimal implementation**

Create `src/design/SurfaceCard.tsx`:

```tsx
import React from "react";

export interface SurfaceCardProps {
  children: React.ReactNode;
  padding?: "sm" | "md" | "lg";
  interactive?: boolean;
  className?: string;
  onClick?: () => void;
}

const PADDING: Record<NonNullable<SurfaceCardProps["padding"]>, string> = {
  sm: "p-2.5",
  md: "p-3.5",
  lg: "p-5",
};

/**
 * The app's card treatment: radius 20, a 4%-alpha shadow, surface colour.
 * Deliberately identical for the community partner row and the moment card so
 * the two main browse surfaces stop looking like different products.
 */
const SurfaceCard: React.FC<SurfaceCardProps> = ({
  children,
  padding = "md",
  interactive = false,
  className = "",
  onClick,
}) => (
  <div
    data-testid="surface-card"
    onClick={onClick}
    className={[
      "rounded-card bg-surface shadow-card",
      // Dark mode drops the shadow rather than darkening it -- see
      // community_card.dart:90.
      "dark:bg-cardbg-dark dark:shadow-none",
      PADDING[padding],
      interactive
        ? "cursor-pointer transition-shadow hover:shadow-raised active:scale-[0.99]"
        : "",
      className,
    ]
      .filter(Boolean)
      .join(" ")}
  >
    {children}
  </div>
);

export default SurfaceCard;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=design/SurfaceCard`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add src/design/SurfaceCard.tsx src/design/SurfaceCard.test.tsx
git commit -m "feat(design): add SurfaceCard

Radius 20 and a 4%-alpha shadow, the same treatment the app gives both
the partner row and the moment card. Dark mode drops the shadow rather
than darkening it, matching community_card.dart:90."
```

---

### Task 9: `Badge`

**Files:**
- Create: `src/design/Badge.tsx`
- Create: `src/design/Badge.test.tsx`

**Interfaces:**
- Consumes: Task 1 tokens.
- Produces: `default export Badge` with props `{ children: React.ReactNode; tone?: "brand" | "banana" }`; `data-testid` `badge`.

**Context the implementer needs:** the alphas are the app's (banana 28%, brand 12%) and **must** be written as arbitrary modifiers — `bg-banana/[0.28]`, not `bg-banana/28`. Tailwind v3's shorthand modifier only accepts steps present in `theme.opacity`; an absent step emits no background rule at all, with no build error. That is the same silent-failure shape the token design was restructured to avoid.

- [ ] **Step 1: Write the failing test**

Create `src/design/Badge.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import Badge from "./Badge";

it("renders its label", () => {
  render(<Badge>VIP</Badge>);
  expect(screen.getByTestId("badge")).toHaveTextContent("VIP");
});

it("defaults to the brand tone", () => {
  render(<Badge>New</Badge>);
  const el = screen.getByTestId("badge");
  expect(el.className).toContain("bg-brand/[0.12]");
  expect(el.className).toContain("text-brand-dark");
});

it("renders the banana tone when asked", () => {
  render(<Badge tone="banana">VIP</Badge>);
  const el = screen.getByTestId("badge");
  expect(el.className).toContain("bg-banana/[0.28]");
  expect(el.className).toContain("text-banana-dark");
});

// Tailwind v3 emits NO background rule for an opacity step missing from
// theme.opacity, and does not fail the build. Arbitrary modifiers always.
it("uses arbitrary opacity modifiers, never bare steps", () => {
  const { rerender } = render(<Badge>New</Badge>);
  expect(screen.getByTestId("badge").className).not.toMatch(/bg-brand\/\d+(\s|$)/);

  rerender(<Badge tone="banana">VIP</Badge>);
  expect(screen.getByTestId("badge").className).not.toMatch(/bg-banana\/\d+(\s|$)/);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=design/Badge`
Expected: FAIL — `Cannot find module './Badge'`.

- [ ] **Step 3: Write minimal implementation**

Create `src/design/Badge.tsx`:

```tsx
import React from "react";

export interface BadgeProps {
  children: React.ReactNode;
  tone?: "brand" | "banana";
}

// Arbitrary modifiers, never `bg-banana/28`: Tailwind v3's shorthand only
// accepts steps present in theme.opacity, and an absent step emits no rule at
// all rather than failing the build.
const TONE: Record<NonNullable<BadgeProps["tone"]>, string> = {
  brand: "bg-brand/[0.12] text-brand-dark dark:text-brand-light",
  banana: "bg-banana/[0.28] text-banana-dark dark:text-banana-light",
};

const Badge: React.FC<BadgeProps> = ({ children, tone = "brand" }) => (
  <span
    data-testid="badge"
    className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-wide ${TONE[tone]}`}
  >
    {children}
  </span>
);

export default Badge;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=design/Badge`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add src/design/Badge.tsx src/design/Badge.test.tsx
git commit -m "feat(design): add Badge

Tonal chips at the app's alphas. Written as arbitrary opacity modifiers
because Tailwind v3 drops a bare /28 silently -- no rule, no build error."
```

---

### Task 10: `FollowButton`

**Files:**
- Create: `src/design/FollowButton.tsx`
- Create: `src/design/FollowButton.test.tsx`

**Interfaces:**
- Consumes: Task 1 tokens; the existing `useFollowUserMutation` / `useUnFollowUserMutation` from `src/store/slices/usersSlice` (already used by `CommunityDetail.tsx:14-15`).
- Produces: `default export FollowButton` with props `{ userId: string; targetUserId: string; isFollowing: boolean; onToggled?: (nowFollowing: boolean) => void }`; `data-testid` `follow-button`.

  **Both ids are required.** Verified in `usersSlice.ts:156-176`: both mutations take `{ userId, targetUserId }`, where `userId` is the viewer and `targetUserId` the person being followed — see the call site at `CommunityDetail.tsx:296`. The primitive takes both as props rather than reading the viewer from the store, so it stays pure and testable without a Redux provider. Callers already hold the viewer id (`CommunityDetail` reads it from `RootState`).

**Context the implementer needs:** follow state is passed in and echoed back through `onToggled` — **never held in local `setState` as the source of truth**. The app's spec names the exact regression: when the same author appears in several posts in one feed, two cards holding independent local state disagree after one is tapped. A web feed has the same shape. Consumers pass state from the RTK Query cache.

Hook names and argument shapes are already verified against `usersSlice.ts:156-176` and `CommunityDetail.tsx:296/336` — no discovery needed.

- [ ] **Step 1: Write the failing test**

Create `src/design/FollowButton.test.tsx`:

```tsx
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import FollowButton from "./FollowButton";

const follow = jest.fn(() => ({ unwrap: () => Promise.resolve({ success: true }) }));
const unfollow = jest.fn(() => ({ unwrap: () => Promise.resolve({ success: true }) }));

jest.mock("../store/slices/usersSlice", () => ({
  useFollowUserMutation: () => [follow, { isLoading: false }],
  useUnFollowUserMutation: () => [unfollow, { isLoading: false }],
}));

beforeEach(() => {
  follow.mockClear();
  unfollow.mockClear();
});

it("reads its label from the passed-in state, not from its own", () => {
  const { rerender } = render(
    <FollowButton userId="me" targetUserId="u1" isFollowing={false} />
  );
  expect(screen.getByTestId("follow-button")).toHaveTextContent("Follow");

  rerender(<FollowButton userId="me" targetUserId="u1" isFollowing={true} />);
  expect(screen.getByTestId("follow-button")).toHaveTextContent("Following");
});

it("calls follow with both ids when not yet following", async () => {
  render(<FollowButton userId="me" targetUserId="u1" isFollowing={false} />);
  fireEvent.click(screen.getByTestId("follow-button"));
  await waitFor(() =>
    expect(follow).toHaveBeenCalledWith({ userId: "me", targetUserId: "u1" })
  );
  expect(unfollow).not.toHaveBeenCalled();
});

it("calls unfollow with both ids when already following", async () => {
  render(<FollowButton userId="me" targetUserId="u1" isFollowing={true} />);
  fireEvent.click(screen.getByTestId("follow-button"));
  await waitFor(() =>
    expect(unfollow).toHaveBeenCalledWith({ userId: "me", targetUserId: "u1" })
  );
  expect(follow).not.toHaveBeenCalled();
});

it("reports the new state to its parent", async () => {
  const onToggled = jest.fn();
  render(
    <FollowButton
      userId="me"
      targetUserId="u1"
      isFollowing={false}
      onToggled={onToggled}
    />
  );
  fireEvent.click(screen.getByTestId("follow-button"));
  await waitFor(() => expect(onToggled).toHaveBeenCalledWith(true));
});

// The regression this prop shape exists to prevent: two buttons for the same
// author in one feed must not disagree after one is clicked. They cannot,
// because neither owns the state.
it("two instances for one user stay in agreement", async () => {
  const { rerender } = render(
    <>
      <FollowButton userId="me" targetUserId="u1" isFollowing={false} />
      <FollowButton userId="me" targetUserId="u1" isFollowing={false} />
    </>
  );
  fireEvent.click(screen.getAllByTestId("follow-button")[0]);
  await waitFor(() => expect(follow).toHaveBeenCalled());

  rerender(
    <>
      <FollowButton userId="me" targetUserId="u1" isFollowing={true} />
      <FollowButton userId="me" targetUserId="u1" isFollowing={true} />
    </>
  );
  screen.getAllByTestId("follow-button").forEach((el) => {
    expect(el).toHaveTextContent("Following");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `CI=true npx react-scripts test --testPathPattern=design/FollowButton`
Expected: FAIL — `Cannot find module './FollowButton'`.

- [ ] **Step 3: Write minimal implementation**

Create `src/design/FollowButton.tsx`:

```tsx
import React from "react";
import {
  useFollowUserMutation,
  useUnFollowUserMutation,
} from "../store/slices/usersSlice";

export interface FollowButtonProps {
  /** The viewer. Both mutations take { userId, targetUserId }. */
  userId: string;
  /** The person being followed. */
  targetUserId: string;
  /**
   * Current follow state, owned by the caller and read from the RTK Query
   * cache -- NOT local state. Two cards by the same author in one feed would
   * otherwise disagree after a tap.
   */
  isFollowing: boolean;
  onToggled?: (nowFollowing: boolean) => void;
}

const FollowButton: React.FC<FollowButtonProps> = ({
  userId,
  targetUserId,
  isFollowing,
  onToggled,
}) => {
  const [followUser, { isLoading: following }] = useFollowUserMutation();
  const [unFollowUser, { isLoading: unfollowing }] = useUnFollowUserMutation();
  const busy = following || unfollowing;

  const handleClick = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (busy) return;
    try {
      if (isFollowing) await unFollowUser({ userId, targetUserId }).unwrap();
      else await followUser({ userId, targetUserId }).unwrap();
      onToggled?.(!isFollowing);
    } catch {
      // The mutation's own error handling surfaces this; the button simply
      // stays in whatever state the cache reports.
    }
  };

  return (
    <button
      type="button"
      data-testid="follow-button"
      onClick={handleClick}
      disabled={busy}
      aria-pressed={isFollowing}
      className={`rounded-full border px-3 py-1 text-xs font-bold transition-colors disabled:opacity-60 ${
        isFollowing
          ? "border-gray-300 text-gray-600 dark:border-gray-600 dark:text-gray-300"
          : "border-brand text-brand-dark hover:bg-brand/[0.08] dark:text-brand-light"
      }`}
    >
      {isFollowing ? "Following" : "Follow"}
    </button>
  );
};

export default FollowButton;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `CI=true npx react-scripts test --testPathPattern=design/FollowButton`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add src/design/FollowButton.tsx src/design/FollowButton.test.tsx
git commit -m "feat(design): add FollowButton

Follow state is a prop read from the RTK Query cache, never local state:
two cards by the same author in one feed would otherwise disagree after
a tap."
```

---

### Task 11: Barrel export and drop the dead Bootstrap packages

**Files:**
- Create: `src/design/index.ts`
- Modify: `package.json` (remove two dependencies)

**Interfaces:**
- Consumes: every primitive from Tasks 6–10.
- Produces: `src/design/index.ts` re-exporting `LanguageExchangePill`, `dotsForLevel`, `Avatar`, `SurfaceCard`, `Badge`, `FollowButton` and their prop types — the single import path the four surface sub-projects use.

**Context the implementer needs:** `react-router-bootstrap` and `@types/react-router-bootstrap` have **zero** usages anywhere in `src/`. They can go now rather than waiting for the "retire Bootstrap" sub-project. The other Bootstrap packages stay — they are load-bearing for 20 files.

- [ ] **Step 1: Confirm the two packages really are unused**

Run: `grep -rn "react-router-bootstrap" src/ || echo "NO USAGES"`
Expected: `NO USAGES`. If anything prints, skip the package removal in Step 4 and leave both dependencies in place.

- [ ] **Step 2: Write the barrel**

Create `src/design/index.ts`:

```ts
// The shared design primitives. Community, Moments, Profile and Notifications
// import from here; nothing else in src/design is public API.
export { default as LanguageExchangePill, dotsForLevel } from "./LanguageExchangePill";
export type { LanguageExchangePillProps } from "./LanguageExchangePill";

export { default as Avatar } from "./Avatar";
export type { AvatarProps } from "./Avatar";

export { default as SurfaceCard } from "./SurfaceCard";
export type { SurfaceCardProps } from "./SurfaceCard";

export { default as Badge } from "./Badge";
export type { BadgeProps } from "./Badge";

export { default as FollowButton } from "./FollowButton";
export type { FollowButtonProps } from "./FollowButton";
```

- [ ] **Step 3: Verify the barrel compiles and the whole suite passes**

Run: `npx tsc --noEmit && CI=true npx react-scripts test`
Expected: no TypeScript errors, and every test file green.

- [ ] **Step 4: Remove the two dead packages**

Run: `npm uninstall react-router-bootstrap @types/react-router-bootstrap`

- [ ] **Step 5: Verify the build still succeeds**

Run: `npx tsc --noEmit && CI=true npx react-scripts build`
Expected: build completes. This is the first full production build in the plan and the real check that the token changes emit valid CSS.

- [ ] **Step 6: Commit**

```bash
git add src/design/index.ts package.json package-lock.json
git commit -m "feat(design): add the primitives barrel, drop dead deps

src/design/index.ts is the single import path for the four surface
sub-projects. react-router-bootstrap and its types had zero usages in
src/, so they go now rather than waiting for the Bootstrap retirement."
```

---

## Verification

After Task 11, confirm the whole sub-project:

- [ ] `CI=true npx react-scripts test` — every test file passes
- [ ] `npx tsc --noEmit` — no type errors
- [ ] `CI=true npx react-scripts build` — production build succeeds
- [ ] `grep -rn "bg-brand/[0-9]\|bg-banana/[0-9]" src/design/` returns nothing — no bare opacity steps survived
- [ ] `git log --oneline main..HEAD` shows 11 commits

**Eyeball before merge** — the one user-visible change in this plan is Task 5:

- [ ] A Community card for a member whose native language is outside the old ten (Estonian, Frisian, Persian, Filipino) shows a real, correct flag
- [ ] `CommunityDetail` — the screen whose flag helper was keyed by name rather than code — renders both flags correctly
- [ ] A member whose language is "Chinese (Traditional)" shows 🇹🇼, not 🇨🇳

**Known intermediate state, not a bug:** until the surface sub-projects convert, a `shadow-card` element can sit beside a `shadow-lg` one on the same screen. §9 of the spec accepts this as the cost of not detonating 327 class usages at once.

---

## Self-Review

**Spec coverage.** §3.1 tokens → Task 1. §3.2 the language module → Tasks 2–4, with §3.2.1's verbatim port in Task 3 and §3.2.2's variant rule in Task 4. §3.2's migration paragraph → Task 5. §3.3 pill → Task 6. §3.4 Avatar → Task 7. §3.5 SurfaceCard → Task 8. §3.6 Badge → Task 9. §3.7 FollowButton → Task 10. §4's `react-router-bootstrap` note → Task 11. §5's "every primitive ships dark variants" → Global Constraints, and every primitive's implementation carries `dark:` classes. §8's full test list → distributed across the task tests, including the config guard (Task 1) and the variant-fidelity assertions (Task 4).

**Deliberately not in this plan**, per spec §7: `MatchTags`, the notification bell, empty states, skeletons, the download banner, the `gray` divergence, and the Bootstrap retirement (sub-project 7).

**Type consistency check.** `displayCode`, `stripVariant`, `toBaseIso6391` and `languageFlag` are spelled identically in Tasks 3, 4, 5 and 6. `dotsForLevel` returns `number | null` in Task 6 and is exported under that name in Task 11. `CATALOG_NAME_TO_FLAG`, `NAME_TO_ISO` and `CODE_TO_FLAG` are generated under those exact names in Task 2 and imported under them in Tasks 4 and 5. `hasStory` (the Avatar prop) is deliberately **not** the same name as `hasActiveStory` (the API field) — the prop is a rendering instruction, the field is one of two possible sources for it.

**Resolved during self-review.** An earlier draft of Task 10 had `followUser(userId)` taking a bare id. `usersSlice.ts:156-176` shows both mutations take `{ userId, targetUserId }` — viewer and target — confirmed against the call site at `CommunityDetail.tsx:296`. `FollowButton` now takes both ids as props rather than reading the viewer from the store, which keeps it renderable in a test without a Redux provider. No open assumptions remain in this plan.
