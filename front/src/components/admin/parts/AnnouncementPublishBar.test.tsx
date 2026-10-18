import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import AnnouncementPublishBar from "./AnnouncementPublishBar";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockPublish = jest.fn();
const mockEnd = jest.fn();
const mockAudience = jest.fn();
jest.mock("../../../store/slices/adminSlice", () => ({
  usePublishAnnouncementMutation: () => mockPublish(),
  useEndAnnouncementMutation: () => mockEnd(),
  useLazyGetAnnouncementAudienceQuery: () => mockAudience(),
}));

let publishTrigger: jest.Mock;
let endTrigger: jest.Mock;
let audienceTrigger: jest.Mock;
let prepare: jest.Mock;
let onDone: jest.Mock;
const resolved = (value: any) => jest.fn(() => ({ unwrap: () => Promise.resolve(value) }));

const renderBar = (props: any = {}) =>
  render(
    <AnnouncementPublishBar
      announcementId="a1"
      status="draft"
      notify={true}
      startsAtIso="2030-01-02T10:00:00.000Z"
      prepare={prepare}
      onDone={onDone}
      {...props}
    />
  );

beforeEach(() => {
  publishTrigger = resolved({ status: "live" });
  endTrigger = resolved({ status: "ended" });
  audienceTrigger = resolved({ count: 120, listed: 300 });
  prepare = jest.fn(() => Promise.resolve("a1"));
  onDone = jest.fn();
  mockPublish.mockReset().mockReturnValue([publishTrigger, { isLoading: false }]);
  mockEnd.mockReset().mockReturnValue([endTrigger, { isLoading: false }]);
  mockAudience.mockReset().mockReturnValue([audienceTrigger, { isFetching: false }]);
});

it("publish now with notify: saves, counts the audience, confirms, then publishes", async () => {
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  expect(prepare).toHaveBeenCalledWith("publish");
  expect(audienceTrigger).toHaveBeenCalledWith("a1");
  expect(screen.getByText(/120/)).toHaveTextContent("Sends a push notification to 120 people now and adds it to 300 notification lists.");
  expect(publishTrigger).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() => expect(publishTrigger).toHaveBeenCalledWith({ id: "a1", at: undefined }));
  await waitFor(() => expect(onDone).toHaveBeenCalledWith("Published."));
});

it("publish without notify skips the dialog", async () => {
  renderBar({ notify: false });
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(publishTrigger).toHaveBeenCalledWith({ id: "a1", at: undefined }));
  expect(audienceTrigger).not.toHaveBeenCalled();
});

it("schedule passes the start time and says when", async () => {
  publishTrigger = resolved({ status: "scheduled" });
  mockPublish.mockReturnValue([publishTrigger, { isLoading: false }]);
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Schedule" }));
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  expect(prepare).toHaveBeenCalledWith("schedule");
  expect(screen.getByText(/at the scheduled start/)).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() => expect(publishTrigger).toHaveBeenCalledWith({ id: "a1", at: "2030-01-02T10:00:00.000Z" }));
  await waitFor(() => expect(onDone).toHaveBeenCalledWith("Scheduled."));
});

it("nothing is sent when the save step fails validation", async () => {
  prepare = jest.fn(() => Promise.resolve(null));
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(prepare).toHaveBeenCalled());
  expect(audienceTrigger).not.toHaveBeenCalled();
  expect(publishTrigger).not.toHaveBeenCalled();
});

it("an audience-count failure is shown and nothing is published", async () => {
  audienceTrigger = jest.fn(() => ({ unwrap: () => Promise.reject({ data: { message: "count failed" } }) }));
  mockAudience.mockReturnValue([audienceTrigger, { isFetching: false }]);
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  expect(await screen.findByRole("alert")).toHaveTextContent("count failed");
  expect(publishTrigger).not.toHaveBeenCalled();
});

