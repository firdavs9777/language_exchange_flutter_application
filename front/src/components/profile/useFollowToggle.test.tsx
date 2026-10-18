import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import useFollowToggle from "./useFollowToggle";

const mockNavigate = jest.fn();
const mockFollow = jest.fn();
const mockUnfollow = jest.fn();

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("../../store/slices/usersSlice", () => ({
  useFollowUserMutation: () => [mockFollow, { isLoading: false }],
  useUnFollowUserMutation: () => [mockUnfollow, { isLoading: false }],
}));

const mockNotifyError = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: { error: (...args: any[]) => mockNotifyError(...args), success: jest.fn(), info: jest.fn() },
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });
const rejected = () => ({ unwrap: () => Promise.reject(new Error("nope")) });

interface ProbeProps {
  isFollowing?: boolean;
  onChanged?: (nowFollowing: boolean) => void;
}

/** The hook has no UI of its own, so a one-button probe stands in for one. */
const Probe: React.FC<ProbeProps> = ({ isFollowing, onChanged }) => {
  const { following, busy, toggle } = useFollowToggle("u2", isFollowing, onChanged);
  return (
    <button type="button" data-testid="probe" disabled={busy} onClick={toggle}>
      {following ? "Following" : "Follow"}
    </button>
  );
};

function renderProbe(props: ProbeProps = {}, viewerId: string | null = "me") {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: viewerId ? { user: { _id: viewerId } } : null }) => state,
    },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <Probe {...props} />
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  mockNotifyError.mockReset();
  mockFollow.mockReturnValue(resolved());
  mockUnfollow.mockReturnValue(resolved());
});

afterEach(() => {
  jest.clearAllMocks();
});

it("follows optimistically, before the mutation resolves", () => {
  mockFollow.mockReturnValue({ unwrap: () => new Promise(() => undefined) });
  renderProbe({ isFollowing: false });

  fireEvent.click(screen.getByTestId("probe"));

  expect(mockFollow).toHaveBeenCalledWith({ userId: "me", targetUserId: "u2" });
  expect(screen.getByTestId("probe")).toHaveTextContent("Following");
});

it("rolls back when the mutation is rejected", async () => {
  mockFollow.mockReturnValue(rejected());
  renderProbe({ isFollowing: false });

  fireEvent.click(screen.getByTestId("probe"));
  expect(screen.getByTestId("probe")).toHaveTextContent("Following");

  await waitFor(() => expect(screen.getByTestId("probe")).toHaveTextContent("Follow"));
});

it("unfollows and reports the new state", async () => {
  const onChanged = jest.fn();
  renderProbe({ isFollowing: true, onChanged });

  fireEvent.click(screen.getByTestId("probe"));

  expect(mockUnfollow).toHaveBeenCalledWith({ userId: "me", targetUserId: "u2" });
  await waitFor(() => expect(onChanged).toHaveBeenCalledWith(false));
});

it("never reports a state the server rejected", async () => {
  const onChanged = jest.fn();
  mockFollow.mockReturnValue(rejected());
  renderProbe({ isFollowing: false, onChanged });

  fireEvent.click(screen.getByTestId("probe"));

  await waitFor(() => expect(screen.getByTestId("probe")).toHaveTextContent("Follow"));
  expect(onChanged).not.toHaveBeenCalled();
});

it("adopts a follow state that arrives after the first render", () => {
  const { rerender } = renderProbe({ isFollowing: false });
  expect(screen.getByTestId("probe")).toHaveTextContent("Follow");

  const store = configureStore({
    reducer: { auth: (state: any = { userInfo: { user: { _id: "me" } } }) => state },
  });
  rerender(
    <Provider store={store}>
      <MemoryRouter>
        <Probe isFollowing />
      </MemoryRouter>
    </Provider>
  );

  expect(screen.getByTestId("probe")).toHaveTextContent("Following");
});

it("sends a signed-out visitor to the login page instead of the API", () => {
  renderProbe({ isFollowing: false }, null);

  fireEvent.click(screen.getByTestId("probe"));

  expect(mockNavigate).toHaveBeenCalledWith("/login");
  expect(mockFollow).not.toHaveBeenCalled();
});

it("says why when a block refuses the follow (403), and rolls back", async () => {
  mockFollow.mockReturnValue({
    unwrap: () => Promise.reject({ status: 403, data: { success: false, error: "Cannot follow this user" } }),
  });
  renderProbe({ isFollowing: false });
  fireEvent.click(screen.getByTestId("probe"));
  await waitFor(() => expect(mockNotifyError).toHaveBeenCalledWith("You can't follow this person"));
  expect(screen.getByTestId("probe")).toHaveTextContent("Follow");
});

it("stays quiet for other failures, as before", async () => {
  mockFollow.mockReturnValue(rejected());
  renderProbe({ isFollowing: false });
  fireEvent.click(screen.getByTestId("probe"));
  await waitFor(() => expect(screen.getByTestId("probe")).toHaveTextContent("Follow"));
  expect(mockNotifyError).not.toHaveBeenCalled();
});
