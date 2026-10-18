/**
 * One way to raise a notification popup.
 *
 * Today there are ~113 `toast.*()` calls across 35 files and each one carries
 * its own options object — the same four keys, copied, with the durations
 * drifting (2000 here, 3000 there, 5000 somewhere else) and `theme: "dark"`
 * hardcoded at 73 of them even though the app follows the OS colour scheme.
 * That is not a style choice repeated 113 times; it is a default that was
 * never given a home.
 *
 * This is that home. `notify.success("Saved")` is the whole call. Durations
 * come from the one place below, so "how long does a toast stay up" is a
 * decision the codebase makes once.
 *
 * Existing `toast.*` calls keep working untouched — src/design/toastTheme.css
 * restyles every toast regardless of how it was raised, so nothing had to be
 * swept to make the popups look right. Use this for new code, and swap old
 * call sites over when you are already editing them.
 *
 * No `theme` is passed at all: the stylesheet points both of toastify's theme
 * classes at one palette chosen by `prefers-color-scheme`, so naming a theme
 * here would be noise that cannot affect the result.
 *
 * NOTE ON IMPORTS: only runtime values are imported from "react-toastify".
 * This repo pins typescript@3.7.2 and compiles through Babel, which strips
 * types per-file and cannot always tell an interface from a value — importing
 * `ToastOptions` here is exactly the pattern that makes webpack fail to
 * resolve a runtime re-export (see the note in src/design/index.ts). The
 * options bag is typed structurally below instead.
 */
import { toast, Slide } from "react-toastify";

/** Structural stand-in for toastify's ToastOptions, kept local on purpose. */
export interface NotifyOptions {
  autoClose?: number | false;
  position?: string;
  hideProgressBar?: boolean;
  closeOnClick?: boolean;
  pauseOnHover?: boolean;
  pauseOnFocusLoss?: boolean;
  draggable?: boolean;
  toastId?: string | number;
  onClose?: () => void;
  [key: string]: any;
}

/**
 * How long each kind of message stays up.
 *
 * An error outlives a success because it is the one the reader has to act on,
 * and because it usually arrives when their attention is somewhere else.
 * Anything the user must acknowledge does not belong in a toast at all — that
 * is what ConfirmDialog is for.
 */
export const TOAST_MS = {
  success: 2600,
  info: 3200,
  warning: 4200,
  error: 5000,
};

/**
 * Slide, not Bounce. A bounce overshoots and settles, which reads as playful
 * the first time and as jitter by the twentieth — and these fire on every
 * save. Slide is the quieter of the two and matches the drawers.
 */
const BASE: NotifyOptions = {
  position: "top-right",
  transition: Slide,
  hideProgressBar: false,
  closeOnClick: true,
  pauseOnHover: true,
  pauseOnFocusLoss: true,
  draggable: true,
};

const withDefaults = (autoClose: number, options?: NotifyOptions): NotifyOptions => ({
  ...BASE,
  autoClose,
  ...(options || {}),
});

const notify = {
  success: (message: any, options?: NotifyOptions) =>
    toast.success(message, withDefaults(TOAST_MS.success, options) as any),
  error: (message: any, options?: NotifyOptions) =>
    toast.error(message, withDefaults(TOAST_MS.error, options) as any),
  info: (message: any, options?: NotifyOptions) =>
    toast.info(message, withDefaults(TOAST_MS.info, options) as any),
  warning: (message: any, options?: NotifyOptions) =>
    toast.warning(message, withDefaults(TOAST_MS.warning, options) as any),
  /** Escape hatch for the rare toast that is none of the four. */
  show: (message: any, options?: NotifyOptions) =>
    toast(message, withDefaults(TOAST_MS.info, options) as any),
  dismiss: (id?: string | number) => toast.dismiss(id as any),
};

export default notify;
