import "@testing-library/jest-dom";
import { render, screen, act, fireEvent } from "@testing-library/react";
import AppDownloadPopup from "./AppDownloadPopup";
import StickyAppBanner from "./StickyAppBanner";
import { APP_STORE_URL, PLAY_STORE_URL, STORE_HOSTS } from "./StoreLink";

const setViewport = (w: number) => {
  Object.defineProperty(window, "innerWidth", { writable: true, configurable: true, value: w });
};

const setUserAgent = (ua: string) => {
  Object.defineProperty(window.navigator, "userAgent", {
    writable: true,
    configurable: true,
    value: ua,
  });
};

beforeEach(() => {
  window.localStorage.clear();
  jest.useFakeTimers();
  setViewport(1280);
  Object.defineProperty(document, "referrer", { writable: true, configurable: true, value: "" });
});
afterEach(() => jest.useRealTimers());

it("stays hidden before either trigger fires", () => {
  render(<AppDownloadPopup />);
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
});

it("appears after the dwell timer", () => {
  render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.getByTestId("download-popup")).toBeInTheDocument();
});

it("appears once the visitor scrolls past the hero", () => {
  render(<AppDownloadPopup />);
  Object.defineProperty(window, "scrollY", { writable: true, configurable: true, value: 900 });
  act(() => { fireEvent.scroll(window); });
  expect(screen.getByTestId("download-popup")).toBeInTheDocument();
});

it("never appears for a visitor who came from an app store", () => {
  Object.defineProperty(document, "referrer", {
    writable: true, configurable: true,
    value: `https://${STORE_HOSTS[0]}/us/app/bananatalk/id6755862146`,
  });
  render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
});

it("stays gone after being dismissed", () => {
  const { unmount } = render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  fireEvent.click(screen.getByTestId("download-popup-dismiss"));
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
  unmount();
  render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
});

// The rule that keeps the two surfaces from stacking on one screen.
it("shows exactly one surface at any viewport", () => {
  setViewport(1280);
  const wide = render(<><AppDownloadPopup /><StickyAppBanner /></>);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.getByTestId("download-popup")).toBeInTheDocument();
  expect(screen.queryByTestId("sticky-app-banner")).not.toBeInTheDocument();
  wide.unmount();

  window.localStorage.clear();
  setViewport(390);
  render(<><AppDownloadPopup /><StickyAppBanner /></>);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
  expect(screen.getByTestId("sticky-app-banner")).toBeInTheDocument();
});

it("closes on Escape and stays gone after being dismissed", () => {
  const { unmount } = render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.getByTestId("download-popup")).toBeInTheDocument();

  fireEvent.keyDown(document, { key: "Escape" });
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();

  unmount();
  render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  expect(screen.queryByTestId("download-popup")).not.toBeInTheDocument();
});

describe("StickyAppBanner store link", () => {
  const originalUserAgent = window.navigator.userAgent;

  afterEach(() => {
    setUserAgent(originalUserAgent);
  });

  it("points at the Play Store for an Android user agent", () => {
    setViewport(390);
    setUserAgent(
      "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Mobile Safari/537.36"
    );
    render(<StickyAppBanner />);
    const href = screen.getByRole("link", { name: /install/i }).getAttribute("href");
    expect(href).toContain(PLAY_STORE_URL);
  });

  it("points at the App Store for an iOS user agent", () => {
    setViewport(390);
    setUserAgent(
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    );
    render(<StickyAppBanner />);
    const href = screen.getByRole("link", { name: /install/i }).getAttribute("href");
    expect(href).toContain(APP_STORE_URL);
  });

  it("tags the install link as the sticky banner", () => {
    setViewport(390);
    render(<StickyAppBanner />);
    const href = screen.getByRole("link", { name: /install/i }).getAttribute("href") || "";
    expect(href).toContain("utm_campaign=sticky-banner");
  });
});

it("offers both stores in the popup, tagged as the popup", () => {
  render(<AppDownloadPopup />);
  act(() => { jest.advanceTimersByTime(20000); });
  const popup = screen.getByTestId("download-popup");
  const links = Array.from(popup.querySelectorAll('[data-testid^="store-link-"]'));
  expect(links).toHaveLength(2);
  links.forEach((a) => expect(a.getAttribute("href")).toContain("utm_campaign=popup"));
});
