import React from "react";

export interface LineChartPoint {
  /** A `YYYY-MM-DD` day, or any sortable label. */
  x: string;
  y: number;
}

export interface LineChartSeries {
  name: string;
  /** A brand token hex — see CHART_COLORS. */
  color: string;
  points: LineChartPoint[];
}

export interface LineChartProps {
  series: LineChartSeries[];
  /** Rendered height in px; the width is fluid (the viewBox scales). */
  height?: number;
  emptyText?: string;
  className?: string;
}

/**
 * The console's two reach series, in tokens from tailwind.config.js.
 *
 * Taps use `banana.dark`, not `banana` DEFAULT: #FFD54F is a 1.4:1 stroke on a
 * white card — all but invisible — where #C9A415 is 2.3:1 and sits inside the
 * palette validator's lightness band. The two still separate for every kind of
 * colour vision (OKLab ΔE 14 protanopia, 21 tritanopia, 19 normal), and the
 * pair passes every check in light mode.
 *
 * Neither clears 3:1 against a light surface, so the relief is secondary
 * encoding, which this chart and the Reach page around it both carry: the
 * legend states each series' total, and every number in the chart also exists
 * in a table below it.
 */
export const CHART_COLORS = { pageViews: "#00BFA5", storeTaps: "#C9A415" };

const VIEW_W = 720;
const PAD = { left: 44, right: 14, top: 12, bottom: 26 };
/** A guard, not a feature: a corrupt date range must not build a huge array. */
const MAX_DAYS = 400;

const DAY_RE = /^\d{4}-\d{2}-\d{2}$/;

