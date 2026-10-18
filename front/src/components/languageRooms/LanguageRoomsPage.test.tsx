import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import LanguageRoomsPage from "./LanguageRoomsPage";

let mockRooms: any = { data: [], isLoading: false, isError: false };
const mockCreate = jest.fn();
jest.mock("../../store/slices/languageRoomsSlice", () => {
  const actual = jest.requireActual("../../store/slices/languageRoomsSlice");
  return {
    groupRoomsByLanguage: actual.groupRoomsByLanguage,
    languageRoomErrorText: actual.languageRoomErrorText,
    useGetLanguageRoomsQuery: () => mockRooms,
    useCreateTopicRoomMutation: () => [mockCreate, { isLoading: false }],
  };
});
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

function renderPage() {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me", language_to_learn: "Korean" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/rooms"]}>
        <Routes>
          <Route path="/rooms" element={<LanguageRoomsPage />} />
          <Route path="/rooms/:id" element={<div data-testid="room-page" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => mockCreate.mockReset());

it("shows each language with its hub and topic rooms, member and online counts", () => {
  mockRooms = {
    data: {
      data: [
        { _id: "h-ko", roomType: "hub", targetLanguage: "ko", title: "Korean", emojiFlag: "🇰🇷", memberCount: 240, onlineCount: 12, isMember: true },
        { _id: "t2", roomType: "topic", targetLanguage: "ko", title: "K-drama", memberCount: 9, onlineCount: 1, isMember: false },
      ],
    },
    isLoading: false,
    isError: false,
  };
  renderPage();
  const group = screen.getByTestId("language-rooms-group-ko");
  expect(group).toHaveTextContent("Korean");
  expect(screen.getByTestId("language-room-card-h-ko")).toHaveTextContent("240");
  expect(screen.getByTestId("language-room-card-h-ko")).toHaveTextContent("12");
  fireEvent.click(screen.getByTestId("language-room-card-t2"));
  expect(screen.getByTestId("room-page")).toBeInTheDocument();
});

it("creates a topic room and opens it", async () => {
  mockRooms = { data: { data: [] }, isLoading: false, isError: false };
  mockCreate.mockReturnValue({ unwrap: () => Promise.resolve({ data: { _id: "new1" } }) });
  renderPage();
  fireEvent.click(screen.getByTestId("language-rooms-create"));
  fireEvent.change(screen.getByTestId("create-topic-room-title"), { target: { value: "Travel" } });
  fireEvent.change(screen.getByTestId("create-topic-room-language"), { target: { value: "es" } });
  fireEvent.click(screen.getByTestId("create-topic-room-submit"));
  await waitFor(() => expect(screen.getByTestId("room-page")).toBeInTheDocument());
  expect(mockCreate).toHaveBeenCalledWith({ title: "Travel", targetLanguage: "es", description: "" });
});

it("keeps the dialog open with the reason on a refusal", async () => {
  mockRooms = { data: { data: [] }, isLoading: false, isError: false };
  mockCreate.mockReturnValue({ unwrap: () => Promise.reject({ status: 400, data: { error: "You can only own up to 10 topic rooms" } }) });
  renderPage();
  fireEvent.click(screen.getByTestId("language-rooms-create"));
  fireEvent.change(screen.getByTestId("create-topic-room-title"), { target: { value: "Travel" } });
  fireEvent.click(screen.getByTestId("create-topic-room-submit"));
  await waitFor(() => expect(screen.getByTestId("create-topic-room-error")).toHaveTextContent("10 rooms"));
});

it("names each language by its code, puts hub languages first, shows recent activity and refreshes", () => {
  const refetch = jest.fn();
  mockRooms = {
    data: {
      data: [
        { _id: "t-uz", roomType: "topic", targetLanguage: "uz", title: "Chat", lastActivityAt: new Date(Date.now() - 5 * 60000).toISOString() },
        { _id: "h-es", roomType: "hub", targetLanguage: "es", title: "Spanish hub" },
      ],
    },
    isLoading: false,
    isError: false,
    refetch,
  };
  renderPage();
  const headings = screen.getAllByRole("heading", { level: 2 }).map((h) => h.textContent);
  expect(headings[0]).toContain("Spanish");
  expect(headings[1]).toContain("Uzbek");
  expect(screen.getByTestId("language-room-active-t-uz")).toHaveTextContent("Active 5m ago");
  fireEvent.click(screen.getByTestId("language-rooms-refresh"));
  expect(refetch).toHaveBeenCalled();
});

it("the language picker lists every language and starts on the one you learn", () => {
  mockRooms = { data: { data: [] }, isLoading: false, isError: false };
  renderPage();
  fireEvent.click(screen.getByTestId("language-rooms-create"));
  const select = screen.getByTestId("create-topic-room-language") as HTMLSelectElement;
  expect(select.value).toBe("ko");
  expect(select.options.length).toBeGreaterThan(150);
});
