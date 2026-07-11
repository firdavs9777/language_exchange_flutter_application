# Workstream A: Auth — Smooth + Cool UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the six audited auth issues (profile-completion dead-end, Apple revocation, refresh-secret weakness, refresh-queue hang, ambiguous errors, non-resumable wizard) and redesign the auth UI into one polished visual system.

**Architecture:** Backend fixes land first (error codes, profileCompleted enforcement, Apple logout revocation, refresh secret) since Flutter tasks consume them. Flutter logic fixes follow (timeout, routing, resume, error mapping), then the UI redesign built on upgraded shared widgets in `lib/pages/authentication/widgets/`.

**Tech Stack:** Node/Express + Mongoose (backend), Flutter + Riverpod + SharedPreferences (app). No test framework exists in the backend — verification uses one-off node scripts + curl against the dev server. Flutter logic gets real `flutter test` unit tests; UI gets `flutter analyze` + device smoke gates.

## Global Constraints

- Repos: backend `/Users/davis/Desktop/Personal/language_exchange_backend_application`, app `/Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app`
- Dart: `package:` imports only (linter-enforced, no relative `../` paths)
- Design tokens: teal `#00BFA5` primary, banana `#FFD54F` accent, system typography, dark-mode parity required (`lib/core/theme/app_theme.dart`)
- No forced logouts: refresh-secret migration must dual-verify legacy tokens
- Backend error responses keep shape `{ success: false, error: <message> }` — new `code` field is additive
- Commit per task; commit messages end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`

---

## Phase 1 — Backend fixes

### Task 1: Structured auth error codes

**Files:**
- Modify: `utils/errorResponse.js`
- Modify: `middleware/error.js` (response emit site)
- Modify: `controllers/auth.js` (verification-code, lockout, rate-limit, duplicate-email sites)

**Interfaces:**
- Produces: `ErrorResponse(message, statusCode, code)` — third optional arg; error JSON gains `"code"` when set. Codes used later by Flutter Task 8: `CODE_EXPIRED`, `CODE_INVALID`, `ACCOUNT_LOCKED`, `RATE_LIMITED`, `EMAIL_EXISTS`, `PROFILE_INCOMPLETE`.

- [ ] **Step 1: Extend ErrorResponse**

```javascript
// utils/errorResponse.js
class ErrorResponse extends Error {
  constructor(message, statusCode, code = null) {
    super(message);
    this.statusCode = statusCode;
    if (code) this.errorCode = code; // 'code' collides with Node err.code (Mongo uses 11000)
  }
}
module.exports = ErrorResponse;
```

- [ ] **Step 2: Emit code in error middleware**

In `middleware/error.js`, find the final `res.status(...).json(...)` at the bottom of `errorHandler` and include the code:

```javascript
  res.status(error.statusCode || 500).json({
    success: false,
    error: error.message || 'Server Error',
    ...(err.errorCode ? { code: err.errorCode } : {}),
  });
