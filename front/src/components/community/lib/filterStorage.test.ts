import { load, save, STORAGE_KEY, DEFAULT_FILTERS } from './filterStorage';

describe('filterStorage', () => {
  beforeEach(() => {
    window.localStorage.clear();
  });

  it('load() returns sensible defaults when storage is empty', () => {
    const filters = load();
    expect(filters).toEqual({ minAge: 18, maxAge: 100 });
  });

  it('save() then load() round-trips the filters', () => {
    const filters = {
      minAge: 21,
      maxAge: 40,
      gender: 'female',
      nativeLanguage: 'English',
      learningLanguage: 'Korean',
      country: 'US',
      topics: ['music', 'travel'],
      languageLevel: 'B1',
      onlineOnly: true,
      newUsersOnly: false,
      topicsAtLeast: 2,
      search: 'anna',
      sort: 'recently_active' as const,
    };
    save(filters);
    expect(load()).toEqual(filters);
  });

  it('save() writes to the community_filters localStorage key', () => {
    save({ minAge: 18, maxAge: 100, gender: 'male' });
    const raw = window.localStorage.getItem(STORAGE_KEY);
    expect(raw).not.toBeNull();
    expect(JSON.parse(raw as string)).toEqual({ minAge: 18, maxAge: 100, gender: 'male' });
  });

  it('load() returns defaults when stored JSON is corrupt', () => {
    window.localStorage.setItem(STORAGE_KEY, '{not valid json');
    expect(load()).toEqual(DEFAULT_FILTERS);
  });

  it('load() returns defaults when stored value is not an object', () => {
    window.localStorage.setItem(STORAGE_KEY, '"just a string"');
    expect(load()).toEqual(DEFAULT_FILTERS);
  });

  it('load() returns defaults when stored value is null literal', () => {
    window.localStorage.setItem(STORAGE_KEY, 'null');
    expect(load()).toEqual(DEFAULT_FILTERS);
  });

  it('DEFAULT_FILTERS matches the empty-state defaults', () => {
    expect(DEFAULT_FILTERS).toEqual({ minAge: 18, maxAge: 100 });
  });
});
