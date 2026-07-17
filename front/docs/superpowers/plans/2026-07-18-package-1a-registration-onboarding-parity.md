# Package 1a — Registration & Onboarding Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring web signup to parity with the app's two-phase onboarding (username live-check, password strength, 18+ gate, CEFR levels, required photo + location, terms), matched exactly to the backend contract, plus a careful backend change so a client-chosen username is honored on both register and edit.

**Architecture:** Two subsystems. **Backend** (`/Users/firdavsmutalipov/Projects/BananaTalk/backend`, Express 4 / CommonJS): a shared username-validation helper reused by `checkUsernameAvailability`, `register`, and `updateUser`; plus a geocoding proxy so web never fabricates coordinates. **Web** (`/Users/firdavsmutalipov/Projects/BananaTalk/front`, React 18 CRA + RTK Query): pure validators + payload builder (TDD'd), three reusable field widgets, and a restructured `Register.tsx` wizard, plus OAuth-completion parity. Build backend first (web depends on it), then web foundations, then the wizard, then OAuth.

**Tech Stack:** Backend: Express 4, Mongoose, `node --test`. Web: React 18, TypeScript, Redux Toolkit / RTK Query, `react-scripts test` (Jest + React Testing Library), `react-toastify`.

## Global Constraints

- Username format: `^[a-z0-9_]{3,20}$`, stored **lowercased**; reserved set = the existing `RESERVED_USERNAMES` in `backend/controllers/users.js` (`admin, root, support, help, api, banatalk, bananatalk, official, staff, moderator`). One source of truth — do not duplicate the set.
- Password rule (match app): min 8 chars, at least one uppercase, one lowercase, one digit.
- Age gate (match app): user must be **≥ 18**.
- Topics are **NOT** collected at signup (app sends `topics: []`). Do not add a topics step.
- Register body must be **app-identical** (`backend/../register_two_screen.dart:585-610`): `{ name, username|null, password, email, bio:'', gender, images:[], birth_day, birth_month, birth_year, native_language, language_to_learn, topics:[], termsAccepted:true, location:{…} }`.
- Location "100% true": never send `coordinates:[0,0]`. Real coords only (GPS reverse-geocode or forward-geocode of a typed city); if none obtainable, send `location` with `city/country/formattedAddress` and **omit** `coordinates` and `type`.
- **Design system: Tailwind for ALL new/modified web UI (user decision 2026-07-18). Do NOT add new `.scss` files.** Reference the modern look in `src/components/profile/EditProfile.tsx` (teal gradient header, `rounded-2xl` glass cards, lucide icons, sticky action bar). The illustrative `className` strings in the component tasks below are placeholders — implement them with Tailwind utility classes matching that reference. The pure logic (validators, payload builder, geocode) is unaffected.
- Backend web base + canonical patterns unchanged. Do NOT run `git push` unless the user asks; commit locally per task.
- Do not touch unrelated pre-existing uncommitted files in either repo. Backend currently has unrelated modified files — stage only files named in each task.

---

## Phase 1 — Backend

### Task 1: Shared username-validation helper

**Files:**
- Create: `backend/utils/usernameValidation.js`
- Modify: `backend/controllers/users.js` (replace inline reserved set + regex in `checkUsernameAvailability` with the helper)
- Test: `backend/test/usernameValidation.test.js`

**Interfaces:**
- Produces: `validateUsername(raw) => { ok: boolean, normalized: string|null, reason: 'invalid_format'|'reserved'|null }` and `RESERVED_USERNAMES` (Set). Pure — no DB. Uniqueness is checked separately by callers.

- [ ] **Step 1: Write the failing test**

```js
// backend/test/usernameValidation.test.js
const test = require('node:test');
const assert = require('node:assert/strict');
const { validateUsername, RESERVED_USERNAMES } = require('../utils/usernameValidation');

test('accepts a valid username and lowercases it', () => {
  assert.deepEqual(validateUsername('  CoolUser_1 '), { ok: true, normalized: 'cooluser_1', reason: null });
});
test('rejects too-short / bad chars', () => {
  assert.equal(validateUsername('ab').ok, false);
  assert.equal(validateUsername('ab').reason, 'invalid_format');
  assert.equal(validateUsername('has space').reason, 'invalid_format');
  assert.equal(validateUsername('WAY_too_long_username_here').reason, 'invalid_format');
});
test('rejects reserved names (case-insensitive)', () => {
  assert.equal(validateUsername('Admin').reason, 'reserved');
  assert.ok(RESERVED_USERNAMES.has('bananatalk'));
});
test('empty/blank normalizes to null ok:false invalid_format', () => {
  assert.equal(validateUsername('').reason, 'invalid_format');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && node --test test/usernameValidation.test.js`
Expected: FAIL — `Cannot find module '../utils/usernameValidation'`.

- [ ] **Step 3: Write minimal implementation**

```js
// backend/utils/usernameValidation.js
const RESERVED_USERNAMES = new Set([
  'admin', 'root', 'support', 'help', 'api',
  'banatalk', 'bananatalk', 'official', 'staff', 'moderator',
]);
const USERNAME_RE = /^[a-z0-9_]{3,20}$/;

function validateUsername(raw) {
  const normalized = (raw || '').trim().toLowerCase();
  if (!USERNAME_RE.test(normalized)) return { ok: false, normalized: null, reason: 'invalid_format' };
  if (RESERVED_USERNAMES.has(normalized)) return { ok: false, normalized: null, reason: 'reserved' };
  return { ok: true, normalized, reason: null };
}

module.exports = { validateUsername, RESERVED_USERNAMES, USERNAME_RE };
```

- [ ] **Step 4: Refactor `checkUsernameAvailability` to use the helper**

In `backend/controllers/users.js`, delete the local `RESERVED_USERNAMES` set and the inline `/^[a-z0-9_]{3,20}$/` check inside `checkUsernameAvailability`; import and use the helper:

```js
const { validateUsername } = require('../utils/usernameValidation');
// ...
exports.checkUsernameAvailability = asyncHandler(async (req, res) => {
  const { ok, normalized, reason } = validateUsername(req.query.value);
  if (!ok) {
    return res.status(200).json({ success: true, data: { available: false, reason } });
  }
  const exists = await User.exists({ username: normalized });
  return res.status(200).json({
    success: true,
    data: { available: !exists, reason: exists ? 'taken' : null },
  });
});
```

- [ ] **Step 5: Run tests + confirm no regression**

Run: `cd backend && node --test test/usernameValidation.test.js && node --check controllers/users.js`
Expected: tests PASS; `node --check` no output.

- [ ] **Step 6: Commit**

```bash
cd backend && git add utils/usernameValidation.js test/usernameValidation.test.js controllers/users.js
git commit -m "refactor(users): extract shared username validation helper"
```

---

### Task 2: Honor client username in `register`

**Files:**
- Modify: `backend/controllers/auth.js` (`register`, currently auto-generates only — around the `const username = await generateUsername(name)` line)
- Test: `backend/test/registerUsername.test.js`

**Interfaces:**
- Consumes: `validateUsername` (Task 1).
- Produces: `register` honors optional `req.body.username`: valid+unique → used; blank/absent → `generateUsername(name)`; invalid/reserved → 400 `USERNAME_INVALID`; taken → 400 `USERNAME_TAKEN`.

- [ ] **Step 1: Write the failing test**

```js
// backend/test/registerUsername.test.js
const test = require('node:test');
const assert = require('node:assert/strict');
const { mock } = require('node:test');
// resolveRegistrationUsername is the pure decision fn extracted in Step 3.
const { resolveRegistrationUsername } = require('../controllers/auth');

test('blank username falls back to generator', async () => {
  const gen = async () => 'auto_generated_1';
  assert.equal(await resolveRegistrationUsername('', 'Jane', { exists: async () => false, generate: gen }), 'auto_generated_1');
});
test('valid unique username is used (lowercased)', async () => {
  assert.equal(await resolveRegistrationUsername('CoolUser', 'Jane', { exists: async () => false, generate: async () => 'x' }), 'cooluser');
});
test('taken username throws USERNAME_TAKEN', async () => {
  await assert.rejects(
    () => resolveRegistrationUsername('taken', 'Jane', { exists: async () => true, generate: async () => 'x' }),
    (e) => e.code === 'USERNAME_TAKEN'
  );
});
test('invalid username throws USERNAME_INVALID', async () => {
  await assert.rejects(
    () => resolveRegistrationUsername('a b', 'Jane', { exists: async () => false, generate: async () => 'x' }),
    (e) => e.code === 'USERNAME_INVALID'
  );
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && node --test test/registerUsername.test.js`
Expected: FAIL — `resolveRegistrationUsername is not a function`.

- [ ] **Step 3: Extract + implement the decision fn, wire into `register`**

Add to `backend/controllers/auth.js` (top-level, exported) and use it inside `register`:

```js
const { validateUsername } = require('../utils/usernameValidation');

// deps = { exists: (username)=>Promise<bool>, generate: (name)=>Promise<string> }
async function resolveRegistrationUsername(rawUsername, name, deps) {
  const raw = (rawUsername || '').trim();
  if (!raw) return deps.generate(name);
  const { ok, normalized, reason } = validateUsername(raw);
  if (!ok) { const e = new Error(reason === 'reserved' ? 'Username is reserved' : 'Invalid username'); e.code = 'USERNAME_INVALID'; e.statusCode = 400; throw e; }
  if (await deps.exists(normalized)) { const e = new Error('Username is already taken'); e.code = 'USERNAME_TAKEN'; e.statusCode = 400; throw e; }
  return normalized;
}
exports.resolveRegistrationUsername = resolveRegistrationUsername;
```

In `register`, replace `const username = await generateUsername(name);` with:

```js
let username;
try {
  username = await resolveRegistrationUsername(req.body.username, name, {
    exists: (u) => User.exists({ username: u }),
    generate: (n) => generateUsername(n),
  });
} catch (err) {
  return next(new ErrorResponse(err.message, err.statusCode || 400, err.code));
}
```

(Confirm `ErrorResponse` supports a 3rd `code` arg — it is already used elsewhere as `new ErrorResponse('...', 400, 'EMAIL_EXISTS')`.)

- [ ] **Step 4: Run tests + syntax check**

Run: `cd backend && node --test test/registerUsername.test.js && node --check controllers/auth.js`
Expected: 4 PASS; no syntax errors.

- [ ] **Step 5: Commit**

```bash
cd backend && git add controllers/auth.js test/registerUsername.test.js
git commit -m "feat(auth): honor client-supplied username in register (fallback to generated)"
```

---

### Task 3: Honor + validate username in `updateUser` (app + web edit parity)

**Files:**
- Modify: `backend/controllers/users.js` (`updateUser` — before the `findByIdAndUpdate`)
- Test: `backend/test/updateUsername.test.js`

**Interfaces:**
- Consumes: `validateUsername` (Task 1).
- Produces: `resolveEditUsername(rawUsername, selfId, deps) => Promise<string|undefined>` — `undefined` when username absent (no change); validated+lowercased when present; throws `USERNAME_INVALID`/`USERNAME_TAKEN` (uniqueness excludes `selfId`).

- [ ] **Step 1: Write the failing test**

```js
// backend/test/updateUsername.test.js
const test = require('node:test');
const assert = require('node:assert/strict');
const { resolveEditUsername } = require('../controllers/users');

test('absent username => undefined (no change)', async () => {
  assert.equal(await resolveEditUsername(undefined, 'me', { existsOther: async () => false }), undefined);
});
test('own unchanged username ok (excludes self)', async () => {
  assert.equal(await resolveEditUsername('MyName', 'me', { existsOther: async (u, id) => false }), 'myname');
});
test('taken by another throws USERNAME_TAKEN', async () => {
  await assert.rejects(() => resolveEditUsername('taken', 'me', { existsOther: async () => true }), (e) => e.code === 'USERNAME_TAKEN');
});
test('invalid throws USERNAME_INVALID', async () => {
  await assert.rejects(() => resolveEditUsername('a b', 'me', { existsOther: async () => false }), (e) => e.code === 'USERNAME_INVALID');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && node --test test/updateUsername.test.js`
Expected: FAIL — `resolveEditUsername is not a function`.

- [ ] **Step 3: Implement + wire into `updateUser`**

Add to `backend/controllers/users.js`:

```js
const { validateUsername } = require('../utils/usernameValidation');

// deps = { existsOther: (username, selfId)=>Promise<bool> }
async function resolveEditUsername(rawUsername, selfId, deps) {
  if (rawUsername === undefined || rawUsername === null) return undefined;
  const { ok, normalized, reason } = validateUsername(rawUsername);
  if (!ok) { const e = new Error(reason === 'reserved' ? 'Username is reserved' : 'Invalid username'); e.code = 'USERNAME_INVALID'; e.statusCode = 400; throw e; }
  if (await deps.existsOther(normalized, selfId)) { const e = new Error('Username is already taken'); e.code = 'USERNAME_TAKEN'; e.statusCode = 400; throw e; }
  return normalized;
}
exports.resolveEditUsername = resolveEditUsername;
```

In `updateUser`, after building `updateData` and before `findByIdAndUpdate`, add:

```js
if ('username' in updateData) {
  try {
    const resolved = await resolveEditUsername(updateData.username, req.params.id, {
      existsOther: (u, id) => User.exists({ username: u, _id: { $ne: id } }),
    });
    if (resolved === undefined) delete updateData.username;
    else updateData.username = resolved;
  } catch (err) {
    return next(new ErrorResponse(err.message, err.statusCode || 400, err.code));
  }
}
```

- [ ] **Step 4: Run tests + syntax check**

Run: `cd backend && node --test test/updateUsername.test.js && node --check controllers/users.js`
Expected: 4 PASS; no syntax errors.

- [ ] **Step 5: Commit**

```bash
cd backend && git add controllers/users.js test/updateUsername.test.js
git commit -m "feat(users): validate + honor username on updateUser (edit parity, self-excluded uniqueness)"
```

---

### Task 4: Geocoding proxy endpoint

**Files:**
- Create: `backend/routes/geocode.js`, `backend/controllers/geocode.js`
- Modify: `backend/server.js` (mount `app.use('/api/v1/geocode', require('./routes/geocode'))` near the other `/api/v1` mounts)
- Test: `backend/test/geocode.test.js`

**Interfaces:**
- Produces: `GET /api/v1/geocode/reverse?lat=&lng=` → `{ success, data:{ city, country, formattedAddress, coordinates:[lng,lat] } }`; `GET /api/v1/geocode/forward?city=&country=` → `{ success, data:{ city, country, formattedAddress, coordinates:[lng,lat] } | null }`. Pure mapper `mapNominatimResult(json, fallbackCoords)` is unit-tested; the HTTP fetch is thin.

**Provider:** OpenStreetMap Nominatim (no key; set `User-Agent: BananaTalk/1.0`). Rate-limited — acceptable for signup volume; revisit if needed.

- [ ] **Step 1: Write the failing test (pure mapper)**

```js
// backend/test/geocode.test.js
const test = require('node:test');
const assert = require('node:assert/strict');
const { mapNominatimResult } = require('../controllers/geocode');

test('maps a nominatim reverse result to our location shape', () => {
  const json = { address: { city: 'Seoul', country: 'South Korea' }, display_name: 'Seoul, South Korea', lat: '37.5', lon: '127.0' };
  assert.deepEqual(mapNominatimResult(json), {
    city: 'Seoul', country: 'South Korea', formattedAddress: 'Seoul, South Korea', coordinates: [127.0, 37.5],
  });
});
test('falls back through town/village for city, tolerates missing coords', () => {
  const json = { address: { village: 'Xanadu', country: 'Nowhere' }, display_name: 'Xanadu' };
  const out = mapNominatimResult(json);
  assert.equal(out.city, 'Xanadu');
  assert.equal(out.coordinates, undefined);
});
test('returns null for empty result', () => {
  assert.equal(mapNominatimResult(null), null);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && node --test test/geocode.test.js`
Expected: FAIL — `Cannot find module '../controllers/geocode'`.

- [ ] **Step 3: Implement controller (mapper + fetch) and route**

```js
// backend/controllers/geocode.js
const asyncHandler = require('../middleware/async');

function mapNominatimResult(json) {
  if (!json || !json.address) return null;
  const a = json.address;
  const city = a.city || a.town || a.village || a.state || null;
  const country = a.country || null;
  const out = { city, country, formattedAddress: json.display_name || [city, country].filter(Boolean).join(', ') };
  if (json.lat != null && json.lon != null) out.coordinates = [parseFloat(json.lon), parseFloat(json.lat)];
  return out;
}

async function nominatim(path) {
  const res = await fetch(`https://nominatim.openstreetmap.org/${path}`, {
    headers: { 'User-Agent': 'BananaTalk/1.0 (support@banatalk.com)' },
  });
  if (!res.ok) return null;
  return res.json();
}

