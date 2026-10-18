import { appSchemeUrl, openInApp } from './openInAppAction';
import { APP_STORE_URL, PLAY_STORE_URL } from '../../utils/platform';

describe('appSchemeUrl', () => {
  it('builds a custom scheme url', () => {
    expect(appSchemeUrl('moment', '123')).toBe('bananatalk://moment/123');
  });

  it('opens a card as the person\'s profile (the app has no card route)', () => {
    expect(appSchemeUrl('card', 'u1')).toBe('bananatalk://profile/u1');
  });

  it('builds invite and story links', () => {
    expect(appSchemeUrl('i', 'ABCD2345')).toBe('bananatalk://i/ABCD2345');
    expect(appSchemeUrl('story', 's1')).toBe('bananatalk://story/s1');
  });
});

describe('openInApp', () => {
  function harness(ua: string, stayVisible: boolean) {
    const navigations: string[] = [];
    let scheduled: (() => void) | null = null;
    openInApp({
      type: 'moment',
      id: '123',
      ua,
      navigate: (u) => navigations.push(u),
      schedule: (fn) => { scheduled = fn; },
      isVisible: () => stayVisible,
    });
    return { navigations, run: () => scheduled && scheduled() };
  }

  it('on ios: navigates to scheme, then store if still visible', () => {
    const h = harness('iPhone', true);
    expect(h.navigations[0]).toBe('bananatalk://moment/123');
    h.run();
    expect(h.navigations[1]).toBe(APP_STORE_URL);
  });

  it('on android: falls back to play store', () => {
    const h = harness('Android', true);
    h.run();
    expect(h.navigations[1]).toBe(PLAY_STORE_URL);
  });

  it('does NOT fall back to store if app took over (page hidden)', () => {
    const h = harness('iPhone', false);
    h.run();
    expect(h.navigations).toHaveLength(1);
  });

  it('on desktop: navigates to /download only', () => {
    const h = harness('Macintosh', true);
    expect(h.navigations).toEqual(['/download']);
  });
});
