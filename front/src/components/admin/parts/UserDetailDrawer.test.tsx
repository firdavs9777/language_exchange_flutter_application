import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import UserDetailDrawer from "./UserDetailDrawer";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockGetUser = jest.fn();
const mockBan = jest.fn();
const mockUnban = jest.fn();
const mockRole = jest.fn();
const mockDelete = jest.fn();
// RTK Query's mutation result carries `reset`, which clears `error`/`isLoading`.
// The default spies here do NOT clear: that emulates the ordinary case where
// the reset happened when the dialog opened and the failure arrived after it.
// The stale-error test below swaps in a reset with the real semantics.
const mockBanState = { isLoading: false, error: undefined as any, reset: jest.fn() };
const mockUnbanState = { isLoading: false, error: undefined as any, reset: jest.fn() };
const mockRoleState = { isLoading: false, error: undefined as any, reset: jest.fn() };
const mockDeleteState = { isLoading: false, error: undefined as any, reset: jest.fn() };
const mockUpdate = jest.fn();
const mockUpdateState = { isLoading: false, error: undefined as any, reset: jest.fn() };

jest.mock("../../../store/slices/adminSlice", () => ({
  useGetAdminUserQuery: (...args: any[]) => mockGetUser(...args),
  useUpdateUserMutation: () => [mockUpdate, mockUpdateState],
  useBanAdminUserMutation: () => [mockBan, mockBanState],
  useUnbanAdminUserMutation: () => [mockUnban, mockUnbanState],
  useChangeAdminUserRoleMutation: () => [mockRole, mockRoleState],
  useHardDeleteAdminUserMutation: () => [mockDelete, mockDeleteState],
}));

const USER = {
  _id: "u1",
  name: "Ada Lovelace",
  email: "ada@example.com",
  username: "ada",
  role: "user",
  isBanned: false,
  banReason: null,
  bannedAt: null,
  createdAt: "2025-01-02T00:00:00.000Z",
  imageUrls: ["https://cdn.example.com/ada.jpg"],
  native_language: "English",
  language_to_learn: "Korean",
  isEmailVerified: true,
  userMode: "vip",
  vipSubscription: { isActive: true, endDate: "2026-12-01T00:00:00.000Z" },
  recentActions: [
    {
      _id: "a1",
      action: "user_banned",
      reason: "spam",
      timestamp: "2026-09-01T00:00:00.000Z",
      moderator: { name: "Grace Hopper", email: "grace@example.com" },
    },
  ],
  activitySummary: {
    lastMessageAt: "2026-09-20T00:00:00.000Z",
    messagesLast30d: 42,
    lastMomentAt: null,
    momentsLast30d: 0,
  },
};

const ok = (data: any, extra: any = {}) => ({
  data,
  isLoading: false,
  isFetching: false,
  isError: false,
  refetch: jest.fn(),
  ...extra,
});

const resolved = () => ({ unwrap: () => Promise.resolve({}) });

beforeEach(() => {
  mockGetUser.mockReset().mockReturnValue(ok(USER));
  mockBan.mockReset().mockImplementation(resolved);
  mockUnban.mockReset().mockImplementation(resolved);
  mockRole.mockReset().mockImplementation(resolved);
  mockDelete.mockReset().mockImplementation(resolved);
  mockBanState.isLoading = false;
  mockBanState.error = undefined;
  mockRoleState.error = undefined;
  mockBanState.reset = jest.fn();
  mockUnbanState.reset = jest.fn();
  mockRoleState.reset = jest.fn();
  mockDeleteState.reset = jest.fn();
});

it("shows the user's identity, activity summary and recent actions", () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  const dialog = screen.getByRole("dialog");
  expect(dialog).toHaveTextContent("Ada Lovelace");
  expect(dialog).toHaveTextContent("ada@example.com");
  expect(screen.getByTestId("drawer-activity")).toHaveTextContent("42");
  expect(screen.getByTestId("drawer-recent-actions")).toHaveTextContent("user_banned");
  expect(screen.getByTestId("drawer-recent-actions")).toHaveTextContent("Grace Hopper");
});

