import { CHECK_USERNAME_URL, GEOCODE_REVERSE_URL, GEOCODE_FORWARD_URL } from '../../constants';

it('exposes the auth/geocode endpoint paths', () => {
  expect(CHECK_USERNAME_URL).toBe('/api/v1/auth/users/check-username');
  expect(GEOCODE_REVERSE_URL).toBe('/api/v1/geocode/reverse');
  expect(GEOCODE_FORWARD_URL).toBe('/api/v1/geocode/forward');
});
