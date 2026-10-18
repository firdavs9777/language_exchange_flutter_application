import { useEffect, useState } from "react";

// Which interrupting surfaces are on screen. Lets the consent bar step aside
// while the download popup is open instead of stacking two asks at once.
type Listener = () => void;
const open = new Set<string>();
const listeners = new Set<Listener>();
const notify = () => listeners.forEach((l) => l());

export function openSurface(key: string): void {
  open.add(key);
  notify();
}

export function closeSurface(key: string): void {
  open.delete(key);
  notify();
}

export function useSurfaceOpen(key: string): boolean {
  const [isOpen, setIsOpen] = useState(() => open.has(key));
  useEffect(() => {
    const listener = () => setIsOpen(open.has(key));
    listeners.add(listener);
    listener();
    return () => {
      listeners.delete(listener);
    };
  }, [key]);
  return isOpen;
}

export function _resetSurfacesForTests(): void {
  open.clear();
  listeners.clear();
}

export function isSurfaceOpen(key: string): boolean {
  return open.has(key);
}
