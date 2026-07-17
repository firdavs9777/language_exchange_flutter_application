export const SIGNUP_STEPS = ['email', 'verify', 'basics', 'languages', 'photo', 'finish'] as const;
export type SignupStep = typeof SIGNUP_STEPS[number];
export const STEP_LABELS: Record<SignupStep, string> = {
  email: 'Email',
  verify: 'Verify',
  basics: 'Account',
  languages: 'Languages',
  photo: 'Photo',
  finish: 'Finish',
};
