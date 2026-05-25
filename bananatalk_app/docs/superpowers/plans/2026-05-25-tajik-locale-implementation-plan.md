# Tajik (tg) Locale Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add full Cyrillic Tajik (`tg-TJ`) localization to BananaTalk: translate all ~1725 ARB keys + backend notification template, wire UI-language plumbing and content-language touchpoints across Moments and Vocabulary. Ship in one PR with no flag or review gate.

**Architecture:** Standard `flutter_localizations` + `intl` with ARB files in `lib/l10n/` and committed `flutter gen-l10n` output. Tajik joins the existing 18 locales without changing the i18n architecture. Wiring is mechanical; the bulk of the work is bulk-translating ARB values into Cyrillic Tajik per the policy in the spec.

**Tech Stack:** Flutter, Dart, `flutter_localizations`, `intl ^0.20.2`, gen-l10n CLI, Node.js backend (for `notification_templates/tg.json`).

**Spec reference:** `docs/superpowers/specs/2026-05-25-tajik-locale-scaffolding-design.md` — keep open in another tab; the translation-policy section is the source of truth for register, plurals, borrowed-word handling, and proper-noun rules.

---

## Phase 1 — Compilable stub

Goal of phase: `flutter analyze` is green with Tajik wired in, even though every Tajik string still renders as English. This locks in the locale ID and gen-l10n output before any bulk work.

### Task 1: Create stub `app_tg.arb` and regenerate localization Dart

**Files:**
- Create: `lib/l10n/app_tg.arb`
- Regen: `lib/l10n/app_localizations.dart` (via `flutter gen-l10n`)
- Create: `lib/l10n/app_localizations_tg.dart` (via `flutter gen-l10n`)

- [ ] **Step 1: Write the stub ARB**

Create `lib/l10n/app_tg.arb` with exactly this content:

```json
{
  "@@locale": "tg",
  "appName": "Bananatalk"
}
```

- [ ] **Step 2: Verify JSON well-formedness**

Run: `python3 -m json.tool lib/l10n/app_tg.arb > /dev/null && echo OK`
Expected output: `OK`

- [ ] **Step 3: Run codegen**

Run: `flutter pub get` (the `l10n.yaml` at `lib/l10n/l10n.yaml` makes pub get trigger gen-l10n).

If for any reason gen-l10n isn't auto-triggered, run `flutter gen-l10n` directly.

- [ ] **Step 4: Verify generated files exist and contain `tg`**

Run: `ls -la lib/l10n/app_localizations_tg.dart && grep -c "Locale('tg')" lib/l10n/app_localizations.dart`
Expected: the file exists; grep returns `1` (one occurrence in the `supportedLocales` const).

- [ ] **Step 5: Verify the app still compiles**

Run: `flutter analyze --no-pub`
Expected: exits 0, no errors. Warnings about gen-l10n output are OK.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_tg.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_tg.dart
git commit -m "feat(tajik): scaffold tg locale (stub ARB + gen-l10n output)"
```

---

## Phase 2 — Wire UI-language plumbing

After this phase, "Тоҷикӣ" appears in the in-app language picker with the 🇹🇯 flag, and selecting it switches MaterialApp to `Locale('tg', 'TJ')`. Every Tajik string still renders English (because the ARB is a stub) — that's expected.

### Task 2: Add `Locale('tg', 'TJ')` to MaterialApp supportedLocales

**File:** `lib/main.dart` (locale list lives around line 288)

- [ ] **Step 1: Read the surrounding context**

Run: `sed -n '266,295p' lib/main.dart`
Expected: a `supportedLocales: const [` block ending with `Locale('vi', 'VN'),`. Confirm shape before editing.

- [ ] **Step 2: Add the Tajik locale entry**

Insert `Locale('tg', 'TJ'),` as the new last entry in the list, immediately after the line containing `Locale('vi', 'VN'),`. Preserve indentation.

The edited block should look like:

```dart
        Locale('vi', 'VN'),
        Locale('tg', 'TJ'),
      ],
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze --no-pub lib/main.dart`
Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(tajik): add Locale('tg', 'TJ') to MaterialApp supportedLocales"
```

### Task 3: Wire LanguageService

