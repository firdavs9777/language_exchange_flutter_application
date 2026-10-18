import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import ProfileActions from "./ProfileActions";

const mockNavigate = jest.fn();
const mockFollow = jest.fn();
const mockUnfollow = jest.fn();
const mockBlock = jest.fn();
const mockUnblock = jest.fn();
const mockReport = jest.fn();
const mockBlockStatus = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("../../../store/slices/usersSlice", () => ({
  useFollowUserMutation: () => [mockFollow, { isLoading: false }],
  useUnFollowUserMutation: () => [mockUnfollow, { isLoading: false }],
  useBlockUserMutation: () => [mockBlock, { isLoading: false }],
  useUnblockUserMutation: () => [mockUnblock, { isLoading: false }],
  useReportUserMutation: () => [mockReport, { isLoading: false }],
  useGetBlockStatusQuery: (arg: any, opts: any) => mockBlockStatus(arg, opts),
}));

const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });
const rejected = () => ({ unwrap: () => Promise.reject(new Error("nope")) });
const pending = () => ({ unwrap: () => new Promise(() => undefined) });

// `null`, not `undefined`: an undefined argument would fall back to the
// default parameter and quietly sign the viewer back in.
function renderActions(props: any = {}, viewerId: string | null = "me") {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: viewerId ? { user: { _id: viewerId } } : null }) => state,
    },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <ProfileActions userId="u2" isOwn={false} name="Ada" {...props} />
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  mockFollow.mockReturnValue(resolved());
  mockUnfollow.mockReturnValue(resolved());
  mockBlock.mockReturnValue(resolved());
  mockUnblock.mockReturnValue(resolved());
  mockReport.mockReturnValue(resolved());
  mockBlockStatus.mockReturnValue({ data: { data: { isBlocked: false } } });
});

afterEach(() => {
  jest.clearAllMocks();
});

describe("own profile", () => {
  it("offers edit profile and settings, and nothing social", () => {
    renderActions({ isOwn: true, userId: "me" });
    expect(screen.getByTestId("action-edit-profile")).toHaveAttribute("href", "/profile/edit");
    expect(screen.getByTestId("action-settings")).toHaveAttribute("href", "/settings");
    expect(screen.queryByTestId("action-message")).not.toBeInTheDocument();
    expect(screen.queryByTestId("action-follow")).not.toBeInTheDocument();
    expect(screen.queryByTestId("action-more")).not.toBeInTheDocument();
  });

  it("links to your own language card, the page you share", () => {
    renderActions({ isOwn: true, userId: "me" });
    expect(screen.getByTestId("action-card")).toHaveAttribute("href", "/card/me");
  });
});

