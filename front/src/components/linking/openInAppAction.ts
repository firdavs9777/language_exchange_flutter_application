import { ShareType } from '../../utils/shareUrl';
import { detectPlatform, APP_STORE_URL, PLAY_STORE_URL } from '../../utils/platform';

/**
 * Every page the app can be asked to open. `i` (invite) and `story` are not
 * share types: invite links are built by the backend, and story links by the
 * app (2.7.0 parses them; 2.6.1 opens the app and drops the link).
 */
export type AppLinkType = ShareType | 'i' | 'story';

export function appSchemeUrl(type: AppLinkType, id: string): string {
  // The app has no card route; a card is a person, so it opens their profile.
  const route = type === 'card' ? 'profile' : type;
  return `bananatalk://${route}/${id}`;
}

export interface OpenInAppOptions {
  type: AppLinkType;
  id: string;
  ua: string;
  navigate: (url: string) => void;
  schedule: (fn: () => void, ms: number) => void;
  isVisible: () => boolean;
}

const FALLBACK_MS = 1500;

export function openInApp(opts: OpenInAppOptions): void {
  const platform = detectPlatform(opts.ua);
  if (platform === 'other') {
    opts.navigate('/download');
    return;
  }
  opts.navigate(appSchemeUrl(opts.type, opts.id));
  opts.schedule(() => {
    if (opts.isVisible()) {
      opts.navigate(platform === 'ios' ? APP_STORE_URL : PLAY_STORE_URL);
    }
  }, FALLBACK_MS);
}
