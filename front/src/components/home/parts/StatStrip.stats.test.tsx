import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import StatStrip from "./StatStrip";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

let mockStatsResult: any = { data: undefined };
jest.mock("../../../store/slices/publicStatsSlice", () => ({
  ...jest.requireActual("../../../store/slices/publicStatsSlice"),
  useGetPublicStatsQuery: () => mockStatsResult,
}));

// Reduced motion makes the count-up instant, so the assertions read final values.
beforeAll(() => {
  Object.defineProperty(window, "matchMedia", {
    writable: true,
    value: () => ({ matches: true, addEventListener() {}, removeEventListener() {} }),
  });
});

it("shows the four curated stats when the count is unavailable", () => {
  mockStatsResult = { data: undefined };
  render(<StatStrip />);
  expect(screen.getAllByTestId("stat-item")).toHaveLength(4);
  expect(screen.queryByText("learners")).not.toBeInTheDocument();
  expect(screen.getByText("Free")).toBeInTheDocument();
});

it("leads with the real learner count when the endpoint has one", () => {
  mockStatsResult = { data: { learners: 12000, countries: 40, languages: 137, generatedAt: "x" } };
  render(<StatStrip />);
  const items = screen.getAllByTestId("stat-item");
  expect(items).toHaveLength(4);
  expect(items[0]).toHaveTextContent("12,000+");
  expect(items[0]).toHaveTextContent("learners");
  expect(screen.queryByText("Free")).not.toBeInTheDocument();
});

it("hides the learner stat when the endpoint returns null (under 1,000)", () => {
  mockStatsResult = { data: { learners: null, countries: 3, languages: 137, generatedAt: "x" } };
  render(<StatStrip />);
  expect(screen.queryByText("learners")).not.toBeInTheDocument();
  expect(screen.getAllByTestId("stat-item")).toHaveLength(4);
});
