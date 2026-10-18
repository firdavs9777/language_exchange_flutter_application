import { renderHook, act } from "@testing-library/react";
import { useOpenStoryFromChat, storyOwnerId } from "./useOpenStoryFromChat";

const mockNavigate = jest.fn();
jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

const originalFetch = global.fetch;
beforeEach(() => {
  (global as any).fetch = jest.fn();
});
afterEach(() => {
  global.fetch = originalFetch;
  jest.clearAllMocks();
});

describe("storyOwnerId", () => {
  it("reads a populated or bare user", () => {
    expect(storyOwnerId({ data: { user: { _id: "u9" } } })).toBe("u9");
    expect(storyOwnerId({ data: { user: "u9" } })).toBe("u9");
    expect(storyOwnerId({ data: {} })).toBe("");
  });
});

it("opens the story's own page, without reading the story first", () => {
  const { result } = renderHook(() => useOpenStoryFromChat());
  act(() => result.current("6a0b0c0d0e0f101112131415"));
  expect(mockNavigate).toHaveBeenCalledWith("/story/6a0b0c0d0e0f101112131415");
  expect((global as any).fetch).not.toHaveBeenCalled();
});

it("encodes an odd id instead of building a broken path", () => {
  const { result } = renderHook(() => useOpenStoryFromChat());
  act(() => result.current("a/b"));
  expect(mockNavigate).toHaveBeenCalledWith("/story/a%2Fb");
});

it("does nothing without a story id", () => {
  const { result } = renderHook(() => useOpenStoryFromChat());
  act(() => result.current(""));
  expect(mockNavigate).not.toHaveBeenCalled();
});
