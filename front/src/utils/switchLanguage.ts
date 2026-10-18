// src/utils/switchLanguage.ts
//
// The one way the app should change language now that locales are chunks.
//
// `i18n.changeLanguage(code)` on its own is not enough, because a chunk that
// failed to load stays failed. Measured against i18next 23.7.18:
//
//   after a failed switch:            state = -1, no bundle in the store
//   plain changeLanguage() again:     no new read -- `queueLoad` short-circuits
//                                     on `else if (this.state[name] < 0) ;`
//   reloadResources() (reload: true): still no new read -- `reload` only skips
//                                     the `hasResourceBundle` branch, not the
//                                     negative-state one
//   clear that state entry, then reloadResources(): the read happens, and the
//                                     language recovers
//
// So recovery needs both halves, and the public API alone cannot do it. The
// state map is reached through a `typeof` guard: if a future i18next drops it,
// this degrades to a plain `changeLanguage` rather than throwing.
import { i18n as I18n } from "i18next";

const NS = "translation";

/** Every code i18next would consult for `code`, best first. */
function resolutionCodes(i18n: I18n, code: string): string[] {
  const utils = (i18n as any).services && (i18n as any).services.languageUtils;
  if (utils && typeof utils.toResolveHierarchy === "function") {
    const codes = utils.toResolveHierarchy(code);
    if (codes && codes.length) return codes;
  }
  if (utils && typeof utils.getBestMatchFromCodes === "function") {
    const best = utils.getBestMatchFromCodes([code]);
    if (best) return best === code ? [code] : [code, best];
  }
  return [code];
}

/**
 * Forget that these codes previously failed to load.
 *
 * Returns true when something was actually cleared, so the caller knows a
 * reload is worth attempting rather than being a no-op.
 */
function clearFailedState(i18n: I18n, codes: string[]): boolean {
  const connector = (i18n as any).services && (i18n as any).services.backendConnector;
  if (!connector || typeof connector.state !== "object" || connector.state === null) return false;
  let cleared = false;
  for (const code of codes) {
    const name = `${code}|${NS}`;
    if (connector.state[name] < 0) {
      delete connector.state[name];
      cleared = true;
    }
  }
  return cleared;
}

/**
 * Switch to `code`, re-fetching any locale chunk that is not in the store --
 * including one an earlier attempt failed to fetch.
 *
 * Synchronous when nothing needs loading (the language is already in the
 * store), so a caller that relies on `i18n.language` right afterwards -- the
 * hydration restore -- keeps behaving the way it did when every locale was
 * inlined. Resolves when the switch has settled; never rejects.
 */
export function switchLanguage(i18n: I18n, code: string): Promise<void> {
  const change = (): Promise<void> => {
    const switched = i18n.changeLanguage(code) as Promise<unknown> | undefined;
    // The guard is for test doubles whose changeLanguage returns undefined.
    if (switched && typeof switched.then === "function") {
      return switched.then(
        () => undefined,
        () => undefined
      );
    }
    return Promise.resolve();
  };

  if (typeof (i18n as any).hasResourceBundle !== "function") return change();

  const missing = resolutionCodes(i18n, code).filter((lng) => !i18n.hasResourceBundle(lng, NS));
  if (!missing.length) return change();

  clearFailedState(i18n, missing);
  if (typeof (i18n as any).reloadResources !== "function") return change();

  // reloadResources never rejects in i18next 23 (its deferred resolves on the
  // error path too), but a future version or a test double might.
  return Promise.resolve()
    .then(() => (i18n as any).reloadResources(missing, NS))
    .then(change, change);
}

export default switchLanguage;
