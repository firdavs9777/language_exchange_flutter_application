import React, { useState, useRef, useEffect } from 'react';
import { Paperclip, Image, Mic, Send, Smile, X } from 'lucide-react';
import VoiceRecorder from './VoiceRecorder';
import EmojiPicker from './EmojiPicker';
import './MessageInput.scss';

interface MessageInputProps {
  onSendMessage: (content: string, type?: 'text') => void;
  onSendVoice: (blob: Blob, duration: number) => void;
  onSendMedia: (file: File, type: 'image' | 'video' | 'file') => void;
  onTyping: () => void;
  onStopTyping: () => void;
  editingMessage?: any;
  onCancelEdit: () => void;
  onConfirmEdit: (messageId: string, content: string) => void;
  placeholder?: string;
}

const MessageInput: React.FC<MessageInputProps> = ({
  onSendMessage,
  onSendVoice,
  onSendMedia,
  onTyping,
  onStopTyping,
  editingMessage,
  onCancelEdit,
  onConfirmEdit,
  placeholder = 'Type a message...',
}) => {
  const [message, setMessage] = useState('');
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const imageInputRef = useRef<HTMLInputElement>(null);

  // Set edit message content
  useEffect(() => {
    if (editingMessage) {
      setMessage(editingMessage.content || editingMessage.message || '');
      inputRef.current?.focus();
    }
  }, [editingMessage]);

  // Auto-resize textarea
  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.style.height = 'auto';
      inputRef.current.style.height = `${Math.min(inputRef.current.scrollHeight, 120)}px`;
    }
  }, [message]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!message.trim()) return;

    if (editingMessage) {
      onConfirmEdit(editingMessage._id, message);
    } else {
      onSendMessage(message, 'text');
    }
    setMessage('');
    setShowEmojiPicker(false);
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setMessage(e.target.value);
    onTyping();
  };

  const handleBlur = () => {
    onStopTyping();
  };

  const handleEmojiSelect = (emoji: string) => {
    setMessage(prev => prev + emoji);
    inputRef.current?.focus();
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>, type: 'image' | 'file') => {
    const file = e.target.files?.[0];
    if (file) {
      const fileType = file.type.startsWith('video/') ? 'video' : type;
      onSendMedia(file, fileType as 'image' | 'video' | 'file');
    }
    e.target.value = '';
  };

  const handleVoiceComplete = (blob: Blob, duration: number) => {
    onSendVoice(blob, duration);
    setIsRecording(false);
  };

  return (
    <div className="message-input-container">
      {/* Edit Mode Header */}
      {editingMessage && (
        <div className="edit-mode-header">
          <span>Editing message</span>
          <button onClick={onCancelEdit}>
            <X size={16} /> Cancel
          </button>
        </div>
      )}

      {/* Emoji Picker */}
      {showEmojiPicker && (
        <EmojiPicker
          onSelect={handleEmojiSelect}
          onClose={() => setShowEmojiPicker(false)}
        />
      )}

      <form onSubmit={handleSubmit} className="message-form">
        {/* Attachment Buttons */}
        {!isRecording && (
          <div className="attachment-buttons">
            <button
              type="button"
              className="attach-btn"
              onClick={() => fileInputRef.current?.click()}
              aria-label="Attach file"
            >
              <Paperclip size={20} />
            </button>
            <button
              type="button"
              className="image-btn"
              onClick={() => imageInputRef.current?.click()}
              aria-label="Attach image"
            >
              <Image size={20} />
            </button>
          </div>
        )}

        {/* Hidden File Inputs */}
        <input
          type="file"
          ref={fileInputRef}
          hidden
          onChange={(e) => handleFileSelect(e, 'file')}
        />
        <input
          type="file"
          ref={imageInputRef}
          accept="image/*,video/*"
          hidden
          onChange={(e) => handleFileSelect(e, 'image')}
        />

        {/* Voice Recorder or Text Input */}
        {isRecording ? (
          <VoiceRecorder
            onComplete={handleVoiceComplete}
            onCancel={() => setIsRecording(false)}
          />
        ) : (
          <>
            {/* Text Input */}
            <div className="input-wrapper">
              <textarea
                ref={inputRef}
                value={message}
                onChange={handleChange}
                onKeyPress={handleKeyPress}
                onBlur={handleBlur}
                placeholder={placeholder}
                rows={1}
              />
              <button
                type="button"
                className="emoji-btn"
                onClick={() => setShowEmojiPicker(!showEmojiPicker)}
                aria-label="Add emoji"
              >
                <Smile size={20} />
              </button>
            </div>

            {/* Voice or Send Button */}
            {message.trim() ? (
              <button
                type="submit"
                className="send-btn active"
                aria-label="Send message"
              >
                <Send size={20} />
              </button>
            ) : (
              <button
                type="button"
                className="voice-btn"
                onClick={() => setIsRecording(true)}
                aria-label="Record voice message"
              >
                <Mic size={20} />
              </button>
            )}
          </>
        )}
      </form>
    </div>
  );
};

export default MessageInput;
