export const QUICK_REACTIONS = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

const senderId = (s: any): string => (typeof s === 'string' ? s : s?._id) ?? '';

const ageMs = (createdAt: string, now: Date) => now.getTime() - new Date(createdAt).getTime();

export function canEdit(msg: any, meId: string, now: Date = new Date()): boolean {
  const t = msg?.messageType ?? msg?.type;
  return senderId(msg?.sender) === meId && t === 'text' && ageMs(msg.createdAt, now) <= 15 * 60 * 1000;
}

export function canDeleteForEveryone(msg: any, meId: string, now: Date = new Date()): boolean {
  return senderId(msg?.sender) === meId && ageMs(msg.createdAt, now) <= 60 * 60 * 1000;
}