```

(Keep everything else in the handler untouched; note we read `err.errorCode`, not `error.errorCode`, because the spread copy at the top loses class fields on some paths — check both if needed: `err.errorCode || error.errorCode`.)

- [ ] **Step 3: Tag the auth sites in `controllers/auth.js`**

Split the combined verification-code check (~line 984). Current code returns one message for both cases; separate them:

```javascript
// BEFORE (single check):
//   return next(new ErrorResponse('Invalid or expired verification code', 400));
// AFTER — look up by hashed code WITHOUT expiry filter, then branch:
const hashedCode = crypto.createHash('sha256').update(code).digest('hex');
const user = await User.findOne({ emailVerificationCode: hashedCode });
if (!user) {
  return next(new ErrorResponse('That code is not correct. Check the code and try again.', 400, 'CODE_INVALID'));
}
if (user.emailVerificationExpire < Date.now()) {
  return next(new ErrorResponse('That code has expired. Request a new one.', 400, 'CODE_EXPIRED'));
}
```

(Adapt field names to the actual ones used in that block — the verify handler already queries these two fields; keep its subsequent logic unchanged. Apply the same split to the password-reset code check in `verifyResetCode`.)

Tag the other sites (message text unchanged, just add codes):
- Account locked (~line 559): `new ErrorResponse(<existing msg>, 423, 'ACCOUNT_LOCKED')`
- Duplicate email on register (~line 819): `..., 400, 'EMAIL_EXISTS')`
- Rate limiter 429s are emitted by `middleware/rateLimiter.js` handlers — add `code: 'RATE_LIMITED'` to their JSON bodies directly.

- [ ] **Step 4: Verify with curl**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application && npm run dev &
sleep 4
curl -s -X POST http://localhost:5001/api/v1/auth/verify-email \
  -H 'Content-Type: application/json' -d '{"email":"x@x.com","code":"000000"}' | python3 -m json.tool
```
Expected: JSON contains `"code": "CODE_INVALID"` (or the endpoint's param-validation error if it guards earlier — then test with a real pending signup). Stop the server after.

- [ ] **Step 5: Commit**

```bash
git add utils/errorResponse.js middleware/error.js controllers/auth.js middleware/rateLimiter.js
git commit -m "feat(auth): structured error codes for auth failures"
```

---

### Task 2: Enforce core fields for profileCompleted

**Files:**
- Modify: `controllers/auth.js:1306-1321` (`updateDetails`)

**Interfaces:**
- Produces: `profileCompleted` can never be true unless gender, birth_year, native_language, language_to_learn all present and languages differ. Flutter Task 6 relies on this flag being trustworthy.

- [ ] **Step 1: Replace the client-override branch**

The hole: `if (profileCompleted === true) { fieldsToUpdate.profileCompleted = true; }` trusts the client. Replace lines 1306-1321 with a single server-side check that merges incoming fields over stored ones:

```javascript
  // profileCompleted is ALWAYS derived server-side from core fields.
  // Merge incoming update over stored values so partial updates still evaluate correctly.
  const effective = {
    gender: fieldsToUpdate.gender ?? userBeforeUpdate?.gender,
    birth_year: fieldsToUpdate.birth_year ?? userBeforeUpdate?.birth_year,
    native_language: fieldsToUpdate.native_language ?? userBeforeUpdate?.native_language,
    language_to_learn: fieldsToUpdate.language_to_learn ?? userBeforeUpdate?.language_to_learn,
  };
  const coreComplete =
    effective.gender && String(effective.gender).length > 0 &&
    effective.birth_year && String(effective.birth_year).length > 0 &&
    effective.native_language && effective.language_to_learn &&
    effective.native_language !== effective.language_to_learn;

  if (coreComplete) {
    fieldsToUpdate.profileCompleted = true;
  } else if (profileCompleted === true) {
    // Client asked to complete but core fields are missing — refuse explicitly.
    return next(new ErrorResponse(
      'Profile is missing required fields (gender, birth date, languages).',
      400,
      'PROFILE_INCOMPLETE'
    ));
  }
```

Note: `userBeforeUpdate` select (line 1295) already fetches `gender native_language language_to_learn` — add `birth_year` to that select.

- [ ] **Step 2: Verify with a node script**

```bash
node -e "
const s = require('fs').readFileSync('controllers/auth.js','utf8');
if (s.includes('if (profileCompleted === true) {') && s.includes('fieldsToUpdate.profileCompleted = true;\n  }')) {
  console.log('CHECK: ensure old client-trust branch is gone');
}
console.log(s.includes('PROFILE_INCOMPLETE') ? 'PASS: guard present' : 'FAIL: guard missing');
"
```
Expected: `PASS: guard present`. Then curl `PUT /api/v1/auth/updatedetails` with a test token + `{"profileCompleted": true}` on an incomplete user → 400 with `code: PROFILE_INCOMPLETE`.

- [ ] **Step 3: Commit**

```bash
git add controllers/auth.js
git commit -m "fix(auth): derive profileCompleted server-side, refuse incomplete override"
```

---

### Task 3: Apple token revocation on logout

**Files:**
- Modify: `controllers/auth.js:650-680` (`logout`), reusing the pattern from the deletion path (lines 1685-1702)

**Interfaces:**
- Consumes: `apple-signin-auth` package, `APPLE_CLIENT_SECRET` + `APPLE_BUNDLE_ID` env vars (already used by deletion path).

- [ ] **Step 1: Add revocation into `logout`**

Insert after the refresh-token revocation block (after line 663), before the cookie reset:

```javascript
  // Apple requires apps to revoke tokens when the user signs out (App Store guideline 4.8)
  const fullUser = await User.findById(req.user.id).select('appleId email');
  if (fullUser?.appleId && process.env.APPLE_CLIENT_SECRET) {
    try {
      const appleSignin = require('apple-signin-auth');
      await appleSignin.revokeAuthorizationToken(process.env.APPLE_CLIENT_SECRET, {
        clientId: process.env.APPLE_BUNDLE_ID || 'com.banatalk.app',
        tokenTypeHint: 'access_token',
      });
      logSecurityEvent('APPLE_TOKEN_REVOKED_ON_LOGOUT', { userId: req.user.id });
    } catch (appleErr) {
      // Non-blocking: logout must still succeed
      console.error('⚠️ Apple token revocation on logout failed (non-blocking):', appleErr.message);
    }
  }
```

- [ ] **Step 2: Verify**

```bash
node -e "require('./controllers/auth.js'); console.log('PASS: module loads')"
```
Expected: `PASS: module loads` (no syntax errors; runtime path exercised in Task 14 device smoke with an Apple-linked test account).

- [ ] **Step 3: Commit**

```bash
git add controllers/auth.js
git commit -m "fix(auth): revoke Apple token on logout per App Store guidance"
```

---

### Task 4: Independent refresh-token secret with legacy fallback

**Files:**
- Modify: `models/User.js:1112-1117` (`generateRefreshToken`)
- Modify: `controllers/auth.js:717-723` (`refreshToken` verify)
- Modify: `config/config.env` (add `REFRESH_TOKEN_SECRET`)

**Interfaces:**
- Produces: new refresh tokens signed with `REFRESH_TOKEN_SECRET`; verification accepts both new and legacy (`JWT_SECRET + '_refresh'`) signatures during migration. DB-side hashed-token allowlist (already present) is unchanged.

- [ ] **Step 1: Add the env var**

Append to `config/config.env` (generate a fresh 64-hex value, don't reuse this literal):

```bash
node -e "console.log('REFRESH_TOKEN_SECRET=' + require('crypto').randomBytes(32).toString('hex'))" >> config/config.env
```

- [ ] **Step 2: Sign with the new secret**

In `models/User.js` `generateRefreshToken`:

```javascript
  const refreshToken = jwt.sign(
    { id: this._id, type: 'refresh' },
    process.env.REFRESH_TOKEN_SECRET || (process.env.JWT_SECRET + '_refresh'),
    { expiresIn: '30d' }
  );
```

- [ ] **Step 3: Dual-verify in the refresh endpoint**

In `controllers/auth.js` replace line 719:

```javascript
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET || (process.env.JWT_SECRET + '_refresh'));
    } catch (primaryErr) {
      if (primaryErr.name === 'TokenExpiredError') throw primaryErr;
      // Legacy tokens issued before the secret split — accept during migration window
      decoded = jwt.verify(refreshToken, process.env.JWT_SECRET + '_refresh');
    }
```

(The surrounding try/catch at line 717/756 already handles final failures; `TokenExpiredError` is rethrown so its 401 message stays accurate.)

- [ ] **Step 4: Verify round-trip with a script**

```bash
node -e "
require('dotenv').config({ path: './config/config.env' });
const jwt = require('jsonwebtoken');
const newSecret = process.env.REFRESH_TOKEN_SECRET;
const legacy = process.env.JWT_SECRET + '_refresh';
const tNew = jwt.sign({id:'x',type:'refresh'}, newSecret, {expiresIn:'30d'});
const tOld = jwt.sign({id:'x',type:'refresh'}, legacy, {expiresIn:'30d'});
const verify = (t) => { try { return jwt.verify(t, newSecret); } catch (e) { if (e.name==='TokenExpiredError') throw e; return jwt.verify(t, legacy); } };
console.log(verify(tNew).type === 'refresh' && verify(tOld).type === 'refresh' ? 'PASS' : 'FAIL');
"
```
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add models/User.js controllers/auth.js
git commit -m "feat(auth): independent REFRESH_TOKEN_SECRET with legacy dual-verify"
```
(config.env is gitignored — set the var on the production host when deploying.)

---

## Phase 2 — Flutter logic fixes

### Task 5: Refresh timeout + clean queue failure

**Files:**
- Modify: `lib/services/api_client.dart:97-183` (`_refreshAccessToken`)
- Test: `test/services/api_client_refresh_test.dart` (new)

**Interfaces:**
- Produces: `_refreshAccessToken()` never blocks longer than 30s; on timeout all queued completers resolve `null` (existing auth-error path then runs).

- [ ] **Step 1: Add timeout to the refresh POST**

In `_refreshAccessToken`, change the `http.post` call (line 120):

```dart
      final response = await http
          .post(
            url,
            body: jsonEncode({'refreshToken': _cachedRefreshToken}),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
```

The existing `catch (e)` block (line 171) already completes the queue with `null` — `TimeoutException` flows through it. No other change needed; verify by reading that the `finally { _isRefreshing = false; }` remains.

- [ ] **Step 2: Unit-test the queue-drain contract**

The refresh method itself needs a live server, but the queue behavior is the regression risk. Extract nothing; test through the public seam with a fake base URL that fails fast:

```dart
// test/services/api_client_refresh_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('concurrent refresh calls all resolve (no hang) when server unreachable', () async {
    SharedPreferences.setMockInitialValues({'refreshToken': 'stale-token'});
    final client = ApiClient(baseUrl: 'http://127.0.0.1:9'); // closed port -> immediate error
    final results = await Future.wait([
      client.refreshAccessTokenForTest(),
      client.refreshAccessTokenForTest(),
      client.refreshAccessTokenForTest(),
    ]).timeout(const Duration(seconds: 40));
    expect(results, [null, null, null]);
  });
}
```

Add a test-only forwarder in `ApiClient` (public API unchanged for app code):

```dart
  @visibleForTesting
  Future<String?> refreshAccessTokenForTest() => _refreshAccessToken();
