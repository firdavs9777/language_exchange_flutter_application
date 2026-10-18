#!/usr/bin/env node
/* eslint-disable */
// List the eng.json strings that are new or changed since <baseRef>, as a
// keys file for scripts/i18n/merge-keys.js: { eng: {...}, kor: {...}, ... }.
// English values are filled in; every other locale gets the value already in
// <out.json> (re-runs keep finished translations) or "" for the translator.
//
// Usage: node scripts/i18n/new-keys.js <baseRef> <out.json>
const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const [, , baseRef, out] = process.argv;
if (!baseRef || !out) {
  console.error("usage: node scripts/i18n/new-keys.js <baseRef> <out.json>");
  process.exit(1);
}
const dir = path.join(__dirname, "..", "..", "src", "utils", "locales");
const leaves = (obj, prefix = "", acc = {}) => {
  for (const [k, v] of Object.entries(obj || {})) {
    const key = prefix ? `${prefix}.${k}` : k;
    if (v && typeof v === "object" && !Array.isArray(v)) leaves(v, key, acc);
    else acc[key] = v;
  }
  return acc;
};
const nest = (pairs) => {
  const root = {};
  for (const [key, value] of pairs) {
    const parts = key.split(".");
    let node = root;
    for (const p of parts.slice(0, -1)) node = node[p] = node[p] || {};
    node[parts[parts.length - 1]] = value;
  }
  return root;
};

const base = leaves(JSON.parse(execSync(`git show ${baseRef}:src/utils/locales/eng.json`, { encoding: "utf8" })));
const cur = leaves(JSON.parse(fs.readFileSync(path.join(dir, "eng.json"), "utf8")));
const changed = Object.keys(cur).filter((k) => typeof cur[k] === "string" && base[k] !== cur[k]).sort();
const prev = fs.existsSync(out) ? JSON.parse(fs.readFileSync(out, "utf8")) : {};
const codes = fs.readdirSync(dir).filter((f) => f.endsWith(".json")).map((f) => f.replace(/\.json$/, ""));

const result = {};
for (const code of codes) {
  const had = leaves(prev[code]);
  result[code] = nest(changed.map((k) => [k, code === "eng" ? cur[k] : had[k] || ""]));
}
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, JSON.stringify(result, null, 2) + "\n");
console.log(`${changed.length} new or changed keys -> ${out}`);
