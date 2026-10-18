import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import AnnouncementModal from "./AnnouncementModal";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k }) }));
let mockUser: any = null;
jest.mock("react-redux", () => ({ useSelector: (fn: any) => fn({ auth: { userInfo: mockUser } }) }));

const A = { id: "a1", title: "Video calls are here", body: "Line 1\nLine 2", emoji: "🎉", imageUrl: null,
  buttonLabel: "Try it", buttonUrl: "https://example.com/x", priority: 0, displayStyle: "popup" as const };

const Where = () => <div data-testid="where">{useLocation().pathname + useLocation().search}</div>;
const renderAt = (ui: React.ReactElement) => render(
  <MemoryRouter initialEntries={["/feed"]}><Routes><Route path="*" element={<>{ui}<Where /></>} /></Routes></MemoryRouter>);

beforeEach(() => { mockUser = null; });

test("renders the hero card as an accessible dialog", () => {
  renderAt(<AnnouncementModal announcement={A} onClose={() => {}} />);
  const dialog = screen.getByRole("dialog");
  expect(dialog).toHaveAttribute("aria-modal", "true");
  expect(screen.getByText("Video calls are here")).toBeInTheDocument();
  expect(screen.getByText("announcements.new")).toBeInTheDocument();
  expect(screen.getByTestId("ann-hero-emoji")).toHaveTextContent("🎉");
});

test("preview mode is not a dialog and does not claim modality", () => {
  renderAt(<AnnouncementModal announcement={A} onClose={() => {}} preview />);
  expect(screen.queryByRole("dialog")).toBeNull();
  expect(screen.getByTestId("ann-modal")).not.toHaveAttribute("aria-modal");
  expect(screen.getByRole("group", { name: "Website pop-up preview" })).toBeInTheDocument();
});

test("✕ and Escape close and remember; backdrop closes without remembering", () => {
  const onClose = jest.fn();
  renderAt(<AnnouncementModal announcement={A} onClose={onClose} />);
  fireEvent.click(screen.getByRole("button", { name: "announcements.close" }));
  expect(onClose).toHaveBeenLastCalledWith(true);
  fireEvent.keyDown(window, { key: "Escape" });
  expect(onClose).toHaveBeenLastCalledWith(true);
  fireEvent.click(screen.getByTestId("ann-backdrop"));
  expect(onClose).toHaveBeenLastCalledWith(false);
});

test("logged out: Read more goes to login with redirect back", () => {
  renderAt(<AnnouncementModal announcement={A} onClose={() => {}} />);
  fireEvent.click(screen.getByRole("button", { name: "announcements.readMore" }));
  expect(screen.getByTestId("where")).toHaveTextContent("/login?redirect=%2Fannouncement%2Fa1");
});

test("logged in: external button opens a new tab; Read more opens the page", () => {
  mockUser = { user: { _id: "u1" } };
  const open = jest.spyOn(window, "open").mockImplementation(() => null);
  renderAt(<AnnouncementModal announcement={A} onClose={() => {}} />);
  fireEvent.click(screen.getByRole("button", { name: "Try it" }));
  expect(open).toHaveBeenCalledWith("https://example.com/x", "_blank", "noopener,noreferrer");
  fireEvent.click(screen.getByRole("button", { name: "announcements.readMore" }));
  expect(screen.getByTestId("where")).toHaveTextContent("/announcement/a1");
  open.mockRestore();
});

test("app-only link hides the primary button", () => {
  renderAt(<AnnouncementModal announcement={{ ...A, buttonUrl: "bananatalk://study" }} onClose={() => {}} />);
  expect(screen.queryByRole("button", { name: "Try it" })).toBeNull();
});

test("a broken image falls back to the gradient header with the emoji", () => {
  renderAt(<AnnouncementModal announcement={{ ...A, imageUrl: "https://cdn.example.com/missing.png" }} onClose={() => {}} />);
  fireEvent.error(screen.getByTestId("ann-hero-image"));
  expect(screen.queryByTestId("ann-hero-image")).toBeNull();
  expect(screen.getByTestId("ann-hero-emoji")).toBeInTheDocument();
});

test("preview mode: no navigation, no close side effects", () => {
  const onClose = jest.fn();
  renderAt(<AnnouncementModal announcement={A} onClose={onClose} preview />);
  fireEvent.click(screen.getByRole("button", { name: "announcements.readMore" }));
  expect(screen.getByTestId("where")).toHaveTextContent("/feed");
});

test("Tab from the last button wraps to the close button, and focus returns to the opener", () => {
  const opener = document.createElement("button");
  document.body.appendChild(opener);
  opener.focus();
  const { unmount } = renderAt(<AnnouncementModal announcement={A} onClose={() => {}} />);
  const close = screen.getByRole("button", { name: "announcements.close" });
  expect(close).toHaveFocus();
  const last = screen.getByRole("button", { name: "announcements.readMore" });
  last.focus();
  fireEvent.keyDown(last, { key: "Tab" });
  expect(close).toHaveFocus();
  unmount();
  expect(opener).toHaveFocus();
  opener.remove();
});

test("a new imageUrl replaces the gradient, and a new URL after an error is tried again", () => {
  const { rerender } = renderAt(<AnnouncementModal announcement={A} onClose={() => {}} />);
  expect(screen.queryByTestId("ann-hero-image")).toBeNull();
  const wrap = (a: any) => (
    <MemoryRouter initialEntries={["/feed"]}><Routes><Route path="*" element={<AnnouncementModal announcement={a} onClose={() => {}} />} /></Routes></MemoryRouter>);
  rerender(wrap({ ...A, imageUrl: "https://cdn.example.com/1.png" }));
  expect(screen.getByTestId("ann-hero-image")).toHaveAttribute("src", "https://cdn.example.com/1.png");
  fireEvent.error(screen.getByTestId("ann-hero-image"));
  expect(screen.queryByTestId("ann-hero-image")).toBeNull();
  rerender(wrap({ ...A, imageUrl: "https://cdn.example.com/2.png" }));
  expect(screen.getByTestId("ann-hero-image")).toHaveAttribute("src", "https://cdn.example.com/2.png");
});

test("the live card is height-capped and scrollable so buttons stay reachable", () => {
  renderAt(<AnnouncementModal announcement={A} onClose={() => {}} />);
  expect(screen.getByTestId("ann-modal").className).toMatch(/max-h-\[90dvh\]/);
  expect(screen.getByTestId("ann-modal").className).toMatch(/overflow-y-auto/);
});
