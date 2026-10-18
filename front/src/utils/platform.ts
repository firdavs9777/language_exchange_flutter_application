// The store URLs live in one place only -- growth/storeUrls.ts (React-free),
// which is what the grep guard in src/components/growth/storeUrls.test.ts
// enforces. This module re-exports them so the non-marketing callers (deep
// links, the app banner) keep their import path.
export { APP_STORE_URL, PLAY_STORE_URL } from '../components/growth/storeUrls';

export type MobilePlatform = 'ios' | 'android' | 'other';

export function detectPlatform(ua: string): MobilePlatform {
  const s = ua.toLowerCase();
  if (/iphone|ipad|ipod/.test(s)) return 'ios';
  if (/android/.test(s)) return 'android';
  return 'other';
}
