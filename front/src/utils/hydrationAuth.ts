import { readStoredUserInfo, setCredentials } from "../store/slices/authSlice";

// Prerendered HTML is logged out, so the first client render must be logged out
// too (authSlice's getInitialUserInfo). The stored session is put back here,
// from an effect after the first commit (App.tsx), where a changed navbar is a
// normal re-render instead of a hydration mismatch.
let restored = false;

/**
 * Restore the signed-in session after hydration. No-op when nothing is stored,
 * and at most once per page load.
 */
export function restoreAuthAfterHydration(dispatch: (action: any) => void): void {
  if (restored) return;
  restored = true;

  const stored = readStoredUserInfo();
  if (stored) dispatch(setCredentials(stored));
}

export function _resetHydrationAuthForTests(): void {
  restored = false;
}
