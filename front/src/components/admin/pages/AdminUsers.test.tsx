import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import AdminUsers, { relativeTime } from "./AdminUsers";

let mockLanguage = "en";
jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: () => "",
    i18n: {
      get language() {
        return mockLanguage;
      },
    },
  }),
}));

const mockSearch = jest.fn();
const mockBanned = jest.fn();
const mockGetUser = jest.fn();
const mockBan = jest.fn();
const mockUnban = jest.fn();
const mockRole = jest.fn();
const mockDelete = jest.fn();
const mockCreate = jest.fn();
const mockUpdate = jest.fn();
const mockIdle = { isLoading: false, error: undefined as any, reset: jest.fn() };

jest.mock("../../../store/slices/adminSlice", () => ({
  useSearchAdminUsersQuery: (...args: any[]) => mockSearch(...args),
  useGetBannedUsersQuery: (...args: any[]) => mockBanned(...args),
  useGetAdminUserQuery: (...args: any[]) => mockGetUser(...args),
  useBanAdminUserMutation: () => [mockBan, mockIdle],
  useUnbanAdminUserMutation: () => [mockUnban, mockIdle],
  useChangeAdminUserRoleMutation: () => [mockRole, mockIdle],
  useHardDeleteAdminUserMutation: () => [mockDelete, mockIdle],
  useCreateUserMutation: () => [mockCreate, mockIdle],
  useUpdateUserMutation: () => [mockUpdate, mockIdle],
}));

const DAY = 24 * 60 * 60 * 1000;

const USERS = [
  {
    _id: "u1",
    name: "Ada Lovelace",
    email: "ada@example.com",
    username: "ada",
    role: "admin",
    isBanned: false,
    createdAt: "2025-01-02T00:00:00.000Z",
    imageUrls: [],
    native_language: "English",
    language_to_learn: "Korean",
    userMode: "vip",
    isEmailVerified: true,
    lastActive: new Date(Date.now() - 3 * DAY).toISOString(),
    vipSubscription: { isActive: true, endDate: "2026-12-01T00:00:00.000Z" },
  },
  {
    _id: "u2",
    name: "Grace Hopper",
    email: "grace@example.com",
    username: "grace",
    role: "user",
    isBanned: true,
    banReason: "spam",
    createdAt: "2025-02-03T00:00:00.000Z",
    imageUrls: [],
    native_language: "Spanish",
    language_to_learn: "English",
    userMode: "regular",
    isEmailVerified: false,
    lastActive: null,
  },
];

const BANNED = [
  {
    _id: "u9",
    name: "Banned Person",
    email: "banned@example.com",
    username: "bp",
    role: "user",
    isBanned: true,
    banReason: "abuse",
    createdAt: "2025-03-04T00:00:00.000Z",
    imageUrls: [],
  },
];

const list = (rows: any[], pagination: any = {}, extra: any = {}) => ({
  data: { data: rows, pagination: { total: rows.length, page: 1, limit: 20, hasMore: false, ...pagination } },
  isLoading: false,
  isFetching: false,
  isError: false,
  refetch: jest.fn(),
  ...extra,
});

beforeEach(() => {
  mockLanguage = "en";
  jest.useFakeTimers();
  mockSearch.mockReset().mockReturnValue(list(USERS));
  mockBanned.mockReset().mockReturnValue(list(BANNED));
  mockGetUser.mockReset().mockReturnValue({
    data: { ...USERS[0], recentActions: [], activitySummary: {} },
    isLoading: false,
    isFetching: false,
    isError: false,
    refetch: jest.fn(),
  });
});
afterEach(() => jest.useRealTimers());

const lastArg = (mock: jest.Mock) => mock.mock.calls[mock.mock.calls.length - 1][0];

it("renders the page heading", () => {
  render(<AdminUsers />);
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Users");
});

it("tables the users the search returned", () => {
  render(<AdminUsers />);
  expect(screen.getAllByTestId("data-row")).toHaveLength(2);
  expect(screen.getByText("Ada Lovelace")).toBeInTheDocument();
  expect(screen.getByText("grace@example.com")).toBeInTheDocument();
});