```

Adapt the constructor line to however `ApiClient` actually receives `baseUrl` (it already has a `baseUrl` field — check its constructor and match).

- [ ] **Step 3: Run the test**

Run: `flutter test test/services/api_client_refresh_test.dart`
Expected: PASS (completes in seconds — the closed port fails fast; the 40s outer timeout only guards against the old hang bug).

- [ ] **Step 4: Commit**

```bash
git add lib/services/api_client.dart test/services/api_client_refresh_test.dart
git commit -m "fix(auth): 30s timeout on token refresh, queue never hangs"
```

---

### Task 6: profileCompleted routing into the completion wizard

**Files:**
- Modify: `lib/providers/provider_models/users_model.dart` (add field)
- Modify: `lib/pages/authentication/login/login_screen.dart:236-279` (routing)
- Modify: `lib/pages/authentication/login/apple_login_screen.dart`, `google_login_screen.dart` (same routing after OAuth success)
- Modify: `lib/pages/authentication/register/register_two_screen.dart` (accept "completion mode")

**Interfaces:**
- Consumes: backend `user.profileCompleted` (present in `/auth/me` and login responses; enforcement from Task 2).
- Produces: `Users.profileCompleted` (bool, default false); `RegisterTwoScreen(completionMode: true)` — wizard skips already-filled steps and calls `PUT /auth/updatedetails` at the end.

- [ ] **Step 1: Add the field to the model**

In `users_model.dart`, mirroring exactly how `termsAccepted` is declared (line 24/45/71/93/113 pattern): constructor param `this.profileCompleted = false`, final field, `toJson` entry, `copyWith` param + assignment, and in `fromJson`: `profileCompleted: json['profileCompleted'] ?? false`.

- [ ] **Step 2: Route incomplete users after login**

In `login_screen.dart`, inside the success block after the terms gate (insert after line 270, before `_maybeOfferBiometric`):

```dart
        // Profile-completion gate: OAuth users may have skipped the wizard.
        final gatedUser = await ref.read(authServiceProvider).getLoggedInUser();
        if (!gatedUser.profileCompleted) {
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RegisterTwoScreen(completionMode: true),
            ),
          );
          if (!mounted) return;
          final recheck = await ref.read(authServiceProvider).getLoggedInUser();
          if (!recheck.profileCompleted) return; // still incomplete — stay on login
        }
