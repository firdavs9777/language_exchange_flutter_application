// Every key a Phase 3 or Phase 4 unit added (scripts/i18n/keys/2026-10-16-p3-*.json / …p4-*.json,
// written by scripts/i18n/new-keys.js) exists in all 18 locale files, is not
// empty, and keeps the English placeholders ({{name}}, {{count}}).
import fs from "fs";
import path from "path";

const keysDir = path.join(__dirname, "../../../scripts/i18n/keys");
const keyFiles = fs.existsSync(keysDir)
  ? fs.readdirSync(keysDir).filter((f) => /^2026-10-16-p[34]-[a-z]+\.json$/.test(f))
  : [];
const localeFiles = fs.readdirSync(__dirname).filter((f) => f.endsWith(".json"));

const leaves = (obj: any, prefix = "", acc: { [k: string]: any } = {}) => {
  Object.keys(obj || {}).forEach((k) => {
    const v = obj[k];
    const key = prefix ? `${prefix}.${k}` : k;
    if (v && typeof v === "object" && !Array.isArray(v)) leaves(v, key, acc);
    else acc[key] = v;
  });
  return acc;
};
const lookup = (obj: any, key: string) =>
  key.split(".").reduce((node: any, part) => (node && typeof node === "object" ? node[part] : undefined), obj);
const placeholders = (s: string) =>
  (s.match(/\{\{\s*[\w.]+\s*\}\}/g) || []).map((p) => p.replace(/\s/g, "")).sort();

it("has 18 locale files", () => {
  expect(localeFiles).toHaveLength(18);
});

keyFiles.forEach((file) => {
  describe(file, () => {
    const keys = JSON.parse(fs.readFileSync(path.join(keysDir, file), "utf8"));
    const english = leaves(keys.eng);

    it("lists at least one key", () => {
      expect(Object.keys(english).length).toBeGreaterThan(0);
    });

    localeFiles.forEach((locale) => {
      it(`${locale}: every key present, non-empty, same placeholders`, () => {
        const data = JSON.parse(fs.readFileSync(path.join(__dirname, locale), "utf8"));
        const problems: string[] = [];
        Object.keys(english).forEach((key) => {
          const value = lookup(data, key);
          if (typeof value !== "string" || !value.trim()) problems.push(`${key}: missing`);
          else if (placeholders(value).join() !== placeholders(String(english[key])).join())
            problems.push(`${key}: placeholders differ`);
        });
        expect(problems).toEqual([]);
      });
    });
  });
});
