import React from 'react';
import { Bookmark } from 'lucide-react';
import moment from 'moment';
import { useGetBookmarksQuery } from '../../../store/slices/chatSlice';

export interface BookmarksViewProps {
  onOpenMessage?(msg: any): void;
}

// Backend shape (controllers/advancedMessages.js getBookmarks):
//   GET /messages/bookmarks -> { success, count, total, pages, data }
//   data: User.bookmarkedMessages[] = [{ _id, message: <populated Message>, bookmarkedAt }]
//   populated Message.sender / Message.receiver -> { _id, name, images }
//   populated Message.message -> text body (field is literally named `message`)
// This view tolerates other shapes too (a bare array, or items that are the
// message itself rather than a bookmark wrapper) so it degrades gracefully
// if the response evolves.
const getBookmarkList = (data: any): any[] => {
  if (Array.isArray(data)) return data;
  if (Array.isArray(data?.data)) return data.data;
  if (Array.isArray(data?.bookmarks)) return data.bookmarks;
  return [];
};

const getMessage = (item: any): any => item?.message ?? item;

const getMessageId = (item: any): string => {
  const msg = getMessage(item);
  return msg?._id ?? item?._id ?? '';
};

const getSender = (item: any): any => getMessage(item)?.sender;

const getSenderName = (item: any): string => {
  const sender = getSender(item);
  if (!sender) return 'Unknown';
  return typeof sender === 'string' ? sender : sender?.name ?? 'Unknown';
};

const getSenderAvatar = (item: any): string | undefined => {
  const sender = getSender(item);
  if (!sender || typeof sender === 'string') return undefined;
  return sender?.images?.[0] || sender?.avatar || sender?.photo;
};

const getPreviewText = (item: any): string => {
  const msg = getMessage(item);
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

const getTimeAgo = (item: any): string => {
  const at = item?.bookmarkedAt ?? getMessage(item)?.createdAt;
  if (!at) return '';
  return moment(at).fromNow();
};

const BookmarksView: React.FC<BookmarksViewProps> = ({ onOpenMessage }) => {
  const { data, isLoading, isError } = useGetBookmarksQuery(undefined);
  const bookmarks = getBookmarkList(data);

  return (
    <div data-testid="bookmarks-view" className="flex h-full flex-col overflow-y-auto">
      {isLoading && (
        <p className="px-4 py-6 text-center text-sm text-gray-400">Loading bookmarks…</p>
      )}

      {isError && (
        <p className="px-4 py-6 text-center text-sm text-red-500">
          Couldn&apos;t load bookmarks.
        </p>
      )}

      {!isLoading && !isError && bookmarks.length === 0 && (
        <div className="flex flex-1 flex-col items-center justify-center gap-2 px-4 py-10 text-center">
          <Bookmark size={28} className="text-gray-300 dark:text-gray-600" />
          <p className="text-sm text-gray-400 dark:text-gray-500">No bookmarked messages yet.</p>
        </div>
      )}

      {!isLoading &&
        !isError &&
        bookmarks.map((item) => {
          const id = getMessageId(item);
          const avatar = getSenderAvatar(item);
          const name = getSenderName(item);

          return (
            <button
              key={id || Math.random()}
              type="button"
              data-testid={`bookmark-item-${id}`}
              onClick={() => onOpenMessage?.(getMessage(item))}
              className="flex w-full items-start gap-3 border-b border-gray-100 px-4 py-3 text-left hover:bg-gray-50 dark:border-gray-800 dark:hover:bg-gray-800/60"
            >
              {avatar ? (
                <img src={avatar} alt={name} className="h-9 w-9 flex-none rounded-full object-cover" />
              ) : (
                <span className="flex h-9 w-9 flex-none items-center justify-center rounded-full bg-indigo-100 text-sm font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-200">
                  {name.charAt(0).toUpperCase()}
                </span>
              )}

              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between gap-2">
                  <span className="truncate text-sm font-semibold text-gray-900 dark:text-gray-100">
                    {name}
                  </span>
                  <span className="flex-none text-xs text-gray-400 dark:text-gray-500">
                    {getTimeAgo(item)}
                  </span>
                </div>
                <p className="truncate text-sm text-gray-600 dark:text-gray-300">
                  {getPreviewText(item)}
                </p>
              </div>

              <Bookmark size={14} className="mt-1 flex-none text-teal-500 dark:text-teal-400" />
            </button>
          );
        })}
    </div>
  );
};

export default BookmarksView;
