import { buildRegisterPayload } from './buildRegisterPayload';

const base = {
  name: 'Jane', username: 'JaneDoe', password: 'Abcdef12', email: 'j@x.com',
  gender: 'female', birthDate: '2000-03-09', native_language: 'English', language_to_learn: 'Korean',
};

it('builds an app-identical body with coordinates', () => {
  const body = buildRegisterPayload({ ...base, location: { city: 'Seoul', country: 'South Korea', coordinates: [127.0, 37.5] } });
  expect(body).toEqual({
    name: 'Jane', username: 'janedoe', password: 'Abcdef12', email: 'j@x.com', bio: '', gender: 'female', images: [],
    birth_year: '2000', birth_month: '03', birth_day: '09',
    native_language: 'English', language_to_learn: 'Korean', topics: [], termsAccepted: true,
    location: { type: 'Point', coordinates: [127.0, 37.5], formattedAddress: 'Seoul, South Korea', city: 'Seoul', country: 'South Korea' },
  });
});
it('omits coordinates and type when absent (never [0,0])', () => {
  const body = buildRegisterPayload({ ...base, location: { city: 'Paris', country: 'France' } });
  expect(body.location).toEqual({ formattedAddress: 'Paris, France', city: 'Paris', country: 'France' });
  expect('coordinates' in body.location).toBe(false);
});
it('lowercases username, null when empty', () => {
  expect(buildRegisterPayload({ ...base, username: '', location: { city: 'A', country: 'B' } }).username).toBeNull();
});
