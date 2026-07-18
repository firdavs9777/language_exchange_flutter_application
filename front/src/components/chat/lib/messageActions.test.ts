import { canEdit, canDeleteForEveryone, QUICK_REACTIONS } from './messageActions';

const now = new Date('2026-07-18T12:00:00Z');
const mk = (over: any = {}) => ({ sender: 'me', messageType: 'text', createdAt: '2026-07-18T11:50:00Z', ...over });

it('canEdit: own text within 15min', () => { expect(canEdit(mk(), 'me', now)).toBe(true); });
it('canEdit: false if not own', () => { expect(canEdit(mk({ sender: 'other' }), 'me', now)).toBe(false); });
it('canEdit: false if older than 15min', () => { expect(canEdit(mk({ createdAt: '2026-07-18T11:40:00Z' }), 'me', now)).toBe(false); });
it('canEdit: false if not text', () => { expect(canEdit(mk({ messageType: 'image' }), 'me', now)).toBe(false); });
it('canEdit: sender as object', () => { expect(canEdit(mk({ sender: { _id: 'me' } }), 'me', now)).toBe(true); });
it('canDeleteForEveryone: own within 1h', () => { expect(canDeleteForEveryone(mk({ createdAt: '2026-07-18T11:15:00Z' }), 'me', now)).toBe(true); });
it('canDeleteForEveryone: false after 1h', () => { expect(canDeleteForEveryone(mk({ createdAt: '2026-07-18T10:00:00Z' }), 'me', now)).toBe(false); });
it('exposes 6 quick reactions', () => { expect(QUICK_REACTIONS).toHaveLength(6); });
