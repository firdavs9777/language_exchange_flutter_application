import { useEffect, useRef, useState } from "react";
import { isPrerendered } from "../../../seo/prerender/hydrationFlag";

/** True when the user has asked for less motion. Read at call time, not cached. */
export function prefersReducedMotion(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  try {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  } catch {
    return false;
  }
}

/**
 * Reports whether the element has entered the viewport.
 *
 * Returns true immediately when IntersectionObserver is unavailable (jsdom,
 * older browsers) or when reduced motion is requested. Visible content is the
 * safe failure: an animation that never runs must never mean content nobody
 * can see.
 */
export function useInView<T extends HTMLElement>(
  options: { once?: boolean; rootMargin?: string } = {}
): [React.RefObject<T>, boolean] {
  const { once = true, rootMargin = "0px 0px -10% 0px" } = options;
  const ref = useRef<T>(null);
  const [inView, setInView] = useState(
    () => typeof IntersectionObserver === "undefined" || prefersReducedMotion() || isPrerendered()
  );

  useEffect(() => {
    if (inView && once) return;
    const el = ref.current;
    if (!el || typeof IntersectionObserver === "undefined") return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setInView(true);
            if (once) observer.disconnect();
          } else if (!once) {
            setInView(false);
          }
        });
      },
      { rootMargin, threshold: 0.12 }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [inView, once, rootMargin]);

  return [ref, inView];
}
