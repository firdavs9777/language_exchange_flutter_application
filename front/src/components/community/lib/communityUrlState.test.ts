import {
  URL_KEYS,
  encodeCommunityState,
  decodeCommunityState,
  hasCommunityUrlState,
  mergeCommunityParams,
} from './communityUrlState';

const params = (query: string) => new URLSearchParams(query);

describe('communityUrlState', () => {
  describe('the key vocabulary', () => {
    it('is the short, stable set the plan fixed', () => {
      expect(URL_KEYS).toEqual([
        'native',
        'learning',
        'age',
        'gender',
        'country',
        'level',
        'topics',
        'mutual',
        'online',
        'new',
        'pair',
        'sort',
        'q',
        'tab',
      ]);
    });
  });

  describe('encode', () => {
    it('writes every filter under its short key', () => {
      const encoded = encodeCommunityState({
        filters: {
          nativeLanguage: 'Korean',
          learningLanguage: 'English',
          minAge: 21,
          maxAge: 35,
          gender: 'female',
          country: 'South Korea',
          languageLevel: 'B2',
          topics: ['music', 'travel'],
          topicsAtLeast: 3,
          onlineOnly: true,
          newUsersOnly: true,
        },
        search: 'anna',
        sort: 'recently_active',
        tab: 'nearby',
      });

      expect(encoded.get('native')).toBe('Korean');
      expect(encoded.get('learning')).toBe('English');
      expect(encoded.get('age')).toBe('21-35');
      expect(encoded.get('gender')).toBe('female');
      expect(encoded.get('country')).toBe('South Korea');
      expect(encoded.get('level')).toBe('B2');
      expect(encoded.get('topics')).toBe('music,travel');
      expect(encoded.get('mutual')).toBe('3');
      expect(encoded.get('online')).toBe('1');
      expect(encoded.get('new')).toBe('1');
      expect(encoded.get('sort')).toBe('recently_active');
      expect(encoded.get('q')).toBe('anna');
      expect(encoded.get('tab')).toBe('nearby');
    });

    it('keeps the default state out of the URL entirely', () => {
      const encoded = encodeCommunityState({
        filters: { minAge: 18, maxAge: 100 },
        search: '',
        sort: undefined,
        // all is written since today became the default landing
        tab: 'today',
      });
      expect(encoded.toString()).toBe('');
    });

    it('drops falsy toggles rather than writing 0', () => {
      const encoded = encodeCommunityState({
        filters: { onlineOnly: false, newUsersOnly: false, topicsAtLeast: 0, topics: [] },
      });
      expect(encoded.toString()).toBe('');
    });

    it('writes the age pair as soon as either end moves', () => {
      expect(encodeCommunityState({ filters: { minAge: 25, maxAge: 100 } }).get('age')).toBe('25-100');
      expect(encodeCommunityState({ filters: { minAge: 18, maxAge: 40 } }).get('age')).toBe('18-40');
    });

    it('emits its keys in one canonical order so the URL is stable', () => {
      const state = {
        filters: { onlineOnly: true, nativeLanguage: 'Korean', gender: 'male' },
        search: 'jin',
      };
      expect(encodeCommunityState(state).toString()).toBe(
        encodeCommunityState(state).toString()
      );
      expect(encodeCommunityState(state).toString()).toBe(
        'native=Korean&gender=male&online=1&q=jin'
      );
    });

    it('ignores values it does not recognise', () => {
      const encoded = encodeCommunityState({
        filters: { gender: 'wizard', languageLevel: 'Z9' },
        sort: 'alphabetical' as any,
        tab: 'nonsense' as any,
      });
      expect(encoded.toString()).toBe('');
    });
  });

  describe('decode', () => {
    it('reads every key back', () => {
      const decoded = decodeCommunityState(
        params(
          'native=Korean&learning=English&age=21-35&gender=female&country=South+Korea' +
            '&level=B2&topics=music,travel&mutual=3&online=1&new=1&sort=recently_active&q=anna&tab=nearby'
        )
      );

      expect(decoded.filters).toEqual({
        nativeLanguage: 'Korean',
        learningLanguage: 'English',
        minAge: 21,
        maxAge: 35,
        gender: 'female',
        country: 'South Korea',
        languageLevel: 'B2',
        topics: ['music', 'travel'],
        topicsAtLeast: 3,
        onlineOnly: true,
        newUsersOnly: true,
      });
      expect(decoded.search).toBe('anna');
      expect(decoded.sort).toBe('recently_active');
      expect(decoded.tab).toBe('nearby');
    });

    it('returns nothing at all for an empty query', () => {
      expect(decodeCommunityState(params(''))).toEqual({});
      expect(hasCommunityUrlState(params(''))).toBe(false);
    });

    it('ignores unknown params', () => {
      expect(decodeCommunityState(params('utm_source=twitter&ref=x'))).toEqual({});
      expect(hasCommunityUrlState(params('utm_source=twitter'))).toBe(false);
    });

    it('drops invalid values instead of trusting them', () => {
      const decoded = decodeCommunityState(
        params('gender=wizard&level=Z9&sort=alphabetical&tab=rocket&mutual=abc&age=oops')
      );
      expect(decoded).toEqual({});
    });

    it('rejects an age range that is out of bounds or inverted', () => {
      expect(decodeCommunityState(params('age=40-20')).filters).toBeUndefined();
      expect(decodeCommunityState(params('age=5-200')).filters).toBeUndefined();
      expect(decodeCommunityState(params('age=21')).filters).toBeUndefined();
    });

    it('clamps the mutual-interest count to its slider range', () => {
      expect(decodeCommunityState(params('mutual=0')).filters).toBeUndefined();
      expect(decodeCommunityState(params('mutual=99')).filters).toEqual({ topicsAtLeast: 10 });
    });

    it('normalises case for the closed vocabularies', () => {
      const decoded = decodeCommunityState(params('gender=FEMALE&level=b2&tab=Topics'));
      expect(decoded.filters).toEqual({ gender: 'female', languageLevel: 'B2' });
      expect(decoded.tab).toBe('topics');
    });

    it('treats a toggle as on only for 1', () => {
      expect(decodeCommunityState(params('online=1')).filters).toEqual({ onlineOnly: true });
      expect(decodeCommunityState(params('online=0')).filters).toBeUndefined();
      expect(decodeCommunityState(params('new=true')).filters).toBeUndefined();
    });

    it('cleans up a sloppy topic list', () => {
      expect(decodeCommunityState(params('topics=music,,travel,music, food ')).filters).toEqual({
        topics: ['music', 'travel', 'food'],
      });
      expect(decodeCommunityState(params('topics=,,')).filters).toBeUndefined();
    });

    it('reports that the URL carries state as soon as one key is valid', () => {
      expect(hasCommunityUrlState(params('online=1'))).toBe(true);
      expect(hasCommunityUrlState(params('q=anna'))).toBe(true);
      expect(hasCommunityUrlState(params('tab=nearby'))).toBe(true);
      expect(hasCommunityUrlState(params('gender=wizard'))).toBe(false);
    });
  });

  describe('round trip', () => {
    it('survives encode -> decode -> encode unchanged', () => {
      const state = {
        filters: {
          nativeLanguage: 'Japanese',
          learningLanguage: 'Spanish',
          minAge: 24,
          maxAge: 44,
          gender: 'other',
          country: 'Japan',
          languageLevel: 'C1',
          topics: ['anime', 'cooking'],
          topicsAtLeast: 2,
          onlineOnly: true,
          newUsersOnly: true,
        },
        search: 'yuki',
        sort: 'recently_active' as const,
        tab: 'nearby' as const,
      };

      const once = encodeCommunityState(state);
      const decoded = decodeCommunityState(once);
      expect(decoded.filters).toEqual(state.filters);
      expect(decoded.search).toBe(state.search);
      expect(decoded.sort).toBe(state.sort);
      expect(decoded.tab).toBe(state.tab);
      expect(encodeCommunityState(decoded as any).toString()).toBe(once.toString());
    });

    it('keeps the space a half-typed search ends on', () => {
      const encoded = encodeCommunityState({ search: 'jin ' });
      expect(encoded.get('q')).toBe('jin ');
      expect(decodeCommunityState(encoded).search).toBe('jin ');
      expect(decodeCommunityState(params('q=%20%20')).search).toBeUndefined();
    });

    it('is a fixed point for the empty state', () => {
      // all is written since today became the default landing
      const once = encodeCommunityState({ filters: {}, search: '', tab: 'today' });
      expect(once.toString()).toBe('');
      expect(encodeCommunityState(decodeCommunityState(once) as any).toString()).toBe('');
    });
  });

  describe('mergeCommunityParams', () => {
    it('replaces the list keys and keeps everything else', () => {
      const merged = mergeCommunityParams(
        params('utm_source=twitter&online=1&q=old'),
        encodeCommunityState({ filters: { gender: 'male' } })
      );
      expect(merged.get('utm_source')).toBe('twitter');
      expect(merged.get('online')).toBeNull();
      expect(merged.get('q')).toBeNull();
      expect(merged.get('gender')).toBe('male');
    });

    it('puts the foreign params first so the result is comparable as a string', () => {
      const merged = mergeCommunityParams(
        params('ref=a&online=1'),
        encodeCommunityState({ filters: { onlineOnly: true } })
      );
      expect(merged.toString()).toBe('ref=a&online=1');
    });
  });


  describe('the reciprocal filter', () => {
    it('round-trips as pair=1', () => {
      const encoded = encodeCommunityState({ filters: { reciprocal: true }, search: '', tab: 'all' });
      expect(encoded.get('pair')).toBe('1');
      expect(decodeCommunityState(params('pair=1')).filters).toEqual(
        expect.objectContaining({ reciprocal: true })
      );
    });
  });
  describe('the serious tab', () => {
    it('round-trips ?tab=serious', () => {
      expect(decodeCommunityState(params('tab=serious')).tab).toBe('serious');
      expect(
        encodeCommunityState({ filters: {}, search: '', tab: 'serious' }).toString()
      ).toBe('tab=serious');
    });
  });
});

describe("today is the default tab", () => {
  it("leaves `today` out of the URL", () => {
    expect(encodeCommunityState({ filters: {}, search: "", tab: "today" } as any).get("tab")).toBeNull();
  });
  it("writes `all` like any other tab", () => {
    expect(encodeCommunityState({ filters: {}, search: "", tab: "all" } as any).get("tab")).toBe("all");
  });
  it("reads tab=today and tab=all back", () => {
    expect(decodeCommunityState(new URLSearchParams("tab=today")).tab).toBe("today");
    expect(decodeCommunityState(new URLSearchParams("tab=all")).tab).toBe("all");
  });
  it("an absent tab decodes as absent -- the page decides the default", () => {
    expect(decodeCommunityState(new URLSearchParams("native=Korean")).tab).toBeUndefined();
  });
});
