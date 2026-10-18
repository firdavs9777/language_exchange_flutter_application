import { renderHook } from "@testing-library/react";
import { useChatBlockState } from "./useChatBlockState";

const mockBlockStatus = jest.fn();
jest.mock("../../../store/slices/usersSlice", () => ({
  useGetBlockStatusQuery: (arg: any, opts: any) => mockBlockStatus(arg, opts),
}));

afterEach(() => jest.clearAllMocks());

it("asks with the same argument the info panel uses", () => {
  mockBlockStatus.mockReturnValue({ data: undefined });
  renderHook(() => useChatBlockState("me", "u2"));
  expect(mockBlockStatus).toHaveBeenCalledWith({ userId: "me", targetUserId: "u2" }, { skip: false });
});

it("is blocked when I blocked them", () => {
  mockBlockStatus.mockReturnValue({ data: { data: { isBlocked: true, isBlockedBy: false } } });
  const { result } = renderHook(() => useChatBlockState("me", "u2"));
  expect(result.current).toEqual({ blocked: true, iBlocked: true, blockedMe: false });
});

it("is blocked when they blocked me", () => {
  mockBlockStatus.mockReturnValue({ data: { data: { isBlocked: false, isBlockedBy: true } } });
  const { result } = renderHook(() => useChatBlockState("me", "u2"));
  expect(result.current).toEqual({ blocked: true, iBlocked: false, blockedMe: true });
});

it("is open while loading, on error, and for a chat with myself", () => {
  mockBlockStatus.mockReturnValue({ data: undefined, isError: true });
  expect(renderHook(() => useChatBlockState("me", "u2")).result.current.blocked).toBe(false);
  renderHook(() => useChatBlockState("me", "me"));
  expect(mockBlockStatus).toHaveBeenLastCalledWith(expect.anything(), { skip: true });
});
