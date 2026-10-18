import React from "react";

export interface SurfaceCardProps {
  children: React.ReactNode;
  padding?: "sm" | "md" | "lg";
  interactive?: boolean;
  className?: string;
  onClick?: () => void;
}

const PADDING: Record<NonNullable<SurfaceCardProps["padding"]>, string> = {
  sm: "p-2.5",
  md: "p-3.5",
  lg: "p-5",
};

/**
 * The app's card treatment: radius 20, a 4%-alpha shadow, surface colour.
 * Deliberately identical for the community partner row and the moment card so
 * the two main browse surfaces stop looking like different products.
 */
const SurfaceCard: React.FC<SurfaceCardProps> = ({
  children,
  padding = "md",
  interactive = false,
  className = "",
  onClick,
}) => (
  <div
    data-testid="surface-card"
    onClick={onClick}
    role={interactive ? "button" : undefined}
    tabIndex={interactive ? 0 : undefined}
    onKeyDown={
      interactive
        ? (e) => {
            if (e.key === "Enter" || e.key === " ") {
              if (e.key === " ") e.preventDefault();
              onClick?.();
            }
          }
        : undefined
    }
    className={[
      "rounded-card bg-surface shadow-card",
      // Dark mode drops the shadow rather than darkening it -- see
      // community_card.dart:90.
      "dark:bg-cardbg-dark dark:shadow-none",
      PADDING[padding],
      interactive
        ? "cursor-pointer transition-shadow hover:shadow-raised active:scale-[0.99]"
        : "",
      className,
    ]
      .filter(Boolean)
      .join(" ")}
  >
    {children}
  </div>
);

export default SurfaceCard;
