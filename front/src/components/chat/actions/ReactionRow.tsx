import React from 'react';
import { QUICK_REACTIONS } from '../lib/messageActions';

interface RawReaction {
  emoji: string;
  user?: string | { _id: string; name?: string; images?: string[] };
  users?: Array<string | { _id: string; name?: string; images?: string[] }>;
  createdAt?: string;
}

interface ReactionRowProps {
  reactions: any;
  myUserId: string;
  onToggle: (emoji: string) => void;
  showQuickPick?: boolean;
}

export interface AggregatedReaction {
  emoji: string;
  count: number;
  reactedByMe: boolean;
}

const userId = (u: string | { _id: string } | undefined | null): string =>
  (typeof u === 'string' ? u : u?._id) ?? '';

/**
 * Aggregates a raw reactions list into one entry per emoji with a total
 * count and whether `myUserId` is among the reactors.
 *
 * Tolerates two backend shapes:
 *  - one reaction object per user per emoji: { emoji, user }
 *  - pre-grouped: { emoji, users: [...] }
 */
export function aggregateReactions(
  reactions: RawReaction[] | null | undefined,
  myUserId: string
): AggregatedReaction[] {
  if (!reactions || reactions.length === 0) return [];

  const byEmoji = new Map<string, AggregatedReaction>();

  for (const r of reactions) {
    if (!r || !r.emoji) continue;
    const existing = byEmoji.get(r.emoji) ?? { emoji: r.emoji, count: 0, reactedByMe: false };

    if (Array.isArray(r.users)) {
      existing.count += r.users.length;
      existing.reactedByMe = existing.reactedByMe || r.users.some((u) => userId(u) === myUserId);
    } else {
      existing.count += 1;
      existing.reactedByMe = existing.reactedByMe || userId(r.user) === myUserId;
    }

    byEmoji.set(r.emoji, existing);
  }

  return Array.from(byEmoji.values());
}

const ReactionRow: React.FC<ReactionRowProps> = ({
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
          data-testid={`reaction-chip-${emoji}`}
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
          {QUICK_REACTIONS.map((emoji) => (
            <button
              key={emoji}
              type="button"
              data-testid={`quick-pick-${emoji}`}
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

export default ReactionRow;
