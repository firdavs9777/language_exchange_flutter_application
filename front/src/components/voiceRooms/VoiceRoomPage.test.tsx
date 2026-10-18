import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import VoiceRoomPage from "./VoiceRoomPage";

const mockActions = {
  join: jest.fn(),
  leave: jest.fn(),
  setMic: jest.fn(),
  raiseHand: jest.fn(),
  sendChat: jest.fn(),
  startAudio: jest.fn(),
  muteAll: jest.fn(),
  promote: jest.fn(),
  endRoom: jest.fn(),
};
let mockState: any = {};
jest.mock("./useVoiceRoom", () => ({ useVoiceRoom: () => Object.assign({}, mockState, mockActions) }));
jest.mock("../../store/slices/voiceRoomsSlice", () => ({
  useGetVoiceRoomQuery: () => ({ data: { _id: "r1", title: "Evening Korean", language: "Korean" } }),
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const base = {
  phase: "live",
  error: "",
  role: "participant",
  hostId: "h1",
  members: [
    { userId: "h1", name: "Mina", role: "host", isMuted: false, isSpeaking: true, handRaised: false },
    { userId: "me", name: "Me", role: "listener", isMuted: true, isSpeaking: false, handRaised: false },
  ],
  micOn: false,
  micProblem: null,
  handRaised: false,
  audioBlocked: false,
  chat: [],
};

function renderPage(state: any = {}) {
  mockState = Object.assign({}, base, state);
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/voice-rooms/r1"]}>
        <Routes>
          <Route path="/voice-rooms/:id" element={<VoiceRoomPage />} />
          <Route path="/voice-rooms" element={<div data-testid="list" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => Object.keys(mockActions).forEach((k) => (mockActions as any)[k].mockReset()));

it("does not join on its own; Join is a click", () => {
  renderPage({ phase: "idle" });
  expect(mockActions.join).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("voice-room-join"));
  expect(mockActions.join).toHaveBeenCalled();
});

it("shows members with the speaker ring and mic state", () => {
  renderPage();
  expect(screen.getByTestId("voice-room-member-h1")).toHaveClass("is-speaking");
  expect(screen.getByTestId("voice-room-member-me")).toHaveClass("is-muted");
  expect(screen.getByText("Evening Korean")).toBeInTheDocument();
});

it("takes the mic, and raises a hand only while muted", () => {
  const { unmount } = renderPage();
  fireEvent.click(screen.getByTestId("voice-room-hand"));
  expect(mockActions.raiseHand).toHaveBeenCalledWith(true);
  fireEvent.click(screen.getByTestId("voice-room-mic"));
  expect(mockActions.setMic).toHaveBeenCalledWith(true);
  unmount();
  renderPage({ micOn: true });
  expect(screen.queryByTestId("voice-room-hand")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("voice-room-mic"));
  expect(mockActions.setMic).toHaveBeenCalledWith(false);
});

it("offers 'tap to enable sound' when the browser blocked audio", () => {
  renderPage({ audioBlocked: true });
  fireEvent.click(screen.getByTestId("voice-room-enable-sound"));
  expect(mockActions.startAudio).toHaveBeenCalled();
});

it.each([
  ["denied", /allow the microphone/i],
  ["unavailable", /no microphone/i],
])("explains a %s mic and keeps the room playing", (problem, text) => {
  renderPage({ micProblem: problem });
  expect(screen.getByTestId("voice-room-mic-problem")).toHaveTextContent(text);
  expect(screen.getByTestId("voice-room-leave")).toBeInTheDocument();
});

it("shows reconnecting, ended, elsewhere, lost and error states", () => {
  const { unmount } = renderPage({ phase: "reconnecting" });
  expect(screen.getByTestId("voice-room-reconnecting")).toBeInTheDocument();
  unmount();
  const a = renderPage({ phase: "ended" });
  expect(screen.getByTestId("voice-room-ended")).toBeInTheDocument();
  a.unmount();
  const b = renderPage({ phase: "elsewhere" });
  fireEvent.click(screen.getByTestId("voice-room-use-here"));
  expect(mockActions.join).toHaveBeenCalled();
  b.unmount();
  const c = renderPage({ phase: "lost" });
  fireEvent.click(screen.getByTestId("voice-room-rejoin"));
  expect(mockActions.join).toHaveBeenCalledTimes(2);
  c.unmount();
  renderPage({ phase: "error", error: "This room is full." });
  expect(screen.getByTestId("voice-room-error")).toHaveTextContent("This room is full.");
});

it("leaving goes back to the list", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("voice-room-leave"));
  expect(mockActions.leave).toHaveBeenCalled();
  expect(screen.getByTestId("list")).toBeInTheDocument();
});

it("chats", () => {
  renderPage({ chat: [{ id: "c1", userId: "h1", name: "Mina", message: "안녕!", at: "2026-10-16T10:00:00Z" }] });
  expect(screen.getByTestId("voice-room-chat-line")).toHaveTextContent("안녕!");
  fireEvent.change(screen.getByTestId("voice-room-chat-input"), { target: { value: "hi" } });
  fireEvent.click(screen.getByTestId("voice-room-chat-send"));
  expect(mockActions.sendChat).toHaveBeenCalledWith("hi");
  expect((screen.getByTestId("voice-room-chat-input") as HTMLInputElement).value).toBe("");
});

it("shows the host panel to the host and wires its mockActions", () => {
  renderPage({ role: "host", hostId: "me", members: base.members.map((m: any) => (m.userId === "me" ? Object.assign({}, m, { role: "host" }) : m)) });
  expect(screen.getByTestId("vr-host-panel")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("vr-host-mute-all"));
  expect(mockActions.muteAll).toHaveBeenCalled();
});

it("hides the host panel from a listener", () => {
  renderPage();
  expect(screen.queryByTestId("vr-host-panel")).not.toBeInTheDocument();
});
