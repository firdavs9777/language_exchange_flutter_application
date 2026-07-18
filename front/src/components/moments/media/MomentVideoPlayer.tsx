import React, { useRef, useState } from 'react';
import { Play } from 'lucide-react';

interface MomentVideoPlayerProps {
  video: {
    url: string;
    thumbnail?: string;
    duration?: number;
    width?: number;
    height?: number;
  };
  className?: string;
}

const formatDuration = (seconds?: number): string | null => {
  if (seconds === undefined || seconds === null || Number.isNaN(seconds) || seconds < 0) {
    return null;
  }
  const totalSeconds = Math.floor(seconds);
  const mins = Math.floor(totalSeconds / 60);
  const secs = totalSeconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

const MomentVideoPlayer: React.FC<MomentVideoPlayerProps> = ({ video, className = '' }) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [hasStarted, setHasStarted] = useState(false);

  const durationLabel = formatDuration(video.duration);

  const handleTogglePlay = () => {
    const el = videoRef.current;
    if (!el) return;
    if (el.paused) {
      el.play();
    } else {
      el.pause();
    }
  };

  return (
    <div
      className={`relative w-full max-h-[420px] overflow-hidden rounded-lg bg-black ${className}`}
      data-testid="moment-video-player"
    >
      <video
        ref={videoRef}
        src={video.url}
        poster={video.thumbnail}
        controls
        preload="metadata"
        playsInline
        className="block max-h-[420px] w-full rounded-lg object-contain"
        onPlay={() => {
          setIsPlaying(true);
          setHasStarted(true);
        }}
        onPause={() => setIsPlaying(false)}
        onClick={handleTogglePlay}
        data-testid="moment-video-element"
      />

      {!isPlaying && (
        <button
          type="button"
          onClick={handleTogglePlay}
          aria-label={hasStarted ? 'Resume video' : 'Play video'}
          data-testid="moment-video-play-overlay"
          className="absolute inset-0 flex items-center justify-center bg-black/20 transition-colors hover:bg-black/30 dark:bg-black/30 dark:hover:bg-black/40"
        >
          <span className="flex h-14 w-14 items-center justify-center rounded-full bg-white/90 text-gray-900 shadow-lg dark:bg-gray-900/80 dark:text-white">
            <Play size={28} fill="currentColor" className="ml-1" />
          </span>
        </button>
      )}

      {durationLabel && !isPlaying && (
        <span
          data-testid="moment-video-duration-badge"
          className="absolute bottom-2 right-2 rounded bg-black/70 px-1.5 py-0.5 text-xs font-medium text-white"
        >
          {durationLabel}
        </span>
      )}
    </div>
  );
};

export default MomentVideoPlayer;
