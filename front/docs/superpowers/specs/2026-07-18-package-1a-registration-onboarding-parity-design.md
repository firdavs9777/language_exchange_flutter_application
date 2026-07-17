# Package 1a — Registration & Onboarding Parity (Web)

**Date:** 2026-07-18
**Status:** Design spec (approved in brainstorming; pending written-spec review → implementation plan).
**Parent:** Package 1 (Auth hardening) of the [mobile-parity roadmap](./2026-07-17-mobile-parity-roadmap.md). Package 1 is split into **1a (this doc)** = registration/onboarding parity, and **1b** = auth resilience (refresh single-flight, error taxonomy, logout-all, route guard) — 1b is a separate later cycle.

## Goal

Bring the **web** signup (`front`, React 18 + CRA + RTK Query) to parity with the **Flutter app's** two-phase onboarding, matching the **backend contract exactly**. The mobile app is the source of truth; every claim below was verified against real app + backend code (file:line references included).

## Source-of-truth: the app's verified onboarding flow

App files under `bananatalk_app/lib/pages/authentication/register/`:

**Phase 0 — Email first:** email → OTP code verify (`sendCodeEmail`, `verifyEmailCode`) BEFORE any profile data. (Web currently verifies *last* — this reorders it.)

**Phase 1 — Basics (`register_screen.dart`):**
- `name`
- `username` — **optional**, live availability check via `UsernameAvailabilityField` → `GET /api/v1/auth/users/check-username?value=`; blocks "next" if entered-but-taken; submitted **lowercased**, `null` when empty (`register_screen.dart:262`, `:193-194`).
- `password` + confirm, with a **password strength meter** (`password_strength_meter.dart`).
- `gender` — chips (male/female/other).
- `birthDate` — **18+ gate**: `if (age < 18) error = mustBe18` (`register_screen.dart:231`, also re-checked `register_two_screen.dart:695`).

**Phase 2 — Wizard (`register_two_screen.dart`, PageView):**
- `profile photo` — **required** (`_submit`: `if (_pickedPhoto == null) return`).
- `native_language` + CEFR level; `language_to_learn` + CEFR level (`native_language_step.dart`, `personal_info_step.dart`).
- **Finish step** (`finish_step.dart`): location + terms + submit.

**Finish submit order & rules (`register_two_screen.dart:431-448`):**
1. photo required → 2. **location required** (`if (_city == null || _country == null) { showLocationError; return; }`) → 3. **terms required** (`if (!_termsAccepted) return`) → submit.

**Email-register payload** (`register_two_screen.dart:585-610`, sent to `authService.register`):
```
{ name, username|null, password, email, bio:'', gender, images:[],
  birth_day, birth_month, birth_year, native_language, language_to_learn,
  topics: [],                       // ← EMPTY: topics NOT collected at signup
  termsAccepted: true,
  location: { type:'Point', coordinates:[lng,lat], formattedAddress:"City, Country", city, country } }
```
Location comes from `geolocator` GPS → `placemarkFromCoordinates` reverse-geocode; when GPS fails the app falls back to `coordinates:[0.0,0.0]` and empty strings.

**Post-register:** on success, separate multipart photo upload `PUT /auth/users/:id/photo`, then auto-login.

**OAuth completion path:** incomplete Google profiles run the same Phase-2 wizard, submitting via `updateDetails` (`updateDetailsURL`) which includes location only `if (city != null && country != null)` and sends `termsAccepted`.

## Backend contract (verified)