```

(Reuse the `user` object from line 238 instead of a second fetch if it's still in scope — prefer one fetch.) Apply the same gate to the OAuth success paths in `apple_login_screen.dart` / `google_login_screen.dart` — find where they `context.go('/home')` and insert the identical block before it.

- [ ] **Step 3: Completion mode on the wizard**

In `register_two_screen.dart`: add `final bool completionMode;` (`this.completionMode = false`). In `initState`, when `completionMode`, prefill controllers from `getLoggedInUser()` and start at the first step whose data is missing (steps: personal info → native language → learning language → photo → finish). On finish, the wizard already calls the update-details service; ensure it sends the 4 core fields and handles the Task 2 `PROFILE_INCOMPLETE` error by jumping to the missing step.

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/pages/authentication lib/providers/provider_models/users_model.dart`
Expected: `No issues found!`
Device check: log in with a test OAuth account whose gender is empty → wizard opens at personal-info step; complete it → lands on `/home`; relaunch app → no wizard.

- [ ] **Step 5: Commit**

```bash
git add lib/providers/provider_models/users_model.dart lib/pages/authentication
git commit -m "fix(auth): gate login on profileCompleted, resume-capable completion wizard"
```

---

### Task 7: Registration wizard progress persistence

**Files:**
- Create: `lib/pages/authentication/register/registration_progress_service.dart`
- Test: `test/authentication/registration_progress_service_test.dart`
- Modify: `lib/pages/authentication/register/register_screen.dart` + `register_two_screen.dart` (save/restore hooks)

**Interfaces:**
- Produces: `RegistrationProgressService` with `save(RegistrationProgress)`, `Future<RegistrationProgress?> load()`, `clear()`. `RegistrationProgress` holds `step` (int), `fields` (Map<String, String>), `savedAt` (DateTime). Progress older than 7 days is discarded on load.

- [ ] **Step 1: Write the failing test**

```dart
// test/authentication/registration_progress_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/authentication/register/registration_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save then load round-trips step and fields', () async {
    final svc = RegistrationProgressService();
    await svc.save(RegistrationProgress(step: 2, fields: {'email': 'a@b.com', 'name': 'Kim'}));
    final loaded = await svc.load();
    expect(loaded!.step, 2);
    expect(loaded.fields['email'], 'a@b.com');
  });

  test('load returns null when nothing saved', () async {
    expect(await RegistrationProgressService().load(), isNull);
  });

  test('clear removes progress', () async {
    final svc = RegistrationProgressService();
    await svc.save(RegistrationProgress(step: 1, fields: {}));
    await svc.clear();
    expect(await svc.load(), isNull);
  });

  test('stale progress (>7 days) is discarded', () async {
    final svc = RegistrationProgressService();
    await svc.save(RegistrationProgress(
      step: 1, fields: {}, savedAt: DateTime.now().subtract(const Duration(days: 8))));
    expect(await svc.load(), isNull);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/authentication/registration_progress_service_test.dart`
Expected: FAIL — file `registration_progress_service.dart` does not exist.

- [ ] **Step 3: Implement**

```dart
// lib/pages/authentication/register/registration_progress_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationProgress {
  RegistrationProgress({required this.step, required this.fields, DateTime? savedAt})
      : savedAt = savedAt ?? DateTime.now();

  final int step;
  final Map<String, String> fields;
  final DateTime savedAt;

  Map<String, dynamic> toJson() =>
      {'step': step, 'fields': fields, 'savedAt': savedAt.toIso8601String()};

  factory RegistrationProgress.fromJson(Map<String, dynamic> json) => RegistrationProgress(
        step: json['step'] as int,
        fields: Map<String, String>.from(json['fields'] as Map),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}

class RegistrationProgressService {
  static const _key = 'registrationProgress';
  static const _maxAge = Duration(days: 7);

  Future<void> save(RegistrationProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }

  Future<RegistrationProgress?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final progress = RegistrationProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (DateTime.now().difference(progress.savedAt) > _maxAge) {
        await clear();
        return null;
      }
      return progress;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/authentication/registration_progress_service_test.dart`