it("shows role and ban status per row", () => {
  render(<AdminUsers />);
  const rows = screen.getAllByTestId("data-row");
  expect(rows[0]).toHaveTextContent("admin");
  expect(rows[1]).toHaveTextContent("Banned");
});

it("asks for page 1 with a limit of 20 and no query on first render", () => {
  render(<AdminUsers />);
  expect(lastArg(mockSearch)).toEqual(
    expect.objectContaining({ page: 1, limit: 20, adminsOnly: undefined })
  );
  expect(lastArg(mockSearch).q).toBeFalsy();
});

it("debounces the search box by 300ms before changing the query", () => {
  render(<AdminUsers />);
  fireEvent.change(screen.getByTestId("admin-users-search"), { target: { value: "ada" } });

  // Still the untyped query: a keystroke must not fire a request.
  act(() => {
    jest.advanceTimersByTime(299);
  });
  expect(lastArg(mockSearch).q).toBeFalsy();

  act(() => {
    jest.advanceTimersByTime(1);
  });
  expect(lastArg(mockSearch)).toEqual(expect.objectContaining({ q: "ada", page: 1 }));
});

it("only sends the last keystroke of a burst", () => {
  render(<AdminUsers />);
  const box = screen.getByTestId("admin-users-search");
  fireEvent.change(box, { target: { value: "a" } });
  act(() => {
    jest.advanceTimersByTime(200);
  });
  fireEvent.change(box, { target: { value: "ada" } });
  act(() => {
    jest.advanceTimersByTime(300);
  });
  const queries = mockSearch.mock.calls.map((c) => c[0] && c[0].q).filter(Boolean);
  expect(queries).not.toContain("a");
  expect(queries).toContain("ada");
});

it("filters to admins from the toggle", () => {
  render(<AdminUsers />);
  fireEvent.click(screen.getByTestId("admin-users-admins-only"));
  expect(lastArg(mockSearch)).toEqual(expect.objectContaining({ adminsOnly: true }));
});

it("switches to the banned tab and reads the banned endpoint", () => {
  render(<AdminUsers />);
  fireEvent.click(screen.getByTestId("admin-users-tab-banned"));
  expect(screen.getByText("Banned Person")).toBeInTheDocument();
  expect(screen.queryByText("Ada Lovelace")).not.toBeInTheDocument();
  expect(lastArg(mockBanned)).toEqual(expect.objectContaining({ page: 1, limit: 20 }));
});

it("passes the debounced text to the banned endpoint as `search`", () => {
  render(<AdminUsers />);
  fireEvent.click(screen.getByTestId("admin-users-tab-banned"));
  fireEvent.change(screen.getByTestId("admin-users-search"), { target: { value: "abuse" } });
  act(() => {
    jest.advanceTimersByTime(300);
  });
  expect(lastArg(mockBanned)).toEqual(expect.objectContaining({ search: "abuse" }));
});

it("pages forward while the backend says there is more", () => {
  mockSearch.mockReturnValue(list(USERS, { hasMore: true }));
  render(<AdminUsers />);
  fireEvent.click(screen.getByTestId("data-table-next"));
  expect(lastArg(mockSearch)).toEqual(expect.objectContaining({ page: 2 }));
});

it("returns to page 1 when the search text changes", () => {
  mockSearch.mockReturnValue(list(USERS, { hasMore: true }));
  render(<AdminUsers />);
  fireEvent.click(screen.getByTestId("data-table-next"));
  expect(lastArg(mockSearch).page).toBe(2);
  fireEvent.change(screen.getByTestId("admin-users-search"), { target: { value: "ada" } });
  act(() => {
    jest.advanceTimersByTime(300);
  });
  expect(lastArg(mockSearch)).toEqual(expect.objectContaining({ q: "ada", page: 1 }));
});

it("opens the detail drawer on a row click", () => {
  render(<AdminUsers />);
  expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
  fireEvent.click(screen.getAllByTestId("data-row")[0]);
  expect(screen.getByRole("dialog")).toBeInTheDocument();
  expect(mockGetUser).toHaveBeenCalledWith("u1");
});

