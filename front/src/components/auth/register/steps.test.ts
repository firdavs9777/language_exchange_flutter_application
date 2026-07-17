import { SIGNUP_STEPS } from './steps';

it('verifies email before collecting profile (app parity)', () => {
  expect(SIGNUP_STEPS.indexOf('verify')).toBeLessThan(SIGNUP_STEPS.indexOf('basics'));
  expect(SIGNUP_STEPS).toEqual(['email', 'verify', 'basics', 'languages', 'photo', 'finish']);
});
