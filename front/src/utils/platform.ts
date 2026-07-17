export type MobilePlatform = 'ios' | 'android' | 'other';

export const APP_STORE_URL =
  'https://apps.apple.com/us/app/bananatalk-learn-meet-or-date/id6755862146';
export const PLAY_STORE_URL =
  'https://play.google.com/store/apps/details?id=com.bananatalk.app';

export function detectPlatform(ua: string): MobilePlatform {
  const s = ua.toLowerCase();
  if (/iphone|ipad|ipod/.test(s)) return 'ios';
  if (/android/.test(s)) return 'android';
  return 'other';
}