it("shows an inline error when the list fails", () => {
  mockSearch.mockReturnValue(list([], {}, { isError: true, data: undefined }));
  render(<AdminUsers />);
  expect(screen.getByTestId("admin-users-error")).toBeInTheDocument();
});

it("shows a loading state on the first load", () => {
  mockSearch.mockReturnValue(list([], {}, { isLoading: true, data: undefined }));
  render(<AdminUsers />);
  expect(screen.getByTestId("admin-users-loading")).toBeInTheDocument();
});

it("renders without crashing when the payload is empty", () => {
  mockSearch.mockReturnValue(list([], {}, { data: undefined }));
  const { container } = render(<AdminUsers />);
  expect(container.textContent).not.toContain("undefined");
  expect(screen.getByTestId("data-table")).toBeInTheDocument();
});

// --- v2 columns and the register popup --------------------------------------

it("pills each user's languages, native first", () => {
  render(<AdminUsers />);
  const pills = screen.getAllByTestId("language-pill");
  expect(pills).toHaveLength(2);
  expect(pills[0]).toHaveTextContent("EN");
  expect(pills[0]).toHaveTextContent("KO");
  expect(pills[1]).toHaveTextContent("ES");
});

it("badges the VIP users and leaves everyone else plain", () => {
  render(<AdminUsers />);
  const rows = screen.getAllByTestId("data-row");
  expect(rows[0]).toHaveTextContent("VIP");
  expect(rows[1]).not.toHaveTextContent("VIP");
});

it("marks who has a verified email", () => {
  render(<AdminUsers />);
  const rows = screen.getAllByTestId("data-row");
  expect(rows[0].querySelector('[data-testid="admin-users-verified"]')).toBeInTheDocument();
  expect(rows[1].querySelector('[data-testid="admin-users-verified"]')).toBeNull();
});

it("shows last active as a relative time, and a dash when there is none", () => {
  render(<AdminUsers />);
  const rows = screen.getAllByTestId("data-row");
  expect(rows[0]).toHaveTextContent("3 days ago");
  expect(rows[1]).toHaveTextContent("—");
});

it("formats last active through the moderator's own language when Intl supports it", () => {
  mockLanguage = "fr";
  render(<AdminUsers />);
  const rows = screen.getAllByTestId("data-row");
  expect(rows[0]).toHaveTextContent("il y a 3 jours");
});

describe("relativeTime", () => {
  it("returns a dash for no value and the raw string for something unparsable", () => {
    expect(relativeTime(null)).toBe("—");
    expect(relativeTime("not-a-date")).toBe("not-a-date");
  });

  it("formats through Intl.RelativeTimeFormat in the language passed in", () => {
    const now = Date.now();
    const then = new Date(now - 3 * DAY).toISOString();
    expect(relativeTime(then, now, "en")).toBe("3 days ago");
    expect(relativeTime(then, now, "fr")).toBe("il y a 3 jours");
  });

  it("falls back to the plain English strings when Intl.RelativeTimeFormat is unavailable", () => {
    const original = (Intl as any).RelativeTimeFormat;
    delete (Intl as any).RelativeTimeFormat;
    try {
      const now = Date.now();
      const then = new Date(now - 3 * DAY).toISOString();
      expect(relativeTime(then, now, "fr")).toBe("3d ago");
    } finally {
      (Intl as any).RelativeTimeFormat = original;
    }
  });

  it("falls back to the date once past 30 days, in any language", () => {
    const now = Date.now();
    const old = new Date(now - 40 * DAY);
    expect(relativeTime(old.toISOString(), now, "fr")).toBe(old.toLocaleDateString());
  });
});

it("opens the register popup from the Add user button", () => {
  render(<AdminUsers />);
  expect(screen.queryByTestId("register-user-dialog")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("admin-users-add"));
  expect(screen.getByTestId("register-user-dialog")).toBeInTheDocument();
});

it("closes the register popup again", () => {
  render(<AdminUsers />);
  fireEvent.click(screen.getByTestId("admin-users-add"));
  fireEvent.click(screen.getByTestId("register-user-cancel"));
  expect(screen.queryByTestId("register-user-dialog")).not.toBeInTheDocument();
});
