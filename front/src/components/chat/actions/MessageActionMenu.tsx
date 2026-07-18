import React from 'react';
import {
  Reply,
  Forward,
  Copy,
  Pin,
  Bookmark,
  Volume2,
  Edit3,
  Trash2,
  X,
} from 'lucide-react';
import ReactionRow from './ReactionRow';
import { canEdit, canDeleteForEveryone } from '../lib/messageActions';

export interface MessageActionMenuProps {
  message: any;
  meId: string;
  onReply(): void;
  onForward(): void;
  onCopy(): void;
  onPin(): void;
  onBookmark(): void;
  onTts(): void;
  onEdit(): void;
  onDelete(): void;
  onReact(emoji: string): void;
  onClose(): void;
}

interface ActionItemProps {
  icon: React.ReactNode;
  label: string;
  tint: string;
  onClick: () => void;
  testId: string;
  danger?: boolean;
}

const ActionItem: React.FC<ActionItemProps> = ({ icon, label, tint, onClick, testId, danger }) => (
  <button
    type="button"
    data-testid={testId}
    onClick={onClick}
    className={
      'flex w-full items-center gap-3 rounded-lg px-2 py-2 text-left text-sm transition-colors ' +
      (danger
        ? 'text-red-600 hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-950/40'
        : 'text-gray-800 hover:bg-gray-100 dark:text-gray-100 dark:hover:bg-gray-800')
    }
  >
    <span
      className={
        'flex h-8 w-8 flex-none items-center justify-center rounded-full ' + tint
      }
    >
      {icon}
    </span>
    <span className="font-medium">{label}</span>
  </button>
);

const MessageActionMenu: React.FC<MessageActionMenuProps> = ({
  message,
  meId,
  onReply,
  onForward,
  onCopy,
  onPin,
  onBookmark,
  onTts,
  onEdit,
  onDelete,
  onReact,
  onClose,
}) => {
  const showEdit = canEdit(message, meId);
  const canDeleteEveryone = canDeleteForEveryone(message, meId);

  const withClose = (fn: () => void) => () => {
    fn();
    onClose();
  };

  const handleReact = (emoji: string) => {
    onReact(emoji);
    onClose();
  };

  return (
    <div
      data-testid="message-action-menu"
      className="w-64 rounded-2xl border border-gray-200 bg-white p-2 shadow-xl dark:border-gray-700 dark:bg-gray-900"
    >
      <div className="flex items-center justify-between border-b border-gray-100 px-1 pb-2 dark:border-gray-800">
        <ReactionRow
          reactions={message?.reactions}
          myUserId={meId}
          onToggle={handleReact}
          showQuickPick
        />
        <button
          type="button"
          aria-label="Close"
          data-testid="message-action-menu-close"
          onClick={onClose}
          className="flex h-6 w-6 flex-none items-center justify-center rounded-full text-gray-400 hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-800 dark:hover:text-gray-200"
        >
          <X size={14} />
        </button>
      </div>

      <div className="mt-1 flex flex-col gap-0.5">
        <ActionItem
          testId="action-reply"
          icon={<Reply size={16} className="text-blue-600 dark:text-blue-300" />}
          tint="bg-blue-100 dark:bg-blue-900/40"
          label="Reply"
          onClick={withClose(onReply)}
        />
        <ActionItem
          testId="action-copy"
          icon={<Copy size={16} className="text-slate-600 dark:text-slate-300" />}
          tint="bg-slate-100 dark:bg-slate-800"
          label="Copy"
          onClick={withClose(onCopy)}
        />
        <ActionItem
          testId="action-forward"
          icon={<Forward size={16} className="text-indigo-600 dark:text-indigo-300" />}
          tint="bg-indigo-100 dark:bg-indigo-900/40"
          label="Forward"
          onClick={withClose(onForward)}
        />
        <ActionItem
          testId="action-pin"
          icon={<Pin size={16} className="text-amber-600 dark:text-amber-300" />}
          tint="bg-amber-100 dark:bg-amber-900/40"
          label="Pin"
          onClick={withClose(onPin)}
        />
        <ActionItem
          testId="action-bookmark"
          icon={<Bookmark size={16} className="text-purple-600 dark:text-purple-300" />}
          tint="bg-purple-100 dark:bg-purple-900/40"
          label="Bookmark"
          onClick={withClose(onBookmark)}
        />
        <ActionItem
          testId="action-tts"
          icon={<Volume2 size={16} className="text-teal-600 dark:text-teal-300" />}
          tint="bg-teal-100 dark:bg-teal-900/40"
          label="Listen"
          onClick={withClose(onTts)}
        />

        {showEdit && (
          <ActionItem
            testId="action-edit"
            icon={<Edit3 size={16} className="text-emerald-600 dark:text-emerald-300" />}
            tint="bg-emerald-100 dark:bg-emerald-900/40"
            label="Edit"
            onClick={withClose(onEdit)}
          />
        )}

        <ActionItem
          testId="action-delete"
          icon={<Trash2 size={16} className="text-red-600 dark:text-red-400" />}
          tint="bg-red-100 dark:bg-red-900/40"
          label={canDeleteEveryone ? 'Delete for everyone' : 'Delete'}
          danger
          onClick={withClose(onDelete)}
        />
      </div>
    </div>
  );
};

export default MessageActionMenu;
