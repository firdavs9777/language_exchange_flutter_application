import { shareContent } from './shareContent';

function fakeNav(canShare: boolean, clipboardShouldFail = false) {
  const calls: any = { share: [], clip: [] };
  const nav = {
    share: canShare ? async (d: any) => { calls.share.push(d); } : undefined,
    canShare: canShare ? () => true : undefined,
    clipboard: {
      writeText: clipboardShouldFail
        ? async () => { throw new Error('denied'); }
        : async (t: string) => { calls.clip.push(t); },
    },
  } as unknown as Navigator;
  return { nav, calls };
}

describe('shareContent', () => {
  it('uses Web Share API when available', async () => {
    const { nav, calls } = fakeNav(true);
    const toasts: string[] = [];
    await shareContent({
      type: 'profile',
      id: 'u1',
      title: 'Hi',
      nav,
      copiedMessage: 'Link copied to clipboard!',
      copyFailedMessage: 'Failed to copy link',
      toast: (m) => toasts.push(m),
    });
    expect(calls.share[0].url).toBe('https://banatalk.com/profile/u1');
  });

  it('falls back to clipboard when Web Share missing', async () => {
    const { nav, calls } = fakeNav(false);
    const toasts: string[] = [];
    await shareContent({
      type: 'moment',
      id: '9',
      title: 'Hi',
      nav,
      copiedMessage: 'Link copied to clipboard!',
      copyFailedMessage: 'Failed to copy link',
      toast: (m) => toasts.push(m),
    });
    expect(calls.clip[0]).toBe('https://banatalk.com/moment/9');
    expect(toasts[0]).toMatch(/copied/i);
  });

  it('surfaces an error toast when the clipboard fallback fails', async () => {
    const { nav } = fakeNav(false, true);
    const toasts: { message: string; variant?: string }[] = [];
    await shareContent({
      type: 'moment',
      id: '9',
      title: 'Hi',
      nav,
      copiedMessage: 'Link copied to clipboard!',
      copyFailedMessage: 'Failed to copy link',
      toast: (message, variant) => toasts.push({ message, variant }),
    });
    expect(toasts[0].variant).toBe('error');
    expect(toasts[0].message).toMatch(/failed/i);
  });
});
