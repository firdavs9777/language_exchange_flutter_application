import React from 'react';
import { Pin, X } from 'lucide-react';

export interface PinnedBarProps {
  pinned: any[];
  onJump(messageId: string): void;
  onUnpin(messageId: string): void;
}

// `pinned` items are Message documents themselves (Message.pinned is a flag
// on the message, unlike bookmarks which wrap a message in a separate
// subdocument) — so text lives directly on `message`/`content`/`text`.
const getMessageId = (msg: any): string => msg?._id ?? msg?.messageId ?? '';

const getPreviewText = (msg: any): string => {
  const content: string | undefined = msg?.message ?? msg?.content ?? msg?.text;
  const type = msg?.messageType ?? msg?.type;

  switch (type) {
    case 'image':
      return '📷 Photo';
    case 'voice':
      return '🎤 Voice message';
    case 'video':
      return '🎬 Video';
    case 'file':
      return '📎 File';
    default:
      return content ?? '';
  }
};

const PinnedBar: React.FC<PinnedBarProps> = ({ pinned, onJump, onUnpin }) => {
  if (!pinned || pinned.length === 0) return null;

  const [first, ...rest] = pinned;
  const firstId = getMessageId(first);

  return (
    <div
      data-testid="pinned-bar"
      className="flex items-center gap-2 border-b border-teal-100 bg-teal-50 px-3 py-2 text-sm dark:border-teal-900/40 dark:bg-teal-950/30"
    >
      <Pin size={14} className="flex-none text-teal-600 dark:text-teal-400" />

      <button
        type="button"
        data-testid="pinned-bar-jump"
        onClick={() => onJump(firstId)}
        className="flex min-w-0 flex-1 items-center gap-2 text-left"
      >
        <span className="truncate text-teal-800 dark:text-teal-200">{getPreviewText(first)}</span>
        {rest.length > 0 && (
          <span className="flex-none rounded-full bg-teal-100 px-2 py-0.5 text-xs font-medium text-teal-700 dark:bg-teal-900/50 dark:text-teal-300">
            {pinned.length} pinned
          </span>
        )}
      </button>

      <button
        type="button"
        aria-label="Unpin message"
        data-testid="pinned-bar-unpin"
        onClick={() => onUnpin(firstId)}
        className="flex h-6 w-6 flex-none items-center justify-center rounded-full text-teal-500 hover:bg-teal-100 hover:text-teal-700 dark:text-teal-400 dark:hover:bg-teal-900/50 dark:hover:text-teal-200"
      >
        <X size={14} />
      </button>
    </div>
  );
};

export default PinnedBar;
