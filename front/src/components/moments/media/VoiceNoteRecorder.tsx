import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Mic, Square, X } from 'lucide-react';

interface VoiceNoteRecorderProps {
  maxSeconds?: number;
  onComplete: (blob: Blob, durationSec: number, waveform: number[]) => void;
  onCancel?: () => void;
}

type RecorderStatus = 'idle' | 'requesting' | 'recording' | 'unsupported' | 'denied' | 'error';

const WAVEFORM_SAMPLES = 40;
const LIVE_LEVEL_BARS = 24;

const formatTime = (seconds: number): string => {
  const totalSeconds = Math.max(0, Math.floor(seconds));
  const mins = Math.floor(totalSeconds / 60);
  const secs = totalSeconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

const isRecordingSupported = (): boolean => {
  return (
    typeof navigator !== 'undefined' &&
    !!navigator.mediaDevices &&
    typeof navigator.mediaDevices.getUserMedia === 'function' &&
    typeof window !== 'undefined' &&
    typeof (window as any).MediaRecorder !== 'undefined'
  );
};

/**
 * Downsample a decoded AudioBuffer into a small array of normalized
 * amplitude samples (0..1), suitable for a compact waveform visualization.
 */
const computeWaveformFromAudioBuffer = (
  buffer: AudioBuffer,
  sampleCount: number = WAVEFORM_SAMPLES
): number[] => {
  const channelData = buffer.getChannelData(0);
  const blockSize = Math.max(1, Math.floor(channelData.length / sampleCount));
  const samples: number[] = [];

  for (let i = 0; i < sampleCount; i++) {
    const start = i * blockSize;
    const end = Math.min(channelData.length, start + blockSize);
    let sum = 0;
    let count = 0;
    for (let j = start; j < end; j++) {
      sum += Math.abs(channelData[j]);
      count++;
    }
    samples.push(count > 0 ? sum / count : 0);
  }

  const max = Math.max(...samples, 0.0001);
  return samples.map((v) => Math.min(1, v / max));
};

const VoiceNoteRecorder: React.FC<VoiceNoteRecorderProps> = ({
  maxSeconds = 60,
  onComplete,
  onCancel,
}) => {
  const [status, setStatus] = useState<RecorderStatus>('idle');
  const [elapsed, setElapsed] = useState(0);
  const [liveLevels, setLiveLevels] = useState<number[]>(Array(LIVE_LEVEL_BARS).fill(0.1));

  const streamRef = useRef<MediaStream | null>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const levelIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const startedAtRef = useRef<number>(0);
  const stoppedRef = useRef(false);
  const elapsedRef = useRef(0);

  const cleanupStream = useCallback(() => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (levelIntervalRef.current) {
      clearInterval(levelIntervalRef.current);
      levelIntervalRef.current = null;
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }
    if (audioContextRef.current) {
      audioContextRef.current.close().catch(() => undefined);
      audioContextRef.current = null;
    }
    analyserRef.current = null;
  }, []);

  const sampleLevel = useCallback(() => {
    const analyser = analyserRef.current;
    if (!analyser) return;
    const data = new Uint8Array(analyser.fftSize);
    analyser.getByteTimeDomainData(data);
    let sumSquares = 0;
    for (let i = 0; i < data.length; i++) {
      const centered = (data[i] - 128) / 128;
      sumSquares += centered * centered;
    }
    const rms = Math.sqrt(sumSquares / data.length);
    setLiveLevels((prev) => [...prev.slice(1), Math.min(1, Math.max(0.05, rms * 4))]);
  }, []);

  const finishRecording = useCallback(
    async (cancelled: boolean) => {
      if (stoppedRef.current) return;
      stoppedRef.current = true;

      const recorder = mediaRecorderRef.current;
      const durationSec = elapsedRef.current;

      if (!recorder || cancelled) {
        cleanupStream();
        if (cancelled) {
          onCancel?.();
        }
        return;
      }

      const blob = await new Promise<Blob>((resolve) => {
        recorder.onstop = () => {
          resolve(new Blob(chunksRef.current, { type: recorder.mimeType || 'audio/webm' }));
        };
        if (recorder.state !== 'inactive') {
          recorder.stop();
        } else {
          resolve(new Blob(chunksRef.current, { type: 'audio/webm' }));
        }
      });

      cleanupStream();

      if (durationSec <= 0 || blob.size === 0) {
        onCancel?.();
        return;
      }

      let waveform: number[] = [];
      try {
        const arrayBuffer = await blob.arrayBuffer();
        const AudioContextCtor =
          (window as any).AudioContext || (window as any).webkitAudioContext;
        if (AudioContextCtor) {
          const decodeCtx: AudioContext = new AudioContextCtor();
          const decoded = await decodeCtx.decodeAudioData(arrayBuffer.slice(0));
          waveform = computeWaveformFromAudioBuffer(decoded);
          decodeCtx.close().catch(() => undefined);
        }
      } catch {
        waveform = [];
      }

      onComplete(blob, durationSec, waveform);
    },
    [onCancel, onComplete, cleanupStream]
  );

  const startRecording = useCallback(async () => {
    if (!isRecordingSupported()) {
      setStatus('unsupported');
      onCancel?.();
      return;
    }

    setStatus('requesting');
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;

      const AudioContextCtor =
        (window as any).AudioContext || (window as any).webkitAudioContext;
      if (AudioContextCtor) {
        const audioContext: AudioContext = new AudioContextCtor();
        const source = audioContext.createMediaStreamSource(stream);
        const analyser = audioContext.createAnalyser();
        analyser.fftSize = 512;
        source.connect(analyser);
        audioContextRef.current = audioContext;
        analyserRef.current = analyser;
        levelIntervalRef.current = setInterval(sampleLevel, 100);
      }

      const recorder = new MediaRecorder(stream);
      mediaRecorderRef.current = recorder;
      chunksRef.current = [];
      stoppedRef.current = false;

      recorder.ondataavailable = (e: BlobEvent) => {
        if (e.data.size > 0) {
          chunksRef.current.push(e.data);
        }
      };

      recorder.start(100);
      startedAtRef.current = Date.now();
      setStatus('recording');
      setElapsed(0);

      timerRef.current = setInterval(() => {
        setElapsed((prev) => {
          const next = prev + 1;
          elapsedRef.current = next;
          if (next >= maxSeconds) {
            finishRecording(false);
          }
          return next;
        });
      }, 1000);
    } catch (err) {
      setStatus('denied');
      cleanupStream();
      onCancel?.();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    startRecording();
    return () => {
      cleanupStream();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleStop = () => {
    finishRecording(false);
  };

  const handleCancel = () => {
    finishRecording(true);
  };

  if (status === 'unsupported') {
    return (
      <div
        data-testid="voice-note-recorder-unsupported"
        className="flex items-center justify-between gap-3 rounded-lg bg-gray-100 px-4 py-3 text-sm text-gray-700 dark:bg-gray-800 dark:text-gray-300"
      >
        <span>Voice recording is not supported in this browser.</span>
      </div>
    );
  }

  if (status === 'denied' || status === 'error') {
    return (
      <div
        data-testid="voice-note-recorder-denied"
        className="flex items-center justify-between gap-3 rounded-lg bg-gray-100 px-4 py-3 text-sm text-gray-700 dark:bg-gray-800 dark:text-gray-300"
      >
        <span>Microphone access was denied. Please allow microphone access to record a voice note.</span>
      </div>
    );
  }

  return (
    <div
      data-testid="voice-note-recorder"
      className="flex items-center gap-3 rounded-full bg-gray-100 px-3 py-2 dark:bg-gray-800"
    >
      <button
        type="button"
        onClick={handleCancel}
        aria-label="Cancel recording"
        data-testid="voice-note-recorder-cancel"
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gray-300 text-gray-700 transition-colors hover:bg-gray-400 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600"
      >
        <X size={16} />
      </button>

      <div className="flex flex-1 items-center gap-2">
        <span
          className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full ${
            status === 'recording' ? 'bg-red-500 text-white animate-pulse' : 'bg-gray-300 text-gray-600'
          }`}
          data-testid="voice-note-recorder-indicator"
        >
          <Mic size={16} />
        </span>

        <div
          className="flex h-8 flex-1 items-center gap-[2px]"
          data-testid="voice-note-recorder-live-waveform"
          aria-hidden="true"
        >
          {liveLevels.map((level, i) => (
            <span
              key={i}
              className="w-full min-w-[2px] rounded-full bg-amber-500 dark:bg-amber-400"
              style={{ height: `${Math.round(level * 100)}%` }}
            />
          ))}
        </div>

        <span
          className="shrink-0 text-xs font-medium tabular-nums text-gray-600 dark:text-gray-300"
          data-testid="voice-note-recorder-time"
        >
          {formatTime(elapsed)} / {formatTime(maxSeconds)}
        </span>
      </div>

      <button
        type="button"
        onClick={handleStop}
        aria-label="Stop recording and send"
        data-testid="voice-note-recorder-stop"
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-amber-500 text-white shadow transition-colors hover:bg-amber-600 dark:bg-amber-600 dark:hover:bg-amber-500"
      >
        <Square size={14} fill="currentColor" />
      </button>
    </div>
  );
};

export default VoiceNoteRecorder;
