import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import VoiceRoomsPage from "./VoiceRoomsPage";

let mockRooms: any = { data: { data: [] }, isLoading: false, isError: false };
const mockArgs: any[] = [];
const mockRsvp = jest.fn();
jest.mock("../../store/slices/voiceRoomsSlice", () => ({
  useGetVoiceRoomsQuery: (arg: any) => {
    mockArgs.push(arg);
    return mockRooms;
  },
  useRsvpVoiceRoomMutation: () => [mockRsvp, { isLoading: false }],
  useCreateVoiceRoomMutation: () => [jest.fn(), { isLoading: false }],
  voiceRoomErrorText: () => "Something went wrong. Try again.",
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const room = (over: any = {}) => ({
  _id: "r1",
  title: "Evening Korean",
  language: "Korean",
  host: { _id: "h1", name: "Mina", images: [] },
  participantCount: 3,
  maxParticipants: 8,
  participants: [],
  status: "active",
  rsvps: [],
  ...over,
});

function renderPage() {
  const store = configureStore({
    reducer: { auth: (s: any = { userInfo: { user: { _id: "me", language_to_learn: "Korean" } } }) => s },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/voice-rooms"]}>
        <Routes>
          <Route path="/voice-rooms" element={<VoiceRoomsPage />} />
          <Route path="/voice-rooms/:id" element={<div data-testid="room-page" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  mockArgs.length = 0;
  mockRsvp.mockReset();
  mockRsvp.mockReturnValue({ unwrap: () => Promise.resolve({}) });
});

it("lists live rooms with host, language and fill, and opens one", () => {
  mockRooms = { data: { data: [room()] }, isLoading: false, isError: false };
  renderPage();
  const card = screen.getByTestId("voice-room-card-r1");
  expect(card).toHaveTextContent("Evening Korean");
  expect(card).toHaveTextContent("Mina");
  expect(card).toHaveTextContent("3/8");
  fireEvent.click(screen.getByTestId("voice-room-join-r1"));
  expect(screen.getByTestId("room-page")).toBeInTheDocument();
});

it("a full room cannot be joined from the list", () => {
  mockRooms = { data: { data: [room({ participantCount: 8 })] }, isLoading: false, isError: false };
  renderPage();
  expect(screen.getByTestId("voice-room-join-r1")).toBeDisabled();
});

it("switches to scheduled rooms and RSVPs", () => {
  mockRooms = { data: { data: [room({ status: "scheduled", scheduledFor: "2030-01-01T10:00:00.000Z" })] }, isLoading: false, isError: false };
  renderPage();
  fireEvent.click(screen.getByTestId("voice-rooms-tab-scheduled"));
  expect(mockArgs[mockArgs.length - 1]).toEqual({ status: "scheduled", page: 1 });
  fireEvent.click(screen.getByTestId("voice-room-rsvp-r1"));
  expect(mockRsvp).toHaveBeenCalledWith({ roomId: "r1", going: true });
});

it("shows RSVP'd rooms as going and lets the member cancel", () => {
  mockRooms = { data: { data: [room({ status: "scheduled", rsvps: [{ user: "me" }] })] }, isLoading: false, isError: false };
  renderPage();
  fireEvent.click(screen.getByTestId("voice-rooms-tab-scheduled"));
  fireEvent.click(screen.getByTestId("voice-room-rsvp-r1"));
  expect(mockRsvp).toHaveBeenCalledWith({ roomId: "r1", going: false });
});

it("has an empty state and a create button", () => {
  mockRooms = { data: { data: [] }, isLoading: false, isError: false };
  renderPage();
  expect(screen.getByTestId("voice-rooms-empty")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("voice-rooms-create"));
  expect(screen.getByTestId("create-voice-room-dialog")).toBeInTheDocument();
});

it("survives an unpopulated host (legacy row)", () => {
  mockRooms = { data: { data: [room({ host: "h1", participants: undefined, participantCount: undefined })] }, isLoading: false, isError: false };
  renderPage();
  expect(screen.getByTestId("voice-room-card-r1")).toHaveTextContent("0/8");
});
