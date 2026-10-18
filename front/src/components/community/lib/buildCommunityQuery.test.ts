import { buildCommunityQuery, withoutVipOnlyFilters } from './buildCommunityQuery';

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

// Reported while checking filters: the New tab and the "New users only"
// switch sent `newUsersOnly=true`, which controllers/users.js has never read --
// it honours `joinedWithin=7d|30d`. So "New" returned exactly the All list.
// 7d is the app's New members segment, and the window the card's New badge
// already uses.
it('asks for new members the way the server understands: joinedWithin=7d', () => {
  const q = buildCommunityQuery({ newUsersOnly: true } as any, { native_language: 'English', language_to_learn: 'Korean' }, 1, 20);
  expect(q.joinedWithin).toBe('7d');
  expect(q.newUsersOnly).toBeUndefined();
});

it('sends no joinedWithin when new members are not asked for', () => {
  const q = buildCommunityQuery({} as any, { native_language: 'English', language_to_learn: 'Korean' }, 1, 20);
  expect(q.joinedWithin).toBeUndefined();
});

// matchLanguage=true joins the two language params with OR -- right for the
// default exchange match (they speak what I learn, OR learn what I speak),
// wrong for two explicit filters: "native Korean" + "learning English" came
// back as anyone who speaks Korean plus anyone learning English. With both set
// the query takes the server's other branch, which applies both (AND), with
// the params in their direct meaning there.
it('two explicit language filters must both hold: no matchLanguage, direct params', () => {
  const q = buildCommunityQuery({ nativeLanguage: 'Korean', learningLanguage: 'English' }, me, 1, 20);
  expect(q.matchLanguage).toBeUndefined();
  expect(q.nativeLanguage).toBe('Korean');
  expect(q.learningLanguage).toBe('English');
});

it('Serious learners -> activeWithin=7d (the app PartnerSegment.serious)', () => {
  const q = buildCommunityQuery({ activeWithin: '7d' }, me, 1, 20);
  expect(q.activeWithin).toBe('7d');
  expect(buildCommunityQuery({}, me, 1, 20).activeWithin).toBeUndefined();
});

it('reciprocal -> reciprocal=true; smart sort passes through', () => {
  const q = buildCommunityQuery({ reciprocal: true, sort: 'smart' }, me, 1, 20);
  expect(q.reciprocal).toBe('true');
  expect(q.sort).toBe('smart');
  expect(buildCommunityQuery({}, me, 1, 20).reciprocal).toBeUndefined();
});

it('drops the VIP-only country filter for free users, keeps it for VIP', () => {
  const filters = { country: 'Japan', gender: 'female' };
  const free = buildCommunityQuery(withoutVipOnlyFilters(filters, false), me, 1, 20);
  expect(free.country).toBeUndefined();
  expect(free.gender).toBe('female');
  const vip = buildCommunityQuery(withoutVipOnlyFilters(filters, true), me, 1, 20);
  expect(vip.country).toBe('Japan');
  // The saved filter itself is untouched, so it applies again after an upgrade.
  expect(filters.country).toBe('Japan');
});