Expected: 4 tests PASS

- [ ] **Step 5: Wire into the wizard screens**

- `register_screen.dart`: on every field change debounce-save (`step: 0`, fields: email/name/gender/birth parts — never password); on successful advance to step 2, save `step: 1`.
- `register_two_screen.dart`: save after each step advance (`step: 1 + subStep`); call `clear()` on successful registration and on explicit "start over".
- On `register_screen` `initState`: `load()` — if progress exists show a `MomentsSnackbar`-style banner "Continue where you left off?" with Continue (restores fields + jumps to step) / Start over (clears).

- [ ] **Step 6: Verify + commit**

Run: `flutter analyze lib/pages/authentication`
Expected: `No issues found!` Device check: fill step 1, kill app, relaunch → resume banner appears with fields intact.

```bash
git add lib/pages/authentication test/authentication
git commit -m "feat(auth): registration wizard resumes after app close"
```

---

### Task 8: Typed auth error codes in the app

**Files:**
- Create: `lib/pages/authentication/auth_error_codes.dart`
- Test: `test/authentication/auth_error_codes_test.dart`
- Modify: `lib/providers/provider_root/auth_providers.dart` (pass `code` through in result maps)
- Modify: `lib/pages/authentication/login/login_screen.dart`, `email_verification/email_verification_screen.dart`, `password_reset/forgot_password_verification_screen.dart` (act on codes)

**Interfaces:**
- Consumes: backend `code` field (Task 1).
- Produces: `AuthErrorCode` enum (`codeExpired, codeInvalid, accountLocked, rateLimited, emailExists, profileIncomplete, unknown`) + `AuthErrorCode parseAuthErrorCode(String?)`. Auth provider result maps gain `'code': response['code']`.

- [ ] **Step 1: Failing test**

```dart
// test/authentication/auth_error_codes_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/authentication/auth_error_codes.dart';

void main() {
  test('parses known codes', () {
    expect(parseAuthErrorCode('CODE_EXPIRED'), AuthErrorCode.codeExpired);
    expect(parseAuthErrorCode('CODE_INVALID'), AuthErrorCode.codeInvalid);
    expect(parseAuthErrorCode('ACCOUNT_LOCKED'), AuthErrorCode.accountLocked);
    expect(parseAuthErrorCode('RATE_LIMITED'), AuthErrorCode.rateLimited);
    expect(parseAuthErrorCode('EMAIL_EXISTS'), AuthErrorCode.emailExists);
    expect(parseAuthErrorCode('PROFILE_INCOMPLETE'), AuthErrorCode.profileIncomplete);
  });
  test('null / unknown map to unknown', () {
    expect(parseAuthErrorCode(null), AuthErrorCode.unknown);
    expect(parseAuthErrorCode('SOMETHING_ELSE'), AuthErrorCode.unknown);
  });
}
```

- [ ] **Step 2: Run — expect FAIL (file missing). Implement:**

```dart
// lib/pages/authentication/auth_error_codes.dart
enum AuthErrorCode {
  codeExpired, codeInvalid, accountLocked, rateLimited,
  emailExists, profileIncomplete, unknown,
}

AuthErrorCode parseAuthErrorCode(String? code) => switch (code) {
      'CODE_EXPIRED' => AuthErrorCode.codeExpired,
      'CODE_INVALID' => AuthErrorCode.codeInvalid,
      'ACCOUNT_LOCKED' => AuthErrorCode.accountLocked,
      'RATE_LIMITED' => AuthErrorCode.rateLimited,
      'EMAIL_EXISTS' => AuthErrorCode.emailExists,
      'PROFILE_INCOMPLETE' => AuthErrorCode.profileIncomplete,
      _ => AuthErrorCode.unknown,
    };
```

Run: `flutter test test/authentication/auth_error_codes_test.dart` → PASS

- [ ] **Step 3: Thread codes through provider + screens**

- `auth_providers.dart`: wherever error result maps are built (`{'success': false, 'message': ...}` — login ~236-273, verification ~899, reset paths), add `'code': responseData['code']`.
- Verification screens: on `codeExpired` → show "expired" message + focus the resend button with countdown visible; on `codeInvalid` → shake the OTP boxes (Task 9 widget) + clear them.
- Login screen: `accountLocked` / `rateLimited` keep existing countdown flows but switch off string-matching (`message.contains('locked')`) in favor of the enum.

- [ ] **Step 4: Verify + commit**

Run: `flutter analyze lib/pages/authentication lib/providers/provider_root/auth_providers.dart` → `No issues found!`

