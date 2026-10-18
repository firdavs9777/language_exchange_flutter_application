import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import EngagementStats, { isNewMember, responseRateOf } from "./EngagementStats";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const daysAgo = (days: number): string =>
  new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

describe("the fields", () => {
  it("rounds a reply rate and rejects an impossible one", () => {
    expect(responseRateOf({ responseRate: 87.4 })).toBe(87);
    expect(responseRateOf({ responseRate: "92" })).toBe(92);
    expect(responseRateOf({ responseRate: 140 })).toBe(null);
    expect(responseRateOf({})).toBe(null);
  });

  it("calls an account new for the first fortnight only", () => {
    expect(isNewMember({ createdAt: daysAgo(3) })).toBe(true);
    expect(isNewMember({ createdAt: daysAgo(20) })).toBe(false);
    expect(isNewMember({ createdAt: "not a date" })).toBe(false);
    expect(isNewMember({})).toBe(false);
  });
});

describe("the strip", () => {
  it("shows the reply rate when the public projection carries one", () => {
    render(<EngagementStats user={{ responseRate: 90, createdAt: daysAgo(400) }} />);
    expect(screen.getByTestId("engagement-response-rate")).toHaveTextContent("90% replies");
    expect(screen.queryByTestId("engagement-new-member")).not.toBeInTheDocument();
  });

  it("introduces a fresh account as a new member", () => {
    render(<EngagementStats user={{ createdAt: daysAgo(2) }} />);
    expect(screen.getByTestId("engagement-new-member")).toHaveTextContent("New member");
  });

  it("renders nothing when neither field is on the record", () => {
    const { container } = render(<EngagementStats user={{ name: "Ada" }} />);
    expect(container).toBeEmptyDOMElement();
  });
});