- `POST /api/v1/auth/register` (`controllers/auth.js:407`) accepts: `email, password, name, gender, bio, birth_year, birth_month, birth_day, images, native_language, language_to_learn, mbti, bloodType, location, termsAccepted`. Required: email, password, name, gender, birth_*, native_language, language_to_learn. `location` optional.
  - **`termsAccepted` is stored** → `user.termsAccepted = true; user.termsAcceptedDate = new Date()` (`controllers/auth.js` ~491). User model has `termsAccepted`, `termsAcceptedDate` (`models/User.js:64-70`). **No backend change needed for terms.**
  - **`username` is IGNORED and auto-generated** → `const username = await generateUsername(name)`. The client-sent username is dropped. **This is the gap fixed in Decision A.**
  - **`topics` is NOT accepted** by register. Topics are set later via `PUT /api/v1/community/topics/my` `{topics:[...]}` (max 10), listed via `GET /api/v1/community/topics` → `{data:[{id,name,icon,category,color,userCount}]}`. Both `protect`ed. **Topics are out of signup scope.**
- `location` schema (`models/User.js:252`): GeoJSON `{ type:'Point', coordinates:[Number] (2dsphere), formattedAddress, street, city, state, zipcode, country }`.
- `PUT /api/v1/auth/users/:id` (`updateUser`) allows `username` (not in the restricted-field list `role,userMode,vipSubscription,fcmTokens,password,email,birthDateChangesAt`), so editing username already reaches the DB — but with **no format/reserved/uniqueness pre-validation** (relies on the unique index throwing). Decision A hardens this for both app and web edit.
- `GET /api/v1/auth/users/check-username?value=` (`checkUsernameAvailability`) → `{data:{available, reason}}`, format `^[a-z0-9_]{3,20}$`, reserved-name set. Reuse this for both signup and edit availability UX.

## Scope

### In scope (1a)
1. **Reorder web signup to email-verify-first**, then Phase-1 Basics, then Phase-2 wizard — matching the app.
2. **Add to web signup:** username (optional, live-check, lowercased), password strength meter, 18+ birthdate gate, CEFR level for both languages, **required** profile photo, **required** location (city+country) with GPS-detect **and manual fallback**, terms-acceptance checkbox.
3. **Terms:** send `termsAccepted:true` in the register body (email flow) / via completion for OAuth. `POST /api/v1/auth/accept-terms` used by the OAuth-completion path when a token already exists. *(Confirm this endpoint exists during planning; if absent, terms for OAuth piggybacks on the profile-completion `PUT`.)*
4. **OAuth completion parity:** incomplete Google profiles run the same Phase-2 wizard.
5. **Backend Decision A** (careful, non-breaking): `register` and `updateUser` honor a client-supplied username — validate format `^[a-z0-9_]{3,20}$`, reserved-name set, uniqueness (excluding self on edit); fall back to `generateUsername(name)` when blank on register. Existing auto-generated usernames untouched.
6. **"100% true" location handling** (Decision B): stored coordinates must be real. GPS granted → real reverse-geocoded coordinates + city/country. Manual entry → forward-geocode to real coordinates if possible; otherwise store city/country/formattedAddress and **omit coordinates** rather than send `[0,0]`. (Verify backend accepts a `location` without `coordinates`, or a top-level city/country without a Point; adjust payload accordingly during planning.)

### Out of scope (1a)
- **Topics/interests at signup** — not in the app flow; deferred to Package 4 (profile) where topic editing lives.
- All of **1b**: refresh single-flight/queue, 429/Retry-After handling, 403 suspended/banned UX, typed error-code taxonomy, logout-all, protected-route wrapper.
- Apple/Facebook native OAuth, FCM, biometric (roadmap out-of-scope).
- httpOnly token migration (tracked as debt, not 1a).

## Web design

### Component structure
Restructure the existing `src/components/auth/Register.tsx` (today a 3-step: account → profile → verify, auto-login, no username/location/terms/CEFR) into a wizard that mirrors the app, reusing its existing `step` state + progress bar rather than rewriting:

- `Register.tsx` — orchestrator: owns wizard state + step routing + final submit.
- New step components under `src/components/auth/register/`:
  - `EmailVerifyStep.tsx` (Phase 0)
  - `BasicsStep.tsx` (Phase 1: name, username, password+strength, gender, birthdate+18 gate)
  - `LanguagesStep.tsx` (Phase 2: native + learning + CEFR levels)
  - `PhotoStep.tsx` (Phase 2: required profile photo)
  - `FinishStep.tsx` (Phase 2: location + terms + submit)
