import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import SendErrorDialog from "./SendErrorDialog";

const mockNavigate = jest.fn();
jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

function show(kind: string, detail = "") {
  const onClose = jest.fn();
  render(
    <MemoryRouter>
      <SendErrorDialog error={{ kind: kind as any, detail }} onClose={onClose} />
    </MemoryRouter>
  );
  return onClose;
}

it("daily limit offers VIP and goes to the VIP page", () => {
  const onClose = show("dailyLimit");
  expect(screen.getByTestId("send-error-dialog")).toHaveTextContent("Daily message limit reached");
  fireEvent.click(screen.getByTestId("send-error-vip"));
  expect(mockNavigate).toHaveBeenCalledWith("/settings/vip");
  expect(onClose).toHaveBeenCalled();
});

it("conversation cap offers VIP", () => {
  show("conversationCap");
  expect(screen.getByTestId("send-error-vip")).toBeInTheDocument();
});

it("first-chat limit explains the wait and has no VIP button", () => {
  show("firstChatLimit", "You can only send 5 messages until they reply. Please wait for a response.");
  expect(screen.getByTestId("send-error-dialog")).toHaveTextContent("until they reply");
  expect(screen.queryByTestId("send-error-vip")).not.toBeInTheDocument();
});

it("blocked says the person can't be messaged", () => {
  const onClose = show("blocked");
  expect(screen.getByTestId("send-error-dialog")).toHaveTextContent("You can't send messages to this person.");
  fireEvent.click(screen.getByTestId("send-error-close"));
  expect(onClose).toHaveBeenCalled();
});
