import { ShareType } from '../../utils/shareUrl';
import { detectPlatform, APP_STORE_URL, PLAY_STORE_URL } from '../../utils/platform';

export function appSchemeUrl(type: ShareType, id: string): string {
  return `bananatalk://${type}/${id}`;
}

export interface OpenInAppOptions {
  type: ShareType;
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
