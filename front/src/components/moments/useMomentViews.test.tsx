import { renderHook } from "@testing-library/react";

const mockTrigger = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));

jest.mock("../../store/slices/momentsSlice", () => ({
  useRecordMomentViewsMutation: () => [mockTrigger, {}],
}));

import { useMomentViews, _resetMomentViewsForTests } from "./useMomentViews";

class FakeIntersectionObserver {
  static instances: FakeIntersectionObserver[] = [];
  callback: any;
  options: any;
  observe = jest.fn();
  unobserve = jest.fn();
  disconnect = jest.fn();
  constructor(callback: any, options: any) {
    this.callback = callback;
    this.options = options;
    FakeIntersectionObserver.instances.push(this);
  }
}

function fire(
  instance: FakeIntersectionObserver,
  target: any,
  isIntersecting: boolean,
  intersectionRatio = isIntersecting ? 1 : 0
) {
  instance.callback([{ target, isIntersecting, intersectionRatio }]);
}

function viewsFor(momentId: string) {
  return mockTrigger.mock.calls
    .flatMap((call) => call[0].views as { momentId: string }[])
    .filter((v) => v.momentId === momentId);
}

describe("useMomentViews", () => {
  let originalIO: any;

  beforeEach(() => {
    jest.useFakeTimers();
    originalIO = (global as any).IntersectionObserver;
    FakeIntersectionObserver.instances = [];
    (global as any).IntersectionObserver = FakeIntersectionObserver;
    mockTrigger.mockClear();
  });

  afterEach(() => {
    _resetMomentViewsForTests();
    if (originalIO === undefined) {
      delete (global as any).IntersectionObserver;
    } else {
      (global as any).IntersectionObserver = originalIO;
    }
    jest.useRealTimers();
  });

  it("uses one shared IntersectionObserver at threshold 0.5", () => {
    const { result } = renderHook(() =>
      useMomentViews({ momentId: "shared-1", isLoggedIn: true })
    );
    result.current({});
    const { result: result2 } = renderHook(() =>
      useMomentViews({ momentId: "shared-2", isLoggedIn: true })
    );
    result2.current({});

    expect(FakeIntersectionObserver.instances).toHaveLength(1);
    expect(FakeIntersectionObserver.instances[0].options).toEqual({
      threshold: 0.5,
    });
  });

  it("queues one view (~1500ms, not completed) after 1.5s visible then hidden, sent on the next flush", () => {
    const { result } = renderHook(() =>
      useMomentViews({ momentId: "moment-a", isLoggedIn: true })
    );
    const el = {};
    result.current(el);
    const instance = FakeIntersectionObserver.instances[0];

    fire(instance, el, true, 0.6);
    jest.advanceTimersByTime(1500);
    fire(instance, el, false, 0);

    // Not sent yet -- only queued internally until the next flush tick.
    expect(mockTrigger).not.toHaveBeenCalled();

    jest.advanceTimersByTime(5000);

    expect(mockTrigger).toHaveBeenCalledTimes(1);
    const views = viewsFor("moment-a");
    expect(views).toHaveLength(1);
    expect(views[0].completed).toBe(false);
    expect(views[0].watchedMs).toBeGreaterThanOrEqual(1400);
    expect(views[0].watchedMs).toBeLessThanOrEqual(1600);
  });

  it("marks completed true once a moment has been watched >=5s", () => {
    const { result } = renderHook(() =>
      useMomentViews({ momentId: "moment-b", isLoggedIn: true })
    );
    const el = {};
    result.current(el);
    const instance = FakeIntersectionObserver.instances[0];

    fire(instance, el, true, 1);
    jest.advanceTimersByTime(6000);

    const views = viewsFor("moment-b");
    expect(views).toHaveLength(1);
    expect(views[0].completed).toBe(true);
  });

  it("does not queue a view for less than 1s of visibility", () => {
    const { result } = renderHook(() =>
      useMomentViews({ momentId: "moment-c", isLoggedIn: true })
    );
    const el = {};
    result.current(el);
    const instance = FakeIntersectionObserver.instances[0];

    fire(instance, el, true, 1);
    jest.advanceTimersByTime(500);
    fire(instance, el, false, 0);

    jest.advanceTimersByTime(5000);

    expect(mockTrigger).not.toHaveBeenCalled();
  });

  it("queues the same moment only once per page session even when seen twice", () => {
    const { result } = renderHook(() =>
      useMomentViews({ momentId: "moment-d", isLoggedIn: true })
    );
    const el = {};
    result.current(el);
    const instance = FakeIntersectionObserver.instances[0];

    fire(instance, el, true, 1);
    jest.advanceTimersByTime(1500);
    fire(instance, el, false, 0);
    jest.advanceTimersByTime(5000); // first flush sends it

    fire(instance, el, true, 1);
    jest.advanceTimersByTime(1500);
    fire(instance, el, false, 0);
    jest.advanceTimersByTime(5000); // second viewing must not queue again

    expect(viewsFor("moment-d")).toHaveLength(1);
  });

  it("creates no observer and records nothing when logged out", () => {
    const { result } = renderHook(() =>
      useMomentViews({ momentId: "moment-e", isLoggedIn: false })
    );
    result.current({});
    jest.advanceTimersByTime(10000);

    expect(FakeIntersectionObserver.instances).toHaveLength(0);
    expect(mockTrigger).not.toHaveBeenCalled();
  });

  it("does not throw when there is no IntersectionObserver (Node-like prerender)", () => {
    delete (global as any).IntersectionObserver;

    expect(() => {
      const { result } = renderHook(() =>
        useMomentViews({ momentId: "moment-f", isLoggedIn: true })
      );
      result.current({});
      jest.advanceTimersByTime(6000);
    }).not.toThrow();

    expect(mockTrigger).not.toHaveBeenCalled();
  });
});
