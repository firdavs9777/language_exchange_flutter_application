import { renderHook } from "@testing-library/react";
import { useBodyScrollLock } from "./dialogChrome";

// Two dialogs can be open at once — the member profile mounts its photo viewer
// twice (a phone copy and a desktop copy, one hidden by CSS), and a modal over
// a modal is an ordinary pattern. Without counting, the second lock captures
// the first's "hidden" as the value to restore, so closing one leaves the page
// unscrollable for good.
describe("useBodyScrollLock", () => {
  afterEach(() => {
    document.body.style.overflow = "";
  });

  it("locks while active and restores after", () => {
    const { unmount } = renderHook(() => useBodyScrollLock(true));
    expect(document.body.style.overflow).toBe("hidden");
    unmount();
    expect(document.body.style.overflow).toBe("");
  });

  it("stays locked until the LAST holder lets go", () => {
    const first = renderHook(() => useBodyScrollLock(true));
    const second = renderHook(() => useBodyScrollLock(true));
    expect(document.body.style.overflow).toBe("hidden");

    second.unmount();
    // One dialog is still open; the page must not start scrolling behind it.
    expect(document.body.style.overflow).toBe("hidden");

    first.unmount();
    expect(document.body.style.overflow).toBe("");
  });

  it("unlocks even when the holders let go in the order they took it", () => {
    // The order that breaks a naive save-and-restore: the FIRST holder restores
    // the empty value, then the SECOND restores the "hidden" it captured from
    // the first — and the page is locked with no dialog on screen.
    const first = renderHook(() => useBodyScrollLock(true));
    const second = renderHook(() => useBodyScrollLock(true));

    first.unmount();
    second.unmount();

    expect(document.body.style.overflow).toBe("");
  });

  it("does nothing while inactive", () => {
    renderHook(() => useBodyScrollLock(false));
    expect(document.body.style.overflow).toBe("");
  });
});
