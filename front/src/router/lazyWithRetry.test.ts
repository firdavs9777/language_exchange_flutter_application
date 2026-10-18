/**
 * @jest-environment node
 */
// Node, no DOM: the point of injecting RetryEnv is that this logic can be
// exercised without a browser, the same way scripts/prerender.js requires the
// route tree without one.
import { retryImport, RetryEnv } from "./lazyWithRetry";

const makeEnv = (alreadyReloaded = false) => {
  const calls = { marked: [] as string[], reloads: 0 };
  const reloaded: Record<string, boolean> = {};
  const env: RetryEnv = {
    hasReloaded: (key) => alreadyReloaded || reloaded[key] === true,
    markReloaded: (key) => {
      reloaded[key] = true;
      calls.marked.push(key);
    },
    reload: () => {
      calls.reloads += 1;
    },
  };
  return { env, calls };
};

/** Resolves once the microtask queue has drained, so a pending promise stays pending. */
const settle = () => new Promise((r) => setTimeout(r, 0));

it("calls the importer once when it succeeds", async () => {
  const { env, calls } = makeEnv();
  let n = 0;
  const value = await retryImport(async () => {
    n += 1;
    return "module";
  }, "chat", env);
  expect({ value, n, reloads: calls.reloads }).toEqual({ value: "module", n: 1, reloads: 0 });
});

it("re-invokes the importer once when the first load rejects, and succeeds", async () => {
  const { env, calls } = makeEnv();
  let n = 0;
  const value = await retryImport(async () => {
    n += 1;
    if (n === 1) throw new Error("ChunkLoadError: Loading chunk 409 failed");
    return "module";
  }, "chat", env);
  expect({ value, n, reloads: calls.reloads }).toEqual({ value: "module", n: 2, reloads: 0 });
});

it("gives up on the importer after the second rejection and reloads once", async () => {
  const { env, calls } = makeEnv();
  let n = 0;
  let settled = false;
  retryImport(
    async () => {
      n += 1;
      throw new Error("ChunkLoadError");
    },
    "chat",
    env
  ).then(
    () => {
      settled = true;
    },
    () => {
      settled = true;
    }
  );
  await settle();
  // Two attempts, one reload, and the promise deliberately left pending while
  // the document is replaced.
  expect({ n, reloads: calls.reloads, marked: calls.marked, settled })
    .toEqual({ n: 2, reloads: 1, marked: ["chat"], settled: false });
});

it("rejects instead of reloading when this chunk already spent its reload", async () => {
  const { env, calls } = makeEnv(true);
  let n = 0;
  const err = await retryImport(
    async () => {
      n += 1;
      throw new Error("ChunkLoadError");
    },
    "chat",
    env
  ).then(() => null, (e) => e);
  expect({ n, reloads: calls.reloads, message: err && err.message })
    .toEqual({ n: 2, reloads: 0, message: "ChunkLoadError" });
});

it("keeps the reload budget per chunk", async () => {
  const { env, calls } = makeEnv();
  const fail = async () => {
    throw new Error("ChunkLoadError");
  };
  // The .catch on each call is not incidental: the second "chat" attempt has
  // no reload left and therefore rejects, and an unhandled rejection fails the
  // suite. The first and third stay pending on purpose (see retryImport).
  const swallow = () => undefined;
  retryImport(fail, "chat", env).catch(swallow);
  await settle();
  retryImport(fail, "chat", env).catch(swallow);
  await settle();
  retryImport(fail, "settings", env).catch(swallow);
  await settle();
  // One reload for chat (the second attempt on the same key is refused), one
  // for settings.
  expect({ reloads: calls.reloads, marked: calls.marked }).toEqual({ reloads: 2, marked: ["chat", "settings"] });
});
