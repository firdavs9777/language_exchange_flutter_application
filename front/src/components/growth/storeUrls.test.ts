import fs from "fs";
import path from "path";
import { APP_STORE_URL, PLAY_STORE_URL } from "./storeUrls";

// One home for the store URLs. Before StoreLink there were six copies of them
// across the app, two of which had drifted to a stale app id, and none of
// which carried a campaign tag. This guard is what stops the seventh: the
// hostnames may appear in exactly one file, and everything else reaches them
// through the exported constants.
//
// The needles are derived from the constants rather than written out, so this
// file does not trip its own rule.
const SRC = path.join(__dirname, "../..");
const ALLOWED = path.join(SRC, "components/growth/storeUrls.ts");
const HOSTS = [APP_STORE_URL, PLAY_STORE_URL].map((url) => url.split("/")[2]);

const TEXT_EXT = [".ts", ".tsx", ".js", ".jsx", ".json", ".css", ".scss", ".html", ".md", ".txt"];

function walk(dir: string, out: string[] = []): string[] {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "node_modules" || entry.name === ".git") continue;
      walk(full, out);
    } else if (TEXT_EXT.indexOf(path.extname(entry.name)) !== -1) {
      out.push(full);
    }
  }
  return out;
}

it("keeps both store hostnames in storeUrls.ts and nowhere else", () => {
  const offenders: string[] = [];
  for (const file of walk(SRC)) {
    if (file === ALLOWED) continue;
    const text = fs.readFileSync(file, "utf8");
    for (const host of HOSTS) {
      if (text.indexOf(host) !== -1) {
        offenders.push(`${path.relative(SRC, file)} contains ${host}`);
      }
    }
  }
  expect(offenders).toEqual([]);
});

it("finds the file it is guarding", () => {
  expect(fs.existsSync(ALLOWED)).toBe(true);
  const text = fs.readFileSync(ALLOWED, "utf8");
  HOSTS.forEach((host) => expect(text).toContain(host));
});
