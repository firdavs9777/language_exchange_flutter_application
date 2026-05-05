# Auth Phase 2 — Biometric login, username availability, signup polish

**Date:** 2026-05-05
**Branch:** `refactor/auth-phase-2` (off `main`)
**Scope:** `lib/pages/authentication/`, the `users` controller in backend, `pubspec.yaml`, `Info.plist`, all 18 ARB locales

## Goal

Four feature tracks, all opt-in or non-disruptive:

1. **Biometric login** — Face ID / Touch ID for returning users (opt-in after first login)
2. **Username availability check** — optional username field on register with live debounced check
3. **Better progress visuals** — segmented bar replaces the simple "Step N of M" pill in the register wizard
4. **Profile-photo cropping** — `image_cropper` integrated in the existing edit flow, plus a new optional photo step in the register wizard

Phase 3 features (magic link, phone OTP, account linking, onboarding tutorial, username generation suggestions) are deferred to a separate spec.

## Dependencies (added in C0)

```yaml
local_auth: ^2.3.0
flutter_secure_storage: ^9.2.4
image_cropper: ^7.1.0
```

iOS `Info.plist` additions (required by `local_auth` + `image_cropper`):
- `NSFaceIDUsageDescription` — "Authenticate to log in to Bananatalk"

## Backend — `/api/v1/users/check-username`

```
GET /api/v1/users/check-username?value=foo
→ 200 { success: true, data: { available: bool, reason?: 'taken'|'invalid_format'|'reserved' } }
```

Server-side validation:
1. Format: `/^[a-z0-9_]{3,20}$/` (lowercase). Invalid → `available: false, reason: 'invalid_format'`.
2. Reserved word check against in-memory list: `[admin, root, support, help, api, banatalk, bananatalk]`. Matched → `available: false, reason: 'reserved'`.
3. Uniqueness: `User.exists({ username: value })`. Matched → `available: false, reason: 'taken'`.

Rate-limited via the existing `generalLimiter` middleware. Endpoint is public (auth not required) — minor enumeration risk acceptable for this app's threat model since usernames are public anyway.

## Folder additions

```
lib/pages/authentication/
├── widgets/                                       (existing — adds 3)
│   ├── biometric_login_button.dart                NEW
│   ├── username_availability_field.dart          NEW
│   └── auth_step_progress.dart                    NEW
├── biometric/                                     NEW
│   ├── biometric_service.dart
│   ├── biometric_token_storage.dart
│   └── enable_biometric_prompt.dart
└── register/register_two/
    └── profile_photo_step.dart                    NEW (inserted into wizard)

lib/pages/profile/edit/picture_edit/
└── photo_picker_sheet.dart                        MODIFIED — runs picker output through image_cropper
```

## Biometric login

### Service layer
```dart
class BiometricService {
  Future<bool> isAvailable();             // device supports + has enrolled
  Future<bool> isEnabled();               // user opted-in for this app?
  Future<bool> authenticate({required String reason});
  Future<void> enable(String token);      // store token in secure storage
  Future<void> disable();                 // clear stored token
  Future<String?> readStoredToken();      // null if not enabled or expired
}
```

`BiometricTokenStorage` wraps `flutter_secure_storage` for the token under key `biometric_auth_token`. The `biometric_enabled` boolean flag stays in `SharedPreferences` for fast read.

### Opt-in flow
After a successful **email** or **OAuth** login → if `BiometricService.isAvailable() && !isEnabled()` → show `EnableBiometricPrompt` modal: "Use Face ID to log in next time?" [Skip] [Enable]. On Enable → biometric prompt fires → on success, store the just-received token in secure storage + set the SharedPreferences flag.

### Returning-user flow
On `LoginScreen.initState()` → if `isEnabled() && isAvailable()` → render `BiometricLoginButton` at the top of the login form: "Continue as Firdavs" with the appropriate Face ID / Touch ID / fingerprint icon. Tap → biometric prompt → on success, read token from secure storage → set in providers exactly as a fresh login would → navigate home.

### Edge cases
- **Token expired server-side** — biometric "succeeds" but the very next API call returns 401. We catch this in the existing 401 handler: clear secure storage + the `biometric_enabled` flag, drop to the login screen with snackbar "Session expired, please log in again."
- **User re-enrolls device biometric** — `local_auth` invalidates the keychain entry. `readStoredToken()` returns null. We fall back to email/password login silently.
- **Multi-account on shared device** — only one biometric token at a time. Logout clears it. Logging in as a different account replaces it.
- **Biometric becomes unavailable** (Face ID disabled in Settings) — `isAvailable()` returns false → button hides → user logs in normally.

### Where users opt OUT later
A "Biometric login" toggle is added to `profile_settings.dart`. Visible only if `BiometricService.isAvailable()`. Toggle on/off calls `enable(currentToken)` or `disable()`.

## Username availability

### Frontend widget
```dart
class UsernameAvailabilityField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final void Function(bool isAvailable) onAvailabilityChanged;
}
```

State machine:
| State | Indicator | Helper text |
|---|---|---|
| Empty | none | none (field is optional) |
| Format invalid | red ✗ | l10n.usernameInvalidFormat |
| Checking (debounced 500ms) | spinner | none |
| Available | green ✓ | l10n.usernameAvailable |
| Taken | red ✗ | l10n.usernameTaken |
| Reserved | red ✗ | l10n.usernameNotAvailable |
| Network failure | none | none — submit allowed; backend re-validates on register |

