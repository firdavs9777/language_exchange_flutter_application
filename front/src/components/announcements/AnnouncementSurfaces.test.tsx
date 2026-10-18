import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, within } from "@testing-library/react";
import { MemoryRouter, useNavigate } from "react-router-dom";
import AnnouncementSurfaces, { _resetPopupForTests } from "./AnnouncementSurfaces";
import { isSurfaceOpen, _resetSurfacesForTests } from "../growth/surfaceRegistry";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k, i18n: { language: "en" } }) }));
jest.mock("react-redux", () => ({ useSelector: (fn: any) => fn({ auth: { userInfo: null } }) }));
const mockHook = jest.fn();
jest.mock("./useWebAnnouncements", () => ({ useWebAnnouncements: () => mockHook() }));

const P = { id: "p1", title: "Pop", body: "b", emoji: "🎉", imageUrl: null, buttonLabel: null, buttonUrl: null, priority: 0, displayStyle: "popup" };
const B = { ...P, id: "b1", title: "Ban", displayStyle: "banner" };

beforeEach(() => { _resetSurfacesForTests(); _resetPopupForTests(); mockHook.mockReset(); });

test("shows the pop-up and the banner, and registers both surfaces", () => {
  const dismiss = jest.fn();
  mockHook.mockReturnValue({ popup: P, banner: B, dismiss });
  render(<MemoryRouter initialEntries={["/feed"]}><AnnouncementSurfaces /></MemoryRouter>);
  expect(screen.getByRole("dialog")).toBeInTheDocument();
  expect(screen.getByTestId("ann-banner")).toBeInTheDocument();
  expect(isSurfaceOpen("announcement-popup")).toBe(true);
  expect(isSurfaceOpen("announcement-banner")).toBe(true);
  // the banner renders first, so pick the close button inside the modal
  fireEvent.click(within(screen.getByTestId("ann-modal")).getByRole("button", { name: "announcements.close" }));
  expect(dismiss).toHaveBeenCalledWith("p1");
});

test("backdrop close hides the pop-up for this page load only", () => {
  const dismiss = jest.fn();
  mockHook.mockReturnValue({ popup: P, banner: null, dismiss });
  render(<MemoryRouter initialEntries={["/feed"]}><AnnouncementSurfaces /></MemoryRouter>);
  fireEvent.click(screen.getByTestId("ann-backdrop"));
  expect(screen.queryByRole("dialog")).toBeNull();
  expect(dismiss).not.toHaveBeenCalled();
});

test("nothing on admin routes", () => {
  mockHook.mockReturnValue({ popup: P, banner: B, dismiss: jest.fn() });
  render(<MemoryRouter initialEntries={["/admin/announcements"]}><AnnouncementSurfaces /></MemoryRouter>);
  expect(screen.queryByRole("dialog")).toBeNull();
  expect(screen.queryByTestId("ann-banner")).toBeNull();
});

test("the pop-up opens only on the first route of the visit", () => {
  mockHook.mockReturnValue({ popup: P, banner: null, dismiss: jest.fn() });
  const { rerender } = render(<MemoryRouter initialEntries={["/feed"]}><AnnouncementSurfaces /></MemoryRouter>);
  fireEvent.click(screen.getByTestId("ann-backdrop"));
  rerender(<MemoryRouter initialEntries={["/chats"]}><AnnouncementSurfaces /></MemoryRouter>);
  expect(screen.queryByRole("dialog")).toBeNull();
});

test("a parent re-render does not move focus out of the modal", () => {
  // a fresh dismiss every render, as an unstable hook would give
  mockHook.mockImplementation(() => ({ popup: P, banner: B, dismiss: jest.fn() }));
  const Wrap = ({ n }: { n: number }) => (
    <MemoryRouter initialEntries={["/feed"]}><span data-n={n} /><AnnouncementSurfaces /></MemoryRouter>
  );
  const { rerender } = render(<Wrap n={0} />);
  const btn = screen.getByTestId("ann-modal").querySelector("button") as HTMLElement;
  btn.focus();
  expect(document.activeElement).toBe(btn);
  rerender(<Wrap n={1} />);
  rerender(<Wrap n={2} />);
  expect(document.activeElement).toBe(btn);
});

test.each(["/login", "/register", "/forgot-password", "/auth/callback", "/verify-email", "/set-new-password"])(
  "no pop-up or banner on auth route %s", (path) => {
    mockHook.mockReturnValue({ popup: P, banner: B, dismiss: jest.fn() });
    render(<MemoryRouter initialEntries={[path]}><AnnouncementSurfaces /></MemoryRouter>);
    expect(screen.queryByRole("dialog")).toBeNull();
    expect(screen.queryByTestId("ann-banner")).toBeNull();
  });

test("an auth route does not use up the once-per-load pop-up", () => {
  mockHook.mockReturnValue({ popup: P, banner: null, dismiss: jest.fn() });
  const Nav = () => { const n = useNavigate(); return <button onClick={() => n("/feed")}>go</button>; };
  render(<MemoryRouter initialEntries={["/login"]}><Nav /><AnnouncementSurfaces /></MemoryRouter>);
  expect(screen.queryByRole("dialog")).toBeNull();
  fireEvent.click(screen.getByText("go"));
  expect(screen.getByRole("dialog")).toBeInTheDocument();
});

test("no pop-up over /announcement/<same id>, but one over another announcement", () => {
  mockHook.mockReturnValue({ popup: P, banner: null, dismiss: jest.fn() });
  const { unmount } = render(<MemoryRouter initialEntries={["/announcement/p1"]}><AnnouncementSurfaces /></MemoryRouter>);
  expect(screen.queryByRole("dialog")).toBeNull();
  unmount();
  render(<MemoryRouter initialEntries={["/announcement/other"]}><AnnouncementSurfaces /></MemoryRouter>);
  expect(screen.getByRole("dialog")).toBeInTheDocument();
});