const nextDay = (day: string): string => {
  const date = new Date(`${day}T00:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() + 1);
  return date.toISOString().slice(0, 10);
};

/**
 * The x axis: the union of every series' dates, with the days in between
 * filled in. The backend's `byDay` is sparse — it returns only the days that
 * had events — so without this a quiet week would draw as a straight line
 * between two far-apart points instead of a line that dips to zero.
 */
export const buildDomain = (series: LineChartSeries[]): string[] => {
  const labels: string[] = [];
  (series || []).forEach((s) => {
    (s?.points || []).forEach((p) => {
      if (p && p.x !== undefined && p.x !== null) labels.push(String(p.x));
    });
  });
  const unique = labels.filter((v, i) => labels.indexOf(v) === i).sort();
  if (unique.length === 0) return [];
  if (!unique.every((v) => DAY_RE.test(v))) return unique;

  const last = unique[unique.length - 1];
  const domain: string[] = [];
  let cursor = unique[0];
  while (cursor <= last && domain.length < MAX_DAYS) {
    domain.push(cursor);
    cursor = nextDay(cursor);
  }
  return domain;
};

const valuesFor = (series: LineChartSeries, domain: string[]): number[] => {
  const byLabel: Record<string, number> = {};
  (series?.points || []).forEach((p) => {
    if (!p || p.x === undefined || p.x === null) return;
    const y = Number(p.y);
    byLabel[String(p.x)] = isFinite(y) ? y : 0;
  });
  return domain.map((label) => byLabel[label] || 0);
};

const round = (n: number): number => Math.round(n * 100) / 100;

const compact = (n: number): string => {
  if (!isFinite(n)) return "0";
  if (Math.abs(n) >= 1000000) return `${round(n / 100000) / 10}M`;
  if (Math.abs(n) >= 1000) return `${round(n / 100) / 10}k`;
  return String(Math.round(n));
};

const shortLabel = (label: string): string => (DAY_RE.test(label) ? label.slice(5) : label);

/**
 * A two-series time chart in plain SVG — no charting library, because the whole
 * need is two paths, three gridlines and a legend, and a library would be a
 * bigger download than the admin chunk itself.
 *
 * Every coordinate is guarded: an empty domain renders the frame and an empty
 * state, a single point sits in the middle of the plot, and an all-zero series
 * uses a max of 1 — none of the three may ever put `NaN` in the markup.
 */
const LineChart: React.FC<LineChartProps> = ({
  series,
  height = 220,
  emptyText = "No data for this period yet.",
  className = "",
}) => {
  const safeSeries = (series || []).filter(Boolean);
  const domain = buildDomain(safeSeries);
  const rows = safeSeries.map((s) => ({ series: s, values: valuesFor(s, domain) }));

  const peak = rows.reduce(
    (max, row) => row.values.reduce((m, v) => (v > m ? v : m), max),
    0
  );
  const maxY = peak > 0 ? peak : 1;

  const plotW = VIEW_W - PAD.left - PAD.right;
  const plotH = Math.max(1, height - PAD.top - PAD.bottom);
  const n = domain.length;

  const xAt = (index: number): number =>
    n <= 1 ? PAD.left + plotW / 2 : PAD.left + (index * plotW) / (n - 1);
  const yAt = (value: number): number =>
    PAD.top + plotH * (1 - (isFinite(value) ? value : 0) / maxY);

  const gridFractions = [1, 0.5, 0];
  const tickIndexes =
    n === 0 ? [] : n === 1 ? [0] : [0, Math.floor((n - 1) / 2), n - 1].filter((v, i, a) => a.indexOf(v) === i);

  const totals = rows.map((row) => row.values.reduce((sum, v) => sum + v, 0));
  const ariaLabel =
    n === 0
      ? emptyText
      : rows
          .map((row, i) => `${row.series.name}: ${totals[i]} over ${n} days`)
          .join("; ");

  return (
    <div className={className} data-testid="line-chart">
      <svg
        data-testid="line-chart-svg"
        role="img"
        aria-label={ariaLabel}
        viewBox={`0 0 ${VIEW_W} ${height}`}
        preserveAspectRatio="none"
        className="w-full"
        style={{ height }}
      >
        {gridFractions.map((fraction) => {
          const y = round(yAt(maxY * fraction));
          return (
            <g key={fraction}>
              <line
                data-testid="line-gridline"
                x1={PAD.left}
                x2={VIEW_W - PAD.right}
                y1={y}
                y2={y}
                stroke="currentColor"
                strokeWidth={1}
                className="text-line dark:text-line-dark"
              />
              <text
                x={PAD.left - 8}
                y={y + 4}
                textAnchor="end"
                fontSize={11}
                fill="currentColor"
                className="fill-current text-ink-500 dark:text-ink-400"
              >
                {compact(maxY * fraction)}
              </text>
            </g>
          );
        })}

        {tickIndexes.map((index) => (
          <text
            key={domain[index]}
            x={round(xAt(index))}
            y={height - 8}
            textAnchor={index === 0 ? "start" : index === n - 1 ? "end" : "middle"}
            fontSize={11}
            fill="currentColor"
            className="fill-current text-ink-500 dark:text-ink-400"
          >
            {shortLabel(domain[index])}
          </text>
        ))}

        {n > 0
          ? rows.map((row) => (
              <path
                key={row.series.name}
                data-testid="line-series"
                d={row.values
                  .map((v, i) => `${i === 0 ? "M" : "L"}${round(xAt(i))} ${round(yAt(v))}`)
                  .join(" ")}
                fill="none"
                stroke={row.series.color}
                strokeWidth={2}
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            ))
          : null}

        {n > 0
          ? rows.map((row) => (
              <circle
                key={`${row.series.name}-end`}
                cx={round(xAt(n - 1))}
                cy={round(yAt(row.values[n - 1] || 0))}
                r={3}
                fill={row.series.color}
              />
            ))
          : null}
      </svg>

      {n === 0 ? (
        <p className="pt-2 text-center text-sm text-ink-500 dark:text-ink-400">{emptyText}</p>
      ) : null}

      <ul
        data-testid="line-legend"
        className="flex flex-wrap items-center gap-x-5 gap-y-1 pt-2 text-xs text-ink-600 dark:text-ink-300"
      >
        {rows.map((row, i) => (
          <li key={row.series.name} className="flex items-center gap-2">
            <span
              aria-hidden="true"
              className="inline-block h-2.5 w-2.5 rounded-full"
              style={{ backgroundColor: row.series.color }}
            />
            <span>{row.series.name}</span>
            <span className="tabular-nums text-ink-900 dark:text-ink-50">
              {totals[i].toLocaleString()}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
};

export default LineChart;
