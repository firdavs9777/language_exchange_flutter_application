import { presenceForStranger, isMutualExchange } from './presence';

const NOW = new Date('2026-10-18T12:00:00Z').getTime();
const hoursAgo = (h: number) => new Date(NOW - h * 3600000).toISOString();

it('shows only online / active today / nothing to strangers', () => {
  expect(presenceForStranger({ isOnline: true }, NOW)).toBe('online');
  expect(presenceForStranger({ lastActive: hoursAgo(3) }, NOW)).toBe('today');
  expect(presenceForStranger({ lastSeen: hoursAgo(23) }, NOW)).toBe('today');
  expect(presenceForStranger({ lastActive: hoursAgo(25) }, NOW)).toBeNull();
  expect(presenceForStranger({}, NOW)).toBeNull();
});

it('shows nothing when the person hides their online status', () => {
  expect(
    presenceForStranger({ isOnline: true, privacySettings: { showOnlineStatus: false } }, NOW)
  ).toBeNull();
});

it('detects a mutual language exchange (case-insensitive)', () => {
  const them = { native_language: 'Korean', language_to_learn: 'English' };
  expect(isMutualExchange(them, { native_language: 'english', language_to_learn: 'korean' })).toBe(true);
  expect(isMutualExchange(them, { native_language: 'English', language_to_learn: 'Japanese' })).toBe(false);
  expect(isMutualExchange(them, undefined)).toBe(false);
});