it("fetches the user it was opened for", () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(mockGetUser).toHaveBeenCalledWith("u1");
});

it("moves focus into the panel when it opens", () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.getByRole("dialog").contains(document.activeElement)).toBe(true);
});

it("closes on Escape, on the backdrop and from the close button", () => {
  const onClose = jest.fn();
  render(<UserDetailDrawer userId="u1" onClose={onClose} />);
  fireEvent.keyDown(document, { key: "Escape" });
  expect(onClose).toHaveBeenCalledTimes(1);
  fireEvent.click(screen.getByTestId("drawer-backdrop"));
  expect(onClose).toHaveBeenCalledTimes(2);
  fireEvent.click(screen.getByTestId("drawer-close"));
  expect(onClose).toHaveBeenCalledTimes(3);
});

it("bans through the confirm dialog with the typed reason", async () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  fireEvent.click(screen.getByTestId("drawer-ban"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), {
    target: { value: "harassment" },
  });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() =>
    expect(mockBan).toHaveBeenCalledWith({ id: "u1", reason: "harassment" })
  );
});

it("does not ban until a reason is given", () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  fireEvent.click(screen.getByTestId("drawer-ban"));
  expect(screen.getByTestId("confirm-dialog-confirm")).toBeDisabled();
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(mockBan).not.toHaveBeenCalled();
});

it("offers unban instead of ban for a banned user", async () => {
  mockGetUser.mockReturnValue(ok({ ...USER, isBanned: true, banReason: "spam" }));
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.queryByTestId("drawer-ban")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("drawer-unban"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), {
    target: { value: "appeal upheld" },
  });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() =>
    expect(mockUnban).toHaveBeenCalledWith({ id: "u1", reason: "appeal upheld" })
  );
});

it("labels the role button by the role the user currently has", () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.getByTestId("drawer-role")).toHaveTextContent("Make admin");

  mockGetUser.mockReturnValue(ok({ ...USER, role: "admin" }));
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.getAllByTestId("drawer-role")[1]).toHaveTextContent("Revoke admin");
});

it("sends the opposite role on a role change", async () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  fireEvent.click(screen.getByTestId("drawer-role"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), {
    target: { value: "joins the mod team" },
  });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() =>
    expect(mockRole).toHaveBeenCalledWith({
      id: "u1",
      role: "admin",
      reason: "joins the mod team",
    })
  );
});

it("requires the user's email typed before a hard delete", async () => {
  const onClose = jest.fn();
  render(<UserDetailDrawer userId="u1" onClose={onClose} />);
  fireEvent.click(screen.getByTestId("drawer-delete"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "gdpr" } });
  expect(screen.getByTestId("confirm-dialog-confirm")).toBeDisabled();
  fireEvent.change(screen.getByTestId("confirm-dialog-typed"), {
    target: { value: "ada@example.com" },
  });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() =>
    expect(mockDelete).toHaveBeenCalledWith({ id: "u1", reason: "gdpr" })
  );
  await waitFor(() => expect(onClose).toHaveBeenCalled());
});

it("shows a failed mutation inside the dialog and keeps it open", () => {
  mockRoleState.error = { data: { message: "You cannot revoke your own admin role" } };
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  fireEvent.click(screen.getByTestId("drawer-role"));
  expect(screen.getByTestId("confirm-dialog-error")).toHaveTextContent(
    "You cannot revoke your own admin role"
  );
  expect(screen.getByTestId("confirm-dialog-confirm")).toBeInTheDocument();
});

it("shows an inline error when the detail fails to load", () => {
  mockGetUser.mockReturnValue(ok(undefined, { isError: true }));
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.getByTestId("drawer-error")).toBeInTheDocument();
});

it("shows a loading state while the detail is in flight", () => {
  mockGetUser.mockReturnValue(ok(undefined, { isLoading: true }));
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.getByTestId("drawer-loading")).toBeInTheDocument();
});

it("reads a detail payload that nests the user under `user`", () => {
  const { recentActions, activitySummary, ...user } = USER as any;
  mockGetUser.mockReturnValue(ok({ user, recentActions, activitySummary }));
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.getByRole("dialog")).toHaveTextContent("ada@example.com");
});

