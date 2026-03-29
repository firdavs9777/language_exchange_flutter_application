import React, { useEffect } from 'react';
import { Mic, Square, Trash2, Send } from 'lucide-react';
import { useVoiceRecorder } from '../hooks/useVoiceRecorder';
import { formatVoiceDuration } from '../utils/messageFormatter';
import './VoiceRecorder.scss';

interface VoiceRecorderProps {
  onComplete: (blob: Blob, duration: number) => void;
  onCancel: () => void;
  maxDuration?: number;
}

const VoiceRecorder: React.FC<VoiceRecorderProps> = ({
  onComplete,
  onCancel,
  maxDuration = 60,
}) => {
  const {
    isRecording,
    duration,
    startRecording,
    stopRecording,
    cancelRecording,
  } = useVoiceRecorder(maxDuration);

  useEffect(() => {
    startRecording();
  }, []);

  const handleStop = async () => {
    const blob = await stopRecording();
    if (blob && duration > 0) {
      onComplete(blob, duration);
    } else {
      onCancel();
    }
  };

  const handleCancel = () => {
    cancelRecording();
    onCancel();
  };

  return (
    <div className="voice-recorder">
      <button className="cancel-btn" onClick={handleCancel} aria-label="Cancel recording">
        <Trash2 size={20} />
      </button>

      <div className="recording-info">
        <div className={`recording-indicator ${isRecording ? 'active' : ''}`}>
          <Mic size={20} />
        </div>
        <span className="recording-duration">{formatVoiceDuration(duration)}</span>
        <div className="recording-wave">
          {[...Array(12)].map((_, i) => (
            <div
              key={i}
              className="wave-bar"
              style={{
                animationDelay: `${i * 0.1}s`,
                height: `${Math.random() * 20 + 10}px`,
              }}
            />
          ))}
        </div>
      </div>

      <button className="send-btn" onClick={handleStop} aria-label="Send voice message">
        <Send size={20} />
      </button>
    </div>
  );
};

export default VoiceRecorder;
