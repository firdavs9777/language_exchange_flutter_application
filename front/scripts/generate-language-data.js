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
