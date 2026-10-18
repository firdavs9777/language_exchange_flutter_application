import "@testing-library/jest-dom";
import React from "react";
import { renderHook } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import useProfileData from "./useProfileData";

const mockGetUserProfile = jest.fn();
const mockGetPublicProfile = jest.fn();
const mockGetMyMoments = jest.fn();

jest.mock("../../store/slices/usersSlice", () => ({
  useGetUserProfileQuery: (arg: any, opts: any) => mockGetUserProfile(arg, opts),
}));
jest.mock("../../store/slices/communitySlice", () => ({
  useGetPublicUserProfileQuery: (arg: any, opts: any) => mockGetPublicProfile(arg, opts),
}));
jest.mock("../../store/slices/momentsSlice", () => ({
  useGetMyMomentsQuery: (arg: any, opts: any) => mockGetMyMoments(arg, opts),
}));

const idle = { data: undefined, isLoading: false, isFetching: false, error: undefined, refetch: jest.fn() };

function wrapper(viewerId?: string) {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: viewerId ? { user: { _id: viewerId } } : null }) => state,
    },
  });
  return ({ children }: { children?: React.ReactNode }) => (
    <Provider store={store}>{children}</Provider>
  );
}

beforeEach(() => {
  mockGetUserProfile.mockReturnValue(idle);
  mockGetPublicProfile.mockReturnValue(idle);
  mockGetMyMoments.mockReturnValue(idle);
});

afterEach(() => {
  mockGetUserProfile.mockReset();
  mockGetPublicProfile.mockReset();
  mockGetMyMoments.mockReset();
});

it("treats a missing userId as the signed-in user's own profile", () => {
  mockGetUserProfile.mockReturnValue({ ...idle, data: { data: { _id: "me", name: "Me" } } });

  const { result } = renderHook(() => useProfileData(), { wrapper: wrapper("me") });

  expect(result.current.isOwn).toBe(true);
  expect(result.current.user && result.current.user.name).toBe("Me");
  // The other-user query never fires for an own profile.
  expect(mockGetPublicProfile.mock.calls[0][1].skip).toBe(true);
  expect(mockGetUserProfile.mock.calls[0][1].skip).toBe(false);
});

it("treats a userId equal to the viewer as own too", () => {
  renderHook(() => useProfileData("me"), { wrapper: wrapper("me") });
  expect(mockGetUserProfile.mock.calls[0][1].skip).toBe(false);
  expect(mockGetPublicProfile.mock.calls[0][1].skip).toBe(true);
});

it("reads another user from the PUBLIC profile endpoint, not the protected one", () => {
  mockGetPublicProfile.mockReturnValue({ ...idle, data: { data: { _id: "u2", name: "Ada" } } });

  const { result } = renderHook(() => useProfileData("u2"), { wrapper: wrapper("me") });

  expect(result.current.isOwn).toBe(false);
  expect(result.current.user && result.current.user.name).toBe("Ada");
  expect(mockGetPublicProfile).toHaveBeenCalledWith("u2", { skip: false });
  expect(mockGetUserProfile.mock.calls[0][1].skip).toBe(true);
  // Moments are fetched for the profile being viewed, not for the viewer.
  expect(mockGetMyMoments.mock.calls[0][0]).toEqual({ userId: "u2" });
});

it("counts followers and following from the arrays the API returns", () => {
  mockGetPublicProfile.mockReturnValue({
    ...idle,
    data: { data: { _id: "u2", followers: ["me", "a"], following: ["b"] } },
  });
  mockGetMyMoments.mockReturnValue({ ...idle, data: { totalMoments: 7, data: [] } });

  const { result } = renderHook(() => useProfileData("u2"), { wrapper: wrapper("me") });

  expect(result.current.stats).toEqual({ followers: 2, following: 1, moments: 7 });
});

it("falls back to the moment list length when no total is returned", () => {
  mockGetMyMoments.mockReturnValue({ ...idle, data: { data: [{ _id: "m1" }, { _id: "m2" }] } });
  const { result } = renderHook(() => useProfileData("u2"), { wrapper: wrapper("me") });
  expect(result.current.stats.moments).toBe(2);
});

it("derives isFollowing from the target's followers, including populated objects", () => {
  mockGetPublicProfile.mockReturnValue({
    ...idle,
    data: { data: { _id: "u2", followers: [{ _id: "me" }] } },
  });
  const { result } = renderHook(() => useProfileData("u2"), { wrapper: wrapper("me") });
  expect(result.current.isFollowing).toBe(true);
});

it("is never following on an own profile", () => {
  mockGetUserProfile.mockReturnValue({ ...idle, data: { data: { _id: "me", followers: ["me"] } } });
  const { result } = renderHook(() => useProfileData(), { wrapper: wrapper("me") });
  expect(result.current.isFollowing).toBe(false);
});

it("reports loading and error from the active query only", () => {
  mockGetUserProfile.mockReturnValue({ ...idle, isLoading: true });
  mockGetPublicProfile.mockReturnValue({ ...idle, error: { status: 404 } });

  const own = renderHook(() => useProfileData(), { wrapper: wrapper("me") });
  expect(own.result.current.loading).toBe(true);
  expect(own.result.current.error).toBeUndefined();

  const other = renderHook(() => useProfileData("u2"), { wrapper: wrapper("me") });
  expect(other.result.current.loading).toBe(false);
  expect(other.result.current.error).toEqual({ status: 404 });
});

it("refetches the profile and the moments together", () => {
  const refetchProfile = jest.fn();
  const refetchMoments = jest.fn();
  mockGetPublicProfile.mockReturnValue({ ...idle, refetch: refetchProfile });
  mockGetMyMoments.mockReturnValue({ ...idle, refetch: refetchMoments });

  const { result } = renderHook(() => useProfileData("u2"), { wrapper: wrapper("me") });
  result.current.refetch();

  expect(refetchProfile).toHaveBeenCalledTimes(1);
  expect(refetchMoments).toHaveBeenCalledTimes(1);
});

it("skips every query for a logged-out viewer with no userId", () => {
  const { result } = renderHook(() => useProfileData(), { wrapper: wrapper(undefined) });
  expect(mockGetUserProfile.mock.calls[0][1].skip).toBe(true);
  expect(mockGetMyMoments.mock.calls[0][1].skip).toBe(true);
  expect(result.current.user).toBeUndefined();
});

// P1-PRIV-1: signed-out visitors of /:id/public get counts, not id lists.
// The page read only the arrays, so every shared profile said 0 followers.
it("counts from followersCount/followingCount when the lists are absent", () => {
  mockGetPublicProfile.mockReturnValue({
    ...idle,
    data: { data: { _id: "u2", name: "Ada", followersCount: 12, followingCount: 3 } },
  });
  const { result } = renderHook(() => useProfileData("u2"), { wrapper: wrapper(undefined) });
  expect(result.current.stats.followers).toBe(12);
  expect(result.current.stats.following).toBe(3);
  expect(result.current.isFollowing).toBe(false);
});

it("prefers the lists when both are present (signed-in viewers)", () => {
  mockGetPublicProfile.mockReturnValue({
    ...idle,
    data: { data: { _id: "u2", followers: ["me", "x"], following: [], followersCount: 99 } },
  });
  const { result } = renderHook(() => useProfileData("u2"), { wrapper: wrapper("me") });
  expect(result.current.stats.followers).toBe(2);
  expect(result.current.isFollowing).toBe(true);
});
