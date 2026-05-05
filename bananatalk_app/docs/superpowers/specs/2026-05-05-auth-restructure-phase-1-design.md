# Auth Restructure & UX Wins — Phase 1

**Date:** 2026-05-05
**Branch:** `refactor/auth-restructure` (off `main`)
**Scope:** `lib/pages/authentication/` only, plus `.gitignore` and 17 ARB locales

## Goal

1. Reorganize the 12-file flat `screens/` directory into flow-based subfolders
2. Extract 6 shared widgets to eliminate ~700 lines of copy-pasted boilerplate
3. Split `register_second.dart` (1530 lines) into per-step files
4. Ship 3 low-risk UX wins: B (show-password toggle), C (password strength indicator), D (remember me)
5. Remove untracked Xcode build artifacts and prevent recurrence
6. Fix the `forget→forgot` typo

Phases 2 (biometric, username availability, profile pic cropping in flow) and 3 (magic link, phone OTP, account linking, onboarding tutorial) are deferred to separate specs.

## Current state

12 Dart files in `lib/pages/authentication/screens/`, all flat:

| File | Lines | Notes |
|---|---|---|
| `register_second.dart` | 1530 | Multi-step PageView wizard, monolithic |
| `register.dart` | 635 | First-step register |
| `google_login.dart` | 616 | OAuth + post-login flow |
| `apple_login.dart` | 555 | OAuth + post-login flow |
| `login.dart` | 494 | Email/password login |
| `terms_of_service.dart` | 462 | Mostly content text |
| `facebook_login.dart` | 457 | OAuth + post-login flow |
| `email_verification.dart` | 322 | OTP entry |
| `forgot_password_verification.dart` | 314 | OTP entry |
| `reset_password.dart` | 266 | New-password entry |
| `email_input.dart` | 226 | Email collection step |
| `forget_password_email.dart` | 207 | Typo: forget → forgot |

Plus a 1.5 MB `screens/build/` directory containing 91 Xcode `XCBuildData/PIFCache/*.json` files (untracked, should never have been written there).

Smells:
- ~12 inline `ScaffoldMessenger.showSnackBar` blocks duplicated
- ~7 `ElevatedButton` blocks duplicated as primary CTAs
- ~6 inline TextField blocks with focus-border, prefix-icon, validation logic
- 3 nearly-identical social login button widgets (Apple/Google/Facebook)
- Inconsistent file naming (`login.dart` vs `terms_of_service.dart` vs `register_second.dart`)

## Target folder layout

```
lib/pages/authentication/
├── widgets/                                    NEW shared building blocks
│   ├── auth_text_field.dart
│   ├── password_field.dart                     B (toggle) + C (strength meter)
│   ├── social_login_button.dart
│   ├── auth_gradient_button.dart
│   ├── auth_snackbar.dart
│   └── auth_screen_scaffold.dart
├── login/                                      NEW
│   ├── login_screen.dart                       was login.dart (+ D remember me)
│   ├── apple_login_screen.dart
│   ├── google_login_screen.dart
│   └── facebook_login_screen.dart
├── register/                                   NEW
│   ├── register_screen.dart                    was register.dart
│   ├── register_two_screen.dart                was register_second.dart, ~400
│   └── register_two/                           extracted steps
│       ├── progress_indicator.dart             "Step 2 of 4" pill
│       ├── personal_info_step.dart
│       ├── native_language_step.dart
│       ├── learning_language_step.dart
│       └── finish_step.dart
├── password_reset/                             NEW + fix typo
│   ├── forgot_password_email_screen.dart       was forget_password_email.dart
│   ├── forgot_password_verification_screen.dart
│   └── reset_password_screen.dart
├── email_verification/                         NEW
│   ├── email_input_screen.dart
│   └── email_verification_screen.dart
└── terms_of_service_screen.dart                solo file, kept at root
```

The empty `screens/` folder is removed. The build artifacts are deleted (untracked anyway) and a `.gitignore` rule blocks future leaks.

The folder name `authentication/` is preserved — renaming to `auth/` would touch every import in the app for marginal value.

## Shared `widgets/` contents

### `auth_text_field.dart`
```dart
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final TextCapitalization capitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final bool enabled;
}
```
Renders the canonical bordered field with primary-color focus, prefix icon, hint, error-state border, ~16-radius. Replaces ~6 inline blocks of ~50 lines each.

### `password_field.dart`
```dart
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool showStrengthMeter;   // C feature; default false
  final TextInputAction textInputAction;
}
```
- **B (show-password)** — eye icon suffix, tap toggles `obscureText`, animated icon swap
- **C (strength meter)** — when `showStrengthMeter: true`, 4-segment bar below the field. Score: length ≥8, has digit, has uppercase, has special char. 0–4 segments fill red → yellow → green. Pure client-side.

Used by login, register, register_two (if used there), reset_password.

### `social_login_button.dart`
```dart
enum SocialProvider { apple, google, facebook }

class SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;
}
```
Platform-correct icon, brand color, label ("Continue with Apple"). Replaces 3 nearly-identical button blocks.

### `auth_gradient_button.dart`
```dart
class AuthGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
}
```
Same `[#00BFA5 → #00897B]` gradient pattern as profile, full-width. Replaces ~7 `ElevatedButton` instances.

### `auth_snackbar.dart`
```dart
enum AuthSnackBarType { success, error, info }
void showAuthSnackBar(BuildContext context, {required String message, AuthSnackBarType type = AuthSnackBarType.success});
```
Same shape as `profile_snackbar.dart` (intentionally — both share the floating row+icon pattern). Replaces ~12 inline calls.

