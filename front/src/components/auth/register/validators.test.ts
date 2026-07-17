import { passwordStrength, isAdult, usernameFormatValid } from './validators';

describe('passwordStrength', () => {
  it('invalid when under rules', () => {
    expect(passwordStrength('abc').valid).toBe(false);
    expect(passwordStrength('alllowercase1').hasUpper).toBe(false);
  });
  it('valid with 8+ upper lower digit', () => {
    const s = passwordStrength('Abcdef12');
    expect(s.valid).toBe(true);
    expect(s.hasMin && s.hasUpper && s.hasLower && s.hasDigit).toBe(true);
  });
});
describe('isAdult', () => {
  const now = new Date('2026-07-18');
  it('true for >=18', () => { expect(isAdult('2008-07-18', now)).toBe(true); });
  it('false for <18', () => { expect(isAdult('2010-01-01', now)).toBe(false); });
  it('false the day before 18th birthday', () => { expect(isAdult('2008-07-19', now)).toBe(false); });
});
describe('usernameFormatValid', () => {
  it('accepts valid', () => { expect(usernameFormatValid('cool_user1')).toBe(true); });
  it('rejects short/space/caps-with-space', () => {
    expect(usernameFormatValid('ab')).toBe(false);
    expect(usernameFormatValid('has space')).toBe(false);
  });
});
