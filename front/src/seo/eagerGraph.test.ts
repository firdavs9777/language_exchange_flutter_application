/**
 * @jest-environment node
 */
// A guard on what a first-time visitor downloads before anything on a
// marketing page paints.
//
// Task B6 moved the bootstrap-icons stylesheet out of the entrypoint and into
// src/lazyIcons.ts, which only modules behind a React.lazy boundary were
// allowed to import. The profile redesign (task P4) rewrote the last three
// screens that spelled `bi-*` -- followers, following and visitors -- onto
// lucide, so lazyIcons.ts is gone and nothing in src/ names the package at
// all. What is still worth guarding is the rule that outlives it: the icon
// font must never be reachable from the entrypoint. Nothing else enforces
// that, and the bundle budget cannot: the icon CSS is ~13.5 KB gzipped and
// the budget's headroom is wider than that, so a regression would slip
// through as a number nobody reads.
//
// So: build the static import graph the way webpack does for the entrypoint --
// start at the three real roots, follow only *static* `import`/`export ... from`
// declarations, and stop at `import()`, which is exactly where a chunk begins.
// If bootstrap-icons (or a re-exporting module like the old lazyIcons) turns
// up in that graph, something eager imported it and the font is in main.css.
//
// Same idea as src/components/growth/storeUrls.test.ts: a cheap source-level
// rule, checked by reading files rather than by building.
import fs from "fs";
import path from "path";

const SRC = path.join(__dirname, "..");

// The three modules that are loaded eagerly in production. index.tsx is the
// webpack entry; routes.tsx and renderRoute.tsx are the two entry points the
// prerender walks, and every eager page hangs off the route tree.
const ROOTS = [
  path.join(SRC, "index.tsx"),
  path.join(SRC, "router", "routes.tsx"),
  path.join(SRC, "seo", "prerender", "renderRoute.tsx"),
];

const FORBIDDEN_PACKAGE = "bootstrap-icons";

// Task D2's half of the rule, and the same shape of mistake: the socket.io
// client (~13 KB gzipped with engine.io and its parsers) is useless to a
// logged-out visitor -- there is no token to authenticate with -- so
// src/components/chat/hooks/useSocket.ts `import()`s it from inside the effect
// that runs only when `state.auth.userInfo` has one. App.tsx still wraps the
// whole tree in SocketProvider, so this module IS eager; what must stay behind
// the boundary is the client it loads. A static `import { io } from
// "socket.io-client"` anywhere in the eager graph -- including a type-only one,
// which TypeScript 3.7 cannot mark as such -- puts it back in main.js.
const FORBIDDEN_SOCKET_PACKAGE = "socket.io-client";
const SOCKET_MODULE = path.join(SRC, "components", "chat", "hooks", "useSocket.ts");
// Phase 4 (voice rooms, calls): livekit-client is ~151 KB gzipped of WebRTC
// that only a member joining a room or a call can use. It is reached only
// through src/lib/livekit/livekitLoader.js, which `import()`s it; a static
// import anywhere in the eager graph would put it in main.js.
const FORBIDDEN_LIVEKIT_PACKAGE = "livekit-client";
// The module that used to carry the stylesheet. Deleted with the last `bi-*`
// screen; asserted below so a re-introduced copy cannot sneak the font back.
const RETIRED_MODULE = path.join(SRC, "lazyIcons.ts");

// Task D1's half of the same rule. English is inlined in src/utils/i18n.ts on
// purpose; the other 17 locales are `import()`ed by src/utils/i18nLazyBackend.ts
// and must stay behind that boundary. A single static `import ko from
// "./locales/kor.json"` slipped back in would put ~18 KB gzipped into main.js
// and, if it were copied for all 17, the ~291 KB this task removed.
const INLINED_LOCALE = path.join(SRC, "utils", "locales", "eng.json");
const LAZY_LOCALE = path.join(SRC, "utils", "locales", "kor.json");

// Extensions we parse. Anything else (.css, .scss, .json, images) is a leaf:
// it has no `import ... from` of its own that could reach further into src/.
const PARSED = [".ts", ".tsx", ".js", ".jsx"];
const RESOLVE_EXT = ["", ".ts", ".tsx", ".js", ".jsx", ".json", ".css", ".scss"];

