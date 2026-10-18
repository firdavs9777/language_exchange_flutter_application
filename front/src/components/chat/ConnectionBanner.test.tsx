import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import ConnectionBanner from "./ConnectionBanner";

const mockUseSocket = jest.fn();
jest.mock("./hooks/useSocket", () => ({ useSocket: () => mockUseSocket() }));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

it("renders nothing while connected and not kicked", () => {
  mockUseSocket.mockReturnValue({ kicked: false, reconnect: jest.fn() });
  const { container } = render(<ConnectionBanner />);
  expect(container).toBeEmptyDOMElement();
});

it("offers to reconnect a kicked tab", () => {
  const reconnect = jest.fn();
  mockUseSocket.mockReturnValue({ kicked: true, reconnect });
  render(<ConnectionBanner />);
  expect(screen.getByTestId("connection-banner")).toHaveTextContent("Chat is open somewhere else");
  fireEvent.click(screen.getByTestId("connection-banner-reconnect"));
  expect(reconnect).toHaveBeenCalled();
});
