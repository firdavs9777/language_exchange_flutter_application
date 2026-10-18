import React, { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { FaChevronDown, FaChevronUp, FaPlay, FaTimes, FaVolumeMute, FaVolumeUp } from "react-icons/fa";
import { useMomentViews } from "../moments/useMomentViews";
import { Reel } from "./lib/reelModel";

// Browsers autoplay only muted video, so every session starts muted; once the
// user unmutes, later reels keep sound for the rest of the page session.
let sessionMuted = true;
export function _resetReelMuteForTests() {
  sessionMuted = true;
}

const WHEEL_LOCK_MS = 450;
const SWIPE_MIN_PX = 60;

export interface ReelViewerProps {
  reels: Reel[];
  index: number;
  hasMore: boolean;
  onIndexChange(next: number): void;
  onNeedMore(): void;
  onClose(): void;
  renderActions?: (reel: Reel) => React.ReactNode;
}

const ReelSlide: React.FC<{ reel: Reel; muted: boolean; children?: React.ReactNode }> = ({ reel, muted, children }) => {
  const { t } = useTranslation();
  const videoRef = useRef<HTMLVideoElement>(null);
  const [blocked, setBlocked] = useState(false);
  const viewRef = useMomentViews({ momentId: reel.id, isLoggedIn: true });

  const play = useCallback(() => {
    const el = videoRef.current;
    if (!el) return;
    let result: any;
    try {
      result = el.play();
    } catch (e) {
      setBlocked(true);
      return;
    }
    if (result && typeof result.then === "function") {
      result.then(
        () => setBlocked(false),
        () => setBlocked(true)
      );
    }
  }, []);

  useEffect(() => {
    play();
    const el = videoRef.current;
    return () => {
      if (el) el.pause();
    };
  }, [reel.id, play]);

  useEffect(() => {
    if (videoRef.current) videoRef.current.muted = muted;
  }, [muted]);

  return (
    <div className="reel-slide" data-testid={`reel-slide-${reel.id}`} ref={viewRef}>
      <video
        key={reel.id}
        ref={videoRef}
        data-testid="reel-video"
        className={`reel-video ${reel.portrait ? "" : "reel-video-landscape"}`}
        src={reel.videoUrl}
        poster={reel.thumbnail || undefined}
        muted={muted}
        loop
        playsInline
        preload="auto"
        onClick={() => {
          const el = videoRef.current;
          if (el && !el.paused) el.pause();
          else play();
        }}
      />
      {blocked && (
        <button type="button" className="reel-tap-to-play" data-testid="reel-tap-to-play" onClick={play}>
          <FaPlay aria-hidden="true" />
          <span>{t("reels.viewer.tap_to_play") || "Tap to play"}</span>
        </button>
      )}
      <div className="reel-caption">
        <div className="reel-author">{reel.author.name}</div>
        {reel.description && <p className="reel-description">{reel.description}</p>}
      </div>
      {children && <div className="reel-rail">{children}</div>}
    </div>
  );
};

/**
 * Full-screen vertical reel player (the app's reels_feed_screen.dart). One
 * <video> element at a time -- the active reel -- so nothing plays in the
 * background and a slow connection downloads one stream, not five.
 */
const ReelViewer: React.FC<ReelViewerProps> = ({
  reels,
  index,
  hasMore,
  onIndexChange,
  onNeedMore,
  onClose,
  renderActions,
}) => {
  const { t } = useTranslation();
  const [muted, setMuted] = useState(sessionMuted);
  const lastWheel = useRef(0);
  const touchStartY = useRef<number | null>(null);
  const reel = reels[index];

  const go = useCallback(
    (delta: number) => {
      const next = index + delta;
      if (next < 0 || next >= reels.length) return;
      onIndexChange(next);
    },
    [index, reels.length, onIndexChange]
  );

  useEffect(() => {
    if (hasMore && index >= reels.length - 3) onNeedMore();
  }, [index, reels.length, hasMore, onNeedMore]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      if (target && (target.tagName === "INPUT" || target.tagName === "TEXTAREA" || target.isContentEditable)) return;
      if (e.key === "ArrowDown" || e.key === "j") go(1);
      else if (e.key === "ArrowUp" || e.key === "k") go(-1);
      else if (e.key === "Escape") onClose();
      else if (e.key === "m") toggleMute();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [go, onClose]);

  // Lock page scroll behind the overlay.
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  function toggleMute() {
    setMuted((m) => {
      sessionMuted = !m;
      return !m;
    });
  }

  if (!reel) return null;

  return (
    <div
      className="reel-viewer"
      role="dialog"
      aria-modal="true"
      aria-label={t("reels.viewer.label") || "Reels"}
      data-testid="reel-viewer"
      onWheel={(e) => {
        const now = Date.now();
        if (Math.abs(e.deltaY) < 30 || now - lastWheel.current < WHEEL_LOCK_MS) return;
        lastWheel.current = now;
        go(e.deltaY > 0 ? 1 : -1);
      }}
      onTouchStart={(e) => {
        touchStartY.current = e.touches && e.touches[0] ? e.touches[0].clientY : null;
      }}
      onTouchEnd={(e) => {
        const start = touchStartY.current;
        const end = e.changedTouches && e.changedTouches[0] ? e.changedTouches[0].clientY : null;
        touchStartY.current = null;
        if (start === null || end === null || Math.abs(start - end) < SWIPE_MIN_PX) return;
        go(start > end ? 1 : -1);
      }}
    >
      <ReelSlide key={reel.id} reel={reel} muted={muted}>
        {renderActions ? renderActions(reel) : null}
      </ReelSlide>

      <button type="button" className="reel-icon-btn reel-close" data-testid="reel-close" onClick={onClose}
        aria-label={t("reels.viewer.close") || "Close"}>
        <FaTimes aria-hidden="true" />
      </button>
      <button type="button" className="reel-icon-btn reel-mute" data-testid="reel-mute" onClick={toggleMute}
        aria-label={muted ? t("reels.viewer.unmute") || "Unmute" : t("reels.viewer.mute") || "Mute"}>
        {muted ? <FaVolumeMute aria-hidden="true" /> : <FaVolumeUp aria-hidden="true" />}
      </button>
      <div className="reel-nav">
        <button type="button" className="reel-icon-btn" data-testid="reel-prev" disabled={index === 0}
          onClick={() => go(-1)} aria-label={t("reels.viewer.previous") || "Previous reel"}>
          <FaChevronUp aria-hidden="true" />
        </button>
        <button type="button" className="reel-icon-btn" data-testid="reel-next" disabled={index >= reels.length - 1}
          onClick={() => go(1)} aria-label={t("reels.viewer.next") || "Next reel"}>
          <FaChevronDown aria-hidden="true" />
        </button>
      </div>
    </div>
  );
};

export default ReelViewer;
