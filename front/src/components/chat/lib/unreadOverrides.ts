/**
 * Live unread counts between two fetches of the conversations list.
 *
 * The server's per-conversation `unreadCount` is the truth. A socket message
 * bumps the number on screen by one until the next fetch, and the fetch wins
 * as soon as it has caught up. The socket payload's own `unreadCount` is not
 * read: before backend P1-CHAT-4 it is always 1.
 */
export type Counts = { [userId: string]: number };

export function displayUnread(id: string, server: Counts, overrides: Counts): number {
  if (overrides[id] !== undefined) return overrides[id];
  return server[id] || 0;
}

export function bumpUnread(id: string, server: Counts, overrides: Counts): Counts {
  return { ...overrides, [id]: displayUnread(id, server, overrides) + 1 };
}

export function pruneOverrides(server: Counts, overrides: Counts): Counts {
  const next: Counts = {};
  Object.keys(overrides).forEach((id) => {
    if ((server[id] || 0) < overrides[id]) next[id] = overrides[id];
  });
  return next;
}
