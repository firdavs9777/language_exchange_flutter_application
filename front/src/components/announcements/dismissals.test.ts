import { readDismissed, dismiss, isDismissed, DISMISS_KEY, _resetDismissalsForTests } from "./dismissals";

beforeEach(() => { window.localStorage.clear(); _resetDismissalsForTests(); });

test("dismiss remembers ids, newest last, capped at 50", () => {
  for (let i = 0; i < 55; i++) dismiss(`id${i}`);
  const ids = readDismissed();
  expect(ids).toHaveLength(50);
  expect(ids[0]).toBe("id5");
  expect(isDismissed("id54")).toBe(true);
  expect(isDismissed("id0")).toBe(false);
});

test("corrupt storage reads as empty", () => {
  window.localStorage.setItem(DISMISS_KEY, "{not json");
  expect(readDismissed()).toEqual([]);
});

test("storage that throws never crashes; dismissal lasts for this page session", () => {
  const spy = jest.spyOn(Storage.prototype, "getItem").mockImplementation(() => { throw new Error("blocked"); });
  const spy2 = jest.spyOn(Storage.prototype, "setItem").mockImplementation(() => { throw new Error("blocked"); });
  expect(() => dismiss("x")).not.toThrow();
  expect(isDismissed("x")).toBe(true);
  spy.mockRestore(); spy2.mockRestore();
});