- New reusable widgets:
  - `UsernameAvailabilityField.tsx` — 500ms debounced call to `check-username`, states: idle/checking/available/taken/invalid; mirrors the app widget.
  - `PasswordStrengthMeter.tsx` — ≥8 chars, upper+lower+digit (match app rule).
  - `LocationField.tsx` — "Use my location" (`navigator.geolocation` + reverse geocode) OR manual country picker + city; guarantees "100% true" coordinates per Decision B.

### State, validation, endpoints
- Reuse RTK Query hooks in `src/store/slices/` (`useRegisterUserMutation`, `useRegisterCodeEmailMutation`, `useVerifyRegistrationCodeMutation`, `useUploadUserPhotoMutation`); add a `checkUsername` query and a geocoding helper.
- Validation gates mirror the app exactly: username (if present) must be available; password strength; age ≥ 18; photo present; city+country present; terms checked — enforced before final submit, with inline field errors.
- Final submit = `POST /auth/register` with the app-identical body (username honored post-Decision-A, `topics:[]`, `termsAccepted:true`, `location{…}`), then `PUT /auth/users/:id/photo`, then auto-login + redirect (respecting existing `?redirect=`).

### Geocoding (the "100% true" dependency)
Need a browser-usable geocoder for reverse (coords→city/country) and forward (city/country→coords). Options evaluated during planning: (a) a tiny backend proxy endpoint wrapping a provider (keeps keys server-side, consistent results app↔web) — **recommended**; (b) a client-side provider with a public key. Must never fabricate coordinates. This is the one genuinely new dependency 1a introduces and will be pinned down in the implementation plan.

## Backend changes (Decision A — careful, non-breaking)

`controllers/auth.js`:
- `register`: read optional `req.body.username`; if non-empty, normalize (lowercase/trim), validate format + reserved set, check uniqueness (`User.exists`), and use it; else keep `generateUsername(name)`. On collision/invalid, return a typed 400 (`USERNAME_TAKEN` / `USERNAME_INVALID`) so web/app can show a field error rather than a generic failure.
- `updateUser` (`controllers/users.js`): when `username` is in the body, apply the same normalize+format+reserved+uniqueness(excluding self) validation before persisting, returning the same typed errors. Careful: do not regress existing edits that omit username; do not disturb users whose usernames were auto-generated.
- Reuse the existing `RESERVED_USERNAMES` set and regex from `checkUsernameAvailability` (extract to a shared helper to avoid drift).

This makes username behavior identical across **app signup, app edit, web signup, web edit, and the backend** — the "match perfectly with backend, and also true for app when editing" requirement.

## Testing
- **Web unit tests** (existing Jest/RTL setup): `UsernameAvailabilityField` (debounce + state transitions incl. taken/invalid), `PasswordStrengthMeter` thresholds, 18+ birthdate validator, `LocationField` (GPS-grant path, manual path, never emits `[0,0]`), and the final-submit payload builder (asserts app-identical body shape).
- **Backend unit tests** (existing `node --test`): username honoring in `register` (custom accepted, blank→generated, taken→typed 400, invalid→typed 400) and `updateUser` (self-exclusion on uniqueness, reserved/invalid rejected).
- Manual: full email signup, Google-OAuth-incomplete completion, and cross-checking a resulting user doc matches an app-created one field-for-field.

## Open items to resolve in the implementation plan
1. Locate `POST /auth/accept-terms` (roadmap named it) vs. folding OAuth terms into the completion `PUT`.
2. Choose the geocoding approach (recommend backend proxy) and provider.
3. Confirm backend tolerates a `location` with no `coordinates` (for the manual-only, no-forward-geocode case) or decide the canonical manual payload.
4. Confirm the CEFR level field name(s) the backend expects (`languageLevel`) and that register / updateDetails accept them.
