import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import { MemoryRouter } from "react-router-dom";
import AppBanner from "./AppBanner";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (_key: string, fallback: string) => fallback }),
}));
jest.mock("./OpenInApp", () => (p: any) => (
  <a href="#open" data-testid="open-in-app" data-type={p.type} data-id={p.id}>Open</a>
));

const IPHONE = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)";
const MAC = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)";
const setUserAgent = (ua: string) =>
  Object.defineProperty(window.navigator, "userAgent", { writable: true, configurable: true, value: ua });

const at = (path: string) => (
  <MemoryRouter initialEntries={[path]}>
    <AppBanner />
  </MemoryRouter>
);

it("renders nothing on the server pass, even for a phone on a deep-linkable route", () => {
  setUserAgent(IPHONE);
  expect(renderToString(at("/moment/abc123"))).toBe("");
});

it("shows the banner after mount for a phone on a moment page", () => {
  setUserAgent(IPHONE);
  render(at("/moment/abc123"));
  expect(screen.getByText("Open this in the BananaTalk app")).toBeInTheDocument();
});

it("stays hidden on desktop", () => {
  setUserAgent(MAC);
  render(at("/moment/abc123"));
  expect(screen.queryByText("Open this in the BananaTalk app")).not.toBeInTheDocument();
});

const HEX = "507f1f77bcf86cd799439011";
const openProps = () => {
  const a = screen.getByTestId("open-in-app");
  return { type: a.getAttribute("data-type"), id: a.getAttribute("data-id") };
};

it.each([
  [`/story/${HEX}`, "story", HEX],
  ["/i/ABCD2345", "i", "ABCD2345"],
  [`/card/${HEX}`, "card", HEX],
  [`/community/${HEX}`, "community", HEX],
])("on %s offers the app with type %s", (p, type, id) => {
  setUserAgent(IPHONE);
  render(at(p));
  expect(openProps()).toEqual({ type, id });
});

it("still skips web-only pages that look like an id", () => {
  setUserAgent(IPHONE);
  render(at("/community/nearby"));
  expect(screen.queryByTestId("open-in-app")).not.toBeInTheDocument();
});

it("keeps the Safari smart-banner tag on the current page, even on desktop", () => {
  setUserAgent(MAC);
  document.head.innerHTML = '<meta name="apple-itunes-app" content="app-id=6755862146, app-argument=https://banatalk.com/">';
  render(at(`/moment/${HEX}`));
  expect(document.querySelector('meta[name="apple-itunes-app"]')!.getAttribute("content"))
    .toBe(`app-id=6755862146, app-argument=https://banatalk.com/moment/${HEX}`);
});
