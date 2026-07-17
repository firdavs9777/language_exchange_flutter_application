export function buildResetPayload(input: { email: string; code: string; newPassword: string }) {
  if (!input.code || !input.code.trim()) {
    throw new Error('Verification code is required to reset the password');
  }
  return { email: input.email, code: input.code.trim(), newPassword: input.newPassword };
}
