import React, { useCallback, useEffect, useState } from "react";
import { X } from "lucide-react";
import { isSuppressed, recordDismissal } from "./growthGate";
import { openSurface, closeSurface, isSurfaceOpen } from "./surfaceRegistry";
import StoreLink from "./StoreLink";
import brandLogo from "../../assets/logo.png";

const DWELL_MS = 20000;
const SCROLL_TRIGGER_PX = 600;

const AppDownloadPopup: React.FC = () => {
  const [open, setOpen] = useState(false);
  const [done, setDone] = useState(false);

  useEffect(() => {
    if (done) return;

    const gated = () =>
      isSuppressed("download-popup", {
        pathname: window.location.pathname,
        referrer: document.referrer,
        viewportWidth: window.innerWidth,
      });

    if (gated()) return;

    const fire = () => {
      if (!gated() && !isSurfaceOpen("announcement-popup")) setOpen(true);
    };

    const timer = window.setTimeout(fire, DWELL_MS);
    const onScroll = () => {
      if (window.scrollY > SCROLL_TRIGGER_PX) fire();
    };
    window.addEventListener("scroll", onScroll, { passive: true });

    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("scroll", onScroll);
    };
  }, [done]);

  const dismiss = useCallback(() => {
    recordDismissal("download-popup");
    setOpen(false);
    setDone(true);
  }, []);

  useEffect(() => {
    if (!open) return;

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") dismiss();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, dismiss]);

  useEffect(() => {
    if (!open) return;
    openSurface("download-popup");
    return () => closeSurface("download-popup");
  }, [open]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-4 sm:items-center">
      <div
        data-testid="download-popup"
        role="dialog"
        aria-modal="true"
        aria-labelledby="download-popup-title"
        className="relative w-full max-w-sm rounded-card bg-surface p-6 shadow-float dark:bg-cardbg-dark"
      >
        <button
          type="button"
          data-testid="download-popup-dismiss"
          onClick={dismiss}
          aria-label="Close"
          className="absolute right-3 top-3 rounded-full p-1 text-gray-400 hover:text-gray-600"
        >
          <X className="h-4 w-4" />
        </button>

        <img src={brandLogo} alt="" aria-hidden className="mx-auto h-14 w-14 rounded-2xl" />
        <h2
          id="download-popup-title"
          className="mt-2 text-lg font-extrabold text-gray-900 dark:text-gray-50"
        >
          Keep the conversation going
        </h2>
        <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
          The AI tutor, voice rooms and reels only live in the app. It's free to start.
        </p>

        <div className="mt-5 flex gap-2">
          <StoreLink
            store="ios"
            placement="popup"
            className="flex-1 rounded-full bg-brand px-4 py-2 text-center text-xs font-extrabold text-white shadow-brand"
          />
          <StoreLink
            store="android"
            placement="popup"
            className="flex-1 rounded-full bg-brand px-4 py-2 text-center text-xs font-extrabold text-white shadow-brand"
          />
        </div>
      </div>
    </div>
  );
};

export default AppDownloadPopup;