/**
 * Strips comments so the specifier regexes below see code only. String and
 * template literals are kept verbatim -- a specifier lives inside one. Without
 * this, prose wins: src/design/index.ts documents the TS 3.7
 * `export type { X } from "./Y"` trap in a comment, and a naive scan reads that
 * as a real edge to a module that does not exist.
 */
function stripNonCode(source: string): string {
  let out = "";
  let i = 0;
  const n = source.length;
  while (i < n) {
    const c = source.charAt(i);
    const next = source.charAt(i + 1);
    if (c === "/" && next === "/") {
      while (i < n && source.charAt(i) !== "\n") i += 1;
    } else if (c === "/" && next === "*") {
      i += 2;
      while (i < n && !(source.charAt(i) === "*" && source.charAt(i + 1) === "/")) i += 1;
      i += 2;
    } else if (c === '"' || c === "'" || c === "`") {
      // Keep the quotes and the body: a specifier lives inside one. Escapes
      // are honoured so a \" cannot end the literal early.
      out += c;
      i += 1;
      while (i < n && source.charAt(i) !== c) {
        if (source.charAt(i) === "\\") {
          out += source.charAt(i) + source.charAt(i + 1);
          i += 2;
          continue;
        }
        out += source.charAt(i);
        i += 1;
      }
      out += c;
      i += 1;
    } else {
      out += c;
      i += 1;
    }
  }
  return out;
}

/**
 * Static `import`/`export ... from` specifiers only.
 *
 * Deliberately misses `import("x")`: a dynamic import is a chunk boundary, and
 * everything beyond it is precisely what this test must NOT walk into. The
 * `from` (or the bare `import "x";` side-effect form) is what separates the
 * two -- `import(` is always followed by the specifier, never by `from`.
 *
 * The gap before `from` excludes `;` and quotes, so the match cannot run past
 * the end of one statement and pick up an unrelated specifier further down.
 */
