import React, { useMemo, useState } from 'react';
import { useSelector } from 'react-redux';
import { X, Search, Send, Check } from 'lucide-react';
import { useGetConversationsQuery } from '../../../store/slices/chatSlice';

export interface ForwardDialogProps {
  open: boolean;
  onForward(receiverIds: string[]): void;
  onClose(): void;
}

interface RootState {
  auth: {
    userInfo: {
      user?: { _id: string };
    } | null;
  };
}

interface Partner {
  _id: string;
  name: string;
  avatar?: string;
}

const partnerAvatar = (user: any): string | undefined =>
  user?.avatar || user?.photo || user?.imageUrls?.[0] || user?.images?.[0];

const ForwardDialog: React.FC<ForwardDialogProps> = ({ open, onForward, onClose }) => {
  const meId = useSelector((state: RootState) => state.auth.userInfo?.user?._id) ?? '';
  const { data, isLoading, isError } = useGetConversationsQuery(
    { page: 1, limit: 50 },
    { skip: !open }
  );

  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [query, setQuery] = useState('');

  const partners: Partner[] = useMemo(() => {
    const list = data?.data;
    if (!Array.isArray(list)) return [];

    const byId = new Map<string, Partner>();
    list.forEach((conversation: any) => {
      const participants = conversation?.participants || [];
      const otherUser = participants.find((p: any) => (p?._id ?? p) !== meId);
      if (!otherUser?._id) return;
      if (!byId.has(otherUser._id)) {
        byId.set(otherUser._id, {
          _id: otherUser._id,
          name: otherUser.name || 'Unknown',
          avatar: partnerAvatar(otherUser),
        });
      }
    });
    return Array.from(byId.values());
  }, [data, meId]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return partners;
    return partners.filter((p) => p.name.toLowerCase().includes(q));
  }, [partners, query]);

  if (!open) return null;

  const toggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleForward = () => {
    if (selected.size === 0) return;
    onForward(Array.from(selected));
  };

  return (
    <div
      data-testid="forward-dialog-backdrop"
      className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 sm:items-center"
      onClick={onClose}
    >
      <div
        data-testid="forward-dialog"
        onClick={(e) => e.stopPropagation()}
        className="flex max-h-[80vh] w-full max-w-sm flex-col rounded-t-2xl bg-white shadow-xl dark:bg-gray-900 sm:rounded-2xl"
      >
        <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3 dark:border-gray-800">
          <h2 className="text-base font-semibold text-gray-900 dark:text-gray-100">Forward to</h2>
          <button
            type="button"
            aria-label="Close"
            data-testid="forward-dialog-close"
            onClick={onClose}
            className="flex h-7 w-7 items-center justify-center rounded-full text-gray-400 hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-800 dark:hover:text-gray-200"
          >
            <X size={16} />
          </button>
        </div>

        <div className="px-4 pt-3">
          <div className="flex items-center gap-2 rounded-full bg-gray-100 px-3 py-2 dark:bg-gray-800">
            <Search size={14} className="text-gray-400" />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search"
              className="w-full bg-transparent text-sm text-gray-800 outline-none placeholder:text-gray-400 dark:text-gray-100"
            />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto px-2 py-2">
          {isLoading && (
            <p className="px-2 py-4 text-center text-sm text-gray-400">Loading conversations…</p>
          )}
          {isError && (
            <p className="px-2 py-4 text-center text-sm text-red-500">
              Couldn&apos;t load conversations.
            </p>
          )}
          {!isLoading && !isError && filtered.length === 0 && (
            <p className="px-2 py-4 text-center text-sm text-gray-400">No conversations found.</p>
          )}

          {filtered.map((partner) => {
            const isSelected = selected.has(partner._id);
            return (
              <button
                key={partner._id}
                type="button"
                data-testid={`forward-target-${partner._id}`}
                onClick={() => toggle(partner._id)}
                className="flex w-full items-center gap-3 rounded-xl px-2 py-2 text-left hover:bg-gray-100 dark:hover:bg-gray-800"
              >
                {partner.avatar ? (
                  <img
                    src={partner.avatar}
                    alt={partner.name}
                    className="h-9 w-9 flex-none rounded-full object-cover"
                  />
                ) : (
                  <span className="flex h-9 w-9 flex-none items-center justify-center rounded-full bg-teal-100 text-sm font-semibold text-teal-700 dark:bg-teal-900/40 dark:text-teal-200">
                    {partner.name.charAt(0).toUpperCase()}
                  </span>
                )}
                <span className="flex-1 truncate text-sm font-medium text-gray-800 dark:text-gray-100">
                  {partner.name}
                </span>
                <span
                  className={
                    'flex h-5 w-5 flex-none items-center justify-center rounded-full border-2 transition-colors ' +
                    (isSelected
                      ? 'border-teal-500 bg-teal-500 text-white'
                      : 'border-gray-300 dark:border-gray-600')
                  }
                >
                  {isSelected && <Check size={12} />}
                </span>
              </button>
            );
          })}
        </div>

        <div className="border-t border-gray-100 px-4 py-3 dark:border-gray-800">
          <button
            type="button"
            data-testid="forward-dialog-submit"
            disabled={selected.size === 0}
            onClick={handleForward}
            className="flex w-full items-center justify-center gap-2 rounded-full bg-teal-500 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-teal-600 disabled:cursor-not-allowed disabled:bg-gray-300 dark:disabled:bg-gray-700"
          >
            <Send size={14} />
            Forward{selected.size > 0 ? ` (${selected.size})` : ''}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ForwardDialog;
