import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import AnnouncementPage from "./AnnouncementPage";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k, i18n: { language: "en" } }) }));
let mockUser: any = { user: { _id: "u1" } };
jest.mock("react-redux", () => ({ useSelector: (fn: any) => fn({ auth: { userInfo: mockUser } }) }));
const mockQuery = jest.fn();
jest.mock("../../store/slices/announcementsSlice", () => ({ useGetPublicAnnouncementQuery: (...a: any[]) => mockQuery(...a) }));

const Where = () => <div data-testid="where">{useLocation().pathname + useLocation().search}</div>;
const renderPage = () => render(
  <MemoryRouter initialEntries={["/announcement/a1"]}>
    <Routes>
      <Route path="/announcement/:id" element={<AnnouncementPage />} />
      <Route path="*" element={<Where />} />
    </Routes>
  </MemoryRouter>);

beforeEach(() => { mockUser = { user: { _id: "u1" } }; mockQuery.mockReset(); });

test("shows the full announcement, keeping line breaks", () => {
  mockQuery.mockReturnValue({ currentData: { id: "a1", title: "T", body: "L1\nL2", emoji: "🎉", imageUrl: null, buttonLabel: null, buttonUrl: null, priority: 0, displayStyle: "popup" } });
  renderPage();
  expect(screen.getByRole("heading", { name: "T" })).toBeInTheDocument();
  expect(screen.getByTestId("ann-page-body")).toHaveClass("whitespace-pre-line");
  expect(mockQuery).toHaveBeenCalledWith({ id: "a1", lang: "en" }, { skip: false });
});

test("404 shows the ended message", () => {
  mockQuery.mockReturnValue({ error: { status: 404 } });
  renderPage();
  expect(screen.getByText("announcements.ended")).toBeInTheDocument();
});

test("logged out redirects to login and back", () => {
  mockUser = null;
  mockQuery.mockReturnValue({});
  renderPage();
  expect(screen.getByTestId("where")).toHaveTextContent("/login?redirect=%2Fannouncement%2Fa1");
});

const full = (id: string, title: string) => ({ id, title, body: "b", emoji: "🎉", imageUrl: null, buttonLabel: null, buttonUrl: null, priority: 0, displayStyle: "popup" });

test("while fetching another id, A's content is never shown as B", () => {
  mockQuery.mockReturnValue({ currentData: full("a0", "Old A"), isFetching: true });
  renderPage(); // route is /announcement/a1
  expect(screen.queryByText("Old A")).toBeNull();
  expect(screen.queryByText("announcements.ended")).toBeNull();
});

test("data whose id does not match the route is not rendered", () => {
  mockQuery.mockReturnValue({ currentData: full("a0", "Old A"), isFetching: false });
  renderPage();
  expect(screen.queryByText("Old A")).toBeNull();
  expect(screen.getByText("announcements.ended")).toBeInTheDocument();
});

test("Back falls back to home when there is no in-app history", () => {
  mockQuery.mockReturnValue({ error: { status: 404 } });
  window.history.replaceState({ idx: 0 }, "");
  renderPage();
  fireEvent.click(screen.getByRole("button", { name: "announcements.back" }));
  expect(screen.getByTestId("where")).toHaveTextContent("/");
});

test("Back goes back when the router has in-app history", () => {
  mockQuery.mockReturnValue({ error: { status: 404 } });
  window.history.replaceState({ idx: 2 }, "");
  render(
    <MemoryRouter initialEntries={["/prev", "/announcement/a1"]} initialIndex={1}>
      <Routes>
        <Route path="/announcement/:id" element={<AnnouncementPage />} />
        <Route path="*" element={<Where />} />
      </Routes>
    </MemoryRouter>);
  fireEvent.click(screen.getByRole("button", { name: "announcements.back" }));
  expect(screen.getByTestId("where")).toHaveTextContent("/prev");
  window.history.replaceState(null, "");
});
