import React, { useEffect, useRef } from "react";
import { trapTab, useBodyScrollLock } from "./dialogChrome";

export interface DialogShellProps {
  /**
   * Accessible name for the dialog. Fallback only: used as `aria-label` when
   * `labelledBy` is not given. Prefer `labelledBy`.
   */
  label?: string;
  /** id of the caller's own visible heading; used as `aria-labelledby`. */
  labelledBy?: string;
  onClose: () => void;
  children: React.ReactNode;
  /** Testid for the panel. Defaults keep a caller's existing ids available. */
  testId?: string;
  backdropTestId?: string;
  panelClassName?: string;
  containerClassName?: string;
  /** Focused on open; without one the panel takes focus. */
  initialFocusRef?: { current: HTMLElement | null };
  /**
   * Whether the soft ways out — Escape and the backdrop — close the dialog.
   * Pass `false` while a mutation is in flight: a dialog that can be dismissed
   * mid-request leaves the caller holding a promise whose result has nowhere
   * to land, so the write still happens and the error never shows. The caller
   * is expected to disable its own Cancel button at the same time.
   */
  dismissible?: boolean;
}

const DEFAULT_PANEL = [
  "relative w-full max-w-md rounded-card border border-line bg-surface p-5 shadow-lg",
  "dark:border-line-dark dark:bg-cardbg-dark",
].join(" ");

const DEFAULT_CONTAINER =
  "fixed inset-0 z-[70] flex items-center justify-center p-4";

/**
 * The shell every modal in the console shares: backdrop, Escape, initial
 * focus, focus restore, a body-scroll lock and a Tab loop that cannot wander
 * out to the page behind.
 *
 * The Tab loop and the scroll lock are `design/dialogChrome`'s — the same two
 * the profile lightbox uses directly — rather than a second copy here: two
 * overlays on one page disagreeing about what Tab does is the whole reason
 * that module exists.
 *
 * Rendered only while the dialog is open — there is no `open` prop, so mount
 * and unmount are the whole lifecycle and the Escape listener cannot outlive
 * a closed dialog.
 */
const DialogShell: React.FC<DialogShellProps> = ({
  label,
  labelledBy,
  onClose,
  children,
  testId = "dialog-shell",
  backdropTestId = "dialog-shell-backdrop",
  panelClassName = DEFAULT_PANEL,
  containerClassName = DEFAULT_CONTAINER,
  initialFocusRef,
  dismissible = true,
}) => {
  const panelRef = useRef<HTMLDivElement | null>(null);

  // The page behind the overlay does not scroll for as long as it is mounted.
  useBodyScrollLock(true);

  // Escape closes, unless the dialog is holding a request open. Bound in an
  // effect, never read during render.
  useEffect(() => {
    if (!dismissible) return undefined;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [onClose, dismissible]);

  // The keyboard follows the eye: focus lands inside the dialog on open, and
  // whatever had focus before the dialog opened (the button that triggered
  // it, almost always) gets it back once the dialog is gone -- otherwise
  // focus silently drops to <body> and a keyboard user has to find their
  // place again.
  useEffect(() => {
    const previouslyFocused = document.activeElement as HTMLElement | null;

    const nominated = initialFocusRef && initialFocusRef.current;
    if (nominated) nominated.focus();
    else if (panelRef.current) panelRef.current.focus();

    return () => {
      if (
        previouslyFocused &&
        typeof previouslyFocused.focus === "function" &&
        document.contains(previouslyFocused)
      ) {
        previouslyFocused.focus();
      }
    };
    // Once, on open/close: a later re-render must not steal focus back from
    // whatever the moderator has tabbed to.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className={containerClassName}>
      <div
        data-testid={backdropTestId}
        onClick={dismissible ? onClose : undefined}
        className="absolute inset-0 bg-ink-900/50"
      />
      <div
        ref={panelRef}
        tabIndex={-1}
        role="dialog"
        aria-modal="true"
        aria-labelledby={labelledBy}
        aria-label={labelledBy ? undefined : label}
        data-testid={testId}
        onKeyDown={(event) => trapTab(panelRef.current, event)}
        className={`${panelClassName} outline-none`}
      >
        {children}
      </div>
    </div>
  );
};

export default DialogShell;
