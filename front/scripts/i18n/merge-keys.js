#!/usr/bin/env node
// Merge translated keys into every locale file.
//
// Usage: node scripts/i18n/merge-keys.js path/to/keys.json
//
// keys.json: { "eng": {...}, "kor": {...}, ... } -- one entry per file in
// src/utils/locales (basename without .json). Each value is deep-merged into
// that locale; existing keys are kept unless the input names them. Refuses to
// run if any locale has no entry, so a key can never land in English alone.
const fs = require("fs");
const path = require("path");

const [, , input] = process.argv;
if (!input) {
  console.error("usage: node scripts/i18n/merge-keys.js <keys.json>");
  process.exit(1);
}

const keys = JSON.parse(fs.readFileSync(input, "utf8"));
const dir = path.join(__dirname, "..", "..", "src", "utils", "locales");
const files = fs.readdirSync(dir).filter((f) => f.endsWith(".json"));
const codes = files.map((f) => f.replace(/\.json$/, ""));
const missing = codes.filter((c) => !keys[c]);
if (missing.length) {
  console.error("no translations provided for:", missing.join(", "));
  process.exit(1);
}

const merge = (target, src) => {
  for (const [k, v] of Object.entries(src)) {
    if (v && typeof v === "object" && !Array.isArray(v)) {
      target[k] = merge(target[k] && typeof target[k] === "object" ? target[k] : {}, v);
    } else {
      target[k] = v;
    }
  }
  return target;
};

for (const file of files) {
  const p = path.join(dir, file);
  const raw = fs.readFileSync(p, "utf8");
  const merged = merge(JSON.parse(raw), keys[file.replace(/\.json$/, "")]);
  fs.writeFileSync(p, JSON.stringify(merged, null, 2) + (raw.endsWith("\n") ? "\n" : ""));
}
console.log(`merged into ${files.length} locale files`);
