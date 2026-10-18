import React from "react";
import { useTranslation } from "react-i18next";

export interface DataTableColumn {
  /** Field read off the row when there is no `render`. */
  key: string;
  header: string;
  /** Full control over the cell: formatting, links, badges. */
  render?: (row: any) => React.ReactNode;
  /** Extra classes for this column's cells (e.g. `text-right tabular-nums`). */
  className?: string;
}

export interface DataTableProps {
  columns: DataTableColumn[];
  rows: any[];
  /** A field name, or a function — anything stable across refetches. */
  rowKey?: string | ((row: any, index: number) => string);
  onRowClick?: (row: any) => void;
  emptyText?: string;
  /** Pagination is opt-in: without `onPageChange` no controls are rendered. */
  page?: number;
  hasMore?: boolean;
  onPageChange?: (page: number) => void;
  /** Accessible name for the table. */
  caption?: string;
  className?: string;
}

const keyFor = (rowKey: DataTableProps["rowKey"], row: any, index: number): string => {
  if (typeof rowKey === "function") return rowKey(row, index);
  if (typeof rowKey === "string") {
    const value = row?.[rowKey];
    if (value !== undefined && value !== null) return String(value);
  }
  return String(index);
};

/**
 * Every table in the console. Deliberately dumb: it does no sorting, no
 * filtering and no fetching — the page owns the data and the query args, so a
 * paginated table and a static one are the same component.
 */
const DataTable: React.FC<DataTableProps> = ({
  columns,
  rows,
  rowKey,
  onRowClick,
  emptyText = "Nothing to show yet.",
  page,
  hasMore,
  onPageChange,
  caption,
  className = "",
}) => {
  const { t } = useTranslation();
  const safeRows = Array.isArray(rows) ? rows : [];
  const currentPage = typeof page === "number" && page > 0 ? page : 1;

  return (
    <div className={className}>
      {/*
        `relative` is load-bearing, not decoration. The cells carry `sr-only`
        labels, and Tailwind's `sr-only` is `position: absolute` — with no
        positioned ancestor their containing block is the INITIAL one, so they
        are laid out against the page rather than against this scroller, and
        `overflow-x: auto` never clips them. A wide table then stretched the
        root's scroll width (804px inside a 390px phone viewport on the moments
        tab, whose Engagement column carries three of them per row), which
        `body { overflow-x: hidden }` then cut off instead of scrolling.
        Positioning this box makes it their containing block, so they are
        clipped and scrolled with the table they belong to.
      */}
      <div className="relative overflow-x-auto">
        <table data-testid="data-table" className="w-full border-collapse text-sm">
          {caption ? <caption className="sr-only">{caption}</caption> : null}
          <thead>
            <tr className="border-b border-line dark:border-line-dark">
              {columns.map((column) => (
                <th
                  key={column.key}
                  scope="col"
                  className={[
                    "whitespace-nowrap px-3 py-2 text-left text-xs font-semibold uppercase",
                    "tracking-wide text-ink-500 dark:text-ink-400",
                    column.className || "",
                  ]
                    .filter(Boolean)
                    .join(" ")}
                >
                  {column.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {safeRows.length === 0 ? (
              <tr>
                <td
                  colSpan={columns.length}
                  className="px-3 py-6 text-center text-sm text-ink-500 dark:text-ink-400"
                >
                  {emptyText}
                </td>
              </tr>
            ) : (
              safeRows.map((row, index) => (
                <tr
                  key={keyFor(rowKey, row, index)}
                  data-testid="data-row"
                  onClick={onRowClick ? () => onRowClick(row) : undefined}
                  onKeyDown={
                    onRowClick
                      ? (e) => {
                          if (e.key === "Enter" || e.key === " ") {
                            e.preventDefault();
                            onRowClick(row);
                          }
                        }
                      : undefined
                  }
                  tabIndex={onRowClick ? 0 : undefined}
                  role={onRowClick ? "button" : undefined}
                  className={[
                    "border-b border-line/70 dark:border-line-dark/70",
                    onRowClick
                      ? "cursor-pointer hover:bg-ink-100 dark:hover:bg-ink-800"
                      : "",
                  ]
                    .filter(Boolean)
                    .join(" ")}
                >
                  {columns.map((column) => (
                    <td
                      key={column.key}
                      className={[
                        "px-3 py-2 align-middle text-ink-800 dark:text-ink-100",
                        column.className || "",
                      ]
                        .filter(Boolean)
                        .join(" ")}
                    >
                      {column.render ? column.render(row) : row?.[column.key]}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {onPageChange ? (
        <div className="flex items-center justify-end gap-3 pt-3 text-sm">
          <span className="text-ink-500 dark:text-ink-400">
            {t("admin.table.page", { page: currentPage }) || `Page ${currentPage}`}
          </span>
          <button
            type="button"
            data-testid="data-table-prev"
            onClick={() => onPageChange(currentPage - 1)}
            disabled={currentPage <= 1}
            className="rounded-chip border border-line px-2.5 py-1 text-ink-700 disabled:cursor-not-allowed disabled:opacity-50 dark:border-line-dark dark:text-ink-200"
          >
            {t("admin.table.previous") || "Previous"}
          </button>
          <button
            type="button"
            data-testid="data-table-next"
            onClick={() => onPageChange(currentPage + 1)}
            disabled={!hasMore}
            className="rounded-chip border border-line px-2.5 py-1 text-ink-700 disabled:cursor-not-allowed disabled:opacity-50 dark:border-line-dark dark:text-ink-200"
          >
            {t("admin.table.next") || "Next"}
          </button>
        </div>
      ) : null}
    </div>
  );
};

export default DataTable;
