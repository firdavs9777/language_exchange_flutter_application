export function passwordStrength(pw: string) {
  const hasMin = pw.length >= 8;
  const hasUpper = /[A-Z]/.test(pw);
  const hasLower = /[a-z]/.test(pw);
  const hasDigit = /[0-9]/.test(pw);
  const valid = hasMin && hasUpper && hasLower && hasDigit;
  const score = [hasMin, hasUpper && hasLower, hasDigit].filter(Boolean).length as 0 | 1 | 2 | 3;
  return { score, hasMin, hasUpper, hasLower, hasDigit, valid };
}

export function isAdult(birthISO: string, now: Date = new Date()): boolean {
  const b = new Date(birthISO);
  if (isNaN(b.getTime())) return false;
  let age = now.getFullYear() - b.getFullYear();
  const m = now.getMonth() - b.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < b.getDate())) age -= 1;
  return age >= 18;
}

export function usernameFormatValid(u: string): boolean {
  return /^[a-z0-9_]{3,20}$/.test((u || '').trim().toLowerCase());
}