**File:** `lib/services/language_service.dart` (5 edits)

- [ ] **Step 1: Read each edit site**

Run: `sed -n '1,100p' lib/services/language_service.dart` then `sed -n '140,210p' lib/services/language_service.dart`
Confirm where the five maps/methods live: supported-codes list (~line 26), `_nativeNames` map (~line 48), `_flags` map (~line 70), `_normalizeLanguageCode` (~line 98), `_localeFromLanguageCode` (~line 148).

- [ ] **Step 2: Edit supported codes list**

Find the comment `// Supported languages (all 18 languages matching ARB files)` and bump the count to 19. Add `'tg', // Tajik` to the supported codes list. Place it at the end of the existing entries, preserving the existing formatting style.

- [ ] **Step 3: Edit `_nativeNames` map**

Add the entry: `'tg': 'Тоҷикӣ',` Place it at the end of the existing entries, before the closing `};`.

- [ ] **Step 4: Edit `_flags` map**

Add the entry: `'tg': '🇹🇯',` Place it at the end, before the closing `};`.

- [ ] **Step 5: Edit `_normalizeLanguageCode` aliases**

In whatever style the existing aliases use (the current example is `'fil': 'tl'`), add four normalizer entries that all map to `'tg'`:

```dart
'tajik': 'tg',
'taj': 'tg',
'tg-tj': 'tg',
'fa-tj': 'tg',
```

- [ ] **Step 6: Edit `_localeFromLanguageCode` switch**

Add a new case `case 'tg':` returning `const Locale('tg', 'TJ');`. Match the formatting of the existing cases (e.g., the `case 'tl':` returning `Locale('tl', 'PH')` at line ~179).

- [ ] **Step 7: Analyze**

Run: `flutter analyze --no-pub lib/services/language_service.dart`
Expected: exits 0.

- [ ] **Step 8: Commit**

```bash
git add lib/services/language_service.dart
git commit -m "feat(tajik): wire tg into LanguageService (codes/names/flag/normalizer/locale)"
```

### Task 4: Wire `language_flags.dart`

**File:** `lib/utils/language_flags.dart` (2 edits)

- [ ] **Step 1: Read each edit site**

Run: `sed -n '95,120p' lib/utils/language_flags.dart` then `sed -n '290,310p' lib/utils/language_flags.dart`
Confirm: flag map at ~line 100 area (the `'tl': '🇵🇭'` is a known landmark at line 109), name-aliases map at ~line 298 area (the `'tagalog': 'tl'` is a known landmark at line 298).

- [ ] **Step 2: Add to flag map**

Add these two entries to the flag map (the map currently containing `'tl': '🇵🇭'`):

```dart
'tg': '🇹🇯',
'tajik': '🇹🇯',
```

- [ ] **Step 3: Add to name-aliases map**

Add these three entries to the name-aliases map (the map currently containing `'tagalog': 'tl'`):

```dart
'tajik': 'tg',
'tajiki': 'tg',
'тоҷикӣ': 'tg',
```

- [ ] **Step 4: Analyze**

Run: `flutter analyze --no-pub lib/utils/language_flags.dart`
Expected: exits 0.

- [ ] **Step 5: Commit**

```bash
git add lib/utils/language_flags.dart
git commit -m "feat(tajik): add tg flag + name aliases to language_flags.dart"
```

---

## Phase 3 — Content-language touchpoints

After this phase, Tajik is selectable as content language wherever users tag content by language (moments, vocab).

### Task 5: Add Tajik to moments filter

**File:** `lib/pages/moments/filter/moment_filter_model.dart` (1 edit)

- [ ] **Step 1: Read the comprehensive list**

Run: `sed -n '90,160p' lib/pages/moments/filter/moment_filter_model.dart`
Confirm the `allLanguages` list and its alphabetical "Additional languages" section.

- [ ] **Step 2: Add Tajik entry**

In `FilterOptions.allLanguages`, in the alphabetical "Additional languages" section, insert `{'code': 'tg', 'name': 'Tajik'},` in correct alphabetical position (between any language starting with "Sw"/"T" entries already present; should land between something like "Swedish" and "Thai" or wherever the alphabet places it).

