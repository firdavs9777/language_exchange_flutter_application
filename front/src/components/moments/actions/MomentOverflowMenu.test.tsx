import "@testing-library/jest-dom";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import MomentOverflowMenu from "./MomentOverflowMenu";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockReport = jest.fn();
const mockBlock = jest.fn();
jest.mock("../../../store/slices/usersSlice", () => ({
  useReportUserMutation: () => [mockReport, { isLoading: false }],
  useBlockUserMutation: () => [mockBlock, { isLoading: false }],
}));
const mockNotify = { success: jest.fn(), error: jest.fn(), info: jest.fn() };
jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: {
    success: (...a: any[]) => mockNotify.success(...a),
    error: (...a: any[]) => mockNotify.error(...a),
    info: (...a: any[]) => mockNotify.info(...a),
  },
}));

function renderMenu(viewerId: string | undefined, author: any) {
  const store = configureStore({
    reducer: { auth: (s: any = { userInfo: viewerId ? { user: { _id: viewerId } } : undefined }) => s },
  });
  return render(
    <Provider store={store}>
      <MomentOverflowMenu momentId="m1" author={author} />
    </Provider>
  );
}

const respond = (value: Promise<any>) => mockReport.mockReturnValue({ unwrap: () => value });

beforeEach(() => respond(Promise.resolve({ success: true })));

it("is not offered on your own moment, whether the author is an id or populated", () => {
  renderMenu("me", "me");
  expect(screen.queryByRole("button", { name: "More options" })).not.toBeInTheDocument();
  renderMenu("me", { _id: "me", name: "Me" });
  expect(screen.queryByRole("button", { name: "More options" })).not.toBeInTheDocument();
});

it("is not offered when signed out", () => {
  renderMenu(undefined, { _id: "a1" });
  expect(screen.queryByRole("button", { name: "More options" })).not.toBeInTheDocument();
});

it("reports with the canonical payload", async () => {
  renderMenu("me", { _id: "a1", name: "Ann" });
  fireEvent.click(screen.getByRole("button", { name: "More options" }));
  fireEvent.click(screen.getByRole("menuitem", { name: "Report" }));
  fireEvent.click(screen.getByLabelText("Harassment"));
  fireEvent.change(screen.getByLabelText("Anything else? (optional)"), { target: { value: " rude " } });
  fireEvent.click(screen.getByRole("button", { name: "Send report" }));
  await waitFor(() => expect(mockNotify.success).toHaveBeenCalled());
  expect(mockReport).toHaveBeenCalledWith({
    type: "moment",
    reportId: "m1",
    reportedUser: "a1",
    reason: "harassment",
    description: "rude",
  });
  expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
});

it("cannot send without a reason", () => {
  renderMenu("me", { _id: "a1" });
  fireEvent.click(screen.getByRole("button", { name: "More options" }));
  fireEvent.click(screen.getByRole("menuitem", { name: "Report" }));
  expect(screen.getByRole("button", { name: "Send report" })).toBeDisabled();
});

it("a repeat report is a calm notice, not an error", async () => {
  respond(Promise.reject({ status: 400, data: { success: false, error: "You have already reported this content. Please wait for moderation." } }));
  renderMenu("me", { _id: "a1" });
  fireEvent.click(screen.getByRole("button", { name: "More options" }));
  fireEvent.click(screen.getByRole("menuitem", { name: "Report" }));
  fireEvent.click(screen.getByLabelText("Spam"));
  fireEvent.click(screen.getByRole("button", { name: "Send report" }));
  expect(await screen.findByText("You've already reported this moment.")).toBeInTheDocument();
  expect(mockNotify.error).not.toHaveBeenCalled();
});

it("other failures show an error and keep the dialog open", async () => {
  respond(Promise.reject({ status: 500, data: {} }));
  renderMenu("me", { _id: "a1" });
  fireEvent.click(screen.getByRole("button", { name: "More options" }));
  fireEvent.click(screen.getByRole("menuitem", { name: "Report" }));
  fireEvent.click(screen.getByLabelText("Spam"));
  fireEvent.click(screen.getByRole("button", { name: "Send report" }));
  await waitFor(() => expect(mockNotify.error).toHaveBeenCalled());
  expect(screen.getByRole("dialog")).toBeInTheDocument();
});

it("blocks the author after a confirm", async () => {
  mockBlock.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  renderMenu("me", { _id: "a1", name: "Ann" });
  fireEvent.click(screen.getByRole("button", { name: "More options" }));
  fireEvent.click(screen.getByRole("menuitem", { name: "Block" }));
  expect(screen.getByText("Block Ann?")).toBeInTheDocument();
  expect(mockBlock).not.toHaveBeenCalled();
  fireEvent.click(screen.getByRole("button", { name: "Block" }));
  await waitFor(() => expect(mockBlock).toHaveBeenCalledWith("a1"));
  await waitFor(() => expect(mockNotify.success).toHaveBeenCalled());
});

it("a failed block stays open with the error", async () => {
  mockBlock.mockReturnValue({ unwrap: () => Promise.reject({ status: 500 }) });
  renderMenu("me", { _id: "a1", name: "Ann" });
  fireEvent.click(screen.getByRole("button", { name: "More options" }));
  fireEvent.click(screen.getByRole("menuitem", { name: "Block" }));
  fireEvent.click(screen.getByRole("button", { name: "Block" }));
  expect(await screen.findByText("That didn't work. Try again.")).toBeInTheDocument();
});
