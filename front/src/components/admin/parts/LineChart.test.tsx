import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import LineChart, { CHART_COLORS } from "./LineChart";

const teal = "#00BFA5";
const banana = "#FFD54F";

it("draws one path per series", () => {
  render(
    <LineChart
      series={[
        { name: "Page views", color: teal, points: [{ x: "2026-09-01", y: 5 }, { x: "2026-09-02", y: 9 }] },
        { name: "Store taps", color: banana, points: [{ x: "2026-09-01", y: 1 }, { x: "2026-09-02", y: 4 }] },
      ]}
    />
  );
  expect(screen.getAllByTestId("line-series")).toHaveLength(2);
});

it("names every series in the legend and in the accessible label", () => {
  render(
    <LineChart
      series={[
        { name: "Page views", color: teal, points: [{ x: "2026-09-01", y: 5 }] },
        { name: "Store taps", color: banana, points: [{ x: "2026-09-01", y: 1 }] },
      ]}
    />
  );
  expect(screen.getByTestId("line-legend")).toHaveTextContent("Page views");
  expect(screen.getByTestId("line-legend")).toHaveTextContent("Store taps");
  const label = screen.getByTestId("line-chart-svg").getAttribute("aria-label") || "";
  expect(label).toContain("Page views");
  expect(label).toContain("Store taps");
});

it("fills the days a sparse series never reported so the line stays contiguous", () => {
  render(
    <LineChart
      series={[
        {
          name: "Page views",
          color: teal,
          // The backend only returns days that had events: Sep 2 and Sep 3 are missing.
          points: [{ x: "2026-09-01", y: 5 }, { x: "2026-09-04", y: 7 }],
        },
      ]}
    />
  );
  const d = screen.getByTestId("line-series").getAttribute("d") || "";
  // Four days in the domain => one move plus three line segments.
  expect((d.match(/L/g) || []).length).toBe(3);
  expect(d.indexOf("M")).toBe(0);
});

it("unions the dates of every series", () => {
  render(
    <LineChart
      series={[
        { name: "Page views", color: teal, points: [{ x: "2026-09-01", y: 5 }] },
        { name: "Store taps", color: banana, points: [{ x: "2026-09-03", y: 2 }] },
      ]}
    />
  );
  screen.getAllByTestId("line-series").forEach((p) => {
    expect((p.getAttribute("d") || "").match(/L/g) || []).toHaveLength(2);
  });
});

it("renders three gridlines", () => {
  render(
    <LineChart series={[{ name: "Page views", color: teal, points: [{ x: "2026-09-01", y: 5 }] }]} />
  );
  expect(screen.getAllByTestId("line-gridline")).toHaveLength(3);
});

it("emits no NaN for an empty series list", () => {
  const { container } = render(<LineChart series={[]} />);
  expect(container.innerHTML).not.toContain("NaN");
  expect(screen.queryByTestId("line-series")).not.toBeInTheDocument();
});

it("emits no NaN when every series is empty", () => {
  const { container } = render(
    <LineChart
      series={[
        { name: "Page views", color: teal, points: [] },
        { name: "Store taps", color: banana, points: [] },
      ]}
    />
  );
  expect(container.innerHTML).not.toContain("NaN");
});

it("emits no NaN for a single point or for all-zero data", () => {
  const one = render(
    <LineChart series={[{ name: "Page views", color: teal, points: [{ x: "2026-09-01", y: 0 }] }]} />
  );
  expect(one.container.innerHTML).not.toContain("NaN");
  const zeros = render(
    <LineChart
      series={[
        { name: "Page views", color: teal, points: [{ x: "2026-09-01", y: 0 }, { x: "2026-09-02", y: 0 }] },
      ]}
    />
  );
  expect(zeros.container.innerHTML).not.toContain("NaN");
});

it("strokes each series with the colour it was given", () => {
  render(
    <LineChart
      series={[
        { name: "Page views", color: teal, points: [{ x: "2026-09-01", y: 5 }, { x: "2026-09-02", y: 6 }] },
        { name: "Store taps", color: banana, points: [{ x: "2026-09-01", y: 1 }, { x: "2026-09-02", y: 2 }] },
      ]}
    />
  );
  const strokes = screen.getAllByTestId("line-series").map((p) => p.getAttribute("stroke"));
  expect(strokes).toEqual([teal, banana]);
});

it("uses brand tokens that stay readable on a light surface", () => {
  // Teal is the brand; taps use banana.dark rather than banana DEFAULT --
  // #FFD54F is a 1.4:1 stroke on a white card, #C9A415 is 2.3:1 and clears
  // the palette validator's lightness band in light mode.
  expect(CHART_COLORS.pageViews).toBe("#00BFA5");
  expect(CHART_COLORS.storeTaps).toBe("#C9A415");
});
