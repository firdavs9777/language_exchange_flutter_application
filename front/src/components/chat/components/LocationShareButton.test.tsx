import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import LocationShareButton from "./LocationShareButton";

const mockSend = jest.fn();
const mockReverse = jest.fn();
const mockNotifyError = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../../store/slices/chatSlice", () => ({
  useSendLocationMessageMutation: () => [mockSend, { isLoading: false }],
}));

jest.mock("../../../store/slices/usersSlice", () => ({
  useLazyReverseGeocodeQuery: () => [mockReverse, {}],
}));

jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { error: (m: string) => mockNotifyError(m), success: jest.fn(), info: jest.fn() },
}));

function installGeolocation(impl: (ok: any, fail: any) => void) {
  (navigator as any).geolocation = { getCurrentPosition: jest.fn(impl) };
}

const position = { coords: { latitude: 37.5665123, longitude: 126.9780456 } };

beforeEach(() => {
  mockSend.mockReturnValue({ unwrap: () => Promise.resolve({ success: true }) });
  mockReverse.mockReturnValue({
    unwrap: () =>
      Promise.resolve({
        data: { city: "Seoul", country: "South Korea", formattedAddress: "Jung-gu, Seoul, South Korea" },
      }),
  });
});

afterEach(() => {
  jest.clearAllMocks();
  delete (navigator as any).geolocation;
});

it("asks before sending, showing the place it found", async () => {
  installGeolocation((ok) => ok(position));
  render(<LocationShareButton receiverId="u2" />);

  fireEvent.click(screen.getByTestId("share-location"));

  expect(await screen.findByText("Share your location?")).toBeInTheDocument();
  expect(screen.getByText("Seoul, South Korea")).toBeInTheDocument();
  expect(mockSend).not.toHaveBeenCalled();
});

it("sends the app's body once confirmed", async () => {
  installGeolocation((ok) => ok(position));
  render(<LocationShareButton receiverId="u2" />);
  fireEvent.click(screen.getByTestId("share-location"));
  fireEvent.click(await screen.findByText("Send"));

  await waitFor(() =>
    expect(mockSend).toHaveBeenCalledWith({
      receiver: "u2",
      latitude: 37.566512,
      longitude: 126.978046,
      placeName: "Seoul, South Korea",
      address: "Jung-gu, Seoul, South Korea",
    })
  );
});

it("still sends the pin when the place lookup fails", async () => {
  installGeolocation((ok) => ok(position));
  mockReverse.mockReturnValue({ unwrap: () => Promise.reject(new Error("nominatim down")) });
  render(<LocationShareButton receiverId="u2" />);
  fireEvent.click(screen.getByTestId("share-location"));
  fireEvent.click(await screen.findByText("Send"));

  await waitFor(() =>
    expect(mockSend).toHaveBeenCalledWith({ receiver: "u2", latitude: 37.566512, longitude: 126.978046 })
  );
});

it("says so when the browser refuses the permission", async () => {
  installGeolocation((_ok, fail) => fail({ code: 1 }));
  render(<LocationShareButton receiverId="u2" />);
  fireEvent.click(screen.getByTestId("share-location"));
  await waitFor(() => expect(mockNotifyError).toHaveBeenCalledWith("Location permission was denied"));
  expect(mockSend).not.toHaveBeenCalled();
});

it("says so when the browser has no geolocation at all", () => {
  render(<LocationShareButton receiverId="u2" />);
  fireEvent.click(screen.getByTestId("share-location"));
  expect(mockNotifyError).toHaveBeenCalledWith("This browser can't share a location");
});

it("keeps the dialog open with the server's reason when the send is refused", async () => {
  installGeolocation((ok) => ok(position));
  mockSend.mockReturnValue({ unwrap: () => Promise.reject({ data: { error: "Cannot send message to blocked user" } }) });
  render(<LocationShareButton receiverId="u2" />);
  fireEvent.click(screen.getByTestId("share-location"));
  fireEvent.click(await screen.findByText("Send"));
  expect(await screen.findByText("Cannot send message to blocked user")).toBeInTheDocument();
});
