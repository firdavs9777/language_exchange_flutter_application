export const WEB_ORIGIN = 'https://banatalk.com';

export type ShareType = 'moment' | 'profile' | 'community';

export function shareUrl(type: ShareType, id: string): string {
  return `${WEB_ORIGIN}/${type}/${encodeURIComponent(id)}`;
}
