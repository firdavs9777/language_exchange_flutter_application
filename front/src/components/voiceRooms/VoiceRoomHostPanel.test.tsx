import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import VoiceRoomHostPanel from "./VoiceRoomHostPanel";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const members = [
  { userId: "me", name: "Me", role: "host", isMuted: false, isSpeaking: false, handRaised: false },
  { userId: "u2", name: "Ana", role: "listener", isMuted: true, isSpeaking: false, handRaised: true },
  { userId: "u3", name: "Sam", role: "cohost", isMuted: true, isSpeaking: false, handRaised: true },
  { userId: "u4", name: "Lee", role: "listener", isMuted: true, isSpeaking: false, handRaised: false },
];

function renderPanel(props: any = {}) {
  const handlers = { onMuteAll: jest.fn(), onPromote: jest.fn(), onEnd: jest.fn() };
  render(<VoiceRoomHostPanel members={members} myId="me" hostId="me" isHost canEnd {...handlers} {...props} />);
  return handlers;
}

it("lists raised hands, oldest first, and promotes a listener to co-host", () => {
  const h = renderPanel();
  expect(screen.getByTestId("vr-host-hand-u2")).toHaveTextContent("Ana");
  expect(screen.getByTestId("vr-host-hand-u3")).toBeInTheDocument();
  expect(screen.queryByTestId("vr-host-hand-u4")).not.toBeInTheDocument();
  expect(screen.queryByTestId("vr-host-promote-u3")).not.toBeInTheDocument(); // already co-host
  fireEvent.click(screen.getByTestId("vr-host-promote-u2"));
  expect(h.onPromote).toHaveBeenCalledWith("u2");
});

it("mutes everyone", () => {
  const h = renderPanel();
  fireEvent.click(screen.getByTestId("vr-host-mute-all"));
  expect(h.onMuteAll).toHaveBeenCalled();
});

it("asks before ending the room", () => {
  const h = renderPanel();
  fireEvent.click(screen.getByTestId("vr-host-end"));
  expect(h.onEnd).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("vr-host-end-cancel"));
  expect(screen.queryByTestId("vr-host-end-confirm")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("vr-host-end"));
  fireEvent.click(screen.getByTestId("vr-host-end-confirm"));
  expect(h.onEnd).toHaveBeenCalled();
});

it("a co-host may end the room but not mute everyone or promote", () => {
  renderPanel({ isHost: false, canEnd: true, hostId: "u9" });
  expect(screen.getByTestId("vr-host-end")).toBeInTheDocument();
  expect(screen.queryByTestId("vr-host-mute-all")).not.toBeInTheDocument();
  expect(screen.queryByTestId("vr-host-promote-u2")).not.toBeInTheDocument();
});

it("renders nothing for a listener", () => {
  renderPanel({ isHost: false, canEnd: false, hostId: "u9" });
  expect(screen.queryByTestId("vr-host-panel")).not.toBeInTheDocument();
});