exports.reverse = asyncHandler(async (req, res) => {
  const { lat, lng } = req.query;
  const json = await nominatim(`reverse?format=jsonv2&lat=${encodeURIComponent(lat)}&lon=${encodeURIComponent(lng)}`);
  return res.status(200).json({ success: true, data: mapNominatimResult(json) });
});

exports.forward = asyncHandler(async (req, res) => {
  const { city = '', country = '' } = req.query;
  const q = encodeURIComponent([city, country].filter(Boolean).join(', '));
  const arr = await nominatim(`search?format=jsonv2&addressdetails=1&limit=1&q=${q}`);
  const first = Array.isArray(arr) && arr.length ? arr[0] : null;
  return res.status(200).json({ success: true, data: mapNominatimResult(first) });
});

exports.mapNominatimResult = mapNominatimResult;
```

```js
// backend/routes/geocode.js
const express = require('express');
const router = express.Router();
const { reverse, forward } = require('../controllers/geocode');
router.get('/reverse', reverse);
router.get('/forward', forward);
module.exports = router;
```

Mount in `backend/server.js` next to the other `/api/v1` route mounts:

```js
app.use('/api/v1/geocode', require('./routes/geocode'));
```

- [ ] **Step 4: Run tests + syntax checks**

Run: `cd backend && node --test test/geocode.test.js && node --check controllers/geocode.js && node --check routes/geocode.js && node --check server.js`
Expected: 3 PASS; no syntax errors.

- [ ] **Step 5: Commit**

```bash
cd backend && git add controllers/geocode.js routes/geocode.js server.js test/geocode.test.js
git commit -m "feat(geocode): add reverse/forward geocoding proxy for accurate signup location"
```

---

## Phase 2 — Web foundations (pure logic, TDD)

### Task 5: Signup validators (pure)

**Files:**
- Create: `front/src/components/auth/register/validators.ts`
- Test: `front/src/components/auth/register/validators.test.ts`

**Interfaces:**
- Produces: `passwordStrength(pw: string) => { score: 0|1|2|3; hasMin: boolean; hasUpper: boolean; hasLower: boolean; hasDigit: boolean; valid: boolean }`; `isAdult(birthISO: string, now?: Date) => boolean`; `usernameFormatValid(u: string) => boolean` (regex `^[a-z0-9_]{3,20}$`, lowercased first).

- [ ] **Step 1: Write the failing test**

```ts
// front/src/components/auth/register/validators.test.ts
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/validators.test.ts --watchAll=false`
Expected: FAIL — cannot find `./validators`.

- [ ] **Step 3: Implement**

```ts
// front/src/components/auth/register/validators.ts
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/validators.test.ts --watchAll=false`
Expected: PASS (all cases).

- [ ] **Step 5: Commit**

```bash
cd front && git add src/components/auth/register/validators.ts src/components/auth/register/validators.test.ts
git commit -m "feat(auth): add signup validators (password strength, 18+ gate, username format)"
```

---

### Task 6: Register payload builder (pure, app-identical body)

**Files:**
- Create: `front/src/components/auth/register/buildRegisterPayload.ts`
- Test: `front/src/components/auth/register/buildRegisterPayload.test.ts`

**Interfaces:**
- Produces: `buildRegisterPayload(form) => RegisterBody`. `form` = `{ name, username, password, email, gender, birthDate:'YYYY-MM-DD', native_language, language_to_learn, location: LocationInput }`. `LocationInput = { city, country, coordinates?: [number,number] }`. Emits `topics:[]`, `termsAccepted:true`, `bio:''`, `images:[]`, split `birth_year/month/day`, and a `location` object that **omits `coordinates`/`type` when coordinates absent** (never `[0,0]`).

- [ ] **Step 1: Write the failing test**

```ts
// front/src/components/auth/register/buildRegisterPayload.test.ts
import { buildRegisterPayload } from './buildRegisterPayload';

