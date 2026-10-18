import React from "react";

export interface RefreshButtonProps {
  /** Refetch whatever the page shows. The page decides what that means. */
  onRefresh: () => void;
  /** RTK Query's `isFetching`: true for a background refetch as well as a first load. */
  isFetching?: boolean;
  label?: string;
}

/**
 * Manual refetch for a page whose data has no push channel. Disabled while a
 * fetch is in flight so a moderator cannot queue five refetches by clicking.
 */
const RefreshButton: React.FC<RefreshButtonProps> = ({
  onRefresh,
  isFetching = false,
  label = "Refresh",
}) => (
  <button
    type="button"
    data-testid="refresh-button"
    onClick={onRefresh}
    disabled={isFetching}
    aria-busy={isFetching}
    className={[
      "inline-flex items-center gap-2 rounded-chip border border-line px-3 py-1.5",
      "text-sm font-medium text-ink-700 transition-colors hover:bg-ink-100",
      "disabled:cursor-not-allowed disabled:opacity-60",
      "dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800",
    ].join(" ")}
  >
    {isFetching ? (
      <span
        data-testid="refresh-spinner"
        aria-hidden="true"
        className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-ink-300 border-t-brand-deep"
      />
    ) : null}
    {label}
  </button>
);

export default RefreshButton;