Format check runs client-side first (regex `/^[a-z0-9_]{3,20}$/`). Network calls only fire after format passes.

### Wiring in register_screen
- New optional field below name, before email
- Submit allowed if username is empty OR available; blocked if invalid/taken
- On submit: pass `username` to register API (already supported — `username` is nullable on the user model)

## Progress visuals — `auth_step_progress.dart`

```dart
class AuthStepProgress extends StatelessWidget {
  final int currentStep;        // 0-indexed
  final int totalSteps;
  final List<String>? labels;
}
```

Renders a segmented bar:
- Completed: solid `#00BFA5`
- Current: gradient pulse animation
- Future: `dividerColor.withValues(alpha: 0.3)`
- Node dots between segments: filled-with-check for completed, outlined-filled for current, empty outline for future
- Optional labels under each node (caption-small, primary for current, muted for others)

Used in `register_two_screen.dart`, replacing the existing simple pill from Phase 1.

## Photo cropping

### Existing edit flow (`photo_picker_sheet.dart`)
After `image_picker` returns a file, run `ImageCropper().cropImage()` with:
- `aspectRatioPresets: [CropAspectRatioPreset.square]` — forced (profile pics are circular crops on square)
- `compressQuality: 85`
- Theme-aware UI strings via `uiSettings`

Cancellation discards the file. Existing callers (`picture_edit.dart`) don't change — they already receive the resulting `File`, and now it's pre-cropped.

### New register-wizard step (`profile_photo_step.dart`)
Inserted into the register wizard after `personal_info_step` and before `native_language_step`. ~200 lines.

- Big circular avatar placeholder with "+" overlay
- Tap → reuses `showPhotoPickerSheet` from `profile/edit/picture_edit/`
- Skip button — explicit "Skip for now" link below the CTA
- Photo held in `_RegisterTwoState` until final submit
- On finish: photo uploaded via the existing user picture-upload API after `_finishRegistration` succeeds

Step inserted into `_totalSteps` calculation: now `[personal_info?] + photo + [native_lang?] + [learning_lang?] + finish`.

## ARB keys (added in C2)

12 keys × 17 locales:

| Key | English |
|---|---|
| `usernameOptional` | Username (optional) |
| `usernameAvailable` | Available |
| `usernameTaken` | Already taken |
| `usernameNotAvailable` | Not available |
| `usernameInvalidFormat` | 3–20 characters, letters, numbers, or underscore |
| `usernameHint` | @username |
| `enableBiometricTitle` | Use Face ID to log in next time? |
| `enableBiometricBody` | Skip typing your password by signing in with biometrics. |
| `enableBiometricCta` | Enable |
| `biometricSignInPrompt` | Authenticate to log in to Bananatalk |
| `continueAs` | Continue as {name} (templated `{name}` String) |
| `addProfilePhotoTitle` | Add a profile photo |
| `addProfilePhotoSkip` | Skip for now |

Translations follow the same Python-script pattern proven in Phase 1.

## Migration plan — 8 commits

| # | Commit | Verification |
|---|---|---|
| C0 | Add 3 deps + iOS `NSFaceIDUsageDescription` | `flutter pub get` resolves; iOS build succeeds |
| C1 | Backend `/users/check-username` endpoint | `curl https://api.banatalk.com/api/v1/users/check-username?value=admin` returns `{available: false, reason: 'reserved'}` |
| C2 | New ARB keys + 17-locale translations | `flutter gen-l10n` clean; all 18 ARBs valid JSON |
| C3 | `auth_step_progress.dart` + wire into wizard | Wizard renders segmented bar; all steps visible |
| C4 | `image_cropper` in `photo_picker_sheet.dart` | Pick photo in profile edit → cropper UI → returns square file |
| C5 | `biometric/` scaffolding (no callers) | `flutter analyze` clean |
| C6 | Wire biometric: opt-in prompt + login button + logout cleanup | Login → opt-in shown → next launch shows button → tap unlocks |
| C7 | `username_availability_field` + register screen wiring | Type → ✓/✗ states transition correctly; register submits with/without username |
| C8 | `profile_photo_step` inserted into register wizard | Wizard has +1 step; photo uploads after finish |

Each commit gates on `flutter analyze` clean + a manual smoke test of the touched flow.

## Risks

- **`local_auth` permissions** — iOS needs `NSFaceIDUsageDescription`; Android needs nothing extra (uses `USE_BIOMETRIC` permission auto-merged from the manifest)
- **`image_cropper` native config** — iOS needs Podfile entry; Android needs `UCropActivity` in the manifest. Verify on both platforms before C4 commit.
- **Token expiry after biometric** — handled in 401 fallback (clear secure storage + drop to login)
- **Multi-account** — single token at a time; logout clears it
- **Username enumeration** — minor; rate-limited; accepted

## Out of scope (Phase 3)

- Magic link login
- Phone-number / SMS OTP login
- Account linking (multiple OAuth providers per user)
- Onboarding tutorial slides after first signup
- Username generation suggestions
- Tests for any new widget (separate effort)