function staticSpecifiers(source: string): string[] {
  const code = stripNonCode(source);
  const out: string[] = [];
  // `import ... from "x"` / `export ... from "x"`, across newlines.
  const withFrom = /(?:^|[\s;}])(?:import|export)\s+(?:[^;'"]*?\s)?from\s*["']([^"']+)["']/g;
  // Side-effect imports: `import "x";` -- no `from`, no braces.
  const sideEffect = /(?:^|[\s;}])import\s*["']([^"']+)["']/g;
  let m: RegExpExecArray | null;
  while ((m = withFrom.exec(code)) !== null) out.push(m[1]);
  while ((m = sideEffect.exec(code)) !== null) out.push(m[1]);
  return out;
}

/** Node-ish resolution for a relative specifier: file, +ext, or /index.+ext. */
function resolveRelative(fromFile: string, spec: string): string | null {
  const base = path.resolve(path.dirname(fromFile), spec);
  for (const ext of RESOLVE_EXT) {
    const candidate = base + ext;
    if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) return candidate;
  }
  for (const ext of RESOLVE_EXT) {
    if (!ext) continue;
    const candidate = path.join(base, "index" + ext);
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

interface Graph {
  /** Every file reachable from ROOTS through static imports. */
  modules: string[];
  /** "<importer> -> <package>" for every static package import we care about. */
  packageHits: string[];
  /** Specifiers we could not resolve, so a silent miss shows up as a failure. */
  unresolved: string[];
}

function walkEagerGraph(): Graph {
  const seen: Record<string, boolean> = {};
  const modules: string[] = [];
  const packageHits: string[] = [];
  const unresolved: string[] = [];
  const queue = ROOTS.slice();

  while (queue.length) {
    const file = queue.shift() as string;
    if (seen[file]) continue;
    seen[file] = true;
    modules.push(file);
    if (PARSED.indexOf(path.extname(file)) === -1) continue;

    const source = fs.readFileSync(file, "utf8");
    for (const spec of staticSpecifiers(source)) {
      if (spec.charAt(0) === ".") {
        const resolved = resolveRelative(file, spec);
        if (resolved) {
          if (!seen[resolved]) queue.push(resolved);
        } else {
          unresolved.push(`${path.relative(SRC, file)} -> ${spec}`);
        }
      } else if (
        spec === FORBIDDEN_PACKAGE ||
        spec.indexOf(FORBIDDEN_PACKAGE + "/") === 0 ||
        spec === FORBIDDEN_SOCKET_PACKAGE ||
        spec.indexOf(FORBIDDEN_SOCKET_PACKAGE + "/") === 0 ||
        spec === FORBIDDEN_LIVEKIT_PACKAGE ||
        spec.indexOf(FORBIDDEN_LIVEKIT_PACKAGE + "/") === 0
      ) {
        // A package import, but one of the two packages that must never be
        // static here: bootstrap-icons carries the webfont and ~2,000 glyph
        // rules, socket.io-client the transport nobody logged out can use.
        packageHits.push(`${path.relative(SRC, file)} -> ${spec}`);
      }
      // Every other package import (react, lucide, bootstrap, ...) is out of
      // scope: this test is about the icon font, not about dependency weight.
    }
  }
  return { modules, packageHits, unresolved };
}

const graph = walkEagerGraph();

it("walks a real graph from all three eager roots", () => {
  // A resolver that quietly resolved nothing would make every other assertion
  // here pass vacuously, so pin the shape: the roots are reachable and the
  // graph is the ~150-module app shell, not a handful of files.
  for (const root of ROOTS) expect(fs.existsSync(root)).toBe(true);
  expect(graph.modules.length).toBeGreaterThan(100);
  expect(graph.modules.indexOf(path.join(SRC, "App.tsx"))).toBeGreaterThan(-1);
  expect(graph.modules.indexOf(path.join(SRC, "components", "footer", "FooterMain.tsx"))).toBeGreaterThan(-1);
  expect(graph.unresolved).toEqual([]);
});

it("has no lazyIcons module left to reach", () => {
  // P4 deleted it along with the last screens that rendered `bi-*` glyphs. If
  // it comes back, it must come back behind a React.lazy boundary -- the
  // graph assertion below covers that case too.
  expect(fs.existsSync(RETIRED_MODULE)).toBe(false);
  const offenders = graph.modules.filter((f) => f === RETIRED_MODULE);
  expect(offenders.map((f) => path.relative(SRC, f))).toEqual([]);
});

it("never statically imports bootstrap-icons or socket.io-client from an eager module", () => {
  // The other half of the same rule: importing the package directly would put
  // the stylesheet back into main.css just as surely as importing lazyIcons.
  expect(graph.packageHits).toEqual([]);
});

it("reaches the socket provider but not the socket client", () => {
  // useSocket.ts in the graph is the control: App.tsx wraps the tree in
  // SocketProvider on every page, prerendered ones included, so the provider
  // itself is eager by design. The assertion that matters is the one above --
  // nothing in that graph names socket.io-client statically.
  expect(graph.modules.indexOf(SOCKET_MODULE)).toBeGreaterThan(-1);
  const staticSocketImports = graph.packageHits.filter(
    (hit) => hit.indexOf(FORBIDDEN_SOCKET_PACKAGE) > -1
  );
  expect(staticSocketImports).toEqual([]);
});

it("proves the socket guard can fire, on the module that really does load the client", () => {
  // useSocket.ts names the package twice -- once in `import(...)` for the
  // value, once in an `import(...)` *type* for `Socket`, which is how a TS 3.7
  // file (no `import type`) refers to it without an edge webpack can see.
  // Neither form is a static specifier; a plain `import { io } from` would be.
  const text = fs.readFileSync(SOCKET_MODULE, "utf8");
  expect(text).toContain(FORBIDDEN_SOCKET_PACKAGE);
  expect(staticSpecifiers(text)).not.toContain(FORBIDDEN_SOCKET_PACKAGE);
  expect(staticSpecifiers('import { io } from "socket.io-client";\n')).toContain(
    FORBIDDEN_SOCKET_PACKAGE
  );
});

it("proves the guard can fire, on a source that really does import the icons", () => {
  // With lazyIcons.ts gone there is no file left in src/ that names the
  // package, so the proof runs on the import it used to hold. Without this,
  // a scanner that silently stopped matching side-effect imports would make
  // the assertions above pass for the wrong reason.
  const source = '// a comment\nimport "bootstrap-icons/font/bootstrap-icons.css";\n';
  expect(staticSpecifiers(source)).toContain("bootstrap-icons/font/bootstrap-icons.css");
});

it("reaches only eng.json statically; the other 17 locales are chunks", () => {
  // eng.json being in the graph is the control: it proves the walk really does
  // resolve .json leaves, so kor.json's absence means something.
  expect(fs.existsSync(LAZY_LOCALE)).toBe(true);
  expect(graph.modules.indexOf(INLINED_LOCALE)).toBeGreaterThan(-1);
  expect(graph.modules.indexOf(LAZY_LOCALE)).toBe(-1);

  const eager = graph.modules.filter((f) => f.indexOf(path.join(SRC, "utils", "locales")) === 0);
  expect(eager.map((f) => path.basename(f))).toEqual(["eng.json"]);
});

// Task S4's half of the rule. `/moments` is prerendered and imports
// `StoriesFeed` statically -- the ring row is on the eager path by design and
// has to stay tiny. Everything a ring LEADS to is a lazy route in
// src/router/routes.tsx: the viewer, the composer, My stories, highlights and
// the three sheets. The viewer is the one that would hurt most (it drags in
// the sheets, the chat slice behind the share sheet and the overlay renderer),
// so it is the canary: a `import StoryViewer from "./StoryViewer"` anywhere in
// the shell -- a convenience re-export, a modal opened from the feed -- puts
// all of it in main.js, and the bundle budget's headroom is wide enough to
// hide it.
const EAGER_STORIES_MODULE = path.join(SRC, "components", "stories", "StoriesFeed.tsx");
const LAZY_STORY_MODULES = [
  path.join(SRC, "components", "stories", "StoryViewer.tsx"),
  path.join(SRC, "components", "stories", "CreateStory.tsx"),
  path.join(SRC, "components", "stories", "MyStories.tsx"),
  path.join(SRC, "components", "stories", "Highlights.tsx"),
];

it("reaches the story ring row but never the story viewer", () => {
  // The ring row in the graph is the control: it proves the walk really does
  // get into components/stories, so the viewer's absence means something.
  expect(fs.existsSync(EAGER_STORIES_MODULE)).toBe(true);
  expect(graph.modules.indexOf(EAGER_STORIES_MODULE)).toBeGreaterThan(-1);

  LAZY_STORY_MODULES.forEach((file) => expect(fs.existsSync(file)).toBe(true));
  const eager = LAZY_STORY_MODULES.filter((f) => graph.modules.indexOf(f) > -1);
  expect(eager.map((f) => path.relative(SRC, f))).toEqual([]);
});

it("proves the story guard can fire, on the module that really does load the viewer", () => {
  // routes.tsx names StoryViewer, but only inside `import(...)` behind
  // lazyWithRetry -- the form staticSpecifiers deliberately does not match.
  const routes = fs.readFileSync(path.join(SRC, "router", "routes.tsx"), "utf8");
  expect(routes).toContain("components/stories/StoryViewer");
  expect(staticSpecifiers(routes)).not.toContain("../components/stories/StoryViewer");
  expect(
    staticSpecifiers('import StoryViewer from "../components/stories/StoryViewer";\n')
  ).toContain("../components/stories/StoryViewer");
});

it("proves the locale guard can fire, on the module that really does load them", () => {
  // i18nLazyBackend names every locale file, but only inside `import(...)`,
  // which staticSpecifiers deliberately does not match. If a static form ever
  // appears there, the assertion above starts failing -- as it should.
  const backend = path.join(SRC, "utils", "i18nLazyBackend.ts");
  const text = fs.readFileSync(backend, "utf8");
  expect(text).toContain("./locales/kor.json");
  expect(staticSpecifiers(text)).not.toContain("./locales/kor.json");
});

it("never reaches the LiveKit loader or livekit-client from an eager module", () => {
  const loader = path.join(SRC, "lib", "livekit", "livekitLoader.js");
  expect(graph.modules.indexOf(loader)).toBe(-1);
  expect(graph.packageHits.filter((hit) => hit.indexOf(FORBIDDEN_LIVEKIT_PACKAGE) > -1)).toEqual([]);
  // The guard can fire: a static import is seen, the loader's import() is not.
  expect(staticSpecifiers('import { Room } from "livekit-client";\n')).toContain(FORBIDDEN_LIVEKIT_PACKAGE);
  expect(staticSpecifiers(fs.readFileSync(loader, "utf8"))).not.toContain(FORBIDDEN_LIVEKIT_PACKAGE);
});
