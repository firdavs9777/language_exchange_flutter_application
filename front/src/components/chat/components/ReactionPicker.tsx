import React from 'react';
import { QUICK_REACTIONS } from '../utils/emojiUtils';
import './ReactionPicker.scss';

interface ReactionPickerProps {
  onSelect: (emoji: string) => void;
  selectedEmoji?: string;
  onClose?: () => void;
}

const ReactionPicker: React.FC<ReactionPickerProps> = ({
  onSelect,
  selectedEmoji,
  onClose,
}) => {
  const handleSelect = (emoji: string) => {
    onSelect(emoji);
    onClose?.();
  };

  return (
    <div className="reaction-picker">
      {QUICK_REACTIONS.map((emoji) => (
        <button
          key={emoji}
          className={`reaction-btn ${selectedEmoji === emoji ? 'selected' : ''}`}
          onClick={() => handleSelect(emoji)}
          aria-label={`React with ${emoji}`}
        >
          {emoji}
        </button>
      ))}
    </div>
  );
};

export default ReactionPicker;
