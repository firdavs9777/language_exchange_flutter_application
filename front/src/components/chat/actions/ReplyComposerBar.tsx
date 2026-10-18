import React from 'react';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react';

export interface ReplyComposerBarProps {
  replyingTo: any | null;
  onCancel(): void;
}

const getSenderName = (msg: any): string => {
  const sender = msg?.sender;
  if (!sender) return 'User';
  return typeof sender === 'string' ? sender : sender?.name ?? 'User';
};

const getPreviewText = (msg: any, t: (key: string, options?: any) => string): string => {
  const content: string | undefined = msg?.message ?? msg?.content ?? msg?.text;
  const type = msg?.messageType ?? msg?.type;

  // The conversation list's preview keys (chatPage.preview.*), emoji included.
  switch (type) {
    case 'image':
      return t('chatPage.preview.photo') || '\u{1F5BC}\uFE0F Photo';
    case 'voice':
      return t('chatPage.preview.voice') || '\u{1F3A4} Voice message';
    case 'video':
      return t('chatPage.preview.video') || '\u{1F3A5} Video';
    case 'file':
      return t('chatPage.preview.file') || '\u{1F4CE} File';
    default:
      return content ?? '';
  }
};

const ReplyComposerBar: React.FC<ReplyComposerBarProps> = ({ replyingTo, onCancel }) => {
  const { t } = useTranslation();
  if (!replyingTo) return null;

  return (
    <div
      data-testid="reply-composer-bar"
      className="flex items-start gap-3 border-l-4 border-indigo-400 bg-indigo-50 px-3 py-2 dark:border-indigo-500 dark:bg-indigo-950/30"
    >
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold text-indigo-700 dark:text-indigo-300">
          {t('chatPage.replyBar.replyingTo', { name: getSenderName(replyingTo) }) ||
            `Replying to ${getSenderName(replyingTo)}`}
        </p>
        <p className="truncate text-sm text-gray-600 dark:text-gray-300">
          {getPreviewText(replyingTo, t)}
        </p>
      </div>

      <button
        type="button"
        aria-label={t("chatPage.replyBar.cancel") || "Cancel reply"}
        data-testid="reply-composer-bar-cancel"
        onClick={onCancel}
        className="flex h-6 w-6 flex-none items-center justify-center rounded-full text-indigo-400 hover:bg-indigo-100 hover:text-indigo-600 dark:text-indigo-300 dark:hover:bg-indigo-900/50 dark:hover:text-indigo-100"
      >
        <X size={14} />
      </button>
    </div>
  );
};

export default ReplyComposerBar;
