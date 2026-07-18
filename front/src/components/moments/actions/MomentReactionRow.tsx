import React from 'react';
import { aggregateReactions } from '../../chat/actions/ReactionRow';

const MOMENT_QUICK_REACTIONS = ['❤️', '🔥', '😂', '😢', '😮', '👏'];

interface MomentReactionRowProps {
  reactions: any;
  myUserId: string;
  onToggle: (emoji: string) => void;
  showQuickPick?: boolean;
}

const MomentReactionRow: React.FC<MomentReactionRowProps> = ({
  reactions,
  myUserId,
  onToggle,
  showQuickPick = false,
}) => {
  const aggregated = aggregateReactions(reactions, myUserId);

  if (aggregated.length === 0 && !showQuickPick) return null;

  return (
    <div className="flex flex-wrap items-center gap-1">
      {aggregated.map(({ emoji, count, reactedByMe }) => (
        <button
          key={emoji}
          type="button"
          data-testid={`moment-reaction-chip-${emoji}`}
          aria-pressed={reactedByMe}
          onClick={() => onToggle(emoji)}
          className={
            'flex items-center gap-1 rounded-full border px-2 py-0.5 text-xs transition-colors ' +
            (reactedByMe
              ? 'border-teal-400 bg-teal-100 text-teal-800 dark:border-teal-500 dark:bg-teal-900/40 dark:text-teal-200'
              : 'border-gray-200 bg-gray-100 text-gray-700 hover:bg-gray-200 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700')
          }
        >
          <span>{emoji}</span>
          <span>{count}</span>
        </button>
      ))}

      {showQuickPick && (
        <div className="flex items-center gap-1 rounded-full bg-gray-100 px-1 py-0.5 dark:bg-gray-800">
          {MOMENT_QUICK_REACTIONS.map((emoji) => (
            <button
              key={emoji}
              type="button"
              data-testid={`moment-quick-pick-${emoji}`}
              onClick={() => onToggle(emoji)}
              className="rounded-full px-1 text-sm hover:bg-gray-200 dark:hover:bg-gray-700"
            >
              {emoji}
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

export default MomentReactionRow;
