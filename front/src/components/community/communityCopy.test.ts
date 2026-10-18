/**
 * Every literal t("...") key the community surfaces use must exist in
 * eng.json as a string (or as an i18next plural pair). The trap this guards:
 * eng.json's "community" is a STRING, so community.nearby.* / community.waves.*
 * could never resolve, the `|| "fallback"` never fired, and users read raw keys.
 */
import fs from "fs";
import path from "path";

const ROOT = path.join(__dirname, "..");
const FILES = [
  "community/NearbyUsers.tsx",
  "community/Waves.tsx",
  "community/WaveSheet.tsx",
  "community/tandem/CommunitySubNav.tsx",
  "community/CommunityFilterSheet.tsx",
  "community/today/MatchCard.tsx",
  "community/today/TodayTab.tsx",
  "profile/useFollowToggle.ts",
];
/** Keys built with template literals, which the scan below cannot see. */
const DYNAMIC_KEYS = ["hi", "cool", "hey", "chat", "hello", "nice"].reduce(
  (all: string[], chip) => all.concat([`waves.sheet.chips.${chip}.label`, `waves.sheet.chips.${chip}.message`]),
  ["waves.sheet.icebreakers.0", "waves.sheet.icebreakers.1", "waves.sheet.icebreakers.2", "waves.sheet.icebreakers.3"]
);

const eng = JSON.parse(
  fs.readFileSync(path.join(__dirname, "../../utils/locales/eng.json"), "utf8")
);

function nodeAt(key: string): any {
  let node: any = eng;
  const parts = key.split(".");
  for (let i = 0; i < parts.length; i += 1) {
    if (!node || typeof node !== "object") return undefined;
    node = node[parts[i]];
  }
  return node;
}

function exists(key: string): boolean {
  if (typeof nodeAt(key) === "string") return true;
  return typeof nodeAt(`${key}_one`) === "string" && typeof nodeAt(`${key}_other`) === "string";
}

function usedKeys(): string[] {
  const used: string[] = [];
  FILES.forEach((file) => {
    const source = fs.readFileSync(path.join(ROOT, file), "utf8");
    const re = /\bt\(\s*"([A-Za-z0-9_.]+)"/g;
    let m = re.exec(source);
    while (m) {
      if (used.indexOf(m[1]) < 0) used.push(m[1]);
      m = re.exec(source);
    }
  });
  return used.concat(DYNAMIC_KEYS);
}

it("finds the keys at all", () => {
  expect(usedKeys().length).toBeGreaterThan(40);
});

it("every community key exists in eng.json", () => {
  expect(usedKeys().filter((key) => !exists(key))).toEqual([]);
});

it("no key hangs under a string parent like the old community.nearby.*", () => {
  const underString = usedKeys().filter((key) => {
    const parts = key.split(".");
    for (let i = 1; i < parts.length; i += 1) {
      if (typeof nodeAt(parts.slice(0, i).join(".")) === "string") return true;
    }
    return false;
  });
  expect(underString).toEqual([]);
});
