import React from "react";
import { SurfaceCard } from "../../../design";

export interface StatCardProps {
  /** What the number counts, in sentence case ("Total users"). */
  label: string;
  /** Pre-formatted: the card never decides thousands separators or units. */
  value: React.ReactNode;
  /** One line of context under the number — a comparison, a period, a ratio. */
  hint?: React.ReactNode;
  className?: string;
}

/**
 * One number and what it counts. The console's whole Overview is a grid of
 * these, so the type scale lives here rather than at each call site.
 */
const StatCard: React.FC<StatCardProps> = ({ label, value, hint, className = "" }) => (
  <SurfaceCard padding="md" className={className}>
    <div data-testid="stat-card">
      <div className="text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400">
        {label}
      </div>
      <div
        data-testid="stat-value"
        className="mt-1 font-display text-2xl tabular-nums text-ink-900 dark:text-ink-50"
      >
        {value}
      </div>
      {hint ? (
        <div className="mt-1 text-xs text-ink-500 dark:text-ink-400">{hint}</div>
      ) : null}
    </div>
  </SurfaceCard>
);

export default StatCard;
