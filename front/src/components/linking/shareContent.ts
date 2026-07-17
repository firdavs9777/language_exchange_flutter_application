import { shareUrl, ShareType } from '../../utils/shareUrl';

export interface ShareContentOptions {
  type: ShareType;
  id: string;
  title: string;
  text?: string;
  nav: Navigator;
  // Messages are supplied by the caller (already translated) so this helper
  // stays framework-free/testable and doesn't need to import i18n.
  copiedMessage: string;
  copyFailedMessage: string;
  toast: (message: string, variant?: 'success' | 'error') => void;
}

export async function shareContent(opts: ShareContentOptions): Promise<void> {
  const url = shareUrl(opts.type, opts.id);
  const data = { title: opts.title, text: opts.text ?? opts.title, url };
  const anyNav = opts.nav as any;
  if (anyNav.share && (!anyNav.canShare || anyNav.canShare(data))) {
    await anyNav.share(data);
    return;
  }
  try {
    await opts.nav.clipboard.writeText(url);
    opts.toast(opts.copiedMessage, 'success');
  } catch (err) {
    opts.toast(opts.copyFailedMessage, 'error');
  }
}
