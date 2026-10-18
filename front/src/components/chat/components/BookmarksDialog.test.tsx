import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import BookmarksDialog from "./BookmarksDialog";

const mockBookmarks = jest.fn();
const mockUnbookmark = jest.fn();
const mockSuccess = jest.fn();
const mockError = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));
jest.mock("../../../store/slices/chatSlice", () => ({
  useGetBookmarksQuery: (arg: any, opts: any) => mockBookmarks(arg, opts),
  useUnbookmarkMessageMutation: () => [mockUnbookmark, { isLoading: false }],
}));
jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { success: (m: string) => mockSuccess(m), error: (m: string) => mockError(m), info: jest.fn() },
}));

const onClose = jest.fn();

function renderDialog() {
  const store = configureStore({
    reducer: { auth: (state: any = { userInfo: { user: { _id: "me" }, token: "t" } }) => state },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <BookmarksDialog onClose={onClose} />
      </MemoryRouter>
    </Provider>
  );
}

const row = (id: string, sender: any, receiver: any, text: string) => ({
  message: { _id: id, message: text, createdAt: "2026-09-20T10:00:00.000Z", sender, receiver },
  bookmarkedAt: "2026-09-21T10:00:00.000Z",
});

beforeEach(() => {
  mockBookmarks.mockReturnValue({
    data: {
      data: [
        row("m1", { _id: "u2", name: "Ada" }, { _id: "me", name: "Me" }, "The bus leaves at 9"),
        row("m2", { _id: "me", name: "Me" }, { _id: "u3", name: "Bo" }, "My address is 12 Elm St"),
        { message: null, bookmarkedAt: "2026-09-21T10:00:00.000Z" },
      ],
    },
    isLoading: false,
    isError: false,
  });
  mockUnbookmark.mockReturnValue({ unwrap: () => Promise.resolve({ success: true }) });
});
afterEach(() => jest.clearAllMocks());

it("lists saved messages newest first, skipping deleted ones", () => {
  renderDialog();
  const rows = screen.getAllByTestId(/^bookmark-row-/);
  expect(rows.map((r) => r.getAttribute("data-testid"))).toEqual(["bookmark-row-m2", "bookmark-row-m1"]);
});

it("names the other person of each chat and links to it", () => {
  renderDialog();
  expect(screen.getByTestId("bookmark-row-m1")).toHaveTextContent("Ada");
  expect(screen.getByTestId("bookmark-open-m1")).toHaveAttribute("href", "/chat/u2");
  expect(screen.getByTestId("bookmark-row-m2")).toHaveTextContent("Bo");
  expect(screen.getByTestId("bookmark-open-m2")).toHaveAttribute("href", "/chat/u3");
});

it("removes a bookmark", async () => {
  renderDialog();
  fireEvent.click(screen.getByTestId("bookmark-remove-m1"));
  expect(mockUnbookmark).toHaveBeenCalledWith("m1");
  await waitFor(() => expect(mockSuccess).toHaveBeenCalledWith("Removed from saved messages"));
});

it("shows what the server said when removing fails", async () => {
  mockUnbookmark.mockReturnValue({ unwrap: () => Promise.reject({ data: { error: "Bookmark not found" } }) });
  renderDialog();
  fireEvent.click(screen.getByTestId("bookmark-remove-m1"));
  await waitFor(() => expect(mockError).toHaveBeenCalledWith("Bookmark not found"));
});

it("has an empty state", () => {
  mockBookmarks.mockReturnValue({ data: { data: [] }, isLoading: false, isError: false });
  renderDialog();
  expect(screen.getByText("No saved messages yet")).toBeInTheDocument();
});