it("a publish failure stays in the dialog", async () => {
  publishTrigger = jest.fn(() => ({ unwrap: () => Promise.reject({ data: { message: "endsAt must be after startsAt" } }) }));
  mockPublish.mockReturnValue([publishTrigger, { isLoading: false }]);
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(await screen.findByTestId("confirm-dialog-error")).toHaveTextContent("endsAt must be after startsAt");
  expect(onDone).not.toHaveBeenCalled();
});

it("live: only End now, behind a confirm", async () => {
  renderBar({ status: "live" });
  expect(screen.queryByRole("button", { name: "Publish now" })).toBeNull();
  fireEvent.click(screen.getByRole("button", { name: "End now" }));
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() => expect(endTrigger).toHaveBeenCalledWith("a1"));
  await waitFor(() => expect(onDone).toHaveBeenCalledWith("Ended."));
});

it("ended: no actions", () => {
  renderBar({ status: "ended" });
  expect(screen.queryAllByRole("button")).toHaveLength(0);
});

it("a double click on Publish now saves and publishes once", async () => {
  let release: (id: string) => void = () => undefined;
  prepare = jest.fn(() => new Promise<string>((resolve) => { release = resolve; }));
  renderBar({ notify: false });
  const button = screen.getByRole("button", { name: "Publish now" });
  fireEvent.click(button);
  fireEvent.click(button);
  expect(prepare).toHaveBeenCalledTimes(1);
  release("a1");
  await waitFor(() => expect(onDone).toHaveBeenCalledTimes(1));
  expect(publishTrigger).toHaveBeenCalledTimes(1);
});

it("a double click on the confirm publishes once", async () => {
  let resolvePublish: (v: any) => void = () => undefined;
  publishTrigger = jest.fn(() => ({ unwrap: () => new Promise((resolve) => { resolvePublish = resolve; }) }));
  mockPublish.mockReturnValue([publishTrigger, { isLoading: false }]);
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  const confirm = screen.getByTestId("confirm-dialog-confirm");
  fireEvent.click(confirm);
  fireEvent.click(confirm);
  expect(publishTrigger).toHaveBeenCalledTimes(1);
  resolvePublish({ status: "live" });
  await waitFor(() => expect(onDone).toHaveBeenCalledTimes(1));
});

it("a double click on the End confirm ends once", async () => {
  let resolveEnd: (v: any) => void = () => undefined;
  endTrigger = jest.fn(() => ({ unwrap: () => new Promise((resolve) => { resolveEnd = resolve; }) }));
  mockEnd.mockReturnValue([endTrigger, { isLoading: false }]);
  renderBar({ status: "live" });
  fireEvent.click(screen.getByRole("button", { name: "End now" }));
  const confirm = screen.getByTestId("confirm-dialog-confirm");
  fireEvent.click(confirm);
  fireEvent.click(confirm);
  expect(endTrigger).toHaveBeenCalledTimes(1);
  resolveEnd({ status: "ended" });
  await waitFor(() => expect(onDone).toHaveBeenCalledTimes(1));
});

it("actions are disabled while the editor says it is busy (image upload)", () => {
  renderBar({ disabled: true });
  expect(screen.getByRole("button", { name: "Publish now" })).toBeDisabled();
  expect(screen.getByRole("button", { name: "Schedule" })).toBeDisabled();
});

it("after a successful publish the actions stay disabled until the status changes", async () => {
  const view = renderBar({ notify: false });
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(onDone).toHaveBeenCalled());
  expect(screen.getByRole("button", { name: "Publish now" })).toBeDisabled();
  view.rerender(
    <AnnouncementPublishBar announcementId="a1" status="live" notify={false}
      startsAtIso={null} prepare={prepare} onDone={onDone} />
  );
  expect(screen.getByRole("button", { name: "End now" })).not.toBeDisabled();
});