const base = {
  name: 'Jane', username: 'JaneDoe', password: 'Abcdef12', email: 'j@x.com',
  gender: 'female', birthDate: '2000-03-09', native_language: 'English', language_to_learn: 'Korean',
};

it('builds an app-identical body with coordinates', () => {
  const body = buildRegisterPayload({ ...base, location: { city: 'Seoul', country: 'South Korea', coordinates: [127.0, 37.5] } });
  expect(body).toEqual({
    name: 'Jane', username: 'janedoe', password: 'Abcdef12', email: 'j@x.com', bio: '', gender: 'female', images: [],
    birth_year: '2000', birth_month: '03', birth_day: '09',
    native_language: 'English', language_to_learn: 'Korean', topics: [], termsAccepted: true,
    location: { type: 'Point', coordinates: [127.0, 37.5], formattedAddress: 'Seoul, South Korea', city: 'Seoul', country: 'South Korea' },
  });
});
it('omits coordinates and type when absent (never [0,0])', () => {
  const body = buildRegisterPayload({ ...base, location: { city: 'Paris', country: 'France' } });
  expect(body.location).toEqual({ formattedAddress: 'Paris, France', city: 'Paris', country: 'France' });
  expect('coordinates' in body.location).toBe(false);
});
it('lowercases username, null when empty', () => {
  expect(buildRegisterPayload({ ...base, username: '', location: { city: 'A', country: 'B' } }).username).toBeNull();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/buildRegisterPayload.test.ts --watchAll=false`
Expected: FAIL — cannot find module.

- [ ] **Step 3: Implement**

```ts
// front/src/components/auth/register/buildRegisterPayload.ts
export interface LocationInput { city: string; country: string; coordinates?: [number, number]; }
export interface RegisterForm {
  name: string; username: string; password: string; email: string; gender: string;
  birthDate: string; native_language: string; language_to_learn: string; location: LocationInput;
}

export function buildRegisterPayload(form: RegisterForm) {
  const [birth_year, birth_month, birth_day] = form.birthDate.split('-');
  const { city, country, coordinates } = form.location;
  const formattedAddress = [city, country].filter(Boolean).join(', ');
  const location: any = { formattedAddress, city, country };
  if (coordinates && coordinates.length === 2) { location.type = 'Point'; location.coordinates = coordinates; }
  const username = form.username.trim() ? form.username.trim().toLowerCase() : null;
  return {
    name: form.name, username, password: form.password, email: form.email, bio: '', gender: form.gender, images: [],
    birth_year, birth_month, birth_day,
    native_language: form.native_language, language_to_learn: form.language_to_learn,
    topics: [], termsAccepted: true, location,
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/buildRegisterPayload.test.ts --watchAll=false`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd front && git add src/components/auth/register/buildRegisterPayload.ts src/components/auth/register/buildRegisterPayload.test.ts
git commit -m "feat(auth): add app-identical register payload builder (100%-true location)"
```

---

### Task 7: RTK Query — checkUsername + geocode endpoints + constants

**Files:**
- Modify: `front/src/constants.ts` (add `CHECK_USERNAME_URL`, `GEOCODE_REVERSE_URL`, `GEOCODE_FORWARD_URL`)
- Modify: `front/src/store/slices/usersSlice.ts` (inject `checkUsername`, `reverseGeocode`, `forwardGeocode`; export hooks)
- Test: `front/src/store/slices/geocodeEndpoints.test.ts` (query-config shape only — no network)

**Interfaces:**
- Produces hooks: `useLazyCheckUsernameQuery`, `useLazyReverseGeocodeQuery`, `useLazyForwardGeocodeQuery`. Response types match backend Task 1 & 4.

- [ ] **Step 1: Add constants**

```ts
// front/src/constants.ts  (append near the other auth URLs)
export const CHECK_USERNAME_URL = "/api/v1/auth/users/check-username";
export const GEOCODE_REVERSE_URL = "/api/v1/geocode/reverse";
export const GEOCODE_FORWARD_URL = "/api/v1/geocode/forward";
```

- [ ] **Step 2: Inject endpoints in `usersSlice.ts`**

Inside `usersApiSlice = apiSlice.injectEndpoints({ endpoints: (builder) => ({ ... }) })`, add:

```ts
checkUsername: builder.query({
  query: (value: string) => ({ url: `${CHECK_USERNAME_URL}?value=${encodeURIComponent(value)}` }),
}),
reverseGeocode: builder.query({
  query: ({ lat, lng }: { lat: number; lng: number }) => ({ url: `${GEOCODE_REVERSE_URL}?lat=${lat}&lng=${lng}` }),
}),
forwardGeocode: builder.query({
  query: ({ city, country }: { city: string; country: string }) => ({ url: `${GEOCODE_FORWARD_URL}?city=${encodeURIComponent(city)}&country=${encodeURIComponent(country)}` }),
}),
```

Add to the exported hooks block at the bottom (append to the existing `export const { ... }`):

```ts
  useLazyCheckUsernameQuery,
  useLazyReverseGeocodeQuery,
  useLazyForwardGeocodeQuery,
```

Add the new constant imports at the top of `usersSlice.ts` from `../../constants`.

- [ ] **Step 3: Write a shape test**

```ts
// front/src/store/slices/geocodeEndpoints.test.ts
import { CHECK_USERNAME_URL, GEOCODE_REVERSE_URL, GEOCODE_FORWARD_URL } from '../../constants';
it('exposes the auth/geocode endpoint paths', () => {
  expect(CHECK_USERNAME_URL).toBe('/api/v1/auth/users/check-username');
  expect(GEOCODE_REVERSE_URL).toBe('/api/v1/geocode/reverse');
  expect(GEOCODE_FORWARD_URL).toBe('/api/v1/geocode/forward');
});
```

- [ ] **Step 4: Run test + typecheck**

Run: `cd front && CI=true npx react-scripts test src/store/slices/geocodeEndpoints.test.ts --watchAll=false && npx tsc --noEmit`
Expected: PASS; no type errors.

- [ ] **Step 5: Commit**

```bash
cd front && git add src/constants.ts src/store/slices/usersSlice.ts src/store/slices/geocodeEndpoints.test.ts
git commit -m "feat(auth): add checkUsername + geocode RTK Query endpoints and constants"
```

---

## Phase 3 — Web field widgets

### Task 8: UsernameAvailabilityField

**Files:**
- Create: `front/src/components/auth/register/UsernameAvailabilityField.tsx`
- Test: `front/src/components/auth/register/UsernameAvailabilityField.test.tsx`

**Interfaces:**
- Consumes: `useLazyCheckUsernameQuery` (Task 7), `usernameFormatValid` (Task 5).
- Produces: `<UsernameAvailabilityField value onChange onAvailabilityChange />`. Debounces 500ms; when empty → `onAvailabilityChange(true)` (optional field). Invalid format → shows format error, `onAvailabilityChange(false)`. Else calls check; taken → `onAvailabilityChange(false)`.

- [ ] **Step 1: Write the failing test (RTL, mocked hook)**

```tsx
// front/src/components/auth/register/UsernameAvailabilityField.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import UsernameAvailabilityField from './UsernameAvailabilityField';

const trigger = jest.fn();
jest.mock('../../../store/slices/usersSlice', () => ({
  useLazyCheckUsernameQuery: () => [trigger, {}],
}));

it('reports available:false for invalid format without calling API', async () => {
  const onAvail = jest.fn();
  render(<UsernameAvailabilityField value="" onChange={() => {}} onAvailabilityChange={onAvail} />);
  fireEvent.change(screen.getByRole('textbox'), { target: { value: 'ab' } });
  await waitFor(() => expect(onAvail).toHaveBeenCalledWith(false));
  expect(trigger).not.toHaveBeenCalled();
});
it('empty value is treated as available (optional)', async () => {
  const onAvail = jest.fn();
  render(<UsernameAvailabilityField value="x" onChange={() => {}} onAvailabilityChange={onAvail} />);
  fireEvent.change(screen.getByRole('textbox'), { target: { value: '' } });
  await waitFor(() => expect(onAvail).toHaveBeenCalledWith(true));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/UsernameAvailabilityField.test.tsx --watchAll=false`
Expected: FAIL — cannot find component.

- [ ] **Step 3: Implement**

```tsx
// front/src/components/auth/register/UsernameAvailabilityField.tsx
import React, { useEffect, useRef, useState } from 'react';
import { useLazyCheckUsernameQuery } from '../../../store/slices/usersSlice';
import { usernameFormatValid } from './validators';

interface Props { value: string; onChange: (v: string) => void; onAvailabilityChange: (ok: boolean) => void; }

const UsernameAvailabilityField: React.FC<Props> = ({ value, onChange, onAvailabilityChange }) => {
  const [status, setStatus] = useState<'idle' | 'checking' | 'available' | 'taken' | 'invalid'>('idle');
  const [trigger] = useLazyCheckUsernameQuery();
  const timer = useRef<ReturnType<typeof setTimeout>>();

  useEffect(() => {
    const v = value.trim().toLowerCase();
    if (timer.current) clearTimeout(timer.current);
    if (v === '') { setStatus('idle'); onAvailabilityChange(true); return; }
    if (!usernameFormatValid(v)) { setStatus('invalid'); onAvailabilityChange(false); return; }
    setStatus('checking');
    timer.current = setTimeout(async () => {
      try {
        const res: any = await trigger(v);
        const ok = !!res?.data?.data?.available;
        setStatus(ok ? 'available' : 'taken');
        onAvailabilityChange(ok);
      } catch { setStatus('taken'); onAvailabilityChange(false); }
    }, 500);
    return () => { if (timer.current) clearTimeout(timer.current); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  return (
    <div className="username-field">
      <input type="text" value={value} placeholder="username (optional)"
        onChange={(e) => onChange(e.target.value)} aria-label="username" />
      {status === 'invalid' && <small className="err">3–20 chars: a–z, 0–9, _</small>}
      {status === 'checking' && <small>Checking…</small>}
      {status === 'available' && <small className="ok">Available</small>}
      {status === 'taken' && <small className="err">Taken</small>}
    </div>
  );
};
export default UsernameAvailabilityField;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/UsernameAvailabilityField.test.tsx --watchAll=false`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd front && git add src/components/auth/register/UsernameAvailabilityField.tsx src/components/auth/register/UsernameAvailabilityField.test.tsx
git commit -m "feat(auth): add UsernameAvailabilityField with debounced live check"
```

---

### Task 9: PasswordStrengthMeter

**Files:**
- Create: `front/src/components/auth/register/PasswordStrengthMeter.tsx`
- Test: `front/src/components/auth/register/PasswordStrengthMeter.test.tsx`

**Interfaces:**
- Consumes: `passwordStrength` (Task 5).
- Produces: `<PasswordStrengthMeter password />` — renders a labeled bar and the unmet-rule hints; purely presentational.

- [ ] **Step 1: Write the failing test**

```tsx
// front/src/components/auth/register/PasswordStrengthMeter.test.tsx
import { render, screen } from '@testing-library/react';
import PasswordStrengthMeter from './PasswordStrengthMeter';

it('shows Weak for short password', () => {
  render(<PasswordStrengthMeter password="abc" />);
  expect(screen.getByText(/Weak/i)).toBeInTheDocument();
});
it('shows Strong for compliant password', () => {
  render(<PasswordStrengthMeter password="Abcdef12" />);
  expect(screen.getByText(/Strong/i)).toBeInTheDocument();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/PasswordStrengthMeter.test.tsx --watchAll=false`
Expected: FAIL — cannot find component.

- [ ] **Step 3: Implement**

```tsx
// front/src/components/auth/register/PasswordStrengthMeter.tsx
import React from 'react';
import { passwordStrength } from './validators';

const LABELS = ['Weak', 'Weak', 'Fair', 'Strong'];

const PasswordStrengthMeter: React.FC<{ password: string }> = ({ password }) => {
  const s = passwordStrength(password);
  const label = password ? LABELS[s.score] : '';
  return (
    <div className="pw-meter">
      <div className={`pw-bar pw-score-${s.score}`} aria-hidden />
      {password && <small>{label}</small>}
      {password && !s.valid && (
        <ul className="pw-hints">
          {!s.hasMin && <li>At least 8 characters</li>}
          {!s.hasUpper && <li>One uppercase letter</li>}
          {!s.hasLower && <li>One lowercase letter</li>}
          {!s.hasDigit && <li>One number</li>}
        </ul>
      )}
    </div>
  );
};
export default PasswordStrengthMeter;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/PasswordStrengthMeter.test.tsx --watchAll=false`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd front && git add src/components/auth/register/PasswordStrengthMeter.tsx src/components/auth/register/PasswordStrengthMeter.test.tsx
git commit -m "feat(auth): add PasswordStrengthMeter"
```

---

### Task 10: LocationField ("100% true" coordinates)

**Files:**
- Create: `front/src/components/auth/register/LocationField.tsx`, `front/src/components/auth/register/resolveLocation.ts`
- Test: `front/src/components/auth/register/resolveLocation.test.ts`

**Interfaces:**
- Consumes: `useLazyReverseGeocodeQuery`, `useLazyForwardGeocodeQuery` (Task 7).
- Produces:
  - Pure `normalizeLocationResult(raw) => LocationInput | null` — passes coordinates through only if 2 finite numbers and NOT `[0,0]`.
  - `<LocationField value onChange />` where `value: LocationInput | null`. "Use my location" → `navigator.geolocation` → reverse geocode. Manual: country select + city text → on blur forward-geocode to fill coordinates (best-effort). Emits `LocationInput` with real coords or none.

- [ ] **Step 1: Write the failing test (pure normalizer)**

```ts
// front/src/components/auth/register/resolveLocation.test.ts
import { normalizeLocationResult } from './resolveLocation';

it('keeps real coordinates', () => {
  expect(normalizeLocationResult({ city: 'Seoul', country: 'KR', coordinates: [127, 37.5] }))
    .toEqual({ city: 'Seoul', country: 'KR', coordinates: [127, 37.5] });
});
it('drops [0,0] fabricated coordinates', () => {
  expect(normalizeLocationResult({ city: 'X', country: 'Y', coordinates: [0, 0] }))
    .toEqual({ city: 'X', country: 'Y' });
});
it('drops non-finite coordinates', () => {
  expect(normalizeLocationResult({ city: 'X', country: 'Y', coordinates: [NaN, 1] as any }))
    .toEqual({ city: 'X', country: 'Y' });
});
it('returns null when no city/country', () => {
  expect(normalizeLocationResult({ city: null, country: null } as any)).toBeNull();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/resolveLocation.test.ts --watchAll=false`
Expected: FAIL — cannot find module.

- [ ] **Step 3: Implement normalizer + component**

```ts
// front/src/components/auth/register/resolveLocation.ts
import { LocationInput } from './buildRegisterPayload';

export function normalizeLocationResult(raw: any): LocationInput | null {
  if (!raw || (!raw.city && !raw.country)) return null;
  const out: LocationInput = { city: raw.city || '', country: raw.country || '' };
  const c = raw.coordinates;
  const finite = Array.isArray(c) && c.length === 2 && c.every((n: any) => Number.isFinite(n));
  const isNullIsland = finite && c[0] === 0 && c[1] === 0;
  if (finite && !isNullIsland) out.coordinates = [c[0], c[1]];
  return out;
}
```

```tsx
// front/src/components/auth/register/LocationField.tsx
import React, { useState } from 'react';
import { useLazyReverseGeocodeQuery, useLazyForwardGeocodeQuery } from '../../../store/slices/usersSlice';
import { LocationInput } from './buildRegisterPayload';
import { normalizeLocationResult } from './resolveLocation';

interface Props { value: LocationInput | null; onChange: (v: LocationInput | null) => void; }

const LocationField: React.FC<Props> = ({ value, onChange }) => {
  const [busy, setBusy] = useState(false);
  const [reverse] = useLazyReverseGeocodeQuery();
  const [forward] = useLazyForwardGeocodeQuery();
  const [city, setCity] = useState(value?.city || '');
  const [country, setCountry] = useState(value?.country || '');

  const detect = () => {
    if (!navigator.geolocation) return;
    setBusy(true);
    navigator.geolocation.getCurrentPosition(async (pos) => {
      try {
        const res: any = await reverse({ lat: pos.coords.latitude, lng: pos.coords.longitude });
        const norm = normalizeLocationResult(res?.data?.data);
        if (norm) { setCity(norm.city); setCountry(norm.country); onChange(norm); }
      } finally { setBusy(false); }
    }, () => setBusy(false), { timeout: 10000 });
  };

  const manualBlur = async () => {
    if (!city || !country) { onChange(city || country ? { city, country } : null); return; }
    try {
      const res: any = await forward({ city, country });
      onChange(normalizeLocationResult(res?.data?.data) || { city, country });
    } catch { onChange({ city, country }); }
  };

  return (
    <div className="location-field">
      <button type="button" onClick={detect} disabled={busy}>
        {busy ? 'Detecting…' : 'Use my location'}
      </button>
      <input aria-label="country" placeholder="Country" value={country}
        onChange={(e) => setCountry(e.target.value)} onBlur={manualBlur} />
      <input aria-label="city" placeholder="City" value={city}
        onChange={(e) => setCity(e.target.value)} onBlur={manualBlur} />
    </div>
  );
};
export default LocationField;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/resolveLocation.test.ts --watchAll=false`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd front && git add src/components/auth/register/LocationField.tsx src/components/auth/register/resolveLocation.ts src/components/auth/register/resolveLocation.test.ts
git commit -m "feat(auth): add LocationField with GPS+manual geocoding, never fabricates [0,0]"
```

---

## Phase 4 — Wizard restructure + OAuth parity

### Task 11: Restructure `Register.tsx` into the app-parity wizard

**Files:**
- Modify: `front/src/components/auth/Register.tsx` (reuse its `step` state + progress bar; reorder to verify-first; wire the new fields/widgets/builder)
- Create: `front/src/components/auth/register/steps.ts` (step order constant + labels)
- Test: `front/src/components/auth/register/steps.test.ts`

**Interfaces:**
- Consumes: all of Tasks 5–10.
- Produces: signup order `['email','verify','basics','languages','photo','finish']`; final submit uses `buildRegisterPayload`, then `useUploadUserPhotoMutation`, then auto-login (existing behavior), honoring `?redirect=`.

- [ ] **Step 1: Write the failing test (step order)**

```ts
// front/src/components/auth/register/steps.test.ts
import { SIGNUP_STEPS } from './steps';
it('verifies email before collecting profile (app parity)', () => {
  expect(SIGNUP_STEPS.indexOf('verify')).toBeLessThan(SIGNUP_STEPS.indexOf('basics'));
  expect(SIGNUP_STEPS).toEqual(['email', 'verify', 'basics', 'languages', 'photo', 'finish']);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/steps.test.ts --watchAll=false`
Expected: FAIL — cannot find module.

- [ ] **Step 3: Add step constant**

```ts
// front/src/components/auth/register/steps.ts
export const SIGNUP_STEPS = ['email', 'verify', 'basics', 'languages', 'photo', 'finish'] as const;
export type SignupStep = typeof SIGNUP_STEPS[number];
export const STEP_LABELS: Record<SignupStep, string> = {
  email: 'Email', verify: 'Verify', basics: 'Account', languages: 'Languages', photo: 'Photo', finish: 'Finish',
};
```

- [ ] **Step 4: Wire the wizard in `Register.tsx`**

In `front/src/components/auth/Register.tsx`:
- Import `SIGNUP_STEPS`, the three widgets (`UsernameAvailabilityField`, `PasswordStrengthMeter`, `LocationField`), `buildRegisterPayload`, `passwordStrength`, `isAdult`.
- Add state: `const [username, setUsername] = useState("")`, `const [usernameOk, setUsernameOk] = useState(true)`, `const [languageLevel, setLanguageLevel] = useState("")`, `const [learningLevel, setLearningLevel] = useState("")`, `const [location, setLocation] = useState<LocationInput | null>(null)`, `const [termsAccepted, setTermsAccepted] = useState(false)`.
- Change the flow so email + code verification (`registerCodeEmail` / `verifyRegistrationCode`) run FIRST (steps `email`,`verify`), then `basics` (name, `UsernameAvailabilityField`, password + `PasswordStrengthMeter`, gender, birthDate), then `languages` (native + learning + CEFR selects bound to `languageLevel`/`learningLevel`), then `photo` (existing image upload, now REQUIRED — block "next" if `selectedImages.length === 0`), then `finish` (`LocationField` + terms checkbox + submit).
- Gate "next"/submit exactly like the app: basics requires `usernameOk`, `passwordStrength(password).valid`, `password === confirmPassword`, `isAdult(birthDate)`; photo requires an image; finish requires `location?.city && location?.country` and `termsAccepted`.
- Replace the register mutation call body with `buildRegisterPayload({ name, username, password, email, gender, birthDate, native_language: nativeLanguage, language_to_learn: languageToLearn, location: location! })`. After success, upload photo via `useUploadUserPhotoMutation`, then set `languageLevel`/`learningLevel` via `useUpdateUserInfoMutation` (`PUT /auth/updatedetails`) since `register` does not persist CEFR, then keep the existing auto-login + redirect.

- [ ] **Step 5: Run typecheck + full test suite**

Run: `cd front && npx tsc --noEmit && CI=true npx react-scripts test src/components/auth --watchAll=false`
Expected: no type errors; all auth tests PASS.

- [ ] **Step 6: Build to confirm no breakage**

Run: `cd front && CI=false npx react-scripts build 2>&1 | tail -5`
Expected: "Compiled" / build succeeds.

- [ ] **Step 7: Commit**

```bash
cd front && git add src/components/auth/Register.tsx src/components/auth/register/steps.ts src/components/auth/register/steps.test.ts
git commit -m "feat(auth): restructure signup into app-parity wizard (verify-first, username/CEFR/photo/location/terms)"
```

---

### Task 12: OAuth-completion parity + terms

**Files:**
- Modify: `front/src/components/auth/AuthCallback.tsx` (route incomplete profiles through the wizard's profile steps; call `POST /auth/accept-terms`)
- Modify: `front/src/store/slices/usersSlice.ts` (add `acceptTerms` mutation → `POST /api/v1/auth/accept-terms`)
- Modify: `front/src/constants.ts` (add `ACCEPT_TERMS_URL`)
- Test: `front/src/store/slices/acceptTerms.test.ts`

**Interfaces:**
- Consumes: Task 11 wizard steps; the verified backend endpoint `POST /api/v1/auth/accept-terms`.
- Produces: `useAcceptTermsMutation`; incomplete OAuth users complete `languages`→`photo`→`finish` (which submits via `updatedetails`, not `register`) and record terms via `acceptTerms`.

- [ ] **Step 1: Add constant + endpoint + shape test**

```ts
// front/src/constants.ts
export const ACCEPT_TERMS_URL = "/api/v1/auth/accept-terms";
```

```ts
// usersSlice.ts — inside injectEndpoints
acceptTerms: builder.mutation({
  query: () => ({ url: ACCEPT_TERMS_URL, method: 'POST' }),
}),
// export: useAcceptTermsMutation
```

```ts
// front/src/store/slices/acceptTerms.test.ts
import { ACCEPT_TERMS_URL } from '../../constants';
it('has the accept-terms path', () => { expect(ACCEPT_TERMS_URL).toBe('/api/v1/auth/accept-terms'); });
```

- [ ] **Step 2: Run test to verify it fails then passes**

Run: `cd front && CI=true npx react-scripts test src/store/slices/acceptTerms.test.ts --watchAll=false`
Expected: after adding the constant, PASS.

- [ ] **Step 3: Wire AuthCallback**

In `AuthCallback.tsx`, where `isProfileComplete(userInfo)` is false, navigate into the wizard at the `languages` step in completion mode (pass `state:{ oauth:true, startStep:'languages' }`), and in the wizard's finish submit for OAuth mode call `useAcceptTermsMutation` after a successful `updatedetails`. Keep the existing complete-profile happy path.

- [ ] **Step 4: Typecheck + build**

Run: `cd front && npx tsc --noEmit && CI=false npx react-scripts build 2>&1 | tail -5`
Expected: no type errors; build succeeds.

- [ ] **Step 5: Commit**

```bash
cd front && git add src/constants.ts src/store/slices/usersSlice.ts src/store/slices/acceptTerms.test.ts src/components/auth/AuthCallback.tsx
git commit -m "feat(auth): OAuth profile-completion parity + accept-terms recording"
```

---

### Task 13: Remove dead auth code (careful cleanup)

**Files:**
- Delete: `front/src/components/auth/OAuthCallback.tsx` (+ `.scss` if unused) — NOT referenced in `AppRouter.tsx`
- Verify: `front/src/store/actions/authAction/`, `front/src/store/reducers/authReducer/` are unreferenced before removing

- [ ] **Step 1: Confirm no references**

Run: `cd front && grep -rn "OAuthCallback\|authAction\|authReducer" src --include=*.ts --include=*.tsx | grep -v "authSlice"`
Expected: only the definitions themselves; no imports from live code. If anything imports them, STOP and leave them.

- [ ] **Step 2: Delete dead files (only those with zero references)**

```bash
cd front && git rm src/components/auth/OAuthCallback.tsx src/components/auth/OAuthCallback.scss
```

- [ ] **Step 3: Typecheck + build**

Run: `cd front && npx tsc --noEmit && CI=false npx react-scripts build 2>&1 | tail -5`
Expected: no type errors; build succeeds.

- [ ] **Step 4: Commit**

```bash
cd front && git add -A && git commit -m "chore(auth): remove dead OAuthCallback duplicate"
```

---

## Phase 5 — Auth UI cohesion + password-reset fix

Grounded in the 2026-07-18 audit. Password reset today is `ForgetPassword.tsx` (3-step: `EnterEmail` → `VerifyCode` → `SetNewPassword`), plain react-bootstrap, and **broken**: `handlePasswordReset` posts `{ email, newPassword }` to `/auth/reset-password`, but the backend `resetPassword` (`backend/controllers/auth.js`) **requires `{ email, code, newPassword }`** and validates the hashed code — so every reset 400s. `VerifyCode.tsx` also clears the code after step 2, so the parent must retain it.

### Task 14: Shared Tailwind auth shell

**Files:**
- Create: `front/src/components/auth/AuthShell.tsx`
- Test: `front/src/components/auth/AuthShell.test.tsx`

**Interfaces:**
- Produces: `<AuthShell title subtitle?>{children}</AuthShell>` — the shared branded container (teal gradient side panel + `rounded-2xl` glass card) used by Login, Register, and the reset flow so all auth pages share one look. Tailwind only.

- [ ] **Step 1: Write the failing test**

```tsx
// front/src/components/auth/AuthShell.test.tsx
import { render, screen } from '@testing-library/react';
import AuthShell from './AuthShell';
it('renders title, subtitle, and children', () => {
  render(<AuthShell title="Reset password" subtitle="We'll email you a code"><button>Go</button></AuthShell>);
  expect(screen.getByText('Reset password')).toBeInTheDocument();
  expect(screen.getByText("We'll email you a code")).toBeInTheDocument();
  expect(screen.getByRole('button', { name: 'Go' })).toBeInTheDocument();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd front && CI=true npx react-scripts test src/components/auth/AuthShell.test.tsx --watchAll=false`
Expected: FAIL — cannot find component.

- [ ] **Step 3: Implement (Tailwind, matching EditProfile look)**

```tsx
// front/src/components/auth/AuthShell.tsx
import React from 'react';

interface Props { title: string; subtitle?: string; children: React.ReactNode; }

const AuthShell: React.FC<Props> = ({ title, subtitle, children }) => (
  <div className="min-h-screen flex bg-gradient-to-br from-teal-50 via-sky-50 to-purple-50">
    <div className="hidden lg:flex flex-1 items-center justify-center bg-gradient-to-br from-[#00BFA5] to-[#00A896] text-white p-12">
      <div className="max-w-md">
        <h1 className="text-4xl font-bold mb-4">BananaTalk</h1>
        <p className="text-white/90">Practice languages with native speakers worldwide.</p>
      </div>
    </div>
    <div className="flex-1 flex items-center justify-center p-6">
      <div className="w-full max-w-md bg-white/80 backdrop-blur-xl rounded-2xl shadow-xl p-8">
        <h2 className="text-2xl font-semibold text-gray-900">{title}</h2>
        {subtitle && <p className="text-gray-500 mt-1 mb-6">{subtitle}</p>}
        <div className={subtitle ? '' : 'mt-6'}>{children}</div>
      </div>
    </div>
  </div>
);
export default AuthShell;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd front && CI=true npx react-scripts test src/components/auth/AuthShell.test.tsx --watchAll=false`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd front && git add src/components/auth/AuthShell.tsx src/components/auth/AuthShell.test.tsx
git commit -m "feat(auth): add shared Tailwind AuthShell for cohesive auth pages"
```

---

### Task 15: Fix password-reset correctness (thread code, strength, guards, i18n)

**Files:**
- Modify: `front/src/components/auth/ForgetPassword.tsx` (retain `code` in parent; send it to reset), `front/src/components/auth/VerifyCode.tsx` (stop clearing code; lift it up; use `isLoading`), `front/src/components/auth/SetNewPassword.tsx` (password strength + loading guard)
- Test: `front/src/components/auth/register/buildResetPayload.test.ts`
- Create: `front/src/components/auth/register/buildResetPayload.ts`

**Interfaces:**
- Consumes: `passwordStrength` (Task 5), `useResetPasswordUserMutation`.
- Produces: `buildResetPayload({email, code, newPassword}) => { email, code, newPassword }` — the backend-required shape (guards against sending a reset without a code).

- [ ] **Step 1: Write the failing test**

```ts
// front/src/components/auth/register/buildResetPayload.test.ts
import { buildResetPayload } from './buildResetPayload';
it('includes the verified code (backend requires it)', () => {
  expect(buildResetPayload({ email: 'a@b.com', code: '123456', newPassword: 'Abcdef12' }))
    .toEqual({ email: 'a@b.com', code: '123456', newPassword: 'Abcdef12' });
});
it('throws if code missing (prevents the current broken call)', () => {
  expect(() => buildResetPayload({ email: 'a@b.com', code: '', newPassword: 'Abcdef12' })).toThrow();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/buildResetPayload.test.ts --watchAll=false`
Expected: FAIL — cannot find module.

- [ ] **Step 3: Implement builder + wire the components**

```ts
// front/src/components/auth/register/buildResetPayload.ts
export function buildResetPayload(input: { email: string; code: string; newPassword: string }) {
  if (!input.code || !input.code.trim()) throw new Error('Verification code is required to reset the password');
  return { email: input.email, code: input.code.trim(), newPassword: input.newPassword };
}
```

Wire-up:
- `ForgetPassword.tsx`: hold `code` in parent state; pass a setter to `VerifyCode`; `handlePasswordReset` calls `useResetPasswordUserMutation` with `buildResetPayload({ email, code, newPassword })`.
- `VerifyCode.tsx`: remove the line that clears `code` on success; call the parent setter with the verified code; wire the destructured `isLoading` to `disabled` on the Verify button; add a "Resend code" button that re-calls `useSendCodeEmailMutation`.
- `SetNewPassword.tsx`: block submit unless `passwordStrength(newPassword).valid` and `newPassword === confirm`; add `disabled` while the reset mutation is loading; render `PasswordStrengthMeter`.

- [ ] **Step 4: Run test + typecheck**

Run: `cd front && CI=true npx react-scripts test src/components/auth/register/buildResetPayload.test.ts --watchAll=false && npx tsc --noEmit`
Expected: PASS; no type errors.

- [ ] **Step 5: Commit**

```bash
cd front && git add src/components/auth/register/buildResetPayload.ts src/components/auth/register/buildResetPayload.test.ts src/components/auth/ForgetPassword.tsx src/components/auth/VerifyCode.tsx src/components/auth/SetNewPassword.tsx
git commit -m "fix(auth): pass verified code to reset-password + add strength/loading guards"
```

---

### Task 16: Rebuild reset UI on AuthShell (Tailwind) + finish i18n/a11y

**Files:**
- Modify: `front/src/components/auth/ForgetPassword.tsx`, `EnterEmail.tsx`, `VerifyCode.tsx`, `SetNewPassword.tsx` (wrap in `AuthShell`, Tailwind, remove bootstrap `Card/Form.Control`), and migrate hardcoded English to the existing i18n `t(...)` keys; add show-password toggle + `aria-label`s; add a "Back to login" link.

**Interfaces:**
- Consumes: `AuthShell` (Task 14), `PasswordStrengthMeter` (Task 9).

- [ ] **Step 1: Migrate `EnterEmail`, `VerifyCode`, `SetNewPassword` to Tailwind + AuthShell**

Replace each step's `Container`/`div.card`/`Form.Control`/`Button` with `AuthShell`-wrapped Tailwind markup (inputs `w-full rounded-lg border px-3 py-2`, primary button `bg-[#00BFA5] text-white rounded-lg py-2 disabled:opacity-50`). Reuse the `EditProfile` visual language. Add a "Back to login" `Link` to `/login` on step 1.

- [ ] **Step 2: Finish i18n**

Replace every hardcoded English string in `VerifyCode.tsx` and `SetNewPassword.tsx` with `t('authentication.passwordReset.*')` keys; add any missing keys to the locale files under `src/utils/locales/*.json` (match the existing key namespace used by `EnterEmail`).

- [ ] **Step 3: a11y**

Give the show-password toggle and any icon-only buttons `aria-label`; ensure each input has an associated `<label htmlFor>`.

- [ ] **Step 4: Typecheck + build + manual smoke**

Run: `cd front && npx tsc --noEmit && CI=false npx react-scripts build 2>&1 | tail -5`
Expected: no type errors; build succeeds. Manual: run the reset flow end-to-end against a dev backend and confirm the password actually resets (no 400).

- [ ] **Step 5: Commit**

```bash
cd front && git add src/components/auth/ForgetPassword.tsx src/components/auth/EnterEmail.tsx src/components/auth/VerifyCode.tsx src/components/auth/SetNewPassword.tsx src/utils/locales/
git commit -m "feat(auth): rebuild reset flow on Tailwind AuthShell, finish i18n + a11y"
```

---

## Self-Review notes (author)

- **Spec coverage:** verify-first reorder (T11), username live-check (T8) + backend honoring (T2/T3), password strength (T5/T9), 18+ gate (T5/T11), CEFR (T11 via updatedetails), required photo (T11), required location + "100% true" coords (T6/T10/T4), terms (T11 register body + T12 accept-terms), topics excluded (T6 emits `topics:[]`, no topics step), OAuth parity (T12). All spec sections map to a task.
- **Open items resolved during planning:** accept-terms endpoint confirmed present (`POST /api/v1/auth/accept-terms`); CEFR set via `updatedetails` because `register` does not accept `languageLevel`; location schema does not require `coordinates`, so manual-only omits them; geocoder = Nominatim proxy (Task 4).
- **Type consistency:** `LocationInput` defined in Task 6, reused in Tasks 10/11; `buildRegisterPayload` body matches the Global Constraints app-identical shape; hook names (`useLazyCheckUsernameQuery`, `useLazyReverseGeocodeQuery`, `useLazyForwardGeocodeQuery`, `useAcceptTermsMutation`) consistent across Tasks 7/8/10/12.
- **Phase 5 coverage:** audit's confirmed reset bug (code not sent) → Task 15 (`buildResetPayload` requires `code`, matches backend `resetPassword` `{email,code,newPassword}`); auth-UI cohesion → Task 14 `AuthShell` (Tailwind) + Task 16 reset-flow migration; reset a11y/i18n/loading/resend/back-to-login → Task 16 + 15; password strength on reset reuses Task 5. Register wizard (Task 11) keeps its functional focus; its visual migration onto `AuthShell`/Tailwind rides along in the Phase 5 cohesion pass (incremental — Register may briefly retain its SCSS until then). Login generic-error toast + icon-button aria-labels are minor polish folded into Task 16's a11y pass where they touch shared components; deeper error-taxonomy work is deferred to 1b.
