import "@testing-library/jest-dom";
import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import { MemoryRouter } from "react-router-dom";
import DownloadApp from "./DownloadApp";
import { APP_STORE_URL, PLAY_STORE_URL } from "../growth/StoreLink";

jest.mock("../../analytics/track", () => ({ trackEvent: jest.fn() }));
jest.mock("../../analytics/ga", () => ({ gaEvent: jest.fn() }));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
// `resetMocks` is on in CRA's Jest config, so the implementation is restored
// per test rather than supplied once by the factory.
jest.mock("qrcode", () => ({ toDataURL: jest.fn() }));

/* eslint-disable @typescript-eslint/no-var-requires */
const QRCode = require("qrcode");

const IPHONE = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15";
const ANDROID = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36";
const DESKTOP = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36";

const realLocation = window.location;
let assign: jest.Mock;

function setUserAgent(ua: string): void {
  Object.defineProperty(window.navigator, "userAgent", { value: ua, configurable: true });
}

beforeEach(() => {
  assign = jest.fn();
  delete (window as any).location;
  (window as any).location = {
    assign,
    href: "https://banatalk.com/download",
    pathname: "/download",
    search: "",
    origin: "https://banatalk.com",
  };
  setUserAgent(DESKTOP);
  (QRCode.toDataURL as jest.Mock).mockResolvedValue("data:image/png;base64,QRCODE");
});

afterAll(() => {
  (window as any).location = realLocation;
});

const renderAt = (entry: string) =>
  render(
    <MemoryRouter initialEntries={[entry]}>
      <DownloadApp />
    </MemoryRouter>
  );

it("leads with one h1 and a subtitle", () => {
  renderAt("/download");
  const h1 = screen.getByRole("heading", { level: 1 });
  expect(h1).toHaveTextContent("Download BananaTalk");
  expect(document.querySelectorAll("h1")).toHaveLength(1);
});

it("offers both store badges, tagged as the download page", () => {
  renderAt("/download");
  const ios = screen.getByTestId("store-link-ios");
  const android = screen.getByTestId("store-link-android");
  expect(ios.getAttribute("href")).toContain(APP_STORE_URL);
  expect(ios.getAttribute("href")).toContain("utm_campaign=download-page");
  expect(android.getAttribute("href")).toContain(PLAY_STORE_URL);
  expect(android.getAttribute("href")).toContain("utm_campaign=download-page");
});

// The prerendered HTML is one order for everyone; the visitor's own store is
// promoted after mount, never during render (a hydration mismatch otherwise).
it("puts the visitor's own store first on Android", async () => {
  setUserAgent(ANDROID);
  renderAt("/download");
  await waitFor(() => {
    const links = document.querySelectorAll("[data-testid^='store-link-']");
    expect(links[0].getAttribute("data-testid")).toBe("store-link-android");
  });
});

it("keeps the App Store first on desktop", async () => {
  renderAt("/download");
  await waitFor(() => {
    const links = document.querySelectorAll("[data-testid^='store-link-']");
    expect(links[0].getAttribute("data-testid")).toBe("store-link-ios");
  });
});

it("reserves the QR box at render and paints the code after mount", async () => {
  renderAt("/download");
  const box = screen.getByTestId("download-qr");
  expect(box).toBeInTheDocument();
  expect(box.querySelector("img")).toBeNull();

  await waitFor(() => expect(box.querySelector("img")).not.toBeNull());
  const img = box.querySelector("img")!;
  expect(img.getAttribute("src")).toBe("data:image/png;base64,QRCODE");
  expect(img.getAttribute("alt")).toBe("QR code to download BananaTalk");
});

// The QR is scanned by a phone, so the URL it carries is the one that hops
// straight to the store.
it("points the QR at the download page with the redirect and source tags", async () => {
  renderAt("/download");
  await waitFor(() => expect(QRCode.toDataURL).toHaveBeenCalled());
  const [target, opts] = (QRCode.toDataURL as jest.Mock).mock.calls[0];
  expect(target).toBe("https://banatalk.com/download?src=qr&go=1");
  expect(opts).toEqual({ margin: 1, width: 192 });
});

it("survives a QR library that fails to load", async () => {
  (QRCode.toDataURL as jest.Mock).mockRejectedValueOnce(new Error("offline"));
  renderAt("/download");
  await waitFor(() => expect(QRCode.toDataURL).toHaveBeenCalled());
  expect(screen.getByTestId("download-qr")).toBeInTheDocument();
  expect(screen.getByRole("heading", { level: 1 })).toBeInTheDocument();
});

// The old page redirected every mobile visitor, which made it unreadable and
// un-indexable. Now the hop is opt-in, carried by the surfaces that link here.
it("does not redirect a mobile visitor who just opened the page", async () => {
  setUserAgent(IPHONE);
  renderAt("/download");
  await waitFor(() => expect(screen.getByTestId("download-qr")).toBeInTheDocument());
  expect(assign).not.toHaveBeenCalled();
});

it("hops to the App Store on an iPhone when go=1", async () => {
  setUserAgent(IPHONE);
  renderAt("/download?go=1");
  await waitFor(() => expect(assign).toHaveBeenCalledTimes(1));
  const url = assign.mock.calls[0][0];
  expect(url).toContain(APP_STORE_URL);
  expect(url).toContain("utm_campaign=download-page");
});

it("hops to Google Play on Android when go=1", async () => {
  setUserAgent(ANDROID);
  renderAt("/download?go=1");
  await waitFor(() => expect(assign).toHaveBeenCalledTimes(1));
  expect(assign.mock.calls[0][0]).toContain(PLAY_STORE_URL);
});

// A desktop has no store to open, so go=1 simply shows the page.
it("shows the page on desktop even with go=1", async () => {
  renderAt("/download?go=1");
  await waitFor(() => expect(screen.getByTestId("download-qr")).toBeInTheDocument());
  expect(assign).not.toHaveBeenCalled();
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Download BananaTalk");
});

it("gives three reasons and the no-card reassurance", () => {
  renderAt("/download");
  expect(screen.getAllByTestId("surface-card")).toHaveLength(3);
  expect(screen.getByTestId("download-free")).toHaveTextContent("Free. No card.");
});

// Every public page is prerendered in Node: nothing may read a browser global
// during render, and the QR box must be in the first paint.
it("renders to a string on the server with the QR box already in place", () => {
  const html = renderToString(
    <MemoryRouter initialEntries={["/download?go=1"]}>
      <DownloadApp />
    </MemoryRouter>
  );
  expect(html).toContain("download-qr");
  expect(html).toContain("Download BananaTalk");
  expect(html).toContain("utm_campaign=download-page");
  expect(html).toContain("Free. No card.");
  expect((html.match(/<h1[\s>]/g) || []).length).toBe(1);
  expect(html).not.toContain("undefined");
});
