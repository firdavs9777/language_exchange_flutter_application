import { useEffect, useState } from "react";
import {
  Consent,
  readConsent,
  writeConsent,
  withdrawConsent,
  setGaDisabled,
  subscribeConsent,
} from "./consent";
import { loadGa, GA_MEASUREMENT_ID } from "./ga";

/**
 * One decision, three places that can change it: the consent bar's manage
 * panel, the privacy settings row and (indirectly) the policy page. They look
 * nothing alike — a fixed bar, a settings card — so this is a hook rather than
 * a component: the behaviour is shared, the chrome is not.
 *
 * "pending" until the effect runs. `readConsent` touches localStorage, which
 * the prerendered pages have no access to, so the first client render must
 * match the server's: undecided-but-not-yet-known, drawing nothing.
 */
export type ConsentState = "pending" | Consent | null;

export function useConsentChoice(): {
  state: ConsentState;
  accept: () => void;
  decline: () => void;
} {
  const [state, setState] = useState<ConsentState>("pending");

  useEffect(() => {
    const stored = readConsent();
    setState(stored);
    // A visitor who accepted on an earlier visit gets gtag back on this page
    // load. This lives here rather than in ConsentBar so that every surface
    // built on the hook behaves the same, instead of quietly depending on the
    // bar having mounted first.
    if (stored === "granted") loadGa();
    // Any other surface that changes the decision moves this one too.
    return subscribeConsent((value) => setState(value));
  }, []);

  return {
    state,
    accept: () => {
      // Lift gtag's kill switch first: a re-accept in the same session has to
      // restart a script that is already on the page, and `loadGa` refuses to
      // run while the flag is up.
      setGaDisabled(false, GA_MEASUREMENT_ID);
      writeConsent("granted");
      loadGa();
    },
    decline: () => withdrawConsent(GA_MEASUREMENT_ID),
  };
}
