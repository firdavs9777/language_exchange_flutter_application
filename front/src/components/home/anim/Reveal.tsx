import React from "react";
import { useInView, prefersReducedMotion } from "./useInView";

export interface RevealProps {
  children: React.ReactNode;
  /** Stagger, in ms, for siblings revealed together. */
  delayMs?: number;
  as?: "div" | "section";
  className?: string;
}

/**
 * Fades and lifts its children into view on scroll.
 *
 * Children are ALWAYS in the DOM — this animates opacity and transform only.
 * Mounting on intersection would hide content from crawlers, from assistive
 * tech, and from any browser whose observer never fires.
 */
const Reveal: React.FC<RevealProps> = ({
  children,
  delayMs = 0,
  as = "div",
  className = "",
}) => {
  const [ref, inView] = useInView<HTMLDivElement>();
  const reduced = prefersReducedMotion();
  const Tag = as as any;

  if (reduced) {
    return (
      <Tag ref={ref} data-testid="reveal" className={className}>
        {children}
      </Tag>
    );
  }

  return (
    <Tag
      ref={ref}
      data-testid="reveal"
      style={{ transitionDelay: `${delayMs}ms` }}
      className={`transition-all duration-700 ease-out ${
        inView ? "translate-y-0 opacity-100" : "translate-y-6 opacity-0"
      } ${className}`}
    >
      {children}
    </Tag>
  );
};

export default Reveal;