If unsure of exact alphabetical position, place it immediately before the entry for `'th'` (Thai). The display order of this list is alphabetical-by-name, so "Tajik" comes before "Thai".

**Do NOT add Tajik to `popularLanguages`** — that's a curated top-10 list. Tajik doesn't belong there.

- [ ] **Step 3: Analyze**

Run: `flutter analyze --no-pub lib/pages/moments/filter/moment_filter_model.dart`
Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/moments/filter/moment_filter_model.dart
git commit -m "feat(tajik): add tg to moments filter allLanguages list"
```

### Task 6: Add Tajik to moment creation

**File:** `lib/pages/moments/create/create_moment.dart` (1 edit, around line 108-130 area)

- [ ] **Step 1: Read the language map**

Run: `sed -n '105,140p' lib/pages/moments/create/create_moment.dart`
Confirm the `_languages` display-name→code map.

- [ ] **Step 2: Add Tajik entry**

Add `'Tajik': 'tg',` to the `_languages` map, in alphabetical position (before `'Thai': 'th'`).

- [ ] **Step 3: Analyze**

Run: `flutter analyze --no-pub lib/pages/moments/create/create_moment.dart`
Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/moments/create/create_moment.dart
git commit -m "feat(tajik): add Tajik to create_moment language map"
```

### Task 7: Add Tajik to single moment display

**File:** `lib/pages/moments/single/single_moment.dart` (3 edits)

- [ ] **Step 1: Read the relevant blocks**

Run: `sed -n '49,110p' lib/pages/moments/single/single_moment.dart`
Confirm: `_languageFlags` map (~line 49), `_getLanguageCode` helper (~line 72), `_getFlagEmoji` helper (~line 92).

- [ ] **Step 2: Add to `_languageFlags` map**

Add `'tg': '🇹🇯',` to the `_languageFlags` map, near the other flag entries.

- [ ] **Step 3: Add `tajik`/`tg` case to `_getLanguageCode`**

Inside `_getLanguageCode`, after the existing if-chain, add (immediately before the fallback `return language.toUpperCase().substring(...);`):

```dart
    if (langLower.contains('tajik') || langLower == 'tg') return 'TG';
```

- [ ] **Step 4: Add `tajik`/`tg` case to `_getFlagEmoji`**

Inside `_getFlagEmoji`, in the same position relative to its fallback, add:

```dart
    if (langLower.contains('tajik') || langLower == 'tg') return '🇹🇯';
```

- [ ] **Step 5: Analyze**

Run: `flutter analyze --no-pub lib/pages/moments/single/single_moment.dart`
Expected: exits 0.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/moments/single/single_moment.dart
git commit -m "feat(tajik): add tg flag + code helpers to single_moment"
```

### Task 8: Add Tajik to moment card header

**File:** `lib/pages/moments/card/moment_card_header.dart` (1 edit)

- [ ] **Step 1: Read the helper**

Run: `sed -n '25,50p' lib/pages/moments/card/moment_card_header.dart`
Confirm the `_getLanguageCode` helper structure.

- [ ] **Step 2: Add the case**

In `_getLanguageCode`, immediately before the fallback return at the bottom, add:

```dart
    if (langLower.contains('tajik') || langLower == 'tg') return 'TG';
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze --no-pub lib/pages/moments/card/moment_card_header.dart`
Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/moments/card/moment_card_header.dart
git commit -m "feat(tajik): add tg case to moment_card_header"
```

### Task 9: Add Tajik to vocabulary add screen

**File:** `lib/pages/learning/vocabulary/vocabulary_add_screen.dart` (2 edits)

- [ ] **Step 1: Read the language lists**

Run: `sed -n '30,45p' lib/pages/learning/vocabulary/vocabulary_add_screen.dart`
Confirm `_languages` list (~line 32) and `_languageNames` map (~line 36).

- [ ] **Step 2: Add `'tg'` to `_languages`**

Append `'tg'` to the `_languages` list at the end:

```dart
final List<String> _languages = [
  'en', 'ko', 'es', 'fr', 'de', 'ja', 'zh', 'ar', 'pt', 'ru', 'it', 'nl', 'hi', 'th', 'vi', 'tg'
];
```

- [ ] **Step 3: Add `'tg': 'Tajik'` to `_languageNames`**

