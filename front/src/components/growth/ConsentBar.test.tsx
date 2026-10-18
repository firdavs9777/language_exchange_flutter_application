import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import ConsentBar from "./ConsentBar";
import { openConsentManager, isGaDisabled, setGaDisabled } from "../../analytics/consent";
import { openSurface, _resetSurfacesForTests } from "./surfaceRegistry";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
// An id must be present for the bar to render at all; ConsentBar.noGa.test.tsx covers the empty case.
jest.mock("../../analytics/ga", () => ({ GA_MEASUREMENT_ID: "G-TEST", loadGa: jest.fn(), gaEvent: jest.fn() }));
const { loadGa } = require("../../analytics/ga");

beforeEach(() => {
  window.localStorage.clear();
  _resetSurfacesForTests();
  setGaDisabled(false, "G-TEST");
  document.cookie = "_ga=GA1.1.9.9; path=/";
  (loadGa as jest.Mock).mockClear();
});

it("is absent from server output", () => {
  expect(renderToString(<ConsentBar />)).toBe("");
});

it("shows when undecided and loads GA only on accept", () => {
  render(<ConsentBar />);
  expect(screen.getByTestId("consent-bar")).toBeInTheDocument();
  expect(loadGa).not.toHaveBeenCalled();
  fireEvent.click(screen.getByText("OK"));
  expect(window.localStorage.getItem("bt.consent")).toBe("granted");
  expect(loadGa).toHaveBeenCalledTimes(1);
  expect(screen.queryByTestId("consent-bar")).not.toBeInTheDocument();
});

it("records a refusal and never loads GA", () => {
  render(<ConsentBar />);
  fireEvent.click(screen.getByText("No thanks"));
  expect(window.localStorage.getItem("bt.consent")).toBe("denied");
  expect(loadGa).not.toHaveBeenCalled();
  expect(screen.queryByTestId("consent-bar")).not.toBeInTheDocument();
});

it("stays hidden once decided, and loads GA on return visits when granted", () => {
  window.localStorage.setItem("bt.consent", "granted");
  render(<ConsentBar />);
  expect(screen.queryByTestId("consent-bar")).not.toBeInTheDocument();
  expect(loadGa).toHaveBeenCalledTimes(1);
});

it("shows when storage throws (treated as undecided)", () => {
  const spy = jest.spyOn(Storage.prototype, "getItem").mockImplementation(() => { throw new Error("blocked"); });
  render(<ConsentBar />);
  expect(screen.getByTestId("consent-bar")).toBeInTheDocument();
  spy.mockRestore();
});

it("steps aside while the download popup is open", () => {
  render(<ConsentBar />);
  act(() => openSurface("download-popup"));
  expect(screen.queryByTestId("consent-bar")).not.toBeInTheDocument();
});

describe("manage mode", () => {
  it("opens on demand and names the current choice", () => {
    window.localStorage.setItem("bt.consent", "granted");
    render(<ConsentBar />);
    expect(screen.queryByTestId("consent-manager")).not.toBeInTheDocument();
    act(() => openConsentManager());
    expect(screen.getByTestId("consent-manager")).toBeInTheDocument();
    expect(screen.getByText("Analytics cookies are on.")).toBeInTheDocument();
  });

  it("declining withdraws: denied, ga-disable set, _ga cookies expired", () => {
    window.localStorage.setItem("bt.consent", "granted");
    render(<ConsentBar />);
    act(() => openConsentManager());
    fireEvent.click(screen.getByText("Turn off"));
    expect(window.localStorage.getItem("bt.consent")).toBe("denied");
    expect(isGaDisabled("G-TEST")).toBe(true);
    expect(document.cookie).not.toContain("_ga=");
    expect(screen.getByText("Analytics cookies are off.")).toBeInTheDocument();
  });

  it("re-accepting clears the flag and loads GA again", () => {
    window.localStorage.setItem("bt.consent", "denied");
    render(<ConsentBar />);
    act(() => openConsentManager());
    fireEvent.click(screen.getByText("Turn off"));
    (loadGa as jest.Mock).mockClear();
    fireEvent.click(screen.getByText("Turn on"));
    expect(window.localStorage.getItem("bt.consent")).toBe("granted");
    expect(isGaDisabled("G-TEST")).toBe(false);
    expect(loadGa).toHaveBeenCalledTimes(1);
  });

  it("closes on Done and leaves the undecided bar alone", () => {
    render(<ConsentBar />);
    act(() => openConsentManager());
    expect(screen.queryByTestId("consent-bar")).not.toBeInTheDocument(); // one ask at a time
    fireEvent.click(screen.getByText("Done"));
    expect(screen.queryByTestId("consent-manager")).not.toBeInTheDocument();
    expect(screen.getByTestId("consent-bar")).toBeInTheDocument();
  });

  it("closes on Escape and hands focus back to whatever opened it", () => {
    render(
      <>
        <button data-testid="trigger" onClick={() => openConsentManager()}>open</button>
        <ConsentBar />
      </>
    );
    const trigger = screen.getByTestId("trigger");
    trigger.focus();
    fireEvent.click(trigger);

    const panel = screen.getByTestId("consent-manager");
    expect(panel).toHaveAttribute("role", "dialog");
    expect(panel).toHaveAttribute("aria-modal", "true");
    expect(panel).toHaveFocus(); // not left behind on the footer link

    fireEvent.keyDown(document, { key: "Escape" });
    expect(screen.queryByTestId("consent-manager")).not.toBeInTheDocument();
    expect(trigger).toHaveFocus();
  });

  it("closes on the backdrop too", () => {
    render(<ConsentBar />);
    act(() => openConsentManager());
    fireEvent.click(screen.getByTestId("dialog-shell-backdrop"));
    expect(screen.queryByTestId("consent-manager")).not.toBeInTheDocument();
  });

  it("shows even while the download popup is up: the visitor asked for it", () => {
    window.localStorage.setItem("bt.consent", "denied");
    render(<ConsentBar />);
    act(() => openSurface("download-popup"));
    act(() => openConsentManager());
    expect(screen.getByTestId("consent-manager")).toBeInTheDocument();
  });
});