### `auth_screen_scaffold.dart`
```dart
class AuthScreenScaffold extends StatelessWidget {
  final String? title;
  final bool showBackButton;
  final Widget body;
  final EdgeInsetsGeometry? bodyPadding;
  final bool resizeToAvoidBottomInset;
}
```
Light scaffold for auth screens — surface bg, transparent AppBar with rounded back, scrollable body that survives keyboard pop-up.

**Estimated reduction:** ~700 lines of duplicated code → ~590 lines of widgets, plus consistent UX across every auth screen.

## File splits

### `register_second.dart` (1530 → ~400)

Already a `PageView` wizard with `_currentStep` index and `_totalSteps` computed from OAuth-user state. The 4 inline build methods become files:

```
register/register_two/
├── progress_indicator.dart        ~80   "Step 2 of 4" pill
├── personal_info_step.dart        ~280  gender + birth date (OAuth top-up)
├── native_language_step.dart      ~220  language picker
├── learning_language_step.dart    ~220  language picker (+ disallow same as native)
└── finish_step.dart               ~180  review + finish CTA
```

`register_two_screen.dart` keeps state class, `PageController`, `_totalSteps` logic, navigation, final submit handler. Each step is a `StatelessWidget`/`ConsumerWidget` receiving controllers and `onNext`/`onBack` callbacks via constructor params. No state ownership moves out.

### Other 11 files — light migration only

All under 700 lines. They get the widget-migration treatment (replace inline TextField / ElevatedButton / snackbar / scaffold with new widgets) but stay as single files.

Expected sizes after migration:
- `login.dart` 494 → ~280 (+ remember-me toggle)
- `register.dart` 635 → ~340
- `apple_login.dart` 555 → ~250
- `google_login.dart` 616 → ~270
- `facebook_login.dart` 457 → ~220
- `reset_password.dart` 266 → ~160
- `forgot_password_email.dart` 207 → ~140
- `forgot_password_verification.dart` 314 → ~200
- `email_input.dart` 226 → ~140
- `email_verification.dart` 322 → ~200
- `terms_of_service.dart` 462 → unchanged (mostly content text)

## UX-win integration

### B — Show-password toggle
Automatic, baked into `PasswordField`. Every screen using it gets the toggle for free.

### C — Password strength indicator
`PasswordField(showStrengthMeter: true)` enabled on:
- `register.dart`'s password field
- `reset_password.dart`'s new-password field
- NOT on login (security through obscurity isn't useful there + nags users)

### D — Remember me
Added to `login_screen.dart` only:
- `CheckboxListTile` below the email/password fields, default ON
- On successful login: `prefs.setString('rememberedEmail', email)` if checked, else `prefs.remove('rememberedEmail')`
- On screen `initState`: prefill email field from `prefs.getString('rememberedEmail')`
- Email only — never persist the password to SharedPreferences

## New ARB keys

8 keys, English source in `app_en.arb`, then translated to 17 locales:

| Key | English | Templated? |
|---|---|---|
| `rememberMe` | "Remember me" | no |
| `passwordWeak` | "Weak" | no |
| `passwordFair` | "Fair" | no |
| `passwordStrong` | "Strong" | no |
| `passwordVeryStrong` | "Very strong" | no |
| `showPassword` | "Show password" | no (a11y label) |
| `hidePassword` | "Hide password" | no (a11y label) |
| `stepProgress` | "Step {current} of {total}" | yes — `{current}` int, `{total}` int |

## Migration plan — 7 commits

| # | Commit | Verification |
|---|---|---|
| C0 | Cleanup: `rm -rf lib/pages/authentication/screens/build/` + add `lib/**/build/` rule to `.gitignore` | `git status` clean of artifacts |
| C1 | Add `widgets/` (6 files), no callers yet | `flutter analyze` clean |
| C2 | Add 8 ARB keys + translate to 17 locales via subagent | `flutter gen-l10n` clean, all 18 ARB files valid JSON |
| C3 | Migrate login + 3 social-login screens. **+D remember-me on login_screen** | Open each, flow works, remembered email prefills on relaunch |
| C4 | Migrate register + password reset + email screens. **B + C automatically active** wherever `PasswordField` lands | Open register, reset, email flows; toggle works; strength meter shows |
| C5 | File moves + folder grouping via `git mv`. **Fix `forget→forgot` typo.** Update imports project-wide | `flutter analyze lib/` zero errors, every import resolves |
| C6 | Split `register_two_screen.dart` (1530) into step files | Step navigation works, all 4 steps render, finish submits |

Each commit gates on `flutter analyze` clean + a manual smoke test of the touched flow. Per-commit revert.

## Risk register

- **Import sprawl from file moves** — `git mv` preserves history; `dart fix` + `flutter analyze` after each commit.
- **OAuth flow regression (Apple/Google/Facebook return URLs)** — don't touch `_handleSocialLogin` callbacks; only the visual button is replaced.
- **`register_two_screen` step extraction breaks PageView state** — steps stay dumb (no local state); parent owns controllers + page index.
- **Remember Me accidentally prefills password** — spec says email only; password is never persisted to SharedPreferences.
- **Translation regressions** — same subagent pattern that landed cleanly across 60 keys × 17 locales for profile.

## Out of scope (deferred)

- Auth provider (`auth_providers.dart`) review and any service-layer changes
- Phase 2 features: biometric login, username availability check, multi-step signup progress visuals beyond the simple "Step 2 of 4" pill, profile-pic cropping in flow
- Phase 3 features: magic link, phone OTP login, account linking, onboarding tutorial slides
- Backend changes (none required for Phase 1; D is client-only)
- Tests for any auth screen (separate effort)
- Dark-mode pass on the new widgets (inherits from existing screen state — verify still works)
