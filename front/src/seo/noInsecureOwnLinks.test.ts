/**
 * @jest-environment node
 */
import fs from "fs";
import path from "path";

// Our own site is https-only (http 301s). Plain-http links cost a redirect and
// show "not secure" on the hop; the parked bananatalk.com (double n) is not ours.
function walk(dir: string, out: string[] = []): string[] {
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    if (fs.statSync(full).isDirectory()) walk(full, out);
    else if (/\.(tsx?|html|json)$/.test(name) && !/\.test\./.test(name)) out.push(full);
  }
  return out;
}

it("links to banatalk.com over https only, and never to bananatalk.com", () => {
  const root = path.resolve(__dirname, "../..");
  const files = walk(path.join(root, "src")).concat(walk(path.join(root, "public")));
  const offenders = files.filter((f) => /http:\/\/(www\.)?banatalk\.com|https?:\/\/(www\.|api\.)?bananatalk\.com/.test(fs.readFileSync(f, "utf8")));
  expect(offenders.map((f) => path.relative(root, f))).toEqual([]);
});
