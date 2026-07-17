import { shareUrl } from './shareUrl';

describe('shareUrl', () => {
  it('builds a moment url', () => {
    expect(shareUrl('moment', '123')).toBe('https://banatalk.com/moment/123');
  });
  it('builds a profile url', () => {
    expect(shareUrl('profile', 'u42')).toBe('https://banatalk.com/profile/u42');
  });
  it('builds a community url', () => {
    expect(shareUrl('community', 'c7')).toBe('https://banatalk.com/community/c7');
  });
  it('encodes ids', () => {
    expect(shareUrl('profile', 'a b')).toBe('https://banatalk.com/profile/a%20b');
  });
});