Add `'tg': 'Tajik',` to the `_languageNames` map at the end.

- [ ] **Step 4: Analyze**

Run: `flutter analyze --no-pub lib/pages/learning/vocabulary/vocabulary_add_screen.dart`
Expected: exits 0.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/learning/vocabulary/vocabulary_add_screen.dart
git commit -m "feat(tajik): add tg to vocabulary_add language list"
```

---

## Phase 4 — Backend notification template

### Task 10: Clone English backend template to Tajik (English content placeholder)

**File:** `backend/notification_templates/tg.json` (NEW)

**Repo layout note:** `backend/` is a sibling of `bananatalk_app/` inside one mono-repo (the parent dir `/Users/firdavsmutalipov/Projects/BananaTalk/` holds the `.git`). All `git` commands below run from inside `bananatalk_app/` and reference backend via `../backend/...`.

- [ ] **Step 1: Copy English template**

Run: `cp ../backend/notification_templates/en.json ../backend/notification_templates/tg.json`

- [ ] **Step 2: Verify JSON validity and identical structure**

Run: `python3 -m json.tool ../backend/notification_templates/tg.json > /dev/null && echo OK`
Expected: `OK`

Run: `diff ../backend/notification_templates/en.json ../backend/notification_templates/tg.json | wc -l`
Expected: `0` (files are identical — translation happens in Phase 6).

- [ ] **Step 3: Commit**

```bash
git add ../backend/notification_templates/tg.json
git commit -m "feat(tajik): seed tg notification template (English content placeholder)"
```

---

## Phase 5 — Translate `app_tg.arb` in batches

This is the bulk of the work: 1725 keys, ~107 KB of source text, translated into Cyrillic Tajik per the spec's translation policy.

**Before starting any batch:** Re-read the "Translation policy" section of `docs/superpowers/specs/2026-05-25-tajik-locale-scaffolding-design.md`. Key constraints:

1. **Preserve every ICU placeholder verbatim.** `{name}`, `{count}`, `{userName}`, plural blocks like `{count, plural, =0{...} =1{...} other{...}}` — never translate the structural keywords (`plural`, `=0`, `=1`, `other`, `select`); only translate the human-language text inside the branches.
2. **`@`-prefixed metadata blocks (e.g., `@appName`):** drop them from `app_tg.arb`. Only the template `app_en.arb` carries them. Locale ARBs are flat key→value pairs.
3. **Proper nouns stay in Latin:** `Bananatalk`, brand names, partner names — do not transliterate.
4. **Borrowed words from Russian are preferred where natural:** `Парол` (password), `Профил` (profile), `Танзимот` (settings), `Стори` (story), etc.
5. **Polite-imperative register for buttons/actions** (`Ворид шавед`, `Захира кунед`), **descriptive for labels** (`Парол`, `Забон`).
6. **Tajik plural rules:** `=0`, `=1`, `other` are sufficient. Don't add `few`/`many` categories.

**Translation method:** Replace the stub `app_tg.arb` written in Task 1 with a complete file that mirrors the structure of `app_en.arb` (1725 key→value pairs, no `@`-prefixed blocks). Build it batch by batch.

**Batch line ranges in `app_en.arb` (source of keys):**
| Batch | Keys | English-file lines | First key | Last key (next batch's first key as boundary) |
|---|---|---|---|---|
| 1 | 1–290 | 3–340 | `appName` | up to (not including) `forward` |
| 2 | 291–580 | 341–772 | `forward` | up to `typeDeleteToConfirm` |
| 3 | 581–870 | 773–1246 | `typeDeleteToConfirm` | up to `pleaseEnterYourName` |
| 4 | 871–1160 | 1247–1663 | `pleaseEnterYourName` | up to `editInterests` |
| 5 | 1161–1450 | 1664–2232 | `editInterests` | up to `highlightNewBadge` |
| 6 | 1451–1725 | 2233–EOF | `highlightNewBadge` | EOF |

Tasks 11-16 each translate one batch.

### Task 11: Translate batch 1 (keys 1-290, auth + onboarding + core nav)

**File:** `lib/l10n/app_tg.arb` (full rewrite — replaces the stub)

- [ ] **Step 1: Read the English source for this batch**

Run: `sed -n '1,340p' lib/l10n/app_en.arb`
Capture the key list. Note any `@key` descriptor blocks for reference (these inform what the key is *for*); the descriptors themselves are NOT copied into `app_tg.arb`.

- [ ] **Step 2: Translate every value in this batch**

Produce a Cyrillic Tajik translation for each of the ~290 keys, applying the translation policy. For keys with ICU placeholders or plurals, work inside the placeholder/plural structure.

- [ ] **Step 3: Write the partial `app_tg.arb`**

Start with `{` on line 1, `"@@locale": "tg",` on line 2, then the translated key→value pairs for batch 1. Leave a trailing comma on the last batch-1 key. Do NOT close the JSON yet (batch 2+ will append more keys before the final `}`).

If your editor prefers self-closing JSON between batches: write a fully-closed JSON containing only batch-1 keys, then re-open and append in each subsequent batch.

- [ ] **Step 4: Verify JSON well-formedness (if closing between batches)**

Run: `python3 -m json.tool lib/l10n/app_tg.arb > /dev/null && echo OK`
Expected: `OK`. If you used the "leave open until the end" approach, skip this verification step in batches 1-5 and do it once at the end of batch 6.

- [ ] **Step 5: Verify ICU placeholder integrity**

Run this placeholder-diff check against the English source for this batch range:

```bash
diff <(grep -oE '\{[^}]*\}' lib/l10n/app_en.arb | sort -u) \
     <(grep -oE '\{[^}]*\}' lib/l10n/app_tg.arb | sort -u)
