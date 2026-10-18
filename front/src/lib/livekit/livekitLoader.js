// The ONLY module that names livekit-client.
//
// Why a .js file with a hand-written .d.ts: livekit-client's typings (and its
// `typesVersions` fallback for TS < 4.8, dist/ts4.2) use `import type`, which
// TypeScript 3.7.2 cannot parse -- 621 errors from one `import { Room }`.
// This file is listed in tsconfig.json "exclude", so the TS program never
// resolves the package; .ts callers see only livekitLoader.d.ts.
//
// Why import(): ~151 KB gzipped of WebRTC that no visitor needs until they
// join a voice room or a call. The chunk is named "livekit" (src/seo/
// eagerGraph.test.ts and the push checks grep main.js for "livekit-client").
let pending = null;

export function loadLivekit() {
  if (!pending) {
    pending = import(/* webpackChunkName: "livekit" */ "livekit-client").catch((err) => {
      // A chunk that failed (flaky network, a tab open across a deploy) must
      // not poison every later attempt.
      pending = null;
      throw err;
    });
  }
  return pending;
}
