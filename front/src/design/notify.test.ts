/**
 * The notification popup's shared defaults.
 *
 * What these hold still is that a caller never has to name the options again.
 * The bug being prevented is the one this helper was extracted from: ~113
 * call sites each passing their own options object, durations drifting
 * between them, and `theme: "dark"` hardcoded at 73 of them so toasts came
 * out near-black on the light UI.
 */
jest.mock("react-toastify", () => {
  const fn: any = jest.fn();
  fn.success = jest.fn();
  fn.error = jest.fn();
  fn.info = jest.fn();
  fn.warning = jest.fn();
  fn.dismiss = jest.fn();
  return { toast: fn, Slide: "SlideTransition" };
});

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { toast } = require("react-toastify");
import notify, { TOAST_MS } from "./notify";

beforeEach(() => {
  jest.clearAllMocks();
});

it("passes the message through and fills in the shared options", () => {
  notify.success("Saved");

  expect(toast.success).toHaveBeenCalledTimes(1);
  const [message, options] = toast.success.mock.calls[0];
  expect(message).toBe("Saved");
  expect(options.position).toBe("top-right");
  expect(options.transition).toBe("SlideTransition");
  expect(options.pauseOnHover).toBe(true);
  expect(options.closeOnClick).toBe(true);
});

it("never names a theme -- the stylesheet decides from prefers-color-scheme", () => {
  // The whole point of the extraction. A theme named here would be a value
  // the CSS deliberately ignores, i.e. a lie in the code.
  notify.success("a");
  notify.error("b");
  notify.info("c");
  notify.warning("d");

  const everyCall = [
    toast.success.mock.calls[0],
    toast.error.mock.calls[0],
    toast.info.mock.calls[0],
    toast.warning.mock.calls[0],
  ];
  everyCall.forEach(([, options]) => {
    expect(options.theme).toBeUndefined();
  });
});

it("gives an error longer on screen than a success", () => {
  // An error is the one the reader has to act on, and it usually arrives when
  // their attention is somewhere else.
  expect(TOAST_MS.error).toBeGreaterThan(TOAST_MS.success);

  notify.success("s");
  notify.error("e");
  expect(toast.success.mock.calls[0][1].autoClose).toBe(TOAST_MS.success);
  expect(toast.error.mock.calls[0][1].autoClose).toBe(TOAST_MS.error);
});

it("lets a caller override a default without losing the rest", () => {
  notify.info("Uploading", { autoClose: false, toastId: "upload" });

  const [, options] = toast.info.mock.calls[0];
  expect(options.autoClose).toBe(false);
  expect(options.toastId).toBe("upload");
  // Still carries the shared ones.
  expect(options.position).toBe("top-right");
  expect(options.transition).toBe("SlideTransition");
});

it("does not mutate the shared defaults between calls", () => {
  // A merged-in-place base object is how one caller's autoClose:false leaks
  // into every later toast.
  notify.info("first", { autoClose: false });
  notify.info("second");

  expect(toast.info.mock.calls[0][1].autoClose).toBe(false);
  expect(toast.info.mock.calls[1][1].autoClose).toBe(TOAST_MS.info);
});

it("forwards dismiss", () => {
  notify.dismiss("upload");
  expect(toast.dismiss).toHaveBeenCalledWith("upload");
});