```

Expected after batch 6 (final): empty diff (every placeholder used in English appears in Tajik). After intermediate batches, the diff is expected to show English-only placeholders for the keys not yet translated — that's fine; the check matters at the end.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_tg.arb
git commit -m "feat(tajik): translate batch 1 of app_tg.arb (keys 1-290)"
```

### Task 12: Translate batch 2 (keys 291-580)

Repeat the Task 11 procedure for keys 291–580 (English-source lines 341–772).

- [ ] **Step 1:** `sed -n '341,772p' lib/l10n/app_en.arb`
- [ ] **Step 2:** Translate every value, applying the policy.
- [ ] **Step 3:** Extend `app_tg.arb` with batch 2 keys.
- [ ] **Step 4:** Re-verify JSON if closing each batch.
- [ ] **Step 5:** Commit:
  ```bash
  git add lib/l10n/app_tg.arb
  git commit -m "feat(tajik): translate batch 2 of app_tg.arb (keys 291-580)"
  ```

### Task 13: Translate batch 3 (keys 581-870)

- [ ] **Step 1:** `sed -n '773,1246p' lib/l10n/app_en.arb`
- [ ] **Step 2:** Translate.
- [ ] **Step 3:** Extend `app_tg.arb`.
- [ ] **Step 4:** Re-verify JSON if applicable.
- [ ] **Step 5:** Commit:
  ```bash
  git add lib/l10n/app_tg.arb
  git commit -m "feat(tajik): translate batch 3 of app_tg.arb (keys 581-870)"
  ```

### Task 14: Translate batch 4 (keys 871-1160)

- [ ] **Step 1:** `sed -n '1247,1663p' lib/l10n/app_en.arb`
- [ ] **Step 2:** Translate.
- [ ] **Step 3:** Extend `app_tg.arb`.
- [ ] **Step 4:** Re-verify JSON if applicable.
- [ ] **Step 5:** Commit:
  ```bash
  git add lib/l10n/app_tg.arb
  git commit -m "feat(tajik): translate batch 4 of app_tg.arb (keys 871-1160)"
  ```

### Task 15: Translate batch 5 (keys 1161-1450)

- [ ] **Step 1:** `sed -n '1664,2232p' lib/l10n/app_en.arb`
- [ ] **Step 2:** Translate.
- [ ] **Step 3:** Extend `app_tg.arb`.
- [ ] **Step 4:** Re-verify JSON if applicable.
- [ ] **Step 5:** Commit:
  ```bash
  git add lib/l10n/app_tg.arb
  git commit -m "feat(tajik): translate batch 5 of app_tg.arb (keys 1161-1450)"
  ```

