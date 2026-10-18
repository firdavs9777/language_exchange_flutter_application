import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { mockAppConfig } from "../utils/testing/mockWebFlags";
import FlagRoute from "./FlagRoute";

jest.mock("../store/slices/appConfigSlice", () => require("../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));
jest.mock("../components/errors/NotFound", () => () => <div data-testid="not-found" />);
jest.mock("../components/Loader", () => () => <div data-testid="loader" />);

const page = () => (
  <FlagRoute flag="webGatheringsEnabled">
    <div data-testid="feature" />
  </FlagRoute>
);

it("shows a spinner, not a 404, while app-config loads (deep links)", () => {
  mockAppConfig("loading");
  render(page());
  expect(screen.getByTestId("flag-route-loading")).toBeInTheDocument();
  expect(screen.queryByTestId("not-found")).not.toBeInTheDocument();
  expect(screen.queryByTestId("feature")).not.toBeInTheDocument();
});

it("is a 404 while the flag is off", () => {
  mockAppConfig({ webGatheringsEnabled: false, gatheringsEnabled: true });
  render(page());
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
  expect(screen.queryByTestId("feature")).not.toBeInTheDocument();
});

it("is a 404 when app-config failed", () => {
  mockAppConfig("error");
  render(page());
  expect(screen.getByTestId("not-found")).toBeInTheDocument();
});

it("renders the page when the flag and its global switch are on", () => {
  mockAppConfig({ webGatheringsEnabled: true, gatheringsEnabled: true });
  render(page());
  expect(screen.getByTestId("feature")).toBeInTheDocument();
});
