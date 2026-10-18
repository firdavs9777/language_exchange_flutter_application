// The loader is the only module that names livekit-client. Jest must never
// load the real package (ESM-only .mjs, outside transformIgnorePatterns), so
// the dynamic import is mocked here with a virtual module.
jest.mock("livekit-client", () => ({ Room: function Room() {}, __fake: true }), { virtual: true });

import fs from "fs";
import path from "path";

beforeEach(() => {
  jest.resetModules();
});

it("loads the module once and caches it", async () => {
  const { loadLivekit } = require("./livekitLoader");
  const a = await loadLivekit();
  const b = await loadLivekit();
  expect(a.__fake).toBe(true);
  expect(a).toBe(b);
});

it("is the only source file that names the package, and only in import()", () => {
  const src = path.join(__dirname, "..", "..");
  const offenders: string[] = [];
  const walk = (dir: string) => {
    fs.readdirSync(dir).forEach((name) => {
      const full = path.join(dir, name);
      if (fs.statSync(full).isDirectory()) return walk(full);
      if (!/\.(ts|tsx|js|jsx)$/.test(name) || /\.test\.(ts|tsx)$/.test(name)) return;
      if (fs.readFileSync(full, "utf8").indexOf("livekit-client") > -1) offenders.push(path.relative(src, full));
    });
  };
  walk(src);
  // The .d.ts declares the loader's shape without naming the package; the
  // fake under testing/ names nothing either. Only the loader may.
  expect(offenders.filter((f) => f !== path.join("lib", "livekit", "livekitLoader.js"))).toEqual([]);
  const loader = fs.readFileSync(path.join(__dirname, "livekitLoader.js"), "utf8");
  expect(loader).toMatch(/import\(\s*\/\*\s*webpackChunkName:\s*"livekit"\s*\*\/\s*"livekit-client"\s*\)/);
});

it("keeps the loader out of the TypeScript program (TS 3.7 cannot parse livekit's typings)", () => {
  const raw = fs.readFileSync(path.join(__dirname, "..", "..", "..", "tsconfig.json"), "utf8");
  const config = JSON.parse(raw.replace(/^\s*\/\/.*$/gm, ""));
  expect(config.exclude).toEqual(expect.arrayContaining(["src/lib/livekit/livekitLoader.js"]));
  expect(fs.existsSync(path.join(__dirname, "livekitLoader.d.ts"))).toBe(true);
});
