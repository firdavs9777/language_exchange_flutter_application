import React from "react";

// Chunk loads can fail, and since task B6 split the app into route chunks they
// can fail where nothing could fail before. The two real causes:
//
//   1. a flaky network dropped one request. Asking again usually works.
//   2. the tab has been open across a deploy. The document in memory names
//      hashed chunks the server no longer has, so *every* retry 404s; only a
//      fresh document can recover, and only once -- a reload loop on a chunk
//      that is genuinely gone would be worse than the error screen.
//
// So: retry the import once, then reload the page at most once per chunk, then
// give up and let the error reach the root route's errorElement (RouteError).
//
// Browser globals are touched only inside the failure path, never at import
// time and never during render, so this module stays safe to require from
// scripts/prerender.js in plain Node.

/** The bits of the browser this module needs. Injected so tests can watch them. */
export interface RetryEnv {
  /** Has a reload already been spent on this chunk in this tab? */
  hasReloaded: (key: string) => boolean;
  /** Remember that one has, for this tab only. */
  markReloaded: (key: string) => void;
  /** Fetch a fresh document. */
  reload: () => void;
}

const FLAG_PREFIX = "bt:chunk-reload:";

// sessionStorage, not localStorage: the flag should die with the tab, and a
// second tab opened later deserves its own reload. Every access is guarded --
// Safari's private mode throws on sessionStorage rather than returning null,
// and a throw here would replace a recoverable chunk error with a crash.
export const browserRetryEnv: RetryEnv = {
  hasReloaded: (key) => {
    try {
      return typeof window !== "undefined" && window.sessionStorage.getItem(FLAG_PREFIX + key) !== null;
    } catch (e) {
      // No storage means no way to remember, and no way to guarantee we stop
      // after one reload. Claim we already reloaded: showing the error screen
      // is strictly better than risking a loop.
      return true;
    }
  },
  markReloaded: (key) => {
    try {
      if (typeof window !== "undefined") window.sessionStorage.setItem(FLAG_PREFIX + key, "1");
    } catch (e) {
      /* see above */
    }
  },
  reload: () => {
    if (typeof window !== "undefined") window.location.reload();
  },
};

/**
 * Runs `importer`, retrying once, then reloading once, then giving up.
 *
 * The promise returned after a reload never settles on purpose: the document
 * is being replaced, and resolving or rejecting would only race the unload
 * with a render.
 */
export function retryImport<T>(importer: () => Promise<T>, key: string, env: RetryEnv = browserRetryEnv): Promise<T> {
  return importer().catch(() =>
    importer().catch((second) => {
      if (env.hasReloaded(key)) throw second;
      env.markReloaded(key);
      env.reload();
      return new Promise<T>(() => undefined);
    })
  );
}

/**
 * React.lazy with the retry above. `key` identifies the chunk in the
 * sessionStorage flag; the module path it loads is the obvious choice.
 */
export function lazyWithRetry<T extends React.ComponentType<any>>(
  key: string,
  importer: () => Promise<{ default: T }>
): React.LazyExoticComponent<T> {
  return React.lazy(() => retryImport(importer, key));
}
