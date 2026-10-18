/**
 * What happens after any social sign-in (Google callback, Apple popup):
 * is the profile complete, and if not, the state that opens the signup
 * wizard in completion mode (Register.tsx, `state.oauth`).
 */

export function isProfileComplete(userInfo: any): boolean {
  // A social account the backend just created says isRegistrationComplete
  // AND profileCompleted:false (be controllers/auth.js, Apple and Google).
  // The explicit "not completed" wins; before Phase 4 the order was the other
  // way round and a fresh Apple sign-up skipped the wizard.
  if (userInfo?.profileCompleted === false) return false;

  if (userInfo?.isRegistrationComplete === true) return true;

  if (userInfo?.profileCompleted === undefined) return false;

  const nativeLanguage = userInfo?.native_language;
  const languageToLearn = userInfo?.language_to_learn;
  const gender = userInfo?.gender;

  const hasDefaultValues =
    (!nativeLanguage || nativeLanguage === "" || nativeLanguage === "English") &&
    (!languageToLearn || languageToLearn === "" || languageToLearn === "Korean") &&
    (!gender || gender === "other" || gender === "");

  return !hasDefaultValues;
}

export interface OAuthCompletionState {
  oauth: true;
  startStep: "languages";
  userData: {
    _id: string;
    name: string;
    email: string;
    bio: string;
    gender: string;
    nativeLanguage: string;
    languageToLearn: string;
    birthDate: string;
  };
}

const DEFAULT_BIO: { [p: string]: string } = {
  google: "Hello! I joined using Google.",
  apple: "Hello! I joined using Apple.",
};

export function oauthCompletionState(userInfo: any, provider: "google" | "apple"): OAuthCompletionState {
  const u = userInfo || {};
  const pad = (v: any) => String(v).padStart(2, "0");
  return {
    oauth: true,
    startStep: "languages",
    userData: {
      _id: u._id || "",
      name: u.name || "",
      email: u.email || "",
      bio: u.bio || DEFAULT_BIO[provider],
      gender: (u.gender && String(u.gender).toLowerCase()) || "other",
      nativeLanguage: u.native_language || "",
      languageToLearn: u.language_to_learn || "",
      birthDate:
        u.birth_year && u.birth_month && u.birth_day
          ? `${u.birth_year}-${pad(u.birth_month)}-${pad(u.birth_day)}`
          : "2000-01-01",
    },
  };
}
