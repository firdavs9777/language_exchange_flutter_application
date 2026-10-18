import { useEffect, useState } from "react";

/**
 * False on the server pass and on the first client render; true from the
 * first effect onward.
 *
 * This is the gate for a value that CANNOT go into prerendered markup because
 * it depends on when it is read rather than on what is being rendered — a
 * relative timestamp being the clear case.
 *
 * Why it matters here specifically: `/moments` is prerendered once at build
 * time and then served as a static file. `moment(createdAt).fromNow()` wrote
 * "16 minutes ago" into that file, and by the time the first visitor loaded it
 * the honest answer was "17 minutes ago". React compares the two during
 * hydration, reports a text mismatch (#425 / #418), and recovers the only way
 * it can: it throws the server HTML away and re-renders the whole tree on the
 * client. That costs exactly the first paint the prerender exists to buy, on
 * every visit after the first minute — and it was invisible, because the page
 * still ends up correct.
 *
 * The rule this encodes: the server and the first client render must produce
 * the SAME string, so both render the stable form and only the second render
 * shows the time-dependent one.
 *
 * `useEffect` does not run during `renderToString`, which is what makes the
 * initial `false` reliable on the server. The state update lands in the
 * post-hydration commit, so the swap is one extra render, batched with every
 * other component doing the same thing.
 */
export function useHasHydrated(): boolean {
  const [hydrated, setHydrated] = useState(false);
  useEffect(() => {
    setHydrated(true);
  }, []);
  return hydrated;
}

export default useHasHydrated;
