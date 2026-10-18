// Set by index.tsx before hydrateRoot. Animations that start hidden and
// reveal on scroll consult it so the first client render matches the
// prerendered markup (which is always the "visible" state); on a prerendered
// page the reveal animation is skipped and content is simply there.
let prerendered = false;

export function markPrerendered(): void {
  prerendered = true;
}

export function isPrerendered(): boolean {
  return prerendered;
}

/**
 * Clear after the first commit (App.tsx). Components mounted during hydration
 * have already taken their initial state, so clearing here costs them nothing
 * and lets everything mounted later — every client-side navigation — animate
 * normally instead of being stuck in the "already visible" state for the
 * whole session.
 */
export function clearPrerendered(): void {
  prerendered = false;
}

/**
 * Whether *this document* was served with prerendered markup, read straight
 * from the DOM rather than from the flag above.
 *
 * The flag is set by index.tsx, and index.tsx is too late for one caller:
 * src/utils/i18n.ts configures i18next as a side effect of being imported, and
 * ES imports run before any statement in the importing module. It has to know
 * at that moment whether the first render must be English, so it asks the DOM
 * the same question index.tsx asks -- does #root already have children.
 */
export function documentIsPrerendered(): boolean {
  if (typeof document === "undefined") return false;
  const root = document.getElementById("root");
  return Boolean(root && root.hasChildNodes());
}
