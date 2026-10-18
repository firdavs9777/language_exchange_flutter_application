import React from "react";

export interface BadgeProps {
  children: React.ReactNode;
  tone?: "brand" | "banana";
}

// Arbitrary modifiers, never `bg-banana/28`: Tailwind v3's shorthand only
// accepts steps present in theme.opacity, and an absent step emits no rule at
// all rather than failing the build.
const TONE: Record<NonNullable<BadgeProps["tone"]>, string> = {
  brand: "bg-brand/[0.12] text-brand-dark dark:text-brand-light",
  banana: "bg-banana/[0.28] text-banana-dark dark:text-banana-light",
};

const Badge: React.FC<BadgeProps> = ({ children, tone = "brand" }) => (
  <span
    data-testid="badge"
    className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-wide ${TONE[tone]}`}
  >
    {children}
  </span>
);

export default Badge;
