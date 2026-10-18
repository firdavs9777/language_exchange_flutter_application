import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import CallInAppButtons from "./CallInAppButtons";
import { openInApp } from "../../linking/openInAppAction";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../linking/openInAppAction", () => ({
  openInApp: jest.fn(),
}));

beforeEach(() => (openInApp as jest.Mock).mockClear());

it("shows voice and video buttons in a 1:1 chat", () => {
  render(<CallInAppButtons partnerId="u2" partnerName="Ada" />);
  expect(screen.getByTestId("chat-header-voice-call")).toBeInTheDocument();
  expect(screen.getByTestId("chat-header-video-call")).toBeInTheDocument();
});

it("hides the buttons in a group chat", () => {
  render(<CallInAppButtons partnerId="u2" partnerName="Ada" isGroup />);
  expect(screen.queryByTestId("chat-header-voice-call")).not.toBeInTheDocument();
  expect(screen.queryByTestId("chat-header-video-call")).not.toBeInTheDocument();
});

it("hides the buttons when the chat is blocked", () => {
  render(<CallInAppButtons partnerId="u2" partnerName="Ada" blocked />);
  expect(screen.queryByTestId("chat-header-voice-call")).not.toBeInTheDocument();
  expect(screen.queryByTestId("chat-header-video-call")).not.toBeInTheDocument();
});

it("hides the buttons without a partner", () => {
  render(<CallInAppButtons partnerId="" partnerName="Ada" />);
  expect(screen.queryByTestId("chat-header-voice-call")).not.toBeInTheDocument();
});

it.each(["voice", "video"])("%s opens the dialog with the partner's name", (kind) => {
  render(<CallInAppButtons partnerId="u2" partnerName="Ada" />);
  expect(screen.queryByTestId("call-in-app-dialog")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId(`chat-header-${kind}-call`));
  expect(screen.getByTestId("call-in-app-dialog")).toBeInTheDocument();
  expect(screen.getByText("Calls happen in the BananaTalk app")).toBeInTheDocument();
  expect(
    screen.getByText("Open the app to call Ada. Incoming calls ring on your phone.")
  ).toBeInTheDocument();
});

it("Open the app hands the partner's profile to the open-in-app helper", () => {
  render(<CallInAppButtons partnerId="u2" partnerName="Ada" />);
  fireEvent.click(screen.getByTestId("chat-header-video-call"));
  fireEvent.click(screen.getByTestId("call-in-app-open"));
  expect(openInApp).toHaveBeenCalledTimes(1);
  expect((openInApp as jest.Mock).mock.calls[0][0]).toEqual(
    expect.objectContaining({ type: "profile", id: "u2" })
  );
  expect(screen.queryByTestId("call-in-app-dialog")).not.toBeInTheDocument();
});

it("Not now closes the dialog without opening the app", () => {
  render(<CallInAppButtons partnerId="u2" partnerName="Ada" />);
  fireEvent.click(screen.getByTestId("chat-header-voice-call"));
  fireEvent.click(screen.getByTestId("call-in-app-dismiss"));
  expect(screen.queryByTestId("call-in-app-dialog")).not.toBeInTheDocument();
  expect(openInApp).not.toHaveBeenCalled();
});