### Task 16: Translate batch 6 (keys 1451-1725) and final validation

- [ ] **Step 1:** `sed -n '2233,$p' lib/l10n/app_en.arb`
- [ ] **Step 2:** Translate.
- [ ] **Step 3:** Close out `app_tg.arb` (final `}`).

- [ ] **Step 4: Final JSON validation**

Run: `python3 -m json.tool lib/l10n/app_tg.arb > /dev/null && echo OK`
Expected: `OK`. If parse fails, the error message names the line; fix and re-validate.

- [ ] **Step 5: Final ICU placeholder integrity check**

```bash
diff <(grep -oE '\{[^}]*\}' lib/l10n/app_en.arb | sort -u) \
     <(grep -oE '\{[^}]*\}' lib/l10n/app_tg.arb | sort -u)
```
Expected: empty diff.

- [ ] **Step 6: Key-count parity check**

```bash
echo "EN: $(grep -cE '^  \"[a-zA-Z_]+\":' lib/l10n/app_en.arb), TG: $(grep -cE '^  \"[a-zA-Z_]+\":' lib/l10n/app_tg.arb)"
```
Expected: EN: 1725, TG: 1725.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/app_tg.arb
git commit -m "feat(tajik): translate batch 6 of app_tg.arb (keys 1451-1725) + final validation"
```

### Task 17: Regenerate localization Dart from completed ARB

- [ ] **Step 1: Run codegen**

Run: `flutter gen-l10n`
Expected: no errors. If gen-l10n complains about missing keys, it's because we omitted a key the template requires — fix the offending key in `app_tg.arb` first.

- [ ] **Step 2: Verify the generated file size matches peers**

Run: `ls -la lib/l10n/app_localizations_tg.dart`
Expected: file size is in the 130-175 KB range (matches Korean, Japanese, Russian peers). If it's still ~tiny (a few KB), gen-l10n failed silently — check stdout.

- [ ] **Step 3: Analyze**

Run: `flutter analyze --no-pub`
Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_localizations.dart lib/l10n/app_localizations_tg.dart
git commit -m "chore(tajik): regenerate AppLocalizations after full tg translation"
```

---

## Phase 6 — Translate backend notification template

### Task 18: Translate `backend/notification_templates/tg.json` values

**File:** `backend/notification_templates/tg.json` (was English clone from Task 10)

- [ ] **Step 1: Read both files side-by-side**

Run: `cat ../backend/notification_templates/en.json` then `cat ../backend/notification_templates/tg.json`

The file is ~54 lines. Each value will translate to one Cyrillic Tajik string.

- [ ] **Step 2: Translate every value**

Apply the same translation policy as the ARB. Preserve every `{{placeholder}}` or `{var}` substitution marker exactly.

- [ ] **Step 3: Validate JSON**

Run: `python3 -m json.tool ../backend/notification_templates/tg.json > /dev/null && echo OK`
Expected: `OK`.

- [ ] **Step 4: Placeholder integrity check**

```bash
diff <(grep -oE '\{\{[^}]*\}\}|\{[a-zA-Z_]+\}' ../backend/notification_templates/en.json | sort -u) \
     <(grep -oE '\{\{[^}]*\}\}|\{[a-zA-Z_]+\}' ../backend/notification_templates/tg.json | sort -u)
```
Expected: empty diff.

- [ ] **Step 5: Commit**

```bash
git add ../backend/notification_templates/tg.json
git commit -m "feat(tajik): translate backend notification template to Cyrillic Tajik"
```

---

## Phase 7 — Smoke test and PR

### Task 19: Manual smoke test on simulator

- [ ] **Step 1: Cold-build the app**

Run: `flutter pub get && flutter clean && flutter pub get`
(The double `pub get` is intentional after `clean` — see the [device_info_plus pub-cache patch](../../../../../.claude/projects/-Users-firdavsmutalipov-Projects-BananaTalk/memory/device_info_plus_patch.md) memory; if a LiveKit crash hits on launch, that patch may need reapplying.)

- [ ] **Step 2: Final analyze**

Run: `flutter analyze --no-pub`
Expected: exits 0.

- [ ] **Step 3: Run on simulator**