it("clears a previous failure's error when the dialog is reopened", async () => {
  // A real `reset()` clears the mutation's error; emulate that here.
  mockBanState.reset = jest.fn(() => {
    mockBanState.error = undefined;
  });
  mockBan.mockImplementation(() => ({
    unwrap: () => {
      // What RTK Query does on a rejected mutation: the hook result carries
      // the error until something resets it.
      mockBanState.error = { data: { message: "Reason is required" } };
      return Promise.reject(mockBanState.error);
    },
  }));

  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  fireEvent.click(screen.getByTestId("drawer-ban"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "spam" } });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() => expect(mockBan).toHaveBeenCalled());

  // Give up and come back: the last attempt's message describes something that
  // is no longer happening, so it must not greet the next one.
  fireEvent.click(screen.getByTestId("confirm-dialog-cancel"));
  fireEvent.click(screen.getByTestId("drawer-ban"));

  expect(mockBanState.reset).toHaveBeenCalled();
  expect(screen.queryByTestId("confirm-dialog-error")).not.toBeInTheDocument();
});

it("resets only the mutation whose dialog is opening", () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  fireEvent.click(screen.getByTestId("drawer-role"));
  expect(mockRoleState.reset).toHaveBeenCalled();
  expect(mockBanState.reset).not.toHaveBeenCalled();
  expect(mockDeleteState.reset).not.toHaveBeenCalled();
});

// --- v2: VIP, verified and the edit dialog ----------------------------------

it("shows the VIP subscription and when it ends", () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  const vip = screen.getByTestId("drawer-vip");
  expect(vip).toHaveTextContent("VIP");
  expect(vip.textContent).toContain(new Date("2026-12-01T00:00:00.000Z").toLocaleDateString());
});

it("says so when the account is not VIP", () => {
  mockGetUser.mockReturnValue(
    ok({ ...USER, userMode: "regular", vipSubscription: { isActive: false, endDate: null } })
  );
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.getByTestId("drawer-vip")).not.toHaveTextContent("VIP");
});

it("shows whether the email is verified", () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.getByTestId("drawer-verified")).toHaveTextContent(/yes/i);

  mockGetUser.mockReturnValue(ok({ ...USER, isEmailVerified: false }));
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.getAllByTestId("drawer-verified")[1]).toHaveTextContent(/no/i);
});

it("pills the two languages", () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  const pill = screen.getByTestId("language-pill");
  expect(pill).toHaveTextContent("EN");
  expect(pill).toHaveTextContent("KO");
});

it("opens the edit dialog from Edit, prefilled with this user", () => {
  render(<UserDetailDrawer userId="u1" onClose={jest.fn()} />);
  expect(screen.queryByTestId("edit-user-dialog")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("drawer-edit"));
  expect(screen.getByTestId("edit-user-dialog")).toBeInTheDocument();
  expect((screen.getByTestId("edit-user-name") as HTMLInputElement).value).toBe("Ada Lovelace");
});

it("keeps the drawer open when Escape closes the edit dialog's own layer", () => {
  const onClose = jest.fn();
  render(<UserDetailDrawer userId="u1" onClose={onClose} />);
  fireEvent.click(screen.getByTestId("drawer-edit"));
  fireEvent.keyDown(document, { key: "Escape" });
  expect(onClose).not.toHaveBeenCalled();
  expect(screen.queryByTestId("edit-user-dialog")).not.toBeInTheDocument();
});

it("closes the edit dialog from Cancel and leaves the drawer up", () => {
  const onClose = jest.fn();
  render(<UserDetailDrawer userId="u1" onClose={onClose} />);
  fireEvent.click(screen.getByTestId("drawer-edit"));
  fireEvent.click(screen.getByTestId("edit-user-cancel"));
  expect(screen.queryByTestId("edit-user-dialog")).not.toBeInTheDocument();
  expect(screen.getByTestId("user-detail-drawer")).toBeInTheDocument();
  expect(onClose).not.toHaveBeenCalled();
});