describe("another user's profile", () => {
  it("offers message, follow and an overflow menu", () => {
    renderActions();
    expect(screen.getByTestId("action-message")).toHaveTextContent("Message");
    expect(screen.getByTestId("action-follow")).toHaveTextContent("Follow");
    expect(screen.getByTestId("action-more")).toBeInTheDocument();
    expect(screen.queryByTestId("action-edit-profile")).not.toBeInTheDocument();
  });

  it("opens the chat by the other user's id and posts nothing", () => {
    const fetchSpy = jest.spyOn(global as any, "fetch").mockImplementation(() => {
      throw new Error("no request expected");
    });
    renderActions();
    fireEvent.click(screen.getByTestId("action-message"));
    expect(mockNavigate).toHaveBeenCalledWith("/chat/u2");
    expect(fetchSpy).not.toHaveBeenCalled();
    fetchSpy.mockRestore();
  });

  it("sends a logged-out viewer to the login screen instead", () => {
    renderActions({}, null);
    fireEvent.click(screen.getByTestId("action-message"));
    expect(mockNavigate).toHaveBeenCalledWith("/login");
  });

  it("flips to Following before the mutation resolves", () => {
    mockFollow.mockReturnValue(pending());
    renderActions();
    fireEvent.click(screen.getByTestId("action-follow"));
    expect(mockFollow).toHaveBeenCalledWith({ userId: "me", targetUserId: "u2" });
    expect(screen.getByTestId("action-follow")).toHaveTextContent("Following");
    expect(screen.getByTestId("action-follow")).toHaveAttribute("aria-pressed", "true");
  });

  it("rolls back to Follow when the mutation fails", async () => {
    mockFollow.mockReturnValue(rejected());
    renderActions();
    fireEvent.click(screen.getByTestId("action-follow"));
    expect(screen.getByTestId("action-follow")).toHaveTextContent("Following");
    await waitFor(() =>
      expect(screen.getByTestId("action-follow")).toHaveTextContent("Follow")
    );
    expect(screen.getByTestId("action-follow")).toHaveAttribute("aria-pressed", "false");
  });

  it("unfollows optimistically and reports the new state", async () => {
    const onFollowChanged = jest.fn();
    renderActions({ isFollowing: true, onFollowChanged });
    expect(screen.getByTestId("action-follow")).toHaveTextContent("Following");
    fireEvent.click(screen.getByTestId("action-follow"));
    expect(mockUnfollow).toHaveBeenCalledWith({ userId: "me", targetUserId: "u2" });
    expect(screen.getByTestId("action-follow")).toHaveTextContent("Follow");
    await waitFor(() => expect(onFollowChanged).toHaveBeenCalledWith(false));
  });

  it("adopts a follow state that arrives after the first render", () => {
    const { rerender } = renderActions({ isFollowing: false });
    expect(screen.getByTestId("action-follow")).toHaveTextContent("Follow");
    rerender(
      <Provider
        store={configureStore({
          reducer: { auth: (s: any = { userInfo: { user: { _id: "me" } } }) => s },
        })}
      >
        <MemoryRouter>
          <ProfileActions userId="u2" isOwn={false} name="Ada" isFollowing />
        </MemoryRouter>
      </Provider>
    );
    expect(screen.getByTestId("action-follow")).toHaveTextContent("Following");
  });

  it("blocks only after the confirm dialog is confirmed", async () => {
    renderActions();
    fireEvent.click(screen.getByTestId("action-more"));
    fireEvent.click(screen.getByTestId("action-block"));
    expect(screen.getByTestId("confirm-dialog")).toBeInTheDocument();
    expect(mockBlock).not.toHaveBeenCalled();

    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    expect(mockBlock).toHaveBeenCalledWith("u2");
    await waitFor(() => expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument());
  });

  it("leaves the block dialog open when the mutation fails", async () => {
    mockBlock.mockReturnValue(rejected());
    renderActions();
    fireEvent.click(screen.getByTestId("action-more"));
    fireEvent.click(screen.getByTestId("action-block"));
    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    await waitFor(() => expect(screen.getByTestId("confirm-dialog-error")).toBeInTheDocument());
    expect(screen.getByTestId("confirm-dialog")).toBeInTheDocument();
  });

  // The dialog collects free text, and `reason` on the Report model is an
  // enum — so what the reader typed is the `description` and the reason is
  // "other". Sending the prose as `reason` would be a 400 from mongoose.
  it("reports with the body POST /api/v1/reports actually accepts", async () => {
    renderActions();
    fireEvent.click(screen.getByTestId("action-more"));
    fireEvent.click(screen.getByTestId("action-report"));
    const confirm = screen.getByTestId("confirm-dialog-confirm");
    expect(confirm).toBeDisabled();

    fireEvent.change(screen.getByTestId("confirm-dialog-reason"), {
      target: { value: "kept messaging after I asked them to stop" },
    });
    fireEvent.click(confirm);
    expect(mockReport).toHaveBeenCalledWith({
      type: "user",
      reportedUser: "u2",
      reason: "other",
      description: "kept messaging after I asked them to stop",
    });
    await waitFor(() => expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument());
  });

  it("stops the report description at the 500 the Report model allows", () => {
    renderActions();
    fireEvent.click(screen.getByTestId("action-more"));
    fireEvent.click(screen.getByTestId("action-report"));
    expect(screen.getByTestId("confirm-dialog-reason")).toHaveAttribute("maxlength", "500");
  });

  it("asks the block status for this pair and offers Block while it is false", () => {
    renderActions();
    expect(mockBlockStatus).toHaveBeenCalledWith(
      { userId: "me", targetUserId: "u2" },
      expect.objectContaining({ skip: false })
    );
    fireEvent.click(screen.getByTestId("action-more"));
    expect(screen.getByTestId("action-block")).toBeInTheDocument();
    expect(screen.queryByTestId("action-unblock")).not.toBeInTheDocument();
  });

  it("offers Unblock instead once the status says the viewer blocked them", async () => {
    mockBlockStatus.mockReturnValue({ data: { data: { isBlocked: true } } });
    renderActions();
    fireEvent.click(screen.getByTestId("action-more"));
    expect(screen.queryByTestId("action-block")).not.toBeInTheDocument();

    fireEvent.click(screen.getByTestId("action-unblock"));
    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    expect(mockUnblock).toHaveBeenCalledWith("u2");
    await waitFor(() => expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument());
  });

  it("does not ask for a block status on the viewer's own profile", () => {
    renderActions({ isOwn: true, userId: "me" });
    expect(mockBlockStatus).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ skip: true })
    );
  });

  it("closes the overflow menu once an action is chosen", () => {
    renderActions();
    fireEvent.click(screen.getByTestId("action-more"));
    expect(screen.getByTestId("action-report")).toBeInTheDocument();
    fireEvent.click(screen.getByTestId("action-block"));
    expect(screen.queryByTestId("action-report")).not.toBeInTheDocument();
  });

  it("closes the overflow menu on Escape", () => {
    renderActions();
    fireEvent.click(screen.getByTestId("action-more"));
    expect(screen.getByTestId("action-block")).toBeInTheDocument();
    fireEvent.keyDown(document, { key: "Escape" });
    expect(screen.queryByTestId("action-block")).not.toBeInTheDocument();
  });
});
