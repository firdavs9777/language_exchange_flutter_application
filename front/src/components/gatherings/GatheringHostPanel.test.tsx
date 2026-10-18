import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import GatheringHostPanel from "./GatheringHostPanel";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
jest.mock("./CoverEditor", () => () => <div data-testid="cover-editor" />);
const mockSuccess = jest.fn();
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { success: (m: any) => mockSuccess(m), error: (m: any) => mockError(m) },
}));
const mockDecide = jest.fn();
const mockDecision = jest.fn();
const mockCancel = jest.fn();
const mockEnd = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useDecideJoinRequestMutation: () => [mockDecide, { isLoading: false }],
  useHostDecisionMutation: () => [mockDecision, { isLoading: false }],
  useCancelGatheringMutation: () => [mockCancel, { isLoading: false }],
  useEndGatheringMutation: () => [mockEnd, { isLoading: false }],
}));

const NOW = new Date("2026-11-01T08:00:00.000Z");
const resolved = () => ({ unwrap: () => Promise.resolve({}) });
const host = (extra: any = {}) => ({
  _id: "g1",
  title: "Coffee",
  language: "korean",
  startsAt: "2026-11-01T09:30:00.000Z",
  durationMinutes: 60,
  capacity: 6,
  quorum: 3,
  joinMode: "approval",
  status: "scheduled",
  going: 1,
  needed: 2,
  quorumMet: false,
  viewerIsAttending: true,
  viewerIsHost: true,
  requests: [{ _id: "u7", name: "Mina", username: "mina", images: [] }],
  ...extra,
});

beforeEach(() => {
  [mockDecide, mockDecision, mockCancel, mockEnd, mockSuccess, mockError].forEach((m) => m.mockReset());
  [mockDecide, mockDecision, mockCancel, mockEnd].forEach((m) => m.mockReturnValue(resolved()));
});

it("renders nothing for a guest or a finished gathering", () => {
  const { container, rerender } = render(<GatheringHostPanel gathering={host({ viewerIsHost: false }) as any} now={NOW} />);
  expect(container).toBeEmptyDOMElement();
  rerender(<GatheringHostPanel gathering={host({ status: "ended" }) as any} now={NOW} />);
  expect(container).toBeEmptyDOMElement();
});

it("lists join requests and approves or declines each", async () => {
  render(<GatheringHostPanel gathering={host() as any} now={NOW} />);
  expect(screen.getByTestId("host-requests")).toHaveTextContent("1 waiting to join");
  expect(screen.getByTestId("host-request-u7")).toHaveTextContent("Mina");
  fireEvent.click(screen.getByTestId("host-approve-u7"));
  await waitFor(() => expect(mockDecide).toHaveBeenCalledWith({ id: "g1", userId: "u7", approve: true }));
  fireEvent.click(screen.getByTestId("host-decline-u7"));
  await waitFor(() => expect(mockDecide).toHaveBeenCalledWith({ id: "g1", userId: "u7", approve: false }));
});

it("says why an approval failed (the gathering filled up)", async () => {
  mockDecide.mockReturnValue({ unwrap: () => Promise.reject({ status: 400, data: { error: "This gathering is full" } }) });
  render(<GatheringHostPanel gathering={host() as any} now={NOW} />);
  fireEvent.click(screen.getByTestId("host-approve-u7"));
  await waitFor(() => expect(mockError).toHaveBeenCalledWith("This gathering is full."));
});

it("asks the T-2h question when quorum is unmet, and runs it anyway", async () => {
  render(<GatheringHostPanel gathering={host() as any} now={NOW} />);
  // `going` counts the host, so going: 1 means nobody else yet.
  expect(screen.getByTestId("host-decision")).toHaveTextContent("Only you are coming so far");
  fireEvent.click(screen.getByTestId("host-run-anyway"));
  await waitFor(() => expect(mockDecision).toHaveBeenCalledWith({ id: "g1", run: true }));
});

it("counts the people coming when there are some", () => {
  render(<GatheringHostPanel gathering={host({ going: 2, needed: 1 }) as any} now={NOW} />);
  expect(screen.getByTestId("host-decision")).toHaveTextContent("Only 2 people are coming so far");
});

it("calls it off only after confirming", async () => {
  render(<GatheringHostPanel gathering={host() as any} now={NOW} />);
  fireEvent.click(screen.getByTestId("host-call-off"));
  expect(mockDecision).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockDecision).toHaveBeenCalledWith({ id: "g1", run: false }));
});

it("does not ask earlier than two hours before", () => {
  render(<GatheringHostPanel gathering={host({ startsAt: "2026-11-01T12:00:00.000Z" }) as any} now={NOW} />);
  expect(screen.queryByTestId("host-decision")).not.toBeInTheDocument();
});

it("offers End only once the start has passed", async () => {
  const { rerender } = render(<GatheringHostPanel gathering={host() as any} now={NOW} />);
  expect(screen.queryByTestId("host-end")).not.toBeInTheDocument();
  rerender(<GatheringHostPanel gathering={host({ status: "confirmed", quorumMet: true }) as any} now={new Date("2026-11-01T10:00:00.000Z")} />);
  fireEvent.click(screen.getByTestId("host-end"));
  await waitFor(() => expect(mockEnd).toHaveBeenCalledWith("g1"));
  expect(mockSuccess).toHaveBeenCalledWith("Ended — message anyone you met, it's free");
});

it("cancels after a confirmation that says how many are expecting it", async () => {
  render(<GatheringHostPanel gathering={host({ going: 4, needed: 0, quorumMet: true, status: "confirmed" }) as any} now={NOW} />);
  fireEvent.click(screen.getByTestId("host-cancel"));
  expect(screen.getByTestId("confirm-dialog")).toHaveTextContent("3 people are expecting this");
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockCancel).toHaveBeenCalledWith("g1"));
});