it("M1: re-scheduling a scheduled row re-enables the buttons once the row's updatedAt changes", async () => {
  publishTrigger = resolved({ status: "scheduled" });
  mockPublish.mockReturnValue([publishTrigger, { isLoading: false }]);
  const base = { announcementId: "a1", status: "scheduled" as const, notify: false,
    startsAtIso: "2030-01-02T10:00:00.000Z", prepare, onDone };
  const view = render(<AnnouncementPublishBar {...base} updatedAt="t1" />);
  fireEvent.click(screen.getByRole("button", { name: "Schedule" }));
  await waitFor(() => expect(onDone).toHaveBeenCalledWith("Scheduled."));
  expect(screen.getByRole("button", { name: "Schedule" })).toBeDisabled();
  view.rerender(<AnnouncementPublishBar {...base} updatedAt="t2" />);
  expect(screen.getByRole("button", { name: "Schedule" })).not.toBeDisabled();
  expect(screen.getByRole("button", { name: "End now" })).not.toBeDisabled();
});

it("M3: a schedule confirmed after its start time is refused in the dialog", async () => {
  jest.useFakeTimers({ doNotFake: ["setTimeout", "setInterval", "queueMicrotask", "nextTick", "setImmediate"] });
  try {
    jest.setSystemTime(new Date("2030-01-02T09:00:00.000Z"));
    renderBar({ status: "draft" });
    fireEvent.click(screen.getByRole("button", { name: "Schedule" }));
    await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
    jest.setSystemTime(new Date("2030-01-02T10:01:00.000Z"));
    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    expect(await screen.findByTestId("confirm-dialog-error")).toHaveTextContent(/start time has passed/i);
    expect(publishTrigger).not.toHaveBeenCalled();
  } finally {
    jest.useRealTimers();
  }
});

it("M3: the done message follows the returned status, not the mode", async () => {
  publishTrigger = resolved({ status: "live" });
  mockPublish.mockReturnValue([publishTrigger, { isLoading: false }]);
  renderBar({ notify: false });
  fireEvent.click(screen.getByRole("button", { name: "Schedule" }));
  await waitFor(() => expect(onDone).toHaveBeenCalledWith("Published."));
});

it("a scheduleRequest from the editor starts the schedule path (save, count, confirm)", async () => {
  const view = renderBar({ status: "scheduled", scheduleRequest: 0 });
  expect(prepare).not.toHaveBeenCalled();
  view.rerender(
    <AnnouncementPublishBar announcementId="a1" status="scheduled" notify={true}
      startsAtIso="2030-01-02T10:00:00.000Z" prepare={prepare} onDone={onDone} scheduleRequest={1} />
  );
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  expect(prepare).toHaveBeenCalledWith("schedule");
  expect(audienceTrigger).toHaveBeenCalledWith("a1");
});

it("cancelling an editor-requested schedule confirm tells the editor; a plain Schedule cancel does not", async () => {
  const onScheduleCancelled = jest.fn();
  const base = { announcementId: "a1", status: "scheduled" as const, notify: true,
    startsAtIso: "2030-01-02T10:00:00.000Z", prepare, onDone, onScheduleCancelled };
  const view = render(<AnnouncementPublishBar {...base} scheduleRequest={0} />);
  fireEvent.click(screen.getByRole("button", { name: "Schedule" }));
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  fireEvent.click(screen.getByTestId("confirm-dialog-cancel"));
  expect(onScheduleCancelled).not.toHaveBeenCalled();
  view.rerender(<AnnouncementPublishBar {...base} scheduleRequest={1} />);
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  fireEvent.click(screen.getByTestId("confirm-dialog-cancel"));
  expect(onScheduleCancelled).toHaveBeenCalledTimes(1);
});

it("a web-only audience says Website only instead of counts", async () => {
  audienceTrigger = resolved({ count: 0, listed: 0, reason: "web_only" });
  mockAudience.mockReturnValue([audienceTrigger, { isFetching: false }]);
  renderBar();
  fireEvent.click(screen.getByRole("button", { name: "Publish now" }));
  await waitFor(() => expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument());
  expect(screen.getByText(/Website only/)).toBeInTheDocument();
  expect(screen.queryByText(/push notification to/)).toBeNull();
});
