import { buildResetPayload } from './buildResetPayload';

it('includes the verified code (backend requires it)', () => {
  expect(buildResetPayload({ email: 'a@b.com', code: '123456', newPassword: 'Abcdef12' }))
    .toEqual({ email: 'a@b.com', code: '123456', newPassword: 'Abcdef12' });
});

it('throws if code missing (prevents the current broken call)', () => {
  expect(() => buildResetPayload({ email: 'a@b.com', code: '', newPassword: 'Abcdef12' })).toThrow();
});

it('throws if code is blank/whitespace', () => {
  expect(() => buildResetPayload({ email: 'a@b.com', code: '   ', newPassword: 'Abcdef12' })).toThrow();
});

it('trims the code', () => {
  expect(buildResetPayload({ email: 'a@b.com', code: ' 123456 ', newPassword: 'Abcdef12' }))
    .toEqual({ email: 'a@b.com', code: '123456', newPassword: 'Abcdef12' });
});
