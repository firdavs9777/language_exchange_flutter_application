import { buildCommunityQuery } from './buildCommunityQuery';

const me = { native_language: 'English', language_to_learn: 'Korean' };

it('inverts native/learning: UI nativeLanguage=Spanish -> API learningLanguage=Spanish', () => {
  const q = buildCommunityQuery({ nativeLanguage: 'Spanish' }, me, 1, 20);
  expect(q.learningLanguage).toBe('Spanish');
  expect(q.nativeLanguage).toBeUndefined();
  expect(q.matchLanguage).toBe('true');
});

it('UI learningLanguage=French -> API nativeLanguage=French', () => {
  const q = buildCommunityQuery({ learningLanguage: 'French' }, me, 1, 20);
  expect(q.nativeLanguage).toBe('French');
  expect(q.matchLanguage).toBe('true');
});

// Verified against the app's _buildFilterParams (partner_discovery_tab.dart):
// when no explicit language filter is selected, the default "language-exchange
// matching" case sends matchLanguage=true PLUS the current user's own
// native/learning languages assigned DIRECTLY (not swapped) to the API's
// nativeLanguage/learningLanguage params:
//   apiNativeParam = myNative (currentUser.native_language)
//   apiLearningParam = myLearning (currentUser.language_to_learn)
// This is correct per the API's inverted semantics: nativeLanguage= finds
// users LEARNING that language (i.e. people who could learn from me, since I
// natively speak it), and learningLanguage= finds users who natively speak
// that language (i.e. native speakers of what I'm trying to learn).
it('no language filter -> matchLanguage=true with my own languages (direct, not swapped)', () => {
  const q = buildCommunityQuery({}, me, 1, 20);
  expect(q.matchLanguage).toBe('true');
  expect(q.nativeLanguage).toBe('English'); // me.native_language, direct
  expect(q.learningLanguage).toBe('Korean'); // me.language_to_learn, direct
});

it('age maps to minAge/maxAge and respects guards (min>18, max<100)', () => {
  const q = buildCommunityQuery({ minAge: 25, maxAge: 40 }, me, 1, 20);
  expect(q.minAge).toBe('25');
  expect(q.maxAge).toBe('40');
  const q2 = buildCommunityQuery({ minAge: 18, maxAge: 100 }, me, 1, 20);
  expect(q2.minAge).toBeUndefined();
  expect(q2.maxAge).toBeUndefined();
});

it('passes gender, onlineOnly, country, languageLevel, topics(csv), topicsAtLeast, search, sort, page, limit', () => {
  const q = buildCommunityQuery(
    {
      gender: 'female',
      onlineOnly: true,
      country: 'Japan',
      languageLevel: 'B2',
      topics: ['t1', 't2'],
      topicsAtLeast: 2,
      search: 'kim',
      sort: 'recently_active',
    },
    me,
    3,
    20
  );
  expect(q).toMatchObject({
    gender: 'female',
    onlineOnly: 'true',
    country: 'Japan',
    languageLevel: 'B2',
    topics: 't1,t2',
    topicsAtLeast: '2',
    search: 'kim',
    sort: 'recently_active',
    page: '3',
    limit: '20',
  });
});