```bash
git add lib/pages/authentication lib/providers/provider_root/auth_providers.dart test/authentication
git commit -m "feat(auth): typed error codes drive precise auth UX"
```

---

## Phase 3 — Auth UI redesign

### Task 9: Shared widget upgrades — OTP field, password strength meter, animated gradient scaffold

**Files:**
- Create: `lib/pages/authentication/widgets/otp_code_field.dart`
- Create: `lib/pages/authentication/widgets/password_strength_meter.dart`
- Create: `lib/pages/authentication/widgets/animated_auth_background.dart`
- Test: `test/authentication/password_strength_test.dart`

**Interfaces:**
- Produces:
  - `OtpCodeField({required int length, required ValueChanged<String> onCompleted, GlobalKey<OtpCodeFieldState>? key})` — 6 boxes, auto-advance, paste-splitting, `shakeAndClear()` method on state for invalid codes.
  - `PasswordStrengthMeter({required String password})` + pure function `PasswordStrength scorePassword(String)` (enum `empty, weak, fair, strong`).
  - `AnimatedAuthBackground({required Widget child})` — slow-drifting teal→banana gradient, dark-mode aware.

- [ ] **Step 1: Failing test for the pure scorer**

```dart
// test/authentication/password_strength_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/authentication/widgets/password_strength_meter.dart';

void main() {
  test('scores passwords per backend policy (8+, upper, lower, digit)', () {
    expect(scorePassword(''), PasswordStrength.empty);
    expect(scorePassword('abc'), PasswordStrength.weak);           // too short
    expect(scorePassword('abcdefgh'), PasswordStrength.weak);      // no upper/digit
    expect(scorePassword('Abcdefg1'), PasswordStrength.fair);      // meets minimum
    expect(scorePassword('Abcdefg1!xY23'), PasswordStrength.strong); // length 12+ & symbol
  });
}
```

Run: `flutter test test/authentication/password_strength_test.dart` → FAIL (missing file)

- [ ] **Step 2: Implement the three widgets**

```dart
// lib/pages/authentication/widgets/password_strength_meter.dart
import 'package:flutter/material.dart';

enum PasswordStrength { empty, weak, fair, strong }

PasswordStrength scorePassword(String password) {
  if (password.isEmpty) return PasswordStrength.empty;
  final hasUpper = password.contains(RegExp(r'[A-Z]'));
  final hasLower = password.contains(RegExp(r'[a-z]'));
  final hasDigit = password.contains(RegExp(r'\d'));
  final hasSymbol = password.contains(RegExp(r'[@$!%*?&]'));
  final meetsMinimum = password.length >= 8 && hasUpper && hasLower && hasDigit;
  if (!meetsMinimum) return PasswordStrength.weak;
  if (password.length >= 12 && hasSymbol) return PasswordStrength.strong;
  return PasswordStrength.fair;
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = scorePassword(password);
    final (fill, color, label) = switch (strength) {
      PasswordStrength.empty => (0.0, Colors.transparent, ''),
      PasswordStrength.weak => (0.33, Colors.redAccent, 'Weak'),
      PasswordStrength.fair => (0.66, const Color(0xFFFFB300), 'Good'),
      PasswordStrength.strong => (1.0, const Color(0xFF00BFA5), 'Strong'),
    };
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: strength == PasswordStrength.empty ? 0 : 1,
      child: Row(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fill, minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ]),
    );
  }
}
```

`OtpCodeField`: 6 `TextField`s (or one invisible field + 6 display boxes — pick one field + boxes, it handles paste natively): 48×56 boxes, rounded 12, teal focus border, `onChanged` collects digits, when `value.length == length` call `onCompleted`. `shakeAndClear()` runs a 300ms horizontal `AnimationController` offset and clears the controller. Full implementation ~120 lines; box decoration uses `Theme.of(context).colorScheme.surface` so dark mode works.

`AnimatedAuthBackground`: `AnimationController` (20s, repeat+reverse) driving `Alignment` of a `LinearGradient` between `[Color(0xFF00BFA5), Color(0xFF00897B)]` (dark) / `[Color(0xFFE0F7F4), Color(0xFFFFF8E1)]` (light) behind `child` in a `Stack`. Respect `MediaQuery.disableAnimations`.

- [ ] **Step 3: Run tests + analyze**

Run: `flutter test test/authentication/ && flutter analyze lib/pages/authentication/widgets`
Expected: all PASS, `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/pages/authentication/widgets test/authentication
git commit -m "feat(auth-ui): OTP field, password strength meter, animated gradient backdrop"
```

---

### Task 10: Login/welcome screen restyle

**Files:**
- Modify: `lib/pages/authentication/login/login_screen.dart` (build method only — logic from Tasks 6/8 untouched)
- Modify: `lib/pages/authentication/widgets/social_login_button.dart`, `biometric_login_button.dart`, `animated_banana_title.dart`

**Interfaces:**
- Consumes: `AnimatedAuthBackground`, `PasswordStrengthMeter` (Task 9), existing `auth_text_field.dart`, `auth_gradient_button.dart`.

- [ ] **Step 1: Restructure the login layout**

