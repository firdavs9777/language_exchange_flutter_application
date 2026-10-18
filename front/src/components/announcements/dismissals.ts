export const DISMISS_KEY = "bt_ann_dismissed_v1";
const MAX = 50;
// Fallback when storage is blocked: dismissal lasts for this page session.
const memory = new Set<string>();

export function readDismissed(): string[] {
  try {
    const raw = window.localStorage.getItem(DISMISS_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed.filter((x) => typeof x === "string") : [];
  } catch {
    return [];
  }
}

export function isDismissed(id: string): boolean {
  return memory.has(id) || readDismissed().indexOf(id) >= 0;
}

export function dismiss(id: string): void {
  try {
    const next = readDismissed().filter((x) => x !== id).concat(id).slice(-MAX);
    window.localStorage.setItem(DISMISS_KEY, JSON.stringify(next));
  } catch {
    // storage blocked: the in-memory set covers this page session
    memory.add(id);
  }
}

export function _resetDismissalsForTests(): void {
  memory.clear();
}
