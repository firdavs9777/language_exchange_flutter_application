import { normalizeLocationResult } from './resolveLocation';

it('keeps real coordinates', () => {
  expect(normalizeLocationResult({ city: 'Seoul', country: 'KR', coordinates: [127, 37.5] }))
    .toEqual({ city: 'Seoul', country: 'KR', coordinates: [127, 37.5] });
});
it('drops [0,0] fabricated coordinates', () => {
  expect(normalizeLocationResult({ city: 'X', country: 'Y', coordinates: [0, 0] }))
    .toEqual({ city: 'X', country: 'Y' });
});
it('drops non-finite coordinates', () => {
  expect(normalizeLocationResult({ city: 'X', country: 'Y', coordinates: [NaN, 1] as any }))
    .toEqual({ city: 'X', country: 'Y' });
});
it('returns null when no city/country', () => {
  expect(normalizeLocationResult({ city: null, country: null } as any)).toBeNull();
});
