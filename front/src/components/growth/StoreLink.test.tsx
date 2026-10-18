import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, createEvent } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import StoreLink, { APP_STORE_URL, PLAY_STORE_URL, storeHref } from "./StoreLink";

jest.mock("../../analytics/track", () => ({ trackEvent: jest.fn() }));
jest.mock("../../analytics/ga", () => ({ gaEvent: jest.fn() }));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

/* eslint-disable @typescript-eslint/no-var-requires */
const { trackEvent } = require("../../analytics/track");
const { gaEvent } = require("../../analytics/ga");

beforeEach(() => {
  (trackEvent as jest.Mock).mockReset();
  (gaEvent as jest.Mock).mockReset();
});

it("points each store at its own URL", () => {
  render(
    <>
      <StoreLink store="ios" placement="hero" />
      <StoreLink store="android" placement="hero" />
    </>
  );
  expect(screen.getByTestId("store-link-ios").getAttribute("href")).toContain(APP_STORE_URL);
  expect(screen.getByTestId("store-link-android").getAttribute("href")).toContain(PLAY_STORE_URL);
});

// The campaign is the whole point of the component: without it every install
// arrives as "direct" and no surface can be told from another.
it("tags every link with the placement as the campaign", () => {
  render(<StoreLink store="ios" placement="final-cta" />);
  const href = screen.getByTestId("store-link-ios").getAttribute("href") || "";
  expect(href).toContain("utm_source=banatalk.com");
  expect(href).toContain("utm_medium=web");
  expect(href).toContain("utm_campaign=final-cta");
});

// The Play URL already carries `?id=`; appending another `?` would make the
// package id unreadable and the link would land on the store's home page.
it("joins the query string with ? or & as the URL requires", () => {
  const ios = storeHref("ios", "hero");
  const android = storeHref("android", "hero");
  expect(ios).toBe(`${APP_STORE_URL}?utm_source=banatalk.com&utm_medium=web&utm_campaign=hero`);
  expect(android).toBe(
    `${PLAY_STORE_URL}&utm_source=banatalk.com&utm_medium=web&utm_campaign=hero`
  );
  expect(android.split("?").length).toBe(2);
});

it("opens the store in a new tab, safely", () => {
  render(<StoreLink store="android" placement="popup" />);
  const a = screen.getByTestId("store-link-android");
  expect(a).toHaveAttribute("target", "_blank");
  expect(a).toHaveAttribute("rel", "noopener noreferrer");
});

it("reports the tap to both trackers with the placement and the platform", () => {
  render(<StoreLink store="android" placement="sticky-banner" />);
  fireEvent.click(screen.getByTestId("store-link-android"));
  expect(trackEvent).toHaveBeenCalledWith("store_tap", {
    placement: "sticky-banner",
    platform: "android",
  });
  expect(gaEvent).toHaveBeenCalledWith("store_tap", {
    placement: "sticky-banner",
    platform: "android",
  });
});

// Measurement must never cost an install: the click keeps navigating even if
// a tracker is unavailable or throws.
it("never blocks the navigation", () => {
  render(<StoreLink store="ios" placement="download-page" />);
  const a = screen.getByTestId("store-link-ios");
  const click = createEvent.click(a);
  fireEvent(a, click);
  expect(click.defaultPrevented).toBe(false);
});

it("still navigates when a tracker throws", () => {
  (trackEvent as jest.Mock).mockImplementation(() => {
    throw new Error("network");
  });
  render(<StoreLink store="ios" placement="footer" />);
  const a = screen.getByTestId("store-link-ios");
  const click = createEvent.click(a);
  expect(() => fireEvent(a, click)).not.toThrow();
  expect(click.defaultPrevented).toBe(false);
});

it("draws the official badge wording for each store", () => {
  render(
    <>
      <StoreLink store="ios" placement="download-page" variant="badge" />
      <StoreLink store="android" placement="download-page" variant="badge" />
    </>
  );
  const ios = screen.getByTestId("store-link-ios");
  expect(ios.textContent).toContain("Download on the");
  expect(ios.textContent).toContain("App Store");
  expect(ios.querySelector("svg")).toBeTruthy();

  const android = screen.getByTestId("store-link-android");
  expect(android.textContent).toContain("Get it on");
  expect(android.textContent).toContain("Google Play");
  expect(android.querySelector("svg")).toBeTruthy();
});

it("names the store on a button and keeps the caller's classes", () => {
  render(
    <StoreLink store="ios" placement="pricing" variant="button" className="rounded-xl bg-brand" />
  );
  const a = screen.getByTestId("store-link-ios");
  expect(a.textContent).toContain("App Store");
  expect(a.className).toContain("rounded-xl");
  expect(a.className).toContain("bg-brand");
});

it("lets a caller supply its own label", () => {
  render(
    <StoreLink store="android" placement="sticky-banner" variant="button">
      Install
    </StoreLink>
  );
  expect(screen.getByRole("link", { name: /install/i })).toBeInTheDocument();
});


// Every public page is prerendered in Node: nothing here may read a browser
// global during render.
it("renders to a string on the server", () => {
  const html = renderToString(
    <>
      <StoreLink store="ios" placement="hero" variant="badge" />
      <StoreLink store="android" placement="hero" variant="button" />
    </>
  );
  expect(html).toContain("store-link-ios");
  expect(html).toContain("utm_campaign=hero");
  expect(html).toContain("App Store");
  expect(html).not.toContain("undefined");
});