Wrap the existing scroll body in `AnimatedAuthBackground`. Layout order: refreshed `AnimatedBananaTitle` (larger, subtle bounce-in once) → email + password `AuthTextField`s with inline validation (email regex on unfocus; error text under field, not snackbar) → remember-me + forgot-password row → primary `AuthGradientButton` with loading spinner state → divider "or continue with" → Apple + Google `SocialLoginButton`s side-by-side at platform-guideline styling (Apple: black/white per brightness, SF symbol; Google: white with 'G' logo, outlined) → biometric button as an icon chip inline with the social row (remove its current bolt-on placement) → register link footer.

- [ ] **Step 2: Inline validation behavior**

`AuthTextField` gains optional `validator` + `errorText` display (8px, red-600 under the field). Email: validate on focus-loss; password: no meter on login (meter is for registration), just show/hide toggle (exists in `password_field.dart`).

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/pages/authentication` → `No issues found!`
Device: light + dark screenshots; loading state on submit; error states render inline (wrong password shows snackbar from Task 8 mapping, field errors inline).

- [ ] **Step 4: Commit**

```bash
git add lib/pages/authentication
git commit -m "feat(auth-ui): redesigned login screen with animated backdrop and inline validation"
```

---

### Task 11: Email verification + register step 1 restyle

**Files:**
- Modify: `lib/pages/authentication/email_verification/email_input_screen.dart`, `email_verification_screen.dart`
- Modify: `lib/pages/authentication/register/register_screen.dart`

**Interfaces:**
- Consumes: `OtpCodeField` + `shakeAndClear()` (Task 9), `AuthErrorCode` (Task 8), `PasswordStrengthMeter` (Task 9), resume banner (Task 7).

- [ ] **Step 1: OTP screen**

Replace the plain code `TextField` in `email_verification_screen.dart` with `OtpCodeField(length: 6, onCompleted: _verify)`. Add: auto-submit on completion, resend button with 60s visible countdown (`TweenAnimationBuilder<int>` or a `Timer.periodic` — disable + show "Resend in 42s"), success checkmark micro-animation (200ms scale-in `Icon(Icons.check_circle)`) before navigating. On `AuthErrorCode.codeInvalid` → `otpKey.currentState?.shakeAndClear()`; on `codeExpired` → toast + pulse the resend button.

- [ ] **Step 2: Register step 1**

`register_screen.dart`: apply `AnimatedAuthBackground`; add `PasswordStrengthMeter(password: _passwordController.text)` under the password field (rebuild via existing `onChanged`); birthdate picker gets a cupertino-style wheel in a bottom sheet instead of raw dropdowns; gender as segmented chips. Step indicator: reuse `auth_step_progress.dart` upgraded with step labels ("About you" / "Languages" / "Photo").

- [ ] **Step 3: Verify + commit**

Run: `flutter analyze lib/pages/authentication` → `No issues found!`
Device: paste a 6-digit code from clipboard → boxes fill; wrong code shakes; resend countdown ticks.

```bash
git add lib/pages/authentication
git commit -m "feat(auth-ui): OTP boxes with shake/resend, register step-1 restyle"
```

---

### Task 12: Register-two wizard restyle

**Files:**
- Modify: `lib/pages/authentication/register/register_two_screen.dart` + `register_two/personal_info_step.dart`, `native_language_step.dart`, `profile_photo_step.dart`, `finish_step.dart`
- Modify: `lib/pages/authentication/widgets/auth_step_progress.dart`

**Interfaces:**
- Consumes: completion mode (Task 6), progress persistence (Task 7).
- Produces: language picker pattern reused later by Workstream C composer.

- [ ] **Step 1: Wizard chrome**

`auth_step_progress.dart`: labeled segments with fill animation between steps; current step label under the bar. Page transitions: `PageView` with `Curves.easeOutCubic` 300ms slide+fade (replace any abrupt setState swaps).

- [ ] **Step 2: Language steps**

`native_language_step.dart`: replace plain list with searchable sheet — search field on top, languages as rows with flag emoji + native name + English name, selected state teal check. Guard: learning language picker excludes the chosen native language (mirrors backend rule, avoids a 400).

- [ ] **Step 3: Photo step**

`profile_photo_step.dart`: circular preview with instant crop (use the `image_picker` result in a `CircleAvatar` at 140dp with an edit badge; if an image cropper package already exists in pubspec use it, otherwise center-crop preview only — do NOT add a new dependency without checking pubspec first). Skip remains allowed (photo is optional by spec).

- [ ] **Step 4: Finish step**

`finish_step.dart`: summary card of entered values with per-row edit shortcuts, confetti-free success animation (scale-in check + haptic) on completion, then routes: normal mode → `/home`; completion mode → pops back to the login gate (Task 6 rechecks).

- [ ] **Step 5: Verify + commit**

Run: `flutter analyze lib/pages/authentication` → `No issues found!`
Device: full wizard run in both modes (fresh email signup, incomplete-OAuth completion); kill-and-resume mid-wizard (Task 7 banner).

```bash
git add lib/pages/authentication
git commit -m "feat(auth-ui): wizard restyle - labeled progress, searchable language picker, photo preview"
```

---

### Task 13: Password reset flow + illustrated error states

**Files:**
- Modify: `lib/pages/authentication/password_reset/forgot_password_email_screen.dart`, `forgot_password_verification_screen.dart`, `reset_password_screen.dart`
- Create: `lib/pages/authentication/widgets/auth_error_state.dart`

**Interfaces:**
- Consumes: `OtpCodeField`, `PasswordStrengthMeter`, `AuthErrorCode`.
- Produces: `AuthErrorState({required AuthErrorKind kind, VoidCallback? onRetry})` with kinds `locked, rateLimited, network` — icon illustration (built from Icons/shapes, no image assets), title, explanation, action button (countdown-aware for locked/rateLimited).

- [ ] **Step 1: Build `AuthErrorState`**

```dart
// lib/pages/authentication/widgets/auth_error_state.dart
import 'package:flutter/material.dart';

