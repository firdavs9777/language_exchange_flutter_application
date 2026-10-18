import { isProfileComplete, oauthCompletionState } from "./socialSignIn";

describe("isProfileComplete (moved from AuthCallback)", () => {
  // Every new social account is created with isRegistrationComplete:true AND
  // profileCompleted:false (Apple: be controllers/auth.js:341-365; Google:
  // :241-249 + the model default, models/User.js:356). The old order returned
  // true on isRegistrationComplete first, so new sign-ups skipped the wizard.
  it("a fresh social account (isRegistrationComplete but profileCompleted:false) is incomplete", () => {
    expect(isProfileComplete({ isRegistrationComplete: true, profileCompleted: false })).toBe(false);
  });
  it("isRegistrationComplete still counts when profileCompleted is absent (older payloads)", () => {
    expect(isProfileComplete({ isRegistrationComplete: true })).toBe(true);
  });
  it("is incomplete while profileCompleted is false or missing", () => {
    expect(isProfileComplete({ profileCompleted: false, native_language: "Korean" })).toBe(false);
    expect(isProfileComplete({})).toBe(false);
    expect(isProfileComplete(undefined)).toBe(false);
  });
  it("treats the old placeholder defaults as incomplete", () => {
    expect(
      isProfileComplete({ profileCompleted: true, native_language: "English", language_to_learn: "Korean", gender: "other" })
    ).toBe(false);
  });
  it("is complete with real values", () => {
    expect(
      isProfileComplete({ profileCompleted: true, native_language: "Uzbek", language_to_learn: "Korean", gender: "male" })
    ).toBe(true);
  });
});

describe("oauthCompletionState", () => {
  // A brand-new Apple account as be controllers/auth.js:341-365 creates it.
  const freshApple = {
    _id: "u1",
    name: "Ada Lovelace",
    email: "abc@privaterelay.appleid.com",
    gender: "",
    bio: "",
    birth_year: "",
    birth_month: "",
    birth_day: "",
    native_language: "",
    language_to_learn: "",
    profileCompleted: false,
    isRegistrationComplete: true,
  };

  it("sends a new Apple account into the wizard at the languages step", () => {
    expect(oauthCompletionState(freshApple, "apple")).toEqual({
      oauth: true,
      startStep: "languages",
      userData: {
        _id: "u1",
        name: "Ada Lovelace",
        email: "abc@privaterelay.appleid.com",
        bio: "Hello! I joined using Apple.",
        gender: "other",
        nativeLanguage: "",
        languageToLearn: "",
        birthDate: "2000-01-01",
      },
    });
  });

  it("keeps Google's default bio and pads a stored birth date", () => {
    const s = oauthCompletionState(
      { _id: "u2", name: "B", email: "b@x.io", gender: "Female", birth_year: "1999", birth_month: "3", birth_day: "7" },
      "google"
    );
    expect(s.userData.bio).toBe("Hello! I joined using Google.");
    expect(s.userData.gender).toBe("female");
    expect(s.userData.birthDate).toBe("1999-03-07");
  });

  it("keeps a bio the person already wrote", () => {
    expect(oauthCompletionState({ _id: "u3", bio: "Hi from Tashkent" }, "apple").userData.bio).toBe("Hi from Tashkent");
  });
});
