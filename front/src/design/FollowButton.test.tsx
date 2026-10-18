import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import FollowButton from "./FollowButton";

const mockFollow = jest.fn(() => ({ unwrap: () => Promise.resolve({ success: true }) }));
const mockUnfollow = jest.fn(() => ({ unwrap: () => Promise.resolve({ success: true }) }));

jest.mock("../store/slices/usersSlice", () => ({
  useFollowUserMutation: () => [mockFollow, { isLoading: false }],
  useUnFollowUserMutation: () => [mockUnfollow, { isLoading: false }],
}));

beforeEach(() => {
  // react-scripts' Jest config sets `resetMocks: true`, which wipes each
  // jest.fn()'s implementation before every test (call tracking survives,
  // return values don't). Restore the implementations here so `.unwrap()`
  // has something to call.
  mockFollow.mockImplementation(() => ({
    unwrap: () => Promise.resolve({ success: true }),
  }));
  mockUnfollow.mockImplementation(() => ({
    unwrap: () => Promise.resolve({ success: true }),
  }));
});

it("reads its label from the passed-in state, not from its own", () => {
  const { rerender } = render(
    <FollowButton userId="me" targetUserId="u1" isFollowing={false} />
  );
  expect(screen.getByTestId("follow-button")).toHaveTextContent("Follow");

  rerender(<FollowButton userId="me" targetUserId="u1" isFollowing={true} />);
  expect(screen.getByTestId("follow-button")).toHaveTextContent("Following");
});

it("calls follow with both ids when not yet following", async () => {
  render(<FollowButton userId="me" targetUserId="u1" isFollowing={false} />);
  fireEvent.click(screen.getByTestId("follow-button"));
  await waitFor(() =>
    expect(mockFollow).toHaveBeenCalledWith({ userId: "me", targetUserId: "u1" })
  );
  expect(mockUnfollow).not.toHaveBeenCalled();
});

it("calls unfollow with both ids when already following", async () => {
  render(<FollowButton userId="me" targetUserId="u1" isFollowing={true} />);
  fireEvent.click(screen.getByTestId("follow-button"));
  await waitFor(() =>
    expect(mockUnfollow).toHaveBeenCalledWith({ userId: "me", targetUserId: "u1" })
  );
  expect(mockFollow).not.toHaveBeenCalled();
});

it("reports the new state to its parent", async () => {
  const onToggled = jest.fn();
  render(
    <FollowButton
      userId="me"
      targetUserId="u1"
      isFollowing={false}
      onToggled={onToggled}
    />
  );
  fireEvent.click(screen.getByTestId("follow-button"));
  await waitFor(() => expect(onToggled).toHaveBeenCalledWith(true));
});

// The regression this prop shape exists to prevent: two buttons for the same
// author in one feed must not disagree after one is clicked. They cannot,
// because neither owns the state.
it("two instances for one user stay in agreement", async () => {
  const { rerender } = render(
    <>
      <FollowButton userId="me" targetUserId="u1" isFollowing={false} />
      <FollowButton userId="me" targetUserId="u1" isFollowing={false} />
    </>
  );
  fireEvent.click(screen.getAllByTestId("follow-button")[0]);
  await waitFor(() => expect(mockFollow).toHaveBeenCalled());

  rerender(
    <>
      <FollowButton userId="me" targetUserId="u1" isFollowing={true} />
      <FollowButton userId="me" targetUserId="u1" isFollowing={true} />
    </>
  );
  screen.getAllByTestId("follow-button").forEach((el) => {
    expect(el).toHaveTextContent("Following");
  });
});

it("ships a dark-mode text variant in both follow states", () => {
  const { rerender } = render(
    <FollowButton userId="me" targetUserId="u1" isFollowing={false} />
  );
  expect(screen.getByTestId("follow-button").className).toContain(
    "dark:text-brand-light"
  );

  rerender(<FollowButton userId="me" targetUserId="u1" isFollowing={true} />);
  expect(screen.getByTestId("follow-button").className).toContain(
    "dark:text-gray-300"
  );
});