Run: `flutter run` (pick an iOS simulator or Android emulator).

- [ ] **Step 4: Switch language to Tajik in-app**

Navigate: Settings → Language. Verify:
- Тоҷикӣ appears in the picker list (with the 🇹🇯 flag if the picker renders flags)
- Selecting Тоҷикӣ flips the UI immediately
- The selected indicator shows on the Тоҷикӣ row

- [ ] **Step 5: Spot-check 6-8 screens**

Visit at minimum:
- Login / Sign-up flows (auth strings)
- Email verification screen (where the original bug lives — verify the error toast renders in Tajik now)
- Home tab
- Messages tab + open one conversation
- Moments tab + open one post + flag chip renders
- Profile tab
- Settings tab
- One notification list (in-app notifications)

For each: look for English text leaking through (would indicate a missed key) or Cyrillic that looks broken (truncated, weird placeholder rendering).

- [ ] **Step 6: Trigger a push notification**

From a second account (or via backend admin), send a chat message to the test account. Verify the push body renders in Cyrillic Tajik (not English fallback).

- [ ] **Step 7: Document findings**

For any issue found:
- If it's a code/wiring bug (e.g., a screen still shows English because it bypasses `AppLocalizations`): fix it now in this PR.
- If it's translation quality (awkward phrasing, wrong register): note it but don't block the PR. Capture in a follow-up TODO.

### Task 20: Open the PR

- [ ] **Step 1: Confirm clean working tree**

Run: `git status`
Expected: clean tree (all Tajik work committed). The unrelated dirty files from before this work should still be there; they are NOT part of this PR — make sure none of them got accidentally staged in any of the commits above.

- [ ] **Step 2: Push the branch**

If on `main`, the user may want to first move the Tajik commits to a feature branch:

```bash
# (Optional — only if user prefers a branch over committing directly to main)
git checkout -b feat/tajik-locale
git push -u origin feat/tajik-locale
```

If committing directly to `main` is the established workflow, push as is:

```bash
git push
```

- [ ] **Step 3: Open the PR**

```bash
gh pr create --title "feat(tajik): full Cyrillic Tajik (tg-TJ) locale support" --body "$(cat <<'EOF'
## Summary
- Adds full Cyrillic Tajik translation of all ~1725 ARB keys in `lib/l10n/app_tg.arb`
- Adds Locale('tg', 'TJ') to MaterialApp supportedLocales + LanguageService + language_flags
- Adds Tajik to content-language pickers in moments filter/create/single/card and vocabulary add
- Adds backend notification template at `backend/notification_templates/tg.json`
- Tracks closure of the user-reported gap from nozil (+992) who selected Persian as a workaround
- Translation is AI-drafted per explicit user decision overriding the original brief's MT warning. Follow-up: native-speaker review pass.

## Test plan
- [ ] `flutter analyze` clean
- [ ] `flutter gen-l10n` produces a tg dart file ~130-175 KB
- [ ] App launches, Тоҷикӣ appears in Settings → Language picker with 🇹🇯 flag
- [ ] Switching to Тоҷикӣ flips the UI immediately; spot-check across Login, Email verification, Home, Messages, Moments, Profile, Settings, Notifications
- [ ] A push notification arrives in Cyrillic Tajik

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR URL printed. Send the URL back to the user.

---

## Self-review summary

This plan covers every section of the spec:
- App-UI plumbing (Tasks 1–4) — MaterialApp, LanguageService, language_flags, generated dart
- Content-language touchpoints (Tasks 5–9) — moments filter/create/single/card, vocabulary add
- Backend notification template (Tasks 10, 18) — clone then translate
- Full ARB translation (Tasks 11–16) — 6 batches with explicit line ranges, ICU integrity checks, key-count parity
- Codegen (Tasks 1, 17) — runs after stub and after full translation
- Testing (Task 19) — 6 manual checks plus push-notification verification
- PR (Task 20) — branch, push, gh pr create

All tasks reference exact file paths. Commit messages are pre-written. Validation commands have expected outputs. The translation batches are the only step that doesn't pre-show the resulting code — that's unavoidable for a 1725-key bulk translation, but each batch is bounded by line range and gated by ICU placeholder integrity + JSON validity checks.
