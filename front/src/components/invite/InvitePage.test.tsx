import "@testing-library/jest-dom";
import React from "react";
import fs from "fs";
import path from "path";
import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { HelmetProvider } from "react-helmet-async";
import InvitePage, { parseInviteCode } from "./InvitePage";
import { APP_STORE_URL, PLAY_STORE_URL } from "../growth/storeUrls";

jest.mock("../../analytics/track", () => ({ trackEvent: jest.fn() }));
jest.mock("../../analytics/ga", () => ({ gaEvent: jest.fn() }));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const renderAt = (entry: string) =>
  render(
    <HelmetProvider>
      <MemoryRouter initialEntries={[entry]}>
        <Routes>
          <Route path="/i/:code" element={<InvitePage />} />
        </Routes>
      </MemoryRouter>
    </HelmetProvider>
  );

const setUserAgent = (ua: string) =>
  Object.defineProperty(window.navigator, "userAgent", { value: ua, configurable: true });

const DESKTOP = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36";
const IPHONE = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15";

beforeEach(() => setUserAgent(DESKTOP));

describe("InvitePage", () => {
  it("shows the code uppercased with both store buttons", () => {
    renderAt("/i/abcd2345");
    expect(screen.getByTestId("invite-code")).toHaveTextContent("ABCD2345");
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("You're invited to BananaTalk");
    expect(screen.getByRole("button", { name: "Copy" })).toBeInTheDocument();
    const hrefs = screen.getAllByRole("link").map((a) => a.getAttribute("href") || "");
    expect(hrefs.some((h) => h.startsWith(APP_STORE_URL))).toBe(true);
    expect(hrefs.some((h) => h.startsWith(PLAY_STORE_URL))).toBe(true);
    expect(screen.queryByTestId("invite-open-app")).toBeNull();
  });

  it("renders the generic page without a code for an invalid one", () => {
    renderAt("/i/!!");
    expect(screen.queryByTestId("invite-code")).toBeNull();
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Join BananaTalk");
    expect(screen.getAllByRole("link").length).toBeGreaterThanOrEqual(2);
  });

  it("offers the deep link on mobile only", async () => {
    setUserAgent(IPHONE);
    renderAt("/i/ABCD2345");
    const link = await screen.findByTestId("invite-open-app");
    expect(link).toHaveAttribute("href", "bananatalk://i/ABCD2345");
  });

  it("copies the code", async () => {
    const writeText = jest.fn().mockResolvedValue(undefined);
    Object.defineProperty(window.navigator, "clipboard", { value: { writeText }, configurable: true });
    renderAt("/i/abcd2345");
    screen.getByRole("button", { name: "Copy" }).click();
    await waitFor(() => expect(writeText).toHaveBeenCalledWith("ABCD2345"));
  });
});

describe("parseInviteCode", () => {
  it("accepts base32 4-16 chars and rejects the rest", () => {
    expect(parseInviteCode("abcd")).toBe("ABCD");
    expect(parseInviteCode("abc")).toBeNull();
    expect(parseInviteCode("ABCD1890")).toBeNull();
    expect(parseInviteCode("A".repeat(17))).toBeNull();
    expect(parseInviteCode(undefined)).toBeNull();
  });
});

describe("apple-app-site-association", () => {
  it("claims /i/*", () => {
    const aasa = JSON.parse(
      fs.readFileSync(
        path.resolve(__dirname, "../../../public/.well-known/apple-app-site-association"),
        "utf8"
      )
    );
    const comps = aasa.applinks.details[0].components;
    expect(comps).toContainEqual({ "/": "/i/*" });
  });
});