enum AuthErrorKind { locked, rateLimited, network }

class AuthErrorState extends StatelessWidget {
  const AuthErrorState({super.key, required this.kind, this.retryAfter, this.onRetry});
  final AuthErrorKind kind;
  final Duration? retryAfter;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = switch (kind) {
      AuthErrorKind.locked => (Icons.lock_clock, 'Account temporarily locked',
          'Too many failed attempts. Try again ${retryAfter != null ? 'in ${retryAfter!.inMinutes} min' : 'later'}.'),
      AuthErrorKind.rateLimited => (Icons.hourglass_top, 'Slow down a moment',
          'Too many attempts. Try again ${retryAfter != null ? 'in ${retryAfter!.inSeconds}s' : 'shortly'}.'),
      AuthErrorKind.network => (Icons.wifi_off, 'No connection',
          'Check your internet connection and try again.'),
    };
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 88, height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFF00BFA5).withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 40, color: const Color(0xFF00BFA5)),
      ),
      const SizedBox(height: 16),
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
      if (onRetry != null) ...[
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ]);
  }
}
```

- [ ] **Step 2: Apply across reset flow**

Reset screens get the same visual system: `AnimatedAuthBackground`, OTP boxes on the verification screen (with resend countdown), `PasswordStrengthMeter` on the new-password screen (backend policy: 8+ chars, upper, lower, digit — meter's `fair` == acceptable). Replace raw network/lockout snackbars in login + reset with `AuthErrorState` rendered in-body (snackbar stays for transient validation only).

- [ ] **Step 3: Verify + commit**

Run: `flutter analyze lib/pages/authentication` → `No issues found!`

```bash
git add lib/pages/authentication
git commit -m "feat(auth-ui): password reset restyle + illustrated lockout/rate-limit/network states"
```

---

### Task 14: Dark-mode parity pass + E2E smoke gate

**Files:**
- Modify: any auth file failing the dark-mode sweep
- Modify: `docs/superpowers/plans/2026-07-11-workstream-a-auth.md` (check off gate)

- [ ] **Step 1: Dark-mode sweep**

Run the app with dark mode forced; walk every auth screen (login, register 1, OTP, wizard 4 steps, reset 3 screens, suspended, terms). Fix any hardcoded `Colors.white`/`Colors.black` found — replace with `Theme.of(context).colorScheme` tokens. `grep -rn "Colors.white\|Colors.black" lib/pages/authentication --include="*.dart"` and justify or fix each hit.

- [ ] **Step 2: Full analyze + tests**

Run: `flutter analyze && flutter test test/authentication test/services`
Expected: `No issues found!`, all tests PASS.

- [ ] **Step 3: Device E2E smoke checklist (the Workstream A gate)**

On a real device against the dev backend:
1. Email signup end-to-end (new email → OTP → wizard → home)
2. Google signup → abandon wizard at languages → force-quit → reopen → login → wizard resumes at languages → complete → home
3. Apple signup fresh → home; logout → backend log shows `APPLE_TOKEN_REVOKED_ON_LOGOUT`
4. Wrong password ×6 → locked state UI with countdown (not raw snackbar)
5. Expired OTP (wait 15+ min or shorten expiry in dev) → "expired" state + resend works
6. Kill backend mid-session → app refresh times out within 30s → clean logout, no hang
7. Existing pre-migration user still logs in (legacy refresh token accepted)

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore(auth): dark-mode parity pass, workstream A smoke gate complete"
```

---

## Self-review notes

- **Spec coverage:** A1 fixes 1-6 → Tasks 2/6/7 (fix 1+6), 3 (fix 2), 4 (fix 3), 5 (fix 4), 1/8 (fix 5). A2 UI → Tasks 9-13; dark mode + gate → Task 14. GDPR grace period + per-user rate limiting: explicitly out of scope per spec.
- **Type consistency:** `AuthErrorCode` names match Task 1 backend codes; `RegistrationProgress` fields consistent between test and implementation; `profileCompleted` field name identical across backend response, `users_model.dart`, and routing checks.
- **Sequencing:** Tasks 1-4 (backend) before 5-8 (Flutter logic) before 9-14 (UI). Task 11/13 depend on Task 9 widgets; Task 6 depends on Task 2.
