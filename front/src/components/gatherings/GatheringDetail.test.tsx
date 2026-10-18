import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import GatheringDetail from "./GatheringDetail";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockSuccess = jest.fn();
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: (m: any) => mockSuccess(m), error: (m: any) => mockError(m) },
}));

let mockQuery: any;
const mockRsvp = jest.fn();
const mockLeave = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useGetGatheringQuery: () => mockQuery,
  useRsvpGatheringMutation: () => [mockRsvp, { isLoading: false }],
  useCancelRsvpMutation: () => [mockLeave, { isLoading: false }],
}));
jest.mock("./GatheringSafetyMenu", () => () => <div data-testid="safety-menu" />);
jest.mock("./GatheringHostPanel", () => () => <div data-testid="host-panel" />);

const gathering = (extra: any = {}) => ({
  _id: "g1",
  title: "Korean coffee chat",
  description: "Bring a topic",
  language: "korean",
  languageLabel: "Korean",
  level: "B1",
  topic: "conversation",
  startsAt: "2030-11-01T10:00:00.000Z",
  durationMinutes: 60,
  hostTimezone: "Asia/Seoul",
  capacity: 6,
  quorum: 3,
  joinMode: "open",
  status: "scheduled",
  going: 1,
  needed: 2,
  quorumMet: false,
  viewerIsAttending: false,
  viewerIsHost: false,
  host: { _id: "h1", name: "Hana", images: [] },
  ...extra,
});

function renderDetail() {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/gatherings/g1"]}>
        <Routes>
          <Route path="/gatherings/:id" element={<GatheringDetail />} />
          <Route path="/gatherings" element={<div data-testid="list-page" />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}
const ok = (data: any) => ({ data, isLoading: false, isError: false, error: undefined, refetch: jest.fn() });

beforeEach(() => {
  mockRsvp.mockReset();
  mockLeave.mockReset();
  mockSuccess.mockReset();
  mockError.mockReset();
  mockQuery = ok(gathering());
});

it("shows the gathering with its time, the host's local time, quorum and host", () => {
  // Pin the viewer to UTC so the Seoul host's time always differs, whatever
  // zone the test machine runs in.
  const zone = jest
    .spyOn(Intl.DateTimeFormat.prototype, "resolvedOptions")
    .mockReturnValue({ timeZone: "UTC" } as any);
  renderDetail();
  expect(screen.getByTestId("gathering-detail")).toHaveTextContent("Korean coffee chat");
  expect(screen.getByTestId("gathering-time")).not.toBeEmptyDOMElement();
  expect(screen.getByTestId("gathering-host-time")).toHaveTextContent("for the host");
  expect(screen.getByTestId("gathering-quorum")).toHaveTextContent("2 more needed to confirm · 1 going");
  expect(screen.getByTestId("gathering-host-link")).toHaveAttribute("href", "/profile/h1");
  expect(screen.getByTestId("safety-menu")).toBeInTheDocument();
  zone.mockRestore();
});

it("RSVPs in open mode and confirms it", async () => {
  mockRsvp.mockReturnValue({ unwrap: () => Promise.resolve({ ...gathering(), viewerIsAttending: true, pending: false }) });
  renderDetail();
  fireEvent.click(screen.getByTestId("gathering-rsvp"));
  await waitFor(() => expect(mockRsvp).toHaveBeenCalledWith("g1"));
  await waitFor(() => expect(mockSuccess).toHaveBeenCalledWith("You're going."));
});

it("sends a request in approval mode and says it is waiting", async () => {
  mockQuery = ok(gathering({ joinMode: "approval" }));
  mockRsvp.mockReturnValue({ unwrap: () => Promise.resolve({ ...gathering(), pending: true }) });
  renderDetail();
  expect(screen.getByTestId("gathering-rsvp")).toHaveTextContent("Ask to join");
  fireEvent.click(screen.getByTestId("gathering-rsvp"));
  await waitFor(() => expect(mockSuccess).toHaveBeenCalledWith("Request sent. The host will decide."));
});

it("leaves after confirming", async () => {
  mockQuery = ok(gathering({ viewerIsAttending: true, going: 2, needed: 1 }));
  mockLeave.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  renderDetail();
  fireEvent.click(screen.getByTestId("gathering-leave"));
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockLeave).toHaveBeenCalledWith("g1"));
});

it("cancels a pending request with the same call", async () => {
  mockQuery = ok(gathering({ joinMode: "approval", viewerRequestPending: true }));
  mockLeave.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  renderDetail();
  fireEvent.click(screen.getByTestId("gathering-cancel-request"));
  await waitFor(() => expect(mockLeave).toHaveBeenCalledWith("g1"));
});

it("shows Full and Closed instead of a button", () => {
  mockQuery = ok(gathering({ going: 6, needed: 0, quorumMet: true }));
  const { unmount } = renderDetail();
  expect(screen.getByTestId("gathering-full")).toBeInTheDocument();
  expect(screen.queryByTestId("gathering-rsvp")).not.toBeInTheDocument();
  unmount();
  mockQuery = ok(gathering({ status: "cancelled" }));
  renderDetail();
  expect(screen.getByTestId("gathering-closed")).toHaveTextContent("Cancelled");
});

it("never offers Leave to the host; shows Edit instead", () => {
  mockQuery = ok(gathering({ viewerIsHost: true, viewerIsAttending: true }));
  renderDetail();
  expect(screen.queryByTestId("gathering-leave")).not.toBeInTheDocument();
  expect(screen.getByTestId("gathering-edit-link")).toHaveAttribute("href", "/gatherings/g1/edit");
});

it("maps a refusal to friendly text", async () => {
  mockRsvp.mockReturnValue({ unwrap: () => Promise.reject({ status: 400, data: { error: "This gathering is full" } }) });
  renderDetail();
  fireEvent.click(screen.getByTestId("gathering-rsvp"));
  await waitFor(() => expect(mockError).toHaveBeenCalledWith("This gathering is full."));
});

it("a missing or blocked gathering is 'not available', not a crash", () => {
  mockQuery = { data: undefined, isLoading: false, isError: true, error: { status: 404, data: { error: "Gathering not found" } }, refetch: jest.fn() };
  renderDetail();
  expect(screen.getByTestId("gathering-unavailable")).toHaveTextContent("This gathering isn't available.");
});

it("tolerates a legacy payload with an unpopulated host and no topic/level", () => {
  mockQuery = ok(gathering({ host: "h1", topic: null, level: null, hostTimezone: null, quorumMet: undefined }));
  renderDetail();
  expect(screen.getByTestId("gathering-detail")).toBeInTheDocument();
  expect(screen.queryByTestId("gathering-host-time")).not.toBeInTheDocument();
});

it("shows the host panel to the host", () => {
  mockQuery = ok(gathering({ viewerIsHost: true, viewerIsAttending: true }));
  renderDetail();
  expect(screen.getByTestId("host-panel")).toBeInTheDocument();
});
