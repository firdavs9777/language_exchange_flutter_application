import React, { useEffect, useRef, useState } from 'react';
import { Play, Pause } from 'lucide-react';

interface VoiceNotePlayerProps {
  audio: {
    url: string;
    duration: number;
    waveform: number[];
  };
  className?: string;
}

const FALLBACK_BAR_COUNT = 24;

const formatTime = (seconds?: number): string => {
  if (seconds === undefined || seconds === null || Number.isNaN(seconds) || seconds < 0) {
    return '0:00';
  }
  const totalSeconds = Math.floor(seconds);
  const mins = Math.floor(totalSeconds / 60);
  const secs = totalSeconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

const normalizeBars = (waveform: number[]): number[] => {
  if (!waveform || waveform.length === 0) {
    return Array(FALLBACK_BAR_COUNT).fill(0.2);
  }
  const max = Math.max(...waveform, 0.0001);
  return waveform.map((v) => {
    const normalized = max > 0 ? v / max : 0;
    return Math.min(1, Math.max(0.08, normalized));
  });
};

const VoiceNotePlayer: React.FC<VoiceNotePlayerProps> = ({ audio, className = '' }) => {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [totalDuration, setTotalDuration] = useState(audio.duration || 0);

  useEffect(() => {
    const el = audioRef.current;
    if (!el) return undefined;

    const handleTimeUpdate = () => setCurrentTime(el.currentTime);
    const handleLoadedMetadata = () => {
      if (el.duration && Number.isFinite(el.duration)) {
        setTotalDuration(el.duration);
      }
    };
    const handleEnded = () => {
      setIsPlaying(false);
      setCurrentTime(0);
    };

    el.addEventListener('timeupdate', handleTimeUpdate);
    el.addEventListener('loadedmetadata', handleLoadedMetadata);
    el.addEventListener('ended', handleEnded);

    return () => {
      el.removeEventListener('timeupdate', handleTimeUpdate);
      el.removeEventListener('loadedmetadata', handleLoadedMetadata);
      el.removeEventListener('ended', handleEnded);
    };
  }, []);

  const handleTogglePlay = () => {
    const el = audioRef.current;
    if (!el) return;
    if (isPlaying) {
      el.pause();
      setIsPlaying(false);
    } else {
      el.play();
      setIsPlaying(true);
    }
  };

  const bars = normalizeBars(audio.waveform);
  const duration = totalDuration || audio.duration || 0;
  const progressRatio = duration > 0 ? Math.min(1, currentTime / duration) : 0;
  const activeBarCount = Math.round(progressRatio * bars.length);

  return (
    <div
      className={`flex w-full items-center gap-3 rounded-full bg-gray-100 px-3 py-2 dark:bg-gray-800 ${className}`}
      data-testid="voice-note-player"
    >
      <audio ref={audioRef} src={audio.url} preload="metadata" data-testid="voice-note-audio" />

      <button
        type="button"
        onClick={handleTogglePlay}
        aria-label={isPlaying ? 'Pause voice note' : 'Play voice note'}
        data-testid="voice-note-play-button"
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-amber-500 text-white shadow transition-colors hover:bg-amber-600 dark:bg-amber-600 dark:hover:bg-amber-500"
      >
        {isPlaying ? <Pause size={16} fill="currentColor" /> : <Play size={16} fill="currentColor" className="ml-0.5" />}
      </button>

      <div
        className="flex h-8 flex-1 items-center gap-[2px]"
        data-testid="voice-note-waveform"
        aria-hidden="true"
      >
        {bars.map((height, i) => (
          <span
            key={i}
            data-testid="voice-note-waveform-bar"
            className={`w-full min-w-[2px] rounded-full transition-colors ${
              i < activeBarCount
                ? 'bg-amber-500 dark:bg-amber-400'
                : 'bg-gray-300 dark:bg-gray-600'
            }`}
            style={{ height: `${Math.round(height * 100)}%` }}
          />
        ))}
      </div>

      <span
        className="shrink-0 text-xs font-medium tabular-nums text-gray-600 dark:text-gray-300"
        data-testid="voice-note-time"
      >
        {formatTime(isPlaying || currentTime > 0 ? currentTime : duration)} / {formatTime(duration)}
      </span>
    </div>
  );
};

export default VoiceNotePlayer;
