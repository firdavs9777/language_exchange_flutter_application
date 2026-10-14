# AI Study Hub + Floating Tab Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace AI Study's three sub-tabs with one compact scroll (today's pack, recommended, a 12-tile feature grid with quota/VIP/NEW badges, progress card) behind a remote flag, and redesign the floating tab bar (active capsule with name, hide on scroll, shared bottom clearance, coffee button removed).

**Architecture:** Pure logic (`badgeFor`, `newBadgeFeatures`, `featureCoverage`, `pickRecommended`, `BarScrollState`) lives in plain Dart files with unit tests; widgets only read providers and call those functions. `LearningMain` keeps its celebration listeners and switches between the new `StudyHub` and the untouched old screen (`LegacyStudyHub`) on `AppConfig.studyHubEnabled`. The tab bar is extracted from `TabBarMenu.dart` into `widgets/navigation/floating_tab_bar.dart`.

**Tech Stack:** Flutter 3 / Dart ≥3.10, Riverpod 2 (`StateProvider`, `FutureProvider`), SharedPreferences, `flutter gen-l10n` (19 ARBs in `lib/l10n`, template `app_en.arb`), Node/Express backend with `node:test`.

**Spec:** `docs/superpowers/specs/2026-10-13-ai-study-hub-and-tab-bar-design.md` (approved by owner 2026-10-14 as written).

## Global Constraints

- Branch `feat/ai-study-hub` (app). Backend work on a branch `feat/study-hub-config` in `/Users/davis/Desktop/Personal/language_exchange_backend_application`.
- Imports are always `package:bananatalk_app/...` — never relative `../` paths (linter enforces).
- **No** `Co-Authored-By` / Claude attribution lines in any commit (owner rule; overrides the harness default).
- Every commit updates `docs/REMAINING_WORK.md` (tick finished items, add new ones) and lists what is still open in the commit body. Backend commits update the backend's `docs/REMAINING_WORK.md` the same way.
- App-config flag `studyHubEnabled` default **false**; `studyVipOnlyFeatures` default **empty**. Old apps ignore both. Deploy backend before the app.
- Spacing constants (exact): page margin 12 · tile gap 8 · group gap 16 · group label → tiles 8 · tile height 64 · today row 72 · recommended 48 · carousel card 84 · card radius 16 · tile radius 14 · tile icon square 36.
- Typography: in the new hub files no `fontSize:` literal; use `Theme.of(context).textTheme`. Minimum rendered size 12.
- Group colours: Talk `#6D3FE0` on `#EFE9FE`; Practice `#00786A` on `#DDF5EF`; Prepare `#A85E00` on `#FEF0D9`. Dark tile surface `#1E1E24`; dark fills = group colour at 18 % alpha, icon colour lightened.
- Badge precedence (first wins): Locked → Exhausted → Low → Due → New → none. At most **3** NEW badges at once (first unseen tiles in grid order).
- Tab bar: height 56, item height 44, inactive item 48 wide icon-only, active capsule = icon + name, fill = tab colour at 14 % (dark 20 %), animate 220 ms `easeOutCubic`; hide/show slide 200 ms; hide after 24 px of downward scroll.
- Analytics event names (exact): `study_tile_tap {feature, badge}`, `study_upgrade_sheet_shown {feature, reason}`, `study_upgrade_unlock {feature, method}`, `study_spotlight_tap {id}`, `study_recommended_tap {area}`.
- Every new user-facing string is an ARB key present in all 19 locales (machine-drafted, appended to `docs/l10n/native-qa-strings-2026-10.csv` for native review).
- Run tests from `bananatalk_app/`: `flutter test <path>`. `flutter analyze` must stay clean for touched files.

## Review Focus

1. **Text scale 1.3 on a 320-wide phone** — tiles must not overflow; titles/descriptions ellipsize, tile grows (min-height 64, not fixed). Pinned by a widget test in Task 5 (`textScaler: TextScaler.linear(1.3)`, `Size(320, 640)`).
2. **Quota provider still loading or errored** — `tutorQuotaProvider` returns `TutorQuotaState.empty`; tiles must show no quota badge and tap must navigate (not open the sheet). Pinned in Task 3 (`badgeFor` with `quota: null`) and Task 5 (tap with empty quota navigates).
3. **SharedPreferences unreadable** — `FeatureSeenStore.readSeen` must fail closed (everything seen → zero NEW badges), never throw. Pinned in Task 3.
4. **Bar hidden, then user switches tabs or opens the keyboard and closes it** — bar must come back on tab switch and when the keyboard closes; a hidden bar must never strand the user. Pinned in Task 8 (`BarScrollState.reset()` on tab select + keyboard test).
5. **Malformed `studyVipOnlyFeatures` from the server** (non-list, mixed types, unknown slugs) — parsed to a `Set<String>` of strings only; unknown slugs ignored; nothing crashes. Pinned in Task 2.

---

## File map

New (app):
- `lib/pages/learning/main/study_hub_metrics.dart` — spacing constants.
- `lib/pages/learning/main/sections/study_features.dart` — `StudyGroup`, `StudyFeature`, `studyFeatureGroups`, `TileBadge`, `badgeFor`, `newBadgeFeatures`, `FeatureCoverage`, `featureCoverage`, `pickRecommended`.
- `lib/services/feature_seen_store.dart` — NEW-badge persistence + `featureSeenProvider`.
- `lib/pages/learning/main/sections/study_feature_tile.dart` — one tile.
- `lib/pages/learning/main/sections/study_feature_groups.dart` — the three labelled 2×2 groups + tap routing.
- `lib/widgets/study/study_upgrade_sheet.dart` — locked/exhausted sheet.
- `lib/pages/learning/main/sections/today_pack_row.dart`, `recommended_tile.dart`, `spotlight_carousel.dart`, `progress_card.dart`.
- `lib/pages/learning/main/study_hub.dart` — the hub screen.
- `lib/pages/learning/main/legacy_study_hub.dart` — today's `LearningMain` body, moved verbatim.
- `lib/pages/learning/exam_study/exam_study_screen.dart` — Scaffold wrapper around `ExamStudyTab`.
- `lib/widgets/navigation/floating_tab_bar.dart` — bar, `BarScrollState`, `FloatingTabBar.clearance`, `tabReselectProvider`.
- `lib/pages/profile/support/support_sheet.dart` — moved `_SupportSheet`.

Changed (app): `lib/models/app_config.dart`, `lib/pages/learning/main/learning_main_screen.dart`, `lib/pages/menu_tab/TabBarMenu.dart`, `lib/services/analytics_service.dart`, `lib/services/session_reset.dart`, `lib/providers/tutor_provider.dart`, `lib/pages/profile/drawer/profile_drawer.dart`, tab pages' bottom padding (list in Task 9), 19 ARBs, `test/guides/every_tab_has_a_guide_test.dart`.

Backend: `config/limitations.js`, `controllers/appConfig.js`, new `test/studyHubConfig.test.js`.

---

### Task 1: Backend — `studyHubEnabled` + `studyVipOnlyFeatures` in app-config

**Files (backend repo `/Users/davis/Desktop/Personal/language_exchange_backend_application`):**
- Modify: `config/limitations.js` (next to `MATCHES_LAYOUT_ENABLED`, line ~61, and the export list ~line 133)
- Modify: `controllers/appConfig.js` (import line 2–4; payload near line 140)
- Create: `test/studyHubConfig.test.js`

**Interfaces:**
- Produces: `GET /api/app-config` → `data.studyHubEnabled: boolean` (env `STUDY_HUB_ENABLED`, default false), `data.studyVipOnlyFeatures: string[]` (env `STUDY_VIP_ONLY_FEATURES`, comma-separated slugs, default `[]`). Valid slugs: `tutor roleplay story photo speak review writing quizzes exam lessons challenges leaderboard`.

- [ ] **Step 1: Branch**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
git checkout main && git pull && git checkout -b feat/study-hub-config
```

- [ ] **Step 2: Write the failing test** — `test/studyHubConfig.test.js`

```js
const { test } = require('node:test');
const assert = require('node:assert/strict');

// STUDY_HUB_ENABLED / STUDY_VIP_ONLY_FEATURES — AI Study hub rollout
// (app spec 2026-10-13 §10). Both ship dark: hub off, nothing VIP-only.

async function withEnv(vars, fn) {
  const saved = {};
  for (const k of Object.keys(vars)) saved[k] = process.env[k];
  try {
    for (const [k, v] of Object.entries(vars)) {
      if (v === undefined) delete process.env[k];
      else process.env[k] = v;
    }
    delete require.cache[require.resolve('../config/limitations')];
    delete require.cache[require.resolve('../controllers/appConfig')];
    return await fn();
  } finally {
    for (const [k, v] of Object.entries(saved)) {
      if (v === undefined) delete process.env[k];
      else process.env[k] = v;
    }
    delete require.cache[require.resolve('../config/limitations')];
    delete require.cache[require.resolve('../controllers/appConfig')];
  }
}

function mockRes() {
  return {
    statusCode: null,
    body: null,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };
}

async function config() {
  const { getAppConfig } = require('../controllers/appConfig');
  const res = mockRes();
  await getAppConfig({ query: {} }, res, () => {});
  return res.body.data;
}

test('defaults: hub off, no VIP-only features', async () => {
  await withEnv({ STUDY_HUB_ENABLED: undefined, STUDY_VIP_ONLY_FEATURES: undefined }, async () => {
    const data = await config();
    assert.equal(data.studyHubEnabled, false);
    assert.deepEqual(data.studyVipOnlyFeatures, []);
  });
});

test('STUDY_HUB_ENABLED=true turns the hub on', async () => {
  await withEnv({ STUDY_HUB_ENABLED: 'true' }, async () => {
    assert.equal((await config()).studyHubEnabled, true);
  });
});

test('STUDY_VIP_ONLY_FEATURES keeps known slugs only, trimmed, deduped', async () => {
  await withEnv({ STUDY_VIP_ONLY_FEATURES: ' photo, story ,bogus,photo,' }, async () => {
    assert.deepEqual((await config()).studyVipOnlyFeatures, ['photo', 'story']);
  });
});
```

- [ ] **Step 3: Run it to verify it fails**

Run: `node --test test/studyHubConfig.test.js`
Expected: FAIL — `data.studyHubEnabled` is `undefined`.

- [ ] **Step 4: Implement** — in `config/limitations.js` after `MATCHES_LAYOUT_ENABLED`:

```js
// AI Study one-scroll hub (app spec 2026-10-13 §10). Off by default: the app
// keeps its three sub-tabs until this is turned on.
const STUDY_HUB_ENABLED = String(process.env.STUDY_HUB_ENABLED || 'false').toLowerCase() === 'true';

// Study features shown with a VIP lock to non-VIP users (spec §4.4). Empty by
// default: nothing is newly locked at launch. Unknown slugs are dropped so a
// typo cannot reach the app.
const STUDY_FEATURE_SLUGS = ['tutor', 'roleplay', 'story', 'photo', 'speak', 'review',
  'writing', 'quizzes', 'exam', 'lessons', 'challenges', 'leaderboard'];
const STUDY_VIP_ONLY_FEATURES = [...new Set(
  String(process.env.STUDY_VIP_ONLY_FEATURES || '')
    .split(',')
    .map((s) => s.trim())
    .filter((s) => STUDY_FEATURE_SLUGS.includes(s)),
)];
```

Add `STUDY_HUB_ENABLED, STUDY_VIP_ONLY_FEATURES,` to `module.exports`. In `controllers/appConfig.js` add both names to the `require('../config/limitations')` destructure and to the payload after `matchesLayoutEnabled`:

```js
      studyHubEnabled: STUDY_HUB_ENABLED,
      studyVipOnlyFeatures: STUDY_VIP_ONLY_FEATURES,
```

- [ ] **Step 5: Run tests**

Run: `node --test test/studyHubConfig.test.js test/matchesLayoutKillSwitch.test.js test/appConfigAnnouncements.test.js`
Expected: all PASS. (Do not use `npm test` — it dies under Node 25; run files individually.)

- [ ] **Step 6: Update backend `docs/REMAINING_WORK.md`** — add to the flag table: `STUDY_HUB_ENABLED` (default false, app 2.8.0+), `STUDY_VIP_ONLY_FEATURES` (default empty). Add open item "Deploy study-hub config before app 2.8.0".

- [ ] **Step 7: Commit (no co-author line)**

```bash
git add config/limitations.js controllers/appConfig.js test/studyHubConfig.test.js docs/REMAINING_WORK.md
git commit -m "feat(app-config): studyHubEnabled + studyVipOnlyFeatures (both dark)

Open: deploy before app 2.8.0; flip STUDY_HUB_ENABLED after the app release."
```

Merging to backend `main` and deploying is an owner gate (they push with their short command) — do not push/deploy.

---

### Task 2: App — `AppConfig` fields, spacing constants, all new strings

**Files:**
- Modify: `lib/models/app_config.dart`
- Create: `lib/pages/learning/main/study_hub_metrics.dart`
- Modify: `lib/l10n/app_*.arb` (19 files), regenerate with `flutter gen-l10n`
- Create: `test/models/app_config_study_hub_test.dart`
- Create: `test/l10n/study_hub_strings_test.dart`
- Modify: `docs/l10n/native-qa-strings-2026-10.csv`

**Interfaces:**
- Produces: `AppConfig.studyHubEnabled` (`bool`, default false), `AppConfig.studyVipOnlyFeatures` (`Set<String>`, default `{}`); class `StudyHubMetrics` with static doubles listed below; the l10n keys listed in Step 5 (all later tasks use these exact names).

- [ ] **Step 1: Write the failing model test** — `test/models/app_config_study_hub_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/app_config.dart';

void main() {
  AppConfig parse(Map<String, dynamic> extra) =>
      AppConfig.fromJson({'minVersion': '1.0.0', ...extra});

  test('older server: hub off, nothing VIP-only', () {
    final c = parse({});
    expect(c.studyHubEnabled, isFalse);
    expect(c.studyVipOnlyFeatures, isEmpty);
  });

  test('reads both fields', () {
    final c = parse({
      'studyHubEnabled': true,
      'studyVipOnlyFeatures': ['photo', 'story'],
    });
    expect(c.studyHubEnabled, isTrue);
    expect(c.studyVipOnlyFeatures, {'photo', 'story'});
  });

  test('malformed list never crashes and keeps strings only', () {
    expect(parse({'studyVipOnlyFeatures': 'photo'}).studyVipOnlyFeatures, isEmpty);
    expect(parse({'studyVipOnlyFeatures': ['photo', 3, null, true]}).studyVipOnlyFeatures,
        {'photo'});
    expect(parse({'studyHubEnabled': 'yes'}).studyHubEnabled, isFalse);
  });
}
```

- [ ] **Step 2: Run it** — `flutter test test/models/app_config_study_hub_test.dart` → FAIL (getter not defined).

- [ ] **Step 3: Implement in `lib/models/app_config.dart`** — add fields after `waveCapEnabled`:

```dart
  /// AI Study one-scroll hub (spec 2026-10-13 §10). Off by default: an older
  /// server keeps the three sub-tabs.
  final bool studyHubEnabled;

  /// `StudyFeature.slug`s shown locked to non-VIP users (spec §4.4). Empty by
  /// default — nothing is newly locked at launch.
  final Set<String> studyVipOnlyFeatures;
```

Constructor: `this.studyHubEnabled = false, this.studyVipOnlyFeatures = const {},`. In `fromJson`:

```dart
      // `== true`, not `as bool?`: a malformed value must read as off, not throw.
      studyHubEnabled: json['studyHubEnabled'] == true,
      studyVipOnlyFeatures: json['studyVipOnlyFeatures'] is List
          ? (json['studyVipOnlyFeatures'] as List).whereType<String>().toSet()
          : const <String>{},
```

- [ ] **Step 4: Create `lib/pages/learning/main/study_hub_metrics.dart`**

```dart
/// AI Study hub spacing (spec 2026-10-13 §3.1). Compact on purpose — the owner
/// asked that no space be wasted. Use these, never literals, in hub files.
class StudyHubMetrics {
  StudyHubMetrics._();

  static const double pageMargin = 12;
  static const double tileGap = 8;
  static const double groupGap = 16;
  static const double groupLabelGap = 8;
  static const double tileHeight = 64;
  static const double todayRowHeight = 72;
  static const double recommendedHeight = 48;
  static const double carouselCardHeight = 84;
  static const double cardRadius = 16;
  static const double tileRadius = 14;
  static const double tileIconSize = 36;
}
```

- [ ] **Step 5: Add strings to `lib/l10n/app_en.arb`** (with `@` metadata for placeholders):

```json
  "studyGroupTalk": "Talk",
  "studyGroupPractice": "Practice",
  "studyGroupPrepare": "Prepare & compete",
  "studyTileTutor": "AI Tutor",
  "studyTileTutorDesc": "Chat about anything",
  "studyTileRoleplay": "Roleplay",
  "studyTileRoleplayDesc": "Real-life scenes",
  "studyTileStory": "Story",
  "studyTileStoryDesc": "Write a story together",
  "studyTilePhoto": "Photo",
  "studyTilePhotoDesc": "Learn words from a photo",
  "studyTileSpeak": "Speak",
  "studyTileSpeakDesc": "Pronunciation check",
  "studyTileReview": "Review",
  "studyTileReviewDesc": "Words due today",
  "studyTileWriting": "Writing",
  "studyTileWritingDesc": "Grammar feedback",
  "studyTileQuizzes": "Quizzes",
  "studyTileQuizzesDesc": "Quick AI quizzes",
  "studyTileExam": "Exam prep",
  "studyTileExamDesc": "TOPIK, JLPT, IELTS…",
  "studyTileLessons": "Lessons",
  "studyTileLessonsDesc": "Step-by-step units",
  "studyTileChallenges": "Challenges",
  "studyTileChallengesDesc": "Daily goals for XP",
  "studyTileLeaderboard": "Leaderboard",
  "studyTileLeaderboardDesc": "See this week's ranks",
  "studyBadgeVip": "VIP",
  "studyBadgeLeft": "{count} left",
  "@studyBadgeLeft": {"placeholders": {"count": {"type": "int"}}},
  "studyBadgeDue": "{count} due",
  "@studyBadgeDue": {"placeholders": {"count": {"type": "int"}}},
  "studyBadgeNew": "NEW",
  "studyEnglishOnly": "English only for now",
  "studyTodayPack": "Today's pack",
  "studyTodayStart": "Start",
  "studyRecommended": "For you: {name} — {percent}% right · 5-min quiz",
  "@studyRecommended": {"placeholders": {"name": {"type": "String"}, "percent": {"type": "int"}}},
  "studyProgressTitle": "Your progress",
  "studyFullReport": "Full report",
  "studyStreakDays": "{count} day streak",
  "@studyStreakDays": {"placeholders": {"count": {"type": "int"}}},
  "studyLevelShort": "Lv {level}",
  "@studyLevelShort": {"placeholders": {"level": {"type": "int"}}},
  "studyUpgradeLockedTitle": "{feature} is a VIP feature",
  "@studyUpgradeLockedTitle": {"placeholders": {"feature": {"type": "String"}}},
  "studyUpgradeExhaustedTitle": "You've used today's {feature}",
  "@studyUpgradeExhaustedTitle": {"placeholders": {"feature": {"type": "String"}}},
  "studyUpgradeBenefitUnlimited": "Unlimited AI practice every day",
  "studyUpgradeBenefitNoAds": "No ads anywhere in the app",
  "studyUpgradeGetVip": "Get VIP — unlimited",
  "guideStudyHubTitle": "Your daily language gym",
  "guideStudyHubBody": "A 5-minute pack every day, plus an AI tutor whenever you want to talk.",
  "guideStudyHubCta": "Start today's pack",
  "guideStudyHubSecondary": "See all features",
  "supportBananaTalkRow": "Support BananaTalk",
  "supportBananaTalkRowSubtitle": "Help a solo developer keep building"
```

Reused existing keys (verified present 2026-10-14; do not duplicate): `notNow`, `study`, `community`, `chats`, `moments`, `profile`, `streak`, `review`, `achievements`, `vocabulary`, `todayPickLanguage`, `packTakePlacement`, `packDoneForToday`, `examStudy`. There is no `level` key — the progress card uses `studyLevelShort`.

- [ ] **Step 6: Translate into the 18 other ARBs** (`ar de es fr hi id it ja ko pt ru tg th tl tr vi zh zh_TW`). Natural, short UI copy; keep `{placeholders}` intact; keep "VIP" and "TOPIK, JLPT, IELTS…" untranslated. Append one CSV row per key × locale to `docs/l10n/native-qa-strings-2026-10.csv` using that file's existing column order (check the header with `head -1`).

- [ ] **Step 7: Write `test/l10n/study_hub_strings_test.dart`**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every AI Study hub string exists in every locale (same reason as
/// guide_strings_test.dart: a missing key ships silent English).
void main() {
  test('every locale defines every study* / supportBananaTalk* key', () {
    final template = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final keys = template.keys
        .where((k) => !k.startsWith('@') &&
            (k.startsWith('studyTile') || k.startsWith('studyGroup') ||
             k.startsWith('studyBadge') || k.startsWith('studyUpgrade') ||
             k.startsWith('studyToday') || k.startsWith('studyProgress') ||
             k.startsWith('supportBananaTalk') ||
             const {'studyEnglishOnly', 'studyRecommended', 'studyFullReport',
                    'studyStreakDays', 'studyLevelShort'}.contains(k)))
        .toList();
    expect(keys.length, greaterThanOrEqualTo(45));
    final arbs = Directory('lib/l10n').listSync().whereType<File>()
        .where((f) => f.path.endsWith('.arb')).toList();
    expect(arbs.length, 19);
    for (final f in arbs) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final k in keys) {
        expect(m[k], isA<String>(), reason: '${f.path} is missing $k');
        expect((m[k] as String).trim(), isNotEmpty, reason: '${f.path} $k is empty');
      }
    }
  });
}
```

(`guideStudyHub*` keys are already covered by `guide_strings_test.dart`, which discovers every `guide*` key.)

- [ ] **Step 8: Generate and run**

Run: `flutter gen-l10n && flutter test test/models/app_config_study_hub_test.dart test/l10n/`
Expected: PASS (incl. `arb_integrity_test`, `guide_strings_test`).

- [ ] **Step 9: Commit** — update `docs/REMAINING_WORK.md` (AI Study section: tick "owner reviews the spec", "write the plan"; add "native review of the study hub strings" under Owner step 10's CSV note).

```bash
git add lib/models/app_config.dart lib/pages/learning/main/study_hub_metrics.dart lib/l10n test/models/app_config_study_hub_test.dart test/l10n/study_hub_strings_test.dart docs/l10n/native-qa-strings-2026-10.csv docs/REMAINING_WORK.md
git commit -m "feat(study-hub): app-config fields, spacing constants, hub strings (19 locales)

Open: hub UI (tasks 3-7), tab bar (8-9), backend deploy, native review."
```

---

### Task 3: Feature catalogue, badge logic, NEW store, coverage, recommended pick

**Files:**
- Create: `lib/pages/learning/main/sections/study_features.dart`
- Create: `lib/services/feature_seen_store.dart`
- Modify: `lib/services/session_reset.dart` (add `featureSeenProvider` to the per-account provider map, next to `guideStateProvider`)
- Create: `test/learning/study_features_test.dart`, `test/services/feature_seen_store_test.dart`
- Modify: `docs/superpowers/specs/2026-10-13-ai-study-hub-and-tab-bar-design.md` §4.6 (coverage table)

**Interfaces:**
- Consumes: `TutorQuotaInfo` (`lib/providers/tutor_quota_provider.dart`: `remaining`, `unlimited`, `shouldShowIndicator`), `WeakArea` from `lib/models/ai/ai_quiz_model.dart` (`name`, `accuracy` 0..1, `attempts`).
- Produces:
  - `enum StudyGroup { talk, practice, prepare }`
  - `enum StudyFeature` with `slug`, `group`, `quotaKey` (String?) — values `tutor roleplay story photo speak review writing quizzes exam lessons challenges leaderboard`
  - `const Map<StudyGroup, List<StudyFeature>> studyFeatureGroups`; `List<StudyFeature> get studyFeatureOrder`
  - `enum TileBadgeKind { locked, exhausted, low, due, isNew }`; `class TileBadge { kind, count }` with `String get analyticsName`
  - `TileBadge? badgeFor(StudyFeature f, {required bool isVip, required Set<String> vipOnly, TutorQuotaInfo? quota, int dueCount = 0, bool isNew = false})`
  - `Set<StudyFeature> newBadgeFeatures(Set<String> seenSlugs, {int max = 3})`
  - `enum FeatureCoverage { supported, englishOnly, unknown }`; `FeatureCoverage featureCoverage(StudyFeature f, String? targetLanguage, {List<ExamLanguage>? examLanguages})`
  - `WeakArea? pickRecommended(List<WeakArea> areas)`
  - `class FeatureSeenStore { static String keyFor(String slug); static Future<Set<String>> readSeen(); static Future<void> markSeen(String slug); }`; `final featureSeenProvider = FutureProvider<Set<String>>`

- [ ] **Step 1: Verify language coverage against the backend** (the spec's "plan's first task" for §4.6). For each feature, find the backend route and check whether it restricts languages:

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
grep -rn "SUPPORTED_LANG\|supportedLanguages\|allowedLanguages\|=== 'en'\|english" controllers/tutor* controllers/pronunciation* controllers/grammar* controllers/quiz* controllers/lesson* controllers/aiQuiz* services/ 2>/dev/null | head -40
```

Record per feature: `all` / list of codes / `en only` / `unknown`, in the spec §4.6 as a table. Then encode only **hard restrictions you found in code** in `_staticLanguageSupport` below (`{'en'}` for English-only; omit the feature when unrestricted or unclear → `unknown`). Exam coverage is dynamic (from `examLanguagesProvider`).

- [ ] **Step 2: Write failing tests** — `test/learning/study_features_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';

TutorQuotaInfo q({int used = 0, int? cap = 10, bool unlimited = false}) => TutorQuotaInfo(
      used: used,
      cap: unlimited ? null : cap,
      remaining: unlimited ? null : (cap! - used),
      resetAt: null,
      unlimited: unlimited,
    );

WeakArea area(String name, double acc, int attempts) => WeakArea(
    name: name, category: 'grammar', accuracy: acc, attempts: attempts, recommendation: '');

void main() {
  group('catalogue', () {
    test('12 unique tiles in spec order', () {
      expect(studyFeatureOrder, [
        StudyFeature.tutor, StudyFeature.roleplay, StudyFeature.story, StudyFeature.photo,
        StudyFeature.speak, StudyFeature.review, StudyFeature.writing, StudyFeature.quizzes,
        StudyFeature.exam, StudyFeature.lessons, StudyFeature.challenges, StudyFeature.leaderboard,
      ]);
      expect(studyFeatureOrder.toSet().length, StudyFeature.values.length);
    });
    test('each tile sits in its own group', () {
      for (final e in studyFeatureGroups.entries) {
        for (final f in e.value) {
          expect(f.group, e.key);
        }
      }
    });
    test('quota keys match tutorQuotaProvider keys', () {
      expect(StudyFeature.tutor.quotaKey, 'chat');
      expect(StudyFeature.speak.quotaKey, 'pronunciation');
      expect(StudyFeature.review.quotaKey, isNull);
    });
  });

  group('badgeFor', () {
    TileBadge? b(StudyFeature f,
            {bool vip = false, Set<String> lock = const {}, TutorQuotaInfo? quota,
             int due = 0, bool isNew = false}) =>
        badgeFor(f, isVip: vip, vipOnly: lock, quota: quota, dueCount: due, isNew: isNew);

    test('locked', () => expect(b(StudyFeature.photo, lock: {'photo'})?.kind, TileBadgeKind.locked));
    test('VIP never sees locked', () => expect(b(StudyFeature.photo, vip: true, lock: {'photo'}), isNull));
    test('exhausted', () {
      final r = b(StudyFeature.tutor, quota: q(used: 10));
      expect(r?.kind, TileBadgeKind.exhausted);
      expect(r?.count, 0);
    });
    test('low at >= 50 %', () {
      final r = b(StudyFeature.tutor, quota: q(used: 5));
      expect(r?.kind, TileBadgeKind.low);
      expect(r?.count, 5);
    });
    test('below 50 % shows nothing', () => expect(b(StudyFeature.tutor, quota: q(used: 4)), isNull));
    test('unlimited shows nothing', () => expect(b(StudyFeature.tutor, quota: q(unlimited: true)), isNull));
    test('quota not loaded shows nothing', () => expect(b(StudyFeature.tutor), isNull));
    test('due only on review', () {
      expect(b(StudyFeature.review, due: 7)?.kind, TileBadgeKind.due);
      expect(b(StudyFeature.review, due: 7)?.count, 7);
      expect(b(StudyFeature.lessons, due: 7), isNull);
    });
    test('new', () => expect(b(StudyFeature.lessons, isNew: true)?.kind, TileBadgeKind.isNew));
    test('precedence: locked > exhausted', () =>
        expect(b(StudyFeature.photo, lock: {'photo'}, quota: q(used: 10))?.kind, TileBadgeKind.locked));
    test('precedence: exhausted > low (exhausted also passes the 50 % test)', () =>
        expect(b(StudyFeature.tutor, quota: q(used: 10))?.kind, TileBadgeKind.exhausted));
    test('precedence: low > new', () =>
        expect(b(StudyFeature.tutor, quota: q(used: 6), isNew: true)?.kind, TileBadgeKind.low));
    test('precedence: due > new', () =>
        expect(b(StudyFeature.review, due: 1, isNew: true)?.kind, TileBadgeKind.due));
  });

  group('newBadgeFeatures', () {
    test('at most 3, first unseen in grid order', () {
      expect(newBadgeFeatures({}), {StudyFeature.tutor, StudyFeature.roleplay, StudyFeature.story});
    });
    test('skips seen tiles', () {
      expect(newBadgeFeatures({'tutor', 'story'}),
          {StudyFeature.roleplay, StudyFeature.photo, StudyFeature.speak});
    });
    test('all seen -> none', () {
      expect(newBadgeFeatures(StudyFeature.values.map((f) => f.slug).toSet()), isEmpty);
    });
  });

  group('featureCoverage', () {
    final langs = [
      const ExamLanguage(id: '1', name: 'Korean', code: 'ko', active: true),
    ];
    test('exam: supported when the target is an exam language (name or code)', () {
      expect(featureCoverage(StudyFeature.exam, 'Korean', examLanguages: langs), FeatureCoverage.supported);
      expect(featureCoverage(StudyFeature.exam, 'ko', examLanguages: langs), FeatureCoverage.supported);
    });
    test('exam: unknown when the list is not loaded', () {
      expect(featureCoverage(StudyFeature.exam, 'Korean'), FeatureCoverage.unknown);
    });
    test('no target language -> unknown', () {
      expect(featureCoverage(StudyFeature.tutor, null), FeatureCoverage.unknown);
      expect(featureCoverage(StudyFeature.tutor, ''), FeatureCoverage.unknown);
    });
  });

  group('pickRecommended', () {
    test('lowest accuracy with >= 3 attempts', () {
      final r = pickRecommended([area('a', 0.4, 2), area('b', 0.6, 5), area('c', 0.5, 3)]);
      expect(r?.name, 'c');
    });
    test('none qualifies -> null', () => expect(pickRecommended([area('a', 0.1, 2)]), isNull));
    test('empty -> null', () => expect(pickRecommended([]), isNull));
  });
}
```

Check `ExamLanguage`'s constructor in `lib/providers/provider_models/exam/exam_language.dart` and adjust the literal to its real required params (fields: `id`, `name`, `code`, `icon?`, `active`). If it has no `const` constructor, drop `const`.

`test/services/feature_seen_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/feature_seen_store.dart';

void main() {
  test('reads empty, then marks and reads back', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await FeatureSeenStore.readSeen(), isEmpty);
    await FeatureSeenStore.markSeen('tutor');
    expect(await FeatureSeenStore.readSeen(), {'tutor'});
  });

  test('wrong-typed value reads as unseen, never throws', () async {
    SharedPreferences.setMockInitialValues({'study_feature_seen_tutor': 'yes'});
    expect(await FeatureSeenStore.readSeen(), isEmpty);
  });

  test('keys are user-scoped (cleared on logout)', () {
    // session_prefs keeps only an allow-list of device-level keys.
    expect(FeatureSeenStore.keyFor('tutor'), 'study_feature_seen_tutor');
  });
}
```

Also add a test that the store fails closed when `SharedPreferences.getInstance` throws: since the mock cannot throw, cover it by making `readSeen` accept an optional `Future<SharedPreferences> Function()? prefs` seam:

```dart
  test('unreadable storage -> everything seen (no NEW badges)', () async {
    final seen = await FeatureSeenStore.readSeen(prefs: () async => throw Exception('io'));
    expect(seen.length, 12);
  });
```

- [ ] **Step 3: Run** — `flutter test test/learning/study_features_test.dart test/services/feature_seen_store_test.dart` → FAIL (files missing).

- [ ] **Step 4: Implement `lib/pages/learning/main/sections/study_features.dart`**

```dart
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';

/// The three Explore groups (spec 2026-10-13 §4.1).
enum StudyGroup { talk, practice, prepare }

/// Every AI Study feature with a tile. [slug] is the analytics id AND the
/// value the server uses in `studyVipOnlyFeatures` — append-only.
enum StudyFeature {
  tutor('tutor', StudyGroup.talk, quotaKey: 'chat'),
  roleplay('roleplay', StudyGroup.talk, quotaKey: 'roleplay'),
  story('story', StudyGroup.talk, quotaKey: 'story'),
  photo('photo', StudyGroup.talk, quotaKey: 'photo'),
  speak('speak', StudyGroup.practice, quotaKey: 'pronunciation'),
  review('review', StudyGroup.practice),
  writing('writing', StudyGroup.practice),
  quizzes('quizzes', StudyGroup.practice),
  exam('exam', StudyGroup.prepare),
  lessons('lessons', StudyGroup.prepare),
  challenges('challenges', StudyGroup.prepare),
  leaderboard('leaderboard', StudyGroup.prepare);

  const StudyFeature(this.slug, this.group, {this.quotaKey});

  final String slug;
  final StudyGroup group;

  /// Key in `tutorQuotaProvider`, or null for features without a daily cap.
  final String? quotaKey;
}

/// Grid order. Replaces `practice_entries.dart` once the hub flag has been
/// on for a release.
const Map<StudyGroup, List<StudyFeature>> studyFeatureGroups = {
  StudyGroup.talk: [StudyFeature.tutor, StudyFeature.roleplay, StudyFeature.story, StudyFeature.photo],
  StudyGroup.practice: [StudyFeature.speak, StudyFeature.review, StudyFeature.writing, StudyFeature.quizzes],
  StudyGroup.prepare: [StudyFeature.exam, StudyFeature.lessons, StudyFeature.challenges, StudyFeature.leaderboard],
};

List<StudyFeature> get studyFeatureOrder =>
    [for (final g in StudyGroup.values) ...studyFeatureGroups[g]!];

enum TileBadgeKind { locked, exhausted, low, due, isNew }

class TileBadge {
  const TileBadge(this.kind, [this.count]);
  final TileBadgeKind kind;
  final int? count;

  /// `badge` param of `study_tile_tap`.
  String get analyticsName => switch (kind) {
        TileBadgeKind.locked => 'locked',
        TileBadgeKind.exhausted => 'exhausted',
        TileBadgeKind.low => 'low',
        TileBadgeKind.due => 'due',
        TileBadgeKind.isNew => 'new',
      };

  @override
  bool operator ==(Object other) =>
      other is TileBadge && other.kind == kind && other.count == count;

  @override
  int get hashCode => Object.hash(kind, count);
}

/// One badge per tile, first match wins (spec §4.3).
TileBadge? badgeFor(
  StudyFeature f, {
  required bool isVip,
  required Set<String> vipOnly,
  TutorQuotaInfo? quota,
  int dueCount = 0,
  bool isNew = false,
}) {
  if (!isVip && vipOnly.contains(f.slug)) return const TileBadge(TileBadgeKind.locked);
  if (quota != null && !quota.unlimited && quota.remaining == 0) {
    return const TileBadge(TileBadgeKind.exhausted, 0);
  }
  if (quota != null && quota.shouldShowIndicator) {
    return TileBadge(TileBadgeKind.low, quota.remaining ?? 0);
  }
  if (f == StudyFeature.review && dueCount > 0) return TileBadge(TileBadgeKind.due, dueCount);
  if (isNew) return const TileBadge(TileBadgeKind.isNew);
  return null;
}

/// The first [max] unseen tiles in grid order (spec §4.5) — an existing user
/// would otherwise open the hub to twelve NEW badges.
Set<StudyFeature> newBadgeFeatures(Set<String> seenSlugs, {int max = 3}) =>
    studyFeatureOrder.where((f) => !seenSlugs.contains(f.slug)).take(max).toSet();

enum FeatureCoverage { supported, englishOnly, unknown }

/// Hard language restrictions found in the backend (Task 3 Step 1). A feature
/// missing here is `unknown` and shows no note.
const Map<StudyFeature, Set<String>> _staticLanguageSupport = {
  // Filled from the Step 1 verification, e.g. StudyFeature.writing: {'en'},
};

/// Whether [f] works for [targetLanguage] (a name like "Korean" or a code
/// like "ko", as stored in `language_to_learn`). Only `englishOnly` changes
/// what the tile says.
FeatureCoverage featureCoverage(
  StudyFeature f,
  String? targetLanguage, {
  List<ExamLanguage>? examLanguages,
}) {
  final target = targetLanguage?.trim().toLowerCase() ?? '';
  if (target.isEmpty) return FeatureCoverage.unknown;
  if (f == StudyFeature.exam) {
    if (examLanguages == null) return FeatureCoverage.unknown;
    final hit = examLanguages.any((l) =>
        l.active && (l.code.toLowerCase() == target || l.name.toLowerCase() == target));
    return hit ? FeatureCoverage.supported : FeatureCoverage.unknown;
  }
  final codes = _staticLanguageSupport[f];
  if (codes == null) return FeatureCoverage.unknown;
  if (codes.contains(target)) return FeatureCoverage.supported;
  if (codes.length == 1 && codes.contains('en')) return FeatureCoverage.englishOnly;
  return FeatureCoverage.unknown;
}

/// Weakest area with enough attempts to mean something (spec §5).
WeakArea? pickRecommended(List<WeakArea> areas) {
  WeakArea? best;
  for (final a in areas) {
    if (a.attempts < 3) continue;
    if (best == null || a.accuracy < best.accuracy) best = a;
  }
  return best;
}
```

Note: `_staticLanguageSupport` is keyed by code; `language_to_learn` may hold a name ("English"). Treat `english` as `en` too: in the `codes` branch, also return `supported` when `target == 'english' && codes.contains('en')`. Add a test once a static entry exists.

- [ ] **Step 5: Implement `lib/services/feature_seen_store.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';

/// Which AI Study tiles this account has opened, for NEW badges (spec §4.5).
/// Keys are user-scoped: session_prefs clears everything not on its
/// device-level allow-list at logout. Fails closed like `GuideStore`: storage
/// unreadable -> everything seen -> no badges.
class FeatureSeenStore {
  static String keyFor(String slug) => 'study_feature_seen_$slug';

  static Future<Set<String>> readSeen({
    Future<SharedPreferences> Function()? prefs,
  }) async {
    final all = StudyFeature.values.map((f) => f.slug);
    try {
      final p = await (prefs ?? SharedPreferences.getInstance)();
      final seen = <String>{};
      for (final slug in all) {
        try {
          if (p.getBool(keyFor(slug)) ?? false) seen.add(slug);
        } catch (_) {}
      }
      return seen;
    } catch (_) {
      return all.toSet();
    }
  }

  static Future<void> markSeen(String slug) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(keyFor(slug), true);
    } catch (_) {}
  }
}

final featureSeenProvider =
    FutureProvider<Set<String>>((ref) => FeatureSeenStore.readSeen());
```

Add `'featureSeenProvider': featureSeenProvider,` to the map in `lib/services/session_reset.dart` under the page-guides comment, with the import.

- [ ] **Step 6: Run** — `flutter test test/learning/study_features_test.dart test/services/feature_seen_store_test.dart test/services/` → PASS (incl. existing session_reset tests).

- [ ] **Step 7: Commit** (update `REMAINING_WORK.md`: tick "Verify each feature's real language support").

```bash
git add lib/pages/learning/main/sections/study_features.dart lib/services/feature_seen_store.dart lib/services/session_reset.dart test/learning/study_features_test.dart test/services/feature_seen_store_test.dart docs/superpowers/specs/2026-10-13-ai-study-hub-and-tab-bar-design.md docs/REMAINING_WORK.md
git commit -m "feat(study-hub): feature catalogue, badge precedence, NEW store, coverage

Open: tile + sheet UI, hub screen, tab bar, backend deploy."
```

---

### Task 4: Analytics events + upgrade/trial sheet

**Files:**
- Modify: `lib/services/analytics_service.dart` (append near the guide events, ~line 190)
- Create: `lib/widgets/study/study_upgrade_sheet.dart`
- Create: `test/widgets/study/study_upgrade_sheet_test.dart`

**Interfaces:**
- Consumes: `StudyFeature` (Task 3), `UnlockCta(featureKey:, onUnlocked:)`, `tutorMemoryAndQuotasProvider` (`lib/providers/tutor_provider.dart`), `VipPlansScreen` (`lib/pages/vip/vip_plans_screen.dart`).
- Produces:
  - `AnalyticsService.studyTileTap({required String feature, String? badge})`, `studyUpgradeSheetShown({required String feature, required String reason})`, `studyUpgradeUnlock({required String feature, required String method})`, `studySpotlightTap(String id)`, `studyRecommendedTap(String area)`
  - `enum StudyUpgradeReason { locked, exhausted }`
  - `Future<bool> showStudyUpgradeSheet(BuildContext context, {required StudyFeature feature, required StudyUpgradeReason reason})` — resolves `true` when a coin unlock succeeded (caller then opens the feature).
  - In `lib/pages/learning/main/sections/study_feature_labels.dart` (created here, shared by sheet and tile): `String studyFeatureTitle(AppLocalizations, StudyFeature)`, `String studyFeatureDescription(AppLocalizations, StudyFeature)`, `IconData studyFeatureIcon(StudyFeature)`, `({Color fg, Color fill}) studyGroupColors(StudyGroup, {required bool dark})`, `String studyGroupLabel(AppLocalizations, StudyGroup)`.

- [ ] **Step 1: Analytics** — add to `AnalyticsService`:

```dart
  /// AI Study hub (spec 2026-10-13 §9). [badge] is the tile's badge at tap
  /// time ('locked' | 'exhausted' | 'low' | 'due' | 'new'), omitted when none.
  Future<void> studyTileTap({required String feature, String? badge}) =>
      _log('study_tile_tap', {'feature': feature, 'badge': badge});

  /// [reason] is 'locked' | 'exhausted'.
  Future<void> studyUpgradeSheetShown({required String feature, required String reason}) =>
      _log('study_upgrade_sheet_shown', {'feature': feature, 'reason': reason});

  /// [method] is 'coins' | 'vip'.
  Future<void> studyUpgradeUnlock({required String feature, required String method}) =>
      _log('study_upgrade_unlock', {'feature': feature, 'method': method});

  Future<void> studySpotlightTap(String id) => _log('study_spotlight_tap', {'id': id});

  Future<void> studyRecommendedTap(String area) =>
      _log('study_recommended_tap', {'area': area});
```

(`_log` already drops null params — confirm by reading lines 15–40; the `debugLogSink` comment says "after nulls" are removed.)

- [ ] **Step 2: Labels file** — `lib/pages/learning/main/sections/study_feature_labels.dart`

```dart
import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';

String studyFeatureTitle(AppLocalizations l, StudyFeature f) => switch (f) {
      StudyFeature.tutor => l.studyTileTutor,
      StudyFeature.roleplay => l.studyTileRoleplay,
      StudyFeature.story => l.studyTileStory,
      StudyFeature.photo => l.studyTilePhoto,
      StudyFeature.speak => l.studyTileSpeak,
      StudyFeature.review => l.studyTileReview,
      StudyFeature.writing => l.studyTileWriting,
      StudyFeature.quizzes => l.studyTileQuizzes,
      StudyFeature.exam => l.studyTileExam,
      StudyFeature.lessons => l.studyTileLessons,
      StudyFeature.challenges => l.studyTileChallenges,
      StudyFeature.leaderboard => l.studyTileLeaderboard,
    };

String studyFeatureDescription(AppLocalizations l, StudyFeature f) => switch (f) {
      StudyFeature.tutor => l.studyTileTutorDesc,
      StudyFeature.roleplay => l.studyTileRoleplayDesc,
      StudyFeature.story => l.studyTileStoryDesc,
      StudyFeature.photo => l.studyTilePhotoDesc,
      StudyFeature.speak => l.studyTileSpeakDesc,
      StudyFeature.review => l.studyTileReviewDesc,
      StudyFeature.writing => l.studyTileWritingDesc,
      StudyFeature.quizzes => l.studyTileQuizzesDesc,
      StudyFeature.exam => l.studyTileExamDesc,
      StudyFeature.lessons => l.studyTileLessonsDesc,
      StudyFeature.challenges => l.studyTileChallengesDesc,
      StudyFeature.leaderboard => l.studyTileLeaderboardDesc,
    };

IconData studyFeatureIcon(StudyFeature f) => switch (f) {
      StudyFeature.tutor => Icons.smart_toy_rounded,
      StudyFeature.roleplay => Icons.theater_comedy_rounded,
      StudyFeature.story => Icons.auto_stories_rounded,
      StudyFeature.photo => Icons.photo_camera_rounded,
      StudyFeature.speak => Icons.record_voice_over_rounded,
      StudyFeature.review => Icons.replay_circle_filled_rounded,
      StudyFeature.writing => Icons.edit_note_rounded,
      StudyFeature.quizzes => Icons.quiz_rounded,
      StudyFeature.exam => Icons.school_rounded,
      StudyFeature.lessons => Icons.menu_book_rounded,
      StudyFeature.challenges => Icons.flag_rounded,
      StudyFeature.leaderboard => Icons.leaderboard_rounded,
    };

/// Group accent (foreground) and fill (light mode). Spec §4.2.
({Color fg, Color fill}) studyGroupColors(StudyGroup g, {required bool dark}) {
  final fg = switch (g) {
    StudyGroup.talk => const Color(0xFF6D3FE0),
    StudyGroup.practice => const Color(0xFF00786A),
    StudyGroup.prepare => const Color(0xFFA85E00),
  };
  if (dark) {
    final light = Color.lerp(fg, Colors.white, 0.45)!;
    return (fg: light, fill: fg.withValues(alpha: 0.18));
  }
  final fill = switch (g) {
    StudyGroup.talk => const Color(0xFFEFE9FE),
    StudyGroup.practice => const Color(0xFFDDF5EF),
    StudyGroup.prepare => const Color(0xFFFEF0D9),
  };
  return (fg: fg, fill: fill);
}

String studyGroupLabel(AppLocalizations l, StudyGroup g) => switch (g) {
      StudyGroup.talk => l.studyGroupTalk,
      StudyGroup.practice => l.studyGroupPractice,
      StudyGroup.prepare => l.studyGroupPrepare,
    };
```

- [ ] **Step 3: Write the failing sheet test** — `test/widgets/study/study_upgrade_sheet_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/widgets/study/study_upgrade_sheet.dart';

void main() {
  final events = <String, Map<String, Object>>{};
  setUp(() {
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events[n] = p;
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  Future<void> open(WidgetTester tester, StudyUpgradeReason reason) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Coins off: UnlockCta renders nothing, no network.
        appConfigProvider.overrideWith((ref) async =>
            const AppConfig(minVersion: '0', latestVersion: '0', forceUpdate: false,
                iosUrl: '', androidUrl: '', releaseNotes: '')),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showStudyUpgradeSheet(context,
                feature: StudyFeature.tutor, reason: reason),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('exhausted copy, VIP + Not now, logs shown', (tester) async {
    await open(tester, StudyUpgradeReason.exhausted);
    expect(find.text("You've used today's AI Tutor"), findsOneWidget);
    expect(find.text('Get VIP — unlimited'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
    expect(events['study_upgrade_sheet_shown'], {'feature': 'tutor', 'reason': 'exhausted'});
  });

  testWidgets('locked copy', (tester) async {
    await open(tester, StudyUpgradeReason.locked);
    expect(find.text('AI Tutor is a VIP feature'), findsOneWidget);
  });

  testWidgets('Not now closes', (tester) async {
    await open(tester, StudyUpgradeReason.exhausted);
    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();
    expect(find.text('Get VIP — unlimited'), findsNothing);
  });
}
```

Run: `flutter test test/widgets/study/study_upgrade_sheet_test.dart` → FAIL.

- [ ] **Step 4: Implement `lib/widgets/study/study_upgrade_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_labels.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';

enum StudyUpgradeReason { locked, exhausted }

/// Shown before navigating to a locked or exhausted tile (spec §4.4), so the
/// user meets the offer instead of a 429. Resolves true when a coin unlock
/// succeeded and the caller should open the feature.
Future<bool> showStudyUpgradeSheet(
  BuildContext context, {
  required StudyFeature feature,
  required StudyUpgradeReason reason,
}) async {
  AnalyticsService.instance
      .studyUpgradeSheetShown(feature: feature.slug, reason: reason.name);
  final unlocked = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _StudyUpgradeSheet(feature: feature, reason: reason),
  );
  return unlocked ?? false;
}

class _StudyUpgradeSheet extends ConsumerWidget {
  const _StudyUpgradeSheet({required this.feature, required this.reason});

  final StudyFeature feature;
  final StudyUpgradeReason reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final colors = studyGroupColors(feature.group,
        dark: Theme.of(context).brightness == Brightness.dark);
    final name = studyFeatureTitle(l, feature);
    final title = reason == StudyUpgradeReason.locked
        ? l.studyUpgradeLockedTitle(name)
        : l.studyUpgradeExhaustedTitle(name);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: colors.fill, borderRadius: BorderRadius.circular(12)),
                child: Icon(studyFeatureIcon(feature), color: colors.fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(studyFeatureDescription(l, feature), style: text.bodyMedium),
            const SizedBox(height: 12),
            _Benefit(l.studyUpgradeBenefitUnlimited),
            _Benefit(l.studyUpgradeBenefitNoAds),
            const SizedBox(height: 16),
            if (feature.quotaKey != null) ...[
              UnlockCta(
                featureKey: feature.quotaKey!,
                onUnlocked: () {
                  AnalyticsService.instance
                      .studyUpgradeUnlock(feature: feature.slug, method: 'coins');
                  ref.invalidate(tutorMemoryAndQuotasProvider);
                  Navigator.of(context).pop(true);
                },
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: () {
                AnalyticsService.instance
                    .studyUpgradeUnlock(feature: feature.slug, method: 'vip');
                final nav = Navigator.of(context);
                nav.pop(false);
                nav.push(AppPageRoute(builder: (_) => const VipPlansScreen()));
              },
              child: Text(l.studyUpgradeGetVip),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.notNow),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(Icons.check_circle_rounded,
              size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        ]),
      );
}
```

Note on the analytics name `study_upgrade_unlock {method: vip}`: it is logged on tapping "Get VIP" (intent), since purchase completion happens in `VipPlansScreen`; record this in the spec §9 as "vip = tapped through to plans".

- [ ] **Step 5: Run** → PASS. Also `flutter analyze lib/widgets/study lib/pages/learning/main lib/services/analytics_service.dart`.

- [ ] **Step 6: Commit** (REMAINING_WORK: nothing new to tick; body lists open tasks).

```bash
git add lib/services/analytics_service.dart lib/pages/learning/main/sections/study_feature_labels.dart lib/widgets/study test/widgets/study docs/REMAINING_WORK.md
git commit -m "feat(study-hub): upgrade/trial sheet + study analytics events

Open: tile grid, hub sections, hub screen, tab bar."
```

---

### Task 5: Feature tile + Explore groups (tap routing, NEW marking, sheet gating)

**Files:**
- Create: `lib/pages/learning/main/sections/study_feature_tile.dart`
- Create: `lib/pages/learning/main/sections/study_feature_groups.dart`
- Create: `lib/pages/learning/exam_study/exam_study_screen.dart`
- Create: `test/learning/study_feature_groups_test.dart`

**Interfaces:**
- Consumes: Task 3 (`badgeFor`, `newBadgeFeatures`, `featureSeenProvider`, `FeatureSeenStore.markSeen`, `featureCoverage`), Task 4 (labels, `showStudyUpgradeSheet`, analytics), `tutorQuotaProvider`, `tutorMemoryProvider`, `vocabularyStatsProvider(null)` (`.dueToday`), `appConfigProvider`, `userProvider` (`.isVip`, `.language_to_learn`), `examLanguagesProvider`.
- Produces:
  - `class StudyFeatureTile extends StatelessWidget { feature, title, description, badge (TileBadge?), onTap }`
  - `class StudyFeatureGroups extends ConsumerWidget { const StudyFeatureGroups({super.key, this.navigate}); final void Function(BuildContext, Widget)? navigate; }` — `navigate` is a test seam, default pushes `AppPageRoute`.
  - `Widget destinationFor(StudyFeature f)` (top-level, in `study_feature_groups.dart`).
  - `class ExamStudyScreen extends StatelessWidget` (AppBar `l.examStudy` + `ExamStudyTab()` body).

- [ ] **Step 1: Write failing widget tests** — `test/learning/study_feature_groups_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_groups.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/services/feature_seen_store.dart';

const _cfg = AppConfig(minVersion: '0', latestVersion: '0', forceUpdate: false,
    iosUrl: '', androidUrl: '', releaseNotes: '');

Widget harness({
  TutorQuotaState quota = TutorQuotaState.empty,
  Set<String> seen = const {},
  required List<String> pushed,
  Size size = const Size(390, 900),
  double textScale = 1.0,
}) =>
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWith((ref) async => _cfg),
        tutorQuotaProvider.overrideWithValue(quota),
        featureSeenProvider.overrideWith((ref) async => seen),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudyFeatureGroups(
                navigate: (_, w) => pushed.add(w.runtimeType.toString()),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders three groups and twelve tiles', (tester) async {
    await tester.pumpWidget(harness(pushed: []));
    await tester.pumpAndSettle();
    expect(find.text('TALK'), findsOneWidget);
    expect(find.text('PRACTICE'), findsOneWidget);
    expect(find.text('PREPARE & COMPETE'), findsOneWidget);
    expect(find.byType(InkWell), findsNWidgets(12));
  });

  testWidgets('at most three NEW badges', (tester) async {
    await tester.pumpWidget(harness(pushed: []));
    await tester.pumpAndSettle();
    expect(find.text('NEW'), findsNWidgets(3));
  });

  testWidgets('exhausted tile opens the sheet instead of navigating', (tester) async {
    final pushed = <String>[];
    final quota = TutorQuotaState(chat: const TutorQuotaInfo(
        used: 10, cap: 10, remaining: 0, resetAt: null, unlimited: false));
    await tester.pumpWidget(harness(quota: quota, pushed: pushed));
    await tester.pumpAndSettle();
    expect(find.text('0 left'), findsOneWidget);
    await tester.tap(find.text('AI Tutor'));
    await tester.pumpAndSettle();
    expect(pushed, isEmpty);
    expect(find.text("You've used today's AI Tutor"), findsOneWidget);
  });

  testWidgets('quota not loaded: tap navigates', (tester) async {
    final pushed = <String>[];
    await tester.pumpWidget(harness(pushed: pushed));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lessons'));
    await tester.pumpAndSettle();
    expect(pushed, ['LessonsScreen']);
  });

  testWidgets('tap marks the tile seen', (tester) async {
    await tester.pumpWidget(harness(pushed: []));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lessons'));
    await tester.pumpAndSettle();
    expect(await FeatureSeenStore.readSeen(), contains('lessons'));
  });

  testWidgets('no overflow at 320 wide and text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness(pushed: [], size: const Size(320, 900), textScale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
```

The tutor tile goes through the persona picker when `tutorMemoryProvider` has no persona; in tests it is unresolved, so the "tap navigates" test uses Lessons. The `userProvider` is unresolved in tests → `isVip` false, target language null; that is intended.

Run: `flutter test test/learning/study_feature_groups_test.dart` → FAIL.

- [ ] **Step 2: Implement `lib/pages/learning/exam_study/exam_study_screen.dart`**

```dart
import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/exam_study_tab.dart';

/// Exam Study as a pushed screen, for the hub's Exam prep tile. The legacy
/// hub still embeds [ExamStudyTab] as its third sub-tab.
class ExamStudyScreen extends StatelessWidget {
  const ExamStudyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.examStudy)),
        body: const ExamStudyTab(),
      );
}
```

- [ ] **Step 3: Implement `study_feature_tile.dart`**

```dart
import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_labels.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';

/// One Explore tile (spec §4.2): tinted icon, title, one-line description,
/// at most one badge. The whole tile is the tap target.
class StudyFeatureTile extends StatelessWidget {
  const StudyFeatureTile({
    super.key,
    required this.feature,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  final StudyFeature feature;
  final String description;
  final TileBadge? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final colors = studyGroupColors(feature.group, dark: dark);
    final title = studyFeatureTitle(l, feature);
    final badgeText = badge == null ? null : _badgeLabel(l, badge!);

    return Semantics(
      button: true,
      label: [title, description, if (badgeText != null) badgeText].join(', '),
      excludeSemantics: true,
      child: Material(
        color: dark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(StudyHubMetrics.tileRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(StudyHubMetrics.tileRadius),
          child: Container(
            constraints: const BoxConstraints(minHeight: StudyHubMetrics.tileHeight),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(StudyHubMetrics.tileRadius),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              Container(
                width: StudyHubMetrics.tileIconSize,
                height: StudyHubMetrics.tileIconSize,
                decoration: BoxDecoration(
                    color: colors.fill, borderRadius: BorderRadius.circular(10)),
                child: Icon(studyFeatureIcon(feature), color: colors.fg, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      if (badge != null) _Badge(badge: badge!, text: badgeText!),
                    ]),
                    Text(description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  static String _badgeLabel(AppLocalizations l, TileBadge b) => switch (b.kind) {
        TileBadgeKind.locked => l.studyBadgeVip,
        TileBadgeKind.exhausted => l.studyBadgeLeft(0),
        TileBadgeKind.low => l.studyBadgeLeft(b.count ?? 0),
        TileBadgeKind.due => l.studyBadgeDue(b.count ?? 0),
        TileBadgeKind.isNew => l.studyBadgeNew,
      };
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge, required this.text});
  final TileBadge badge;
  final String text;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (badge.kind) {
      TileBadgeKind.exhausted => (AppColors.error, Colors.white),
      TileBadgeKind.locked => (const Color(0xFF2B2B33), const Color(0xFFFFD54F)),
      TileBadgeKind.isNew => (const Color(0xFF6D3FE0), Colors.white),
      _ => (const Color(0xFFFEF0D9), const Color(0xFF8A4B00)),
    };
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (badge.kind == TileBadgeKind.locked)
          Icon(Icons.lock_rounded, size: 12, color: fg),
        Text(text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
```

Check `AppColors.error` exists in `lib/core/theme/app_theme.dart` (it is used by `TabBarMenu.dart`). Make sure `labelSmall` in the app theme is ≥12; if the theme leaves it at Material's 11, set `labelSmall: AppTypography.labelSmall` sized 12 in this widget via `.copyWith(fontSize: ...)` is NOT allowed (no literals) — instead read `AppTypography.labelSmall` and check its size; if <12, raise it in `app_theme.dart` only if no other screen breaks (`grep -rn "labelSmall" lib | wc -l` first; if widely used, accept 11 and note it in REMAINING_WORK).

- [ ] **Step 4: Implement `study_feature_groups.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/ai/grammar/grammar_feedback_screen.dart';
import 'package:bananatalk_app/pages/ai/pronunciation/pronunciation_screen.dart';
import 'package:bananatalk_app/pages/ai/quiz/ai_quiz_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/image_vocab_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/persona_picker_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/scenario_picker_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/story_setup_screen.dart';
import 'package:bananatalk_app/pages/ai/tutor/tutor_chat_screen.dart';
import 'package:bananatalk_app/pages/learning/challenges/challenges_screen.dart';
import 'package:bananatalk_app/pages/learning/exam_study/exam_study_screen.dart';
import 'package:bananatalk_app/pages/learning/leaderboard/leaderboard_screen.dart';
import 'package:bananatalk_app/pages/learning/lessons/lessons_screen.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_labels.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_tile.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocabulary_review_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/feature_seen_store.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/study/study_upgrade_sheet.dart';

Widget destinationFor(StudyFeature f) => switch (f) {
      StudyFeature.tutor => const TutorChatScreen(),
      StudyFeature.roleplay => const ScenarioPickerScreen(),
      StudyFeature.story => const StorySetupScreen(),
      StudyFeature.photo => const ImageVocabScreen(),
      StudyFeature.speak => const PronunciationScreen(),
      StudyFeature.review => const VocabularyReviewScreen(),
      StudyFeature.writing => const GrammarFeedbackScreen(),
      StudyFeature.quizzes => const AIQuizScreen(),
      StudyFeature.exam => const ExamStudyScreen(),
      StudyFeature.lessons => const LessonsScreen(),
      StudyFeature.challenges => const ChallengesScreen(),
      StudyFeature.leaderboard => const LeaderboardScreen(),
    };

/// The three Explore groups (spec §4). Tap order: badge-gated sheet first,
/// then the persona picker for Talk tiles without a persona, then the
/// destination.
class StudyFeatureGroups extends ConsumerWidget {
  const StudyFeatureGroups({super.key, this.navigate});

  /// Test seam; defaults to pushing an [AppPageRoute].
  final void Function(BuildContext context, Widget destination)? navigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final user = ref.watch(userProvider).valueOrNull;
    final isVip = user?.isVip ?? false;
    final vipOnly = ref.watch(appConfigProvider).valueOrNull?.studyVipOnlyFeatures ?? const <String>{};
    final quota = ref.watch(tutorQuotaProvider);
    final due = ref.watch(vocabularyStatsProvider(null)).valueOrNull?.dueToday ?? 0;
    // Loading: treat everything as seen so badges do not flash in.
    final seen = ref.watch(featureSeenProvider).valueOrNull
        ?? StudyFeature.values.map((f) => f.slug).toSet();
    final fresh = newBadgeFeatures(seen);
    final examLangs = ref.watch(examLanguagesProvider).valueOrNull;
    final target = user?.language_to_learn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in StudyGroup.values) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: StudyHubMetrics.groupLabelGap),
            child: Text(
              studyGroupLabel(l, group).toUpperCase(),
              style: text.labelLarge?.copyWith(
                letterSpacing: 0.9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _Grid(children: [
            for (final f in studyFeatureGroups[group]!)
              Builder(builder: (context) {
                final badge = badgeFor(f,
                    isVip: isVip,
                    vipOnly: vipOnly,
                    quota: f.quotaKey == null ? null : quota.get(f.quotaKey!),
                    dueCount: due,
                    isNew: fresh.contains(f));
                final englishOnly = featureCoverage(f, target, examLanguages: examLangs) ==
                    FeatureCoverage.englishOnly;
                return StudyFeatureTile(
                  feature: f,
                  description: englishOnly ? l.studyEnglishOnly : studyFeatureDescription(l, f),
                  badge: badge,
                  onTap: () => _onTap(context, ref, f, badge),
                );
              }),
          ]),
          const SizedBox(height: StudyHubMetrics.groupGap),
        ],
      ],
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, StudyFeature f, TileBadge? badge) async {
    AnalyticsService.instance.studyTileTap(feature: f.slug, badge: badge?.analyticsName);
    FeatureSeenStore.markSeen(f.slug).then((_) => ref.invalidate(featureSeenProvider));

    if (badge?.kind == TileBadgeKind.locked) {
      await showStudyUpgradeSheet(context, feature: f, reason: StudyUpgradeReason.locked);
      return;
    }
    if (badge?.kind == TileBadgeKind.exhausted) {
      final unlocked = await showStudyUpgradeSheet(context,
          feature: f, reason: StudyUpgradeReason.exhausted);
      if (!unlocked || !context.mounted) return;
    }
    if (!context.mounted) return;
    _open(context, ref, f);
  }

  void _open(BuildContext context, WidgetRef ref, StudyFeature f) {
    final push = navigate ??
        (BuildContext c, Widget w) => Navigator.push(c, AppPageRoute(builder: (_) => w));
    var dest = destinationFor(f);
    // Talk tiles need a persona; the picker forwards to the chosen feature
    // (same rule as the old _TutorModeChips._open).
    if (f.group == StudyGroup.talk &&
        ref.read(tutorMemoryProvider).valueOrNull?.persona == null) {
      dest = PersonaPickerScreen(destinationAfterPick: dest);
    }
    push(context, dest);
  }
}

/// 2-column grid with fixed gaps; rows size to their tallest tile so text
/// scale never clips.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: children[i]),
          const SizedBox(width: StudyHubMetrics.tileGap),
          Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
        ]),
      ));
      if (i + 2 < children.length) rows.add(const SizedBox(height: StudyHubMetrics.tileGap));
    }
    return Column(children: rows);
  }
}
```

Before relying on `const` constructors, check each destination screen has a `const` no-arg constructor (they are used as `const X()` in `ai_tools_tab.dart` / `learn_tab.dart`; `ChallengesScreen`, `LeaderboardScreen`, `LessonsScreen` too). The "tap navigates" test asserts the runtimeType name `LessonsScreen`.

The tests find `TALK` etc. via `toUpperCase()` — fine for English. Use `find.byType(InkWell)` count 12 only if no other InkWell renders; if the badge or grid adds one, switch to `find.byType(StudyFeatureTile)`.

- [ ] **Step 5: Run** → `flutter test test/learning/study_feature_groups_test.dart` PASS; `flutter analyze` clean.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/learning/main/sections/study_feature_tile.dart lib/pages/learning/main/sections/study_feature_groups.dart lib/pages/learning/exam_study/exam_study_screen.dart test/learning/study_feature_groups_test.dart docs/REMAINING_WORK.md
git commit -m "feat(study-hub): feature tiles and Explore groups with badge-gated taps

Open: hub sections, hub screen + flag, tab bar."
```

---

### Task 6: Hub sections — today row, recommended, spotlight, progress card

**Files:**
- Create: `lib/pages/learning/main/sections/today_pack_row.dart`, `recommended_tile.dart`, `spotlight_carousel.dart`, `progress_card.dart`
- Create: `test/learning/study_hub_sections_test.dart`

**Interfaces:**
- Consumes: `DailyPack` (`needsLanguage`, `levelPlaced`, `packComplete`, `theme?.topic`, `stations` with `isOutstanding`), `weakAreasProvider` (`lib/providers/provider_root/ai_providers.dart`), `pickRecommended`, `Announcement` (`id`, `title`, `buttonLabel?`, `buttonUrl?`, `hasButton`), `openAnnouncementLink(url)` (`lib/widgets/promo/announcement_modal.dart`), `AnnouncementScreen(id:)`, `LearningProgress` (`currentStreak`, `level`, `totalXP`, `dailyXP`, `dailyGoal`).
- Produces:
  - `TodayPackRow({required DailyPack pack, required VoidCallback onOpen, required VoidCallback onPickLanguage, required VoidCallback onTakePlacement})`
  - `RecommendedTile()` (ConsumerWidget; renders `SizedBox.shrink()` unless `pickRecommended` returns an area)
  - `SpotlightCarousel()` (ConsumerWidget) + `class SpotlightDismissStore { static Future<Set<String>> read(); static Future<void> dismiss(String id); }` key `study_spotlight_dismissed` (string list) + `final spotlightDismissedProvider = FutureProvider<Set<String>>`
  - `List<Announcement> spotlightItems(List<Announcement> all, Set<String> dismissed)` — pure: drop dismissed, max 3, keep server order.
  - `ProgressCard({required LearningProgress progress, required VoidCallback onFullReport})`

- [ ] **Step 1: Failing tests** — `test/learning/study_hub_sections_test.dart` covering:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/main/sections/spotlight_carousel.dart';
import 'package:bananatalk_app/pages/learning/main/sections/today_pack_row.dart';

Widget app(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

DailyPack pack({bool needsLanguage = false, bool placed = true, bool complete = false}) => DailyPack(
      needsLanguage: needsLanguage,
      dateKey: '2026-10-14',
      weekKey: '2026-W42',
      dayInWeek: 2,
      theme: const PackTheme(id: 'p', topic: 'Travel', level: 'beginner'),
      stations: const [PackStation(kind: 'grammar', status: StationStatus.todo)],
      packComplete: complete,
      levelPlaced: placed,
    );

void main() {
  group('spotlightItems', () {
    Announcement a(String id) => Announcement.fromJson({'id': id, 'title': 't$id', 'body': ''});
    test('drops dismissed, keeps order, max 3', () {
      final all = [a('1'), a('2'), a('3'), a('4'), a('5')];
      expect(spotlightItems(all, {'2'}).map((x) => x.id), ['1', '3', '4']);
    });
  });

  group('TodayPackRow', () {
    testWidgets('normal: topic + Start', (t) async {
      var opened = false;
      await t.pumpWidget(app(TodayPackRow(pack: pack(), onOpen: () => opened = true,
          onPickLanguage: () {}, onTakePlacement: () {})));
      expect(find.text('Travel'), findsOneWidget);
      await t.tap(find.text('Start'));
      expect(opened, isTrue);
    });
    testWidgets('needs language -> picker prompt', (t) async {
      var picked = false;
      await t.pumpWidget(app(TodayPackRow(pack: pack(needsLanguage: true), onOpen: () {},
          onPickLanguage: () => picked = true, onTakePlacement: () {})));
      await t.tap(find.byType(InkWell).first);
      expect(picked, isTrue);
    });
    testWidgets('not placed -> placement', (t) async {
      var placement = false;
      await t.pumpWidget(app(TodayPackRow(pack: pack(placed: false), onOpen: () {},
          onPickLanguage: () {}, onTakePlacement: () => placement = true)));
      await t.tap(find.byType(InkWell).first);
      expect(placement, isTrue);
    });
  });
}
```

Check `DailyPack`'s constructor (`lib/models/learning/daily_pack_model.dart` ~line 270) for the exact named params and defaults (`packComplete`, `levelPlaced`), and `Announcement.fromJson`'s required keys; adjust literals to match. Recommended-area selection is already unit-tested in Task 3.

Run → FAIL.

- [ ] **Step 2: Implement `today_pack_row.dart`** — a 72-high (min) card, `StudyHubMetrics.cardRadius`, gradient `#667EEA→#764BA2` (the hub's brand), states in this order:
  1. `pack.needsLanguage` → title `l.todayPickLanguage`, whole row taps `onPickLanguage`.
  2. `!pack.levelPlaced` → title `l.packTakePlacement`, taps `onTakePlacement`.
  3. `pack.packComplete` → title `l.packDoneForToday`, check icon, taps `onOpen` (review).
  4. else → caption `l.studyTodayPack`, title `pack.theme?.topic ?? l.studyTodayPack`, trailing `FilledButton.tonal(child: Text(l.studyTodayStart), onPressed: onOpen)`; the row itself also taps `onOpen`.

Text: caption `bodySmall` white70, title `titleMedium` w800 white, ellipsis 1 line. Wrap in `Material` + `InkWell` (the test taps `InkWell`).

Read `daily_pack_hero_card.dart` lines 50–180 first and mirror its precedence exactly if it differs from the above (it is the source of truth for which state wins).

- [ ] **Step 3: Implement `recommended_tile.dart`**

```dart
class RecommendedTile extends ConsumerWidget {
  const RecommendedTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas = ref.watch(weakAreasProvider).valueOrNull;
    final area = areas == null ? null : pickRecommended(areas);
    if (area == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final percent = (area.accuracy * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: StudyHubMetrics.tileGap),
      child: Material(
        color: const Color(0xFFFEF0D9).withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 1),
        borderRadius: BorderRadius.circular(StudyHubMetrics.tileRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(StudyHubMetrics.tileRadius),
          onTap: () {
            AnalyticsService.instance.studyRecommendedTap(area.name);
            Navigator.push(context, AppPageRoute(builder: (_) => const AIQuizScreen()));
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: StudyHubMetrics.recommendedHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                const Icon(Icons.gps_fixed_rounded, color: Color(0xFFA85E00), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.studyRecommended(area.name, percent),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
```

(imports: material, riverpod, l10n, `ai_providers.dart`, `study_features.dart`, `study_hub_metrics.dart`, `ai_quiz_screen.dart`, `analytics_service.dart`, `app_page_route.dart`.) Loading/error → `valueOrNull` null → hidden, as spec §5 requires.

- [ ] **Step 4: Implement `spotlight_carousel.dart`** — `SpotlightDismissStore` mirrors `FeatureSeenStore` (wrapped reads, string list under `study_spotlight_dismissed`, fail → empty set i.e. show), `spotlightItems` pure function, and the widget:
  - reads `appConfigProvider.valueOrNull?.announcements ?? []` and `spotlightDismissedProvider`; `items = spotlightItems(...)`; empty → `SizedBox.shrink()`.
  - `SizedBox(height: StudyHubMetrics.carouselCardHeight, child: PageView.builder(...))` + dot row (only when `items.length > 1`).
  - Card: emoji (if any) + title (`titleSmall` w700, 2 lines) + optional `buttonLabel` (`labelLarge`, primary colour); close `IconButton(Icons.close_rounded, tooltip: MaterialLocalizations.of(context).closeButtonTooltip)` → `SpotlightDismissStore.dismiss(id)` then `ref.invalidate(spotlightDismissedProvider)`.
  - Tap: `AnalyticsService.instance.studySpotlightTap(a.id)`; `a.hasButton ? openAnnouncementLink(a.buttonUrl!) : Navigator.push(context, AppPageRoute(builder: (_) => AnnouncementScreen(id: a.id)))`.
  - The hub (Task 7) decides guide vs carousel; the carousel itself does not read the guide.

- [ ] **Step 5: Implement `progress_card.dart`** — card (radius 16, padding 12, title `l.studyProgressTitle` `titleSmall` w700): row of three stats, each a `titleLarge` w800 value over a `bodySmall` label: `progress.currentStreak` over `l.streak`; `l.studyLevelShort(progress.level)` alone; `progress.dailyXP / progress.dailyGoal` XP as a `LinearProgressIndicator` with the numbers in `bodySmall`. Below: `Wrap(spacing: 8, runSpacing: 8)` of `ActionChip`s: `l.studyFullReport` → `onFullReport`; `l.achievements` → `AchievementsScreen()`; `l.vocabulary` → `VocabularyScreen()`; `l.review` → `SrsDashboardScreen()`. Add a widget test to `study_hub_sections_test.dart`: tapping "Full report" calls `onFullReport`.

- [ ] **Step 6: Run** → `flutter test test/learning/study_hub_sections_test.dart` PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/learning/main/sections/today_pack_row.dart lib/pages/learning/main/sections/recommended_tile.dart lib/pages/learning/main/sections/spotlight_carousel.dart lib/pages/learning/main/sections/progress_card.dart test/learning/study_hub_sections_test.dart docs/REMAINING_WORK.md
git commit -m "feat(study-hub): today row, recommended tile, spotlight carousel, progress card

Open: hub screen + flag switch, guide, tab bar."
```

---

### Task 7: `StudyHub` screen, flag switch, new guide, tutor activation fix

**Files:**
- Create: `lib/pages/learning/main/legacy_study_hub.dart` (move, don't rewrite)
- Create: `lib/pages/learning/main/study_hub.dart`
- Modify: `lib/pages/learning/main/learning_main_screen.dart`
- Modify: `lib/providers/tutor_provider.dart` (`TutorChatController.send`, ~line 405)
- Modify: `test/guides/every_tab_has_a_guide_test.dart`
- Create: `test/learning/study_hub_test.dart`, `test/learning/study_hub_typography_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 2–6; `PageGuide` (`surface`, `onCta`, `secondaryLabel`, `onSecondary`); `shouldShowGuide` inputs via `isGuidePeriodProvider`; `tabReselectProvider` arrives in Task 8 — this task exposes `StudyHub(scrollController:)`? No: `StudyHub` owns its `ScrollController` and Task 8 adds the listener.
- Produces: `class StudyHub extends ConsumerStatefulWidget` (public `static const groupsKey = ValueKey('study-hub-groups')` so tests and the guide scroll to it); `class LegacyStudyHub extends ConsumerStatefulWidget` (old body).

- [ ] **Step 1: Move the old body.** Create `legacy_study_hub.dart` containing today's `_LearningMainState.build`'s `return Scaffold(...)` subtree and `_buildHeaderActions`, as `LegacyStudyHub` with its own `TabController` (`SingleTickerProviderStateMixin`). Copy imports as needed. Do not change behaviour. Then reduce `learning_main_screen.dart` to: the celebration listeners (unchanged) + 

```dart
    final hubOn = ref.watch(appConfigProvider).valueOrNull?.studyHubEnabled ?? false;
    return hubOn ? const StudyHub() : const LegacyStudyHub();
```

(drop the `TabController`, `SingleTickerProviderStateMixin`, and now-unused imports from `learning_main_screen.dart`).

- [ ] **Step 2: Failing tests** — `test/learning/study_hub_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/learning/main/learning_main_screen.dart';
import 'package:bananatalk_app/pages/learning/main/legacy_study_hub.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';

AppConfig cfg(bool on) => AppConfig(minVersion: '0', latestVersion: '0', forceUpdate: false,
    iosUrl: '', androidUrl: '', releaseNotes: '', studyHubEnabled: on);

Future<void> pump(WidgetTester t, bool on) async {
  await t.pumpWidget(ProviderScope(
    overrides: [appConfigProvider.overrideWith((ref) async => cfg(on))],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LearningMain(),
    ),
  ));
  await t.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('flag off renders the legacy hub', (t) async {
    await pump(t, false);
    expect(find.byType(LegacyStudyHub), findsOneWidget);
    expect(find.byType(StudyHub), findsNothing);
  });

  testWidgets('flag on renders the hub with all three groups', (t) async {
    await pump(t, true);
    expect(find.byType(StudyHub), findsOneWidget);
    await t.scrollUntilVisible(find.text('PREPARE & COMPETE'), 200);
    expect(find.text('TALK'), findsOneWidget);
  });
}
```

Providers the hub watches that hit the network (`learningProgressProvider`, `dailyPackProvider`, `weakAreasProvider`, `userProvider`, `tutorMemoryAndQuotasProvider`, `vocabularyStatsProvider`, `examLanguagesProvider`, `challengesProvider`) must be overridden in `pump` with fixtures or `Future.value(...)`/never-completing futures so no real HTTP runs. Look at `test/learning/learn_tab_pack_test.dart` and `test/guides/page_guide_test.dart` for the fixtures they already use (`community_fixture.dart` for `userProvider`) and add overrides until the test runs without `HttpClient` errors. Write the overrides list once as `final _overrides = [...]` at the top of the file.

Guide tests (spec §11): with a user in the 7-day window (use `community_fixture.dart` with a recent `createdAt`) and no activation done, the guide shows "Your daily language gym"; tapping "See all features" makes `find.byKey(StudyHub.groupsKey)` visible (`tester.getRect` within the viewport); the spotlight carousel is absent while the guide shows (provide one announcement in `cfg`).

`test/learning/study_hub_typography_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Spec §3.2: hub files use the text theme, never size literals.
void main() {
  const files = [
    'lib/pages/learning/main/study_hub.dart',
    'lib/pages/learning/main/sections/study_feature_tile.dart',
    'lib/pages/learning/main/sections/study_feature_groups.dart',
    'lib/pages/learning/main/sections/today_pack_row.dart',
    'lib/pages/learning/main/sections/recommended_tile.dart',
    'lib/pages/learning/main/sections/spotlight_carousel.dart',
    'lib/pages/learning/main/sections/progress_card.dart',
    'lib/widgets/study/study_upgrade_sheet.dart',
  ];
  for (final f in files) {
    test('$f has no fontSize literal', () {
      expect(File(f).readAsStringSync().contains(RegExp(r'fontSize:\s*\d')), isFalse);
    });
  }
}
```

Run both → FAIL.

- [ ] **Step 3: Implement `study_hub.dart`.** One `Scaffold` + `RefreshIndicator` + `CustomScrollView(controller: _scroll)`:
  1. `SliverAppBar(pinned: true, expandedHeight: 110, toolbarHeight: 56)` with the existing gradient (`#667EEA→#764BA2`, dark `#1A1A2E→#16213E`). Expanded: line 1 = greeting `l.study` (`headlineSmall` w800 white) + `VipUpPill(onLight: false)`, `CoinBalancePill(onLight: false)`, `NotificationBell(color: Colors.white)`; line 2 = chips (white 16 % fill, `labelLarge` white): `l.studyStreakDays(progress.currentStreak)`, `l.studyLevelShort(progress.level)`, and `user.language_to_learn` when non-empty. Collapsed: title only. No ⋮ menu.
  2. `SliverPadding(padding: EdgeInsets.fromLTRB(m, m, m, FloatingTabBar.clearance(context)))` with `SliverList.list(children: [...])` where `m = StudyHubMetrics.pageMargin`. `FloatingTabBar.clearance` is created now as a stub in `lib/widgets/navigation/floating_tab_bar.dart`:

```dart
import 'package:flutter/widgets.dart';

class FloatingTabBar {
  static const double height = 56;
  static const double _gapNoInset = 8;
  static const double _breathing = 12;

  /// Space a tab page must leave at its bottom so content scrolls clear of
  /// the floating bar (spec §8.2). Mirrors the bar's own positioning.
  static double clearance(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final gap = inset > 0 ? inset - 4 : _gapNoInset;
    return gap + height + _breathing;
  }
}
```

     Task 8 turns this class into the widget and keeps `clearance` unchanged.
  3. Children, in order, separated by `SizedBox(height: StudyHubMetrics.tileGap)` unless noted:
     - Guide **or** carousel: `final guideOn = ref.watch(isGuidePeriodProvider).valueOrNull ?? false;` then `PageGuide(...)` (always mounted — it hides itself) and `if (!guideOn) const SpotlightCarousel()`. `PageGuide` args: `surface: GuideSurface.aiStudy`, `icon: Icons.auto_awesome_rounded`, `accent: Color(0xFF667EEA)`, `title: l.guideStudyHubTitle`, `body: l.guideStudyHubBody`, `ctaLabel: l.guideStudyHubCta`, `onCta: _openPack`, `secondaryLabel: l.guideStudyHubSecondary`, `onSecondary: _scrollToGroups`, `padding: EdgeInsets.zero`.
       `isGuidePeriodProvider` is coarser than `PageGuide`'s own rule (no per-surface `acted`/retired), so the carousel can stay hidden a little longer than the card; acceptable, note it in a comment.
     - `dailyPackProvider.when(loading: SizedBox(height: StudyHubMetrics.todayRowHeight, child: Center(child: CircularProgressIndicator())), error: SizedBox.shrink, data: TodayPackRow(...))`. Callbacks are **moved verbatim** from `learn_tab.dart` lines 62–93 (the `.then` invalidations of `dailyPackProvider`, `masteryProvider`, `learningProgressProvider`) and `_pickLearningLanguage` (lines 593–617). Make `_pickLearningLanguage` public as `pickLearningLanguage` in `learn_tab.dart` and import it, rather than copying it.
     - `const RecommendedTile()`
     - `SizedBox(height: StudyHubMetrics.groupGap)`, then `KeyedSubtree(key: StudyHub.groupsKey, child: const StudyFeatureGroups())`
     - `ProgressCard(progress: progress, onFullReport: () => openProgress(context, ref))` — likewise make `LearnTab._openProgress` a public top-level `openProgress(BuildContext, WidgetRef)` in `learn_tab.dart` and reuse it. Hidden when `learningProgressProvider` has no data.
     - `if (ref.watch(showAdsProvider)) const NativeAdWidget(key: ValueKey('study-hub-native'))`
  4. `_scrollToGroups`: `Scrollable.ensureVisible(StudyHub.groupsKey.currentContext!, duration: 300ms, curve: Curves.easeOutCubic)` — needs a `GlobalKey`, so declare `static final groupsKey = GlobalKey(debugLabel: 'study-hub-groups');` (not `ValueKey`) and update the test to `find.byKey(StudyHub.groupsKey)`.
  5. `RefreshIndicator.onRefresh`: invalidate `learningProgressProvider`, `dailyPackProvider`, `weakAreasProvider`, `tutorMemoryAndQuotasProvider`, `vocabularyStatsProvider(null)`.

- [ ] **Step 4: Tutor activation fix** — in `TutorChatController.send`, after `_safeSet(state.copyWith(session: updated, sending: false));`:

```dart
      // A real tutor exchange is a learning start (spec §7): without this,
      // tutor-only users kept the AI Study guide all week. Recorded on the
      // first successful reply, not on end(), which screens rarely call.
      ActivationStore().markDone(ActivationAction.lesson).ignore();
```

Roleplay sessions run through the same controller (`startRoleplay` then `send`), so both are covered. Import `package:bananatalk_app/services/activation_store.dart`. Add a unit test in `test/activation/` following the existing activation tests' style if `TutorChatController` can be built with a fake `TutorService`; if its constructor needs a real `Ref`, use a `ProviderContainer` with `tutorServiceProvider.overrideWithValue(fake)` and assert `await ActivationStore().isDone(ActivationAction.lesson)` after `send('hi')`.

- [ ] **Step 5: Guide coverage test** — in `test/guides/every_tab_has_a_guide_test.dart` change the AI Study row's file to `lib/pages/learning/main/study_hub.dart`, and add a second row `'AI Study (legacy)': (file: 'lib/pages/learning/main/legacy_study_hub.dart', mounts: 'GuideSurface.aiStudy')`.

- [ ] **Step 6: Run** — `flutter test test/learning test/guides test/activation` → all PASS; `flutter analyze` clean.

- [ ] **Step 7: Commit** (REMAINING_WORK: tick "Implementation" partially — add sub-items "hub screen done, tab bar pending").

```bash
git add lib/pages/learning/main lib/providers/tutor_provider.dart lib/widgets/navigation/floating_tab_bar.dart test/learning test/guides test/activation docs/REMAINING_WORK.md
git commit -m "feat(study-hub): one-scroll hub behind studyHubEnabled, new guide, tutor counts as a lesson

Open: floating tab bar redesign, coffee removal, device QA, baseline queries."
```

---

### Task 8: Floating tab bar — active capsule, hide on scroll, keyboard, reselect

**Files:**
- Modify: `lib/widgets/navigation/floating_tab_bar.dart` (grow the Task 7 stub)
- Modify: `lib/pages/menu_tab/TabBarMenu.dart` (replace the inline bar ~lines 322–400 and `_buildNavItem`/`_getTabColor` ~406–562)
- Modify: `lib/pages/learning/main/study_hub.dart` (listen to reselect)
- Create: `test/widgets/navigation/floating_tab_bar_test.dart`

**Interfaces:**
- Produces:
  - `class BarScrollState { bool get visible; void onScroll({required double delta, required bool atTop, required bool atEnd}); void reset(); }` — pure, threshold 24.
  - `final tabReselectProvider = StateProvider<({int tab, int seq})>((ref) => (tab: -1, seq: 0));`
  - `class FloatingTabBar extends StatelessWidget { FloatingTabBar({required List<FloatingTabItem> items, required int selected, required ValueChanged<int> onSelect, required bool visible}); static double clearance(BuildContext); static const double height = 56; }`
  - `class FloatingTabItem { final IconData icon, activeIcon; final String label; final Color color; final int badgeCount; final String? imageAsset; final String? avatarUrl; }`

- [ ] **Step 1: Failing tests** — `test/widgets/navigation/floating_tab_bar_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/widgets/navigation/floating_tab_bar.dart';

void main() {
  group('BarScrollState', () {
    test('hides after 24 px down, not before', () {
      final s = BarScrollState();
      s.onScroll(delta: 20, atTop: false, atEnd: false);
      expect(s.visible, isTrue);
      s.onScroll(delta: 5, atTop: false, atEnd: false);
      expect(s.visible, isFalse);
    });
    test('any upward scroll shows', () {
      final s = BarScrollState()..onScroll(delta: 40, atTop: false, atEnd: false);
      s.onScroll(delta: -1, atTop: false, atEnd: false);
      expect(s.visible, isTrue);
    });
    test('top or end shows', () {
      final s = BarScrollState()..onScroll(delta: 40, atTop: false, atEnd: false);
      s.onScroll(delta: 3, atTop: false, atEnd: true);
      expect(s.visible, isTrue);
      s.onScroll(delta: 40, atTop: false, atEnd: false);
      s.onScroll(delta: 0, atTop: true, atEnd: false);
      expect(s.visible, isTrue);
    });
    test('upward scroll resets the accumulator', () {
      final s = BarScrollState()
        ..onScroll(delta: 20, atTop: false, atEnd: false)
        ..onScroll(delta: -2, atTop: false, atEnd: false)
        ..onScroll(delta: 20, atTop: false, atEnd: false);
      expect(s.visible, isTrue);
    });
    test('reset shows', () {
      final s = BarScrollState()..onScroll(delta: 40, atTop: false, atEnd: false);
      s.reset();
      expect(s.visible, isTrue);
    });
  });

  Widget bar({int selected = 0, bool visible = true, ValueChanged<int>? onSelect}) => MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            FloatingTabBar(
              selected: selected,
              visible: visible,
              onSelect: onSelect ?? (_) {},
              items: const [
                FloatingTabItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded,
                    label: 'AI Study', color: Color(0xFF8B5CF6)),
                FloatingTabItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded,
                    label: 'Community', color: Color(0xFF00BFA5)),
              ],
            ),
          ]),
        ),
      );

  testWidgets('active tab draws its name, inactive does not', (t) async {
    await t.pumpWidget(bar());
    expect(find.text('AI Study'), findsOneWidget);
    expect(find.text('Community'), findsNothing);
    expect(find.bySemanticsLabel('Community'), findsOneWidget);
  });

  testWidgets('hidden bar slides off screen', (t) async {
    await t.pumpWidget(bar(visible: false));
    await t.pumpAndSettle();
    final rect = t.getRect(find.byType(FloatingTabBar));
    expect(rect.top, greaterThanOrEqualTo(t.view.physicalSize.height / t.view.devicePixelRatio));
  });

  testWidgets('keyboard open hides the bar', (t) async {
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(t.view.resetViewInsets);
    await t.pumpWidget(bar());
    await t.pumpAndSettle();
    expect(find.text('AI Study').hitTestable(), findsNothing);
  });
}
```

Run → FAIL.

- [ ] **Step 2: Implement** in `floating_tab_bar.dart` (keep `clearance` from Task 7):

```dart
class BarScrollState {
  static const double hideAfter = 24;
  bool _visible = true;
  double _down = 0;

  bool get visible => _visible;

  void onScroll({required double delta, required bool atTop, required bool atEnd}) {
    if (atTop || atEnd || delta < 0) {
      _down = 0;
      _visible = true;
      return;
    }
    _down += delta;
    if (_down > hideAfter) _visible = false;
  }

  void reset() {
    _down = 0;
    _visible = true;
  }
}

/// Re-tapping the active tab bumps [seq]; a tab with a list scrolls to top.
final tabReselectProvider =
    StateProvider<({int tab, int seq})>((ref) => (tab: -1, seq: 0));
```

`FloatingTabBar` widget: `Positioned(left: 0, right: 0, bottom: gap)` where `gap` = same formula as `clearance` minus `height + _breathing`; wrap in `AnimatedSlide(offset: hidden ? Offset(0, 2) : Offset.zero, duration: 200ms, curve: Curves.easeOutCubic)` with `hidden = !visible || MediaQuery.viewInsetsOf(context).bottom > 0`; and `IgnorePointer(ignoring: hidden)`. Inside: the existing glass pill (copy decoration from `TabBarMenu.dart` lines 327–360, radius 28, `height: 56`). Items: `Semantics(selected:, button: true, label: item.label)` → `GestureDetector(onTap: () => onSelect(i))` → `AnimatedContainer(duration: 220ms, curve: Curves.easeOutCubic, height: 44, padding: selected ? EdgeInsets.symmetric(horizontal: 14) : EdgeInsets.zero, constraints: BoxConstraints(minWidth: 48), decoration: BoxDecoration(color: selected ? item.color.withValues(alpha: dark ? 0.20 : 0.14) : transparent, borderRadius: 22))` → `Row(mainAxisSize: min)`: icon (size 24; avatar/image variants copied from the old `_buildNavItem`), then when selected `SizedBox(width: 6)` + `Text(item.label, style: textTheme.labelLarge.copyWith(fontWeight: w700, color: _darken(item.color, dark)))` and, when `badgeCount > 0`, the count pill after the label; when not selected the red count badge stays on the icon (copy the old `Positioned(right: -7, top: -4)` pill, raising its `fontSize: 9.5` to the theme `labelSmall`). `_darken(c, dark)` = `dark ? Color.lerp(c, Colors.white, 0.35)! : Color.lerp(c, Colors.black, 0.35)!` (≥4.5:1 on the 14 % fill — verify the five tab colours with a quick contrast calc in the test file as a unit test of `_darken` exposed as `@visibleForTesting tabLabelColor`).

`find.bySemanticsLabel('Community')` needs `excludeSemantics: true` on the item's `Semantics` so the icon's own semantics don't merge oddly.

- [ ] **Step 3: Wire into `TabBarMenu.dart`.**
  - Add `final BarScrollState _barScroll = BarScrollState(); bool _barVisible = true;`
  - Wrap the page `Stack` in

```dart
NotificationListener<ScrollUpdateNotification>(
  onNotification: (n) {
    if (n.metrics.axis != Axis.vertical || n.dragDetails == null && n.scrollDelta == null) return false;
    _barScroll.onScroll(
      delta: n.scrollDelta ?? 0,
      atTop: n.metrics.pixels <= n.metrics.minScrollExtent,
      atEnd: n.metrics.pixels >= n.metrics.maxScrollExtent,
    );
    if (_barScroll.visible != _barVisible) setState(() => _barVisible = _barScroll.visible);
    return false;
  },
  child: <existing Stack>,
)
```

  - Replace the inline `Positioned(... bar ...)` with `FloatingTabBar(selected: selectedPageIndex, visible: _barVisible, onSelect: _selectPage, items: [...])` using labels `l.study`, `l.community`, `l.chats`, `l.moments`, `l.profile` (or the Task 2 fallbacks), the same icons/colours/badges as today (`_getTabColor` values move into the items).
  - In `_selectPage(index)`: if `index == ref.read(selectedTabProvider)` → `ref.read(tabReselectProvider.notifier).state = (tab: index, seq: prev.seq + 1)`; always `_barScroll.reset(); setState(() => _barVisible = true);`. Keep `_tabRefreshNotifier.value++` (Chats still uses it).
  - Delete `_buildNavItem` and `_getTabColor`.
- [ ] **Step 4: Reselect in the hub** — in `StudyHub` build: `ref.listen(tabReselectProvider, (_, next) { if (next.tab == 0 && _scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); });`. Add a widget test in `study_hub_test.dart`: scroll down 600, set the provider to `(tab: 0, seq: 1)`, `pumpAndSettle`, expect `_scroll.offset == 0` (expose via `find.byType(CustomScrollView)` → `Scrollable.of` position pixels).
- [ ] **Step 5: Run** — `flutter test test/widgets/navigation test/learning/study_hub_test.dart` PASS; run the existing tab tests too: `grep -rln "TabsScreen\|selectedTabProvider" test | xargs flutter test`.
- [ ] **Step 6: Commit**

```bash
git add lib/widgets/navigation/floating_tab_bar.dart lib/pages/menu_tab/TabBarMenu.dart lib/pages/learning/main/study_hub.dart test/widgets/navigation test/learning/study_hub_test.dart docs/REMAINING_WORK.md
git commit -m "feat(tab-bar): active capsule with name, hide on scroll and keyboard, reselect to top

Open: coffee removal + shared clearance, device QA."
```

---

### Task 9: Coffee button out, Support row in, shared bottom clearance everywhere

**Files:**
- Create: `lib/pages/profile/support/support_sheet.dart` (move `_SupportSheet` + `_SupportSheetState` from `TabBarMenu.dart` ~lines 694–954, rename `SupportSheet`, add `static Future<void> show(BuildContext context)`)
- Modify: `lib/pages/menu_tab/TabBarMenu.dart` (delete `_CoffeeButton` ~564–693, its `Positioned` ~316–320, `_SupportSheet`; drop unused imports e.g. `url_launcher`, `ad_service` if no longer used)
- Modify: `lib/pages/profile/drawer/profile_drawer.dart` (Support section ~line 406: add a `DrawerMenuItem` after Help Center)
- Modify bottom padding literals:
  - `lib/pages/learning/main/sections/learn_tab.dart:53`, `ai_tools_tab.dart:96` (legacy hub — still shipped while the flag is off), `ai_tools_tab.dart:168` (`_showArrow` hint, `bottom: 110` → `FloatingTabBar.clearance(context) + 10`)
  - `lib/pages/chat/list/chat_list_screen.dart:1191`, `:1454` (refresh button → `FloatingTabBar.clearance(context)`)
  - `lib/pages/moments/feed/moments_feed_widget.dart:97`
  - `lib/pages/community/tabs/genders_tab.dart:569`, `topics_tab.dart:181`, `city_tab.dart:902`, `partner_discovery_tab.dart:751`, `:830`
  - Re-grep first: `grep -rnE "EdgeInsets[^;]*\b(88|90|96|100|110|120)\)|bottom: ?(88|90|96|100|110|120)\b" lib/pages/learning/main lib/pages/community lib/pages/chat/list lib/pages/moments lib/pages/profile` and include anything new.
- Create: `test/widgets/navigation/no_bottom_literal_test.dart`, `test/profile/support_row_test.dart`

**Interfaces:**
- Consumes: `FloatingTabBar.clearance(context)` (Task 7/8).
- Produces: `SupportSheet.show(BuildContext)`.

- [ ] **Step 1: Failing static test** — `test/widgets/navigation/no_bottom_literal_test.dart`

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Spec §8.2: tab pages clear the floating bar with FloatingTabBar.clearance,
/// never a guessed literal (the bar's height changed; the 100s did not).
void main() {
  const dirs = [
    'lib/pages/learning/main',
    'lib/pages/community',
    'lib/pages/chat/list',
    'lib/pages/moments/feed',
    'lib/pages/profile',
  ];
  final literal = RegExp(r'(bottom:\s*(88|90|96|100|110|120)\b)|(EdgeInsets\.fromLTRB\([^)]*,\s*(88|90|96|100|110|120)\))');

  test('no tab page keeps a bottom clearance literal', () {
    final hits = <String>[];
    for (final d in dirs) {
      for (final f in Directory(d).listSync(recursive: true).whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (literal.hasMatch(lines[i])) hits.add('${f.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('the coffee button is gone', () {
    expect(File('lib/pages/menu_tab/TabBarMenu.dart').readAsStringSync().contains('_CoffeeButton'),
        isFalse);
  });
}
```

Run → FAIL (lists every literal). If a hit is not tab-bar clearance (e.g. a dialog's internal padding in `lib/pages/profile`), narrow `dirs` to the specific files rather than weakening the regex, and say why in a comment.

- [ ] **Step 2: Move the sheet** — cut `_SupportSheet`/`_SupportSheetState` to `support_sheet.dart` unchanged except the rename and:

```dart
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SupportSheet(),
      );
```

Copy the `showModalBottomSheet` arguments from `_CoffeeButtonState` (~line 605) exactly so it looks the same.

- [ ] **Step 3: Drawer row** — after the Help Center item + `DrawerDivider()`:

```dart
                      DrawerMenuItem(
                        icon: Icons.local_cafe_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: l10n.supportBananaTalkRow,
                        subtitle: l10n.supportBananaTalkRowSubtitle,
                        onTap: () {
                          Navigator.pop(context);
                          SupportSheet.show(context);
                        },
                      ),
                      const DrawerDivider(),
```

`Navigator.pop(context)` closes the drawer first; if `context` is the drawer's own (deactivated after pop), capture `final rootContext = Navigator.of(context, rootNavigator: true).context;` before popping and call `SupportSheet.show(rootContext)` — check how the Help Center row's `_showHelpCenterDialog(context)` handles it and copy that.

`test/profile/support_row_test.dart`: pump `ProfileDrawer` (see existing tests under `test/profile` for its harness), tap "Support BananaTalk", `pumpAndSettle`, expect the sheet's `supportSheetDonateButton` text ("Donate via PayPal") on screen.

- [ ] **Step 4: Remove the coffee button and replace the literals** with `FloatingTabBar.clearance(context)` (drop `const` on the enclosing `EdgeInsets`; e.g. `EdgeInsets.fromLTRB(16, 20, 16, FloatingTabBar.clearance(context))`, `EdgeInsets.only(bottom: FloatingTabBar.clearance(context))`). Where the literal sits in a method without `context`, pass it in or read it in `build` into a local.

- [ ] **Step 5: Run** — `flutter test test/widgets/navigation test/profile test/community test/chat test/moments test/learning` PASS; `flutter analyze` clean (unused imports in `TabBarMenu.dart`).

- [ ] **Step 6: Commit**

```bash
git add -A lib/pages lib/widgets/navigation test/widgets/navigation test/profile docs/REMAINING_WORK.md
git commit -m "feat(tab-bar): coffee button moves to Profile > Support; tab pages share the bar clearance

Open: device QA (light/dark, SE width, text 1.3, ko + ar RTL), baseline prod queries, backend deploy, native review."
```

---

### Task 10: QA sheet, remaining-work wrap-up, full suite

**Files:**
- Create: `docs/qa/study-hub-matrix.md`
- Modify: `docs/REMAINING_WORK.md`, `docs/superpowers/specs/2026-10-13-ai-study-hub-and-tab-bar-design.md` (§9 note on `method: vip`)

- [ ] **Step 1: QA matrix** — `docs/qa/study-hub-matrix.md`, one row per check with an empty result column: flag off = old screen; flag on = hub; light/dark; iPhone SE (320 pt) no overflow; text scale 1.3; Korean; Arabic (RTL — badges on the leading side of the trailing edge, chevrons mirrored); exhausted tutor tile → sheet → coin unlock → opens tutor; locked tile with `STUDY_VIP_ONLY_FEATURES=photo` on a dev server; NEW badges max 3 and clear on tap; second account on same device sees its own NEW badges; guide "See all features" scrolls; carousel hidden during guide, dismiss persists; tab bar hides on scroll down in every tab, shows on scroll up/top/end, hidden with keyboard in Chats search, re-tap AI Study scrolls to top; Support row opens the sheet; nothing floats over content.
- [ ] **Step 2: Full suite** — `flutter test` (whole app). Expected: same pass/fail set as `main` plus the new tests passing. If any pre-existing failure appears, compare against `git stash; flutter test <file>; git stash pop` on `main` before touching it, and record it in the summary rather than "fixing" unrelated tests.
- [ ] **Step 3: REMAINING_WORK.md** — in "AI Study hub + floating tab bar": tick Implementation; keep open: backend deploy of Task 1 (owner), baseline prod queries (before turning the flag on), device QA rows (link `docs/qa/study-hub-matrix.md`), native review of the new strings, delete `LearnTab`/`AIToolsTab`/`LegacyStudyHub`/`practice_entries.dart`/`study_hub_tabs.dart` once the flag has been on for a full release, per-tab announcement targeting (later). Add under §2 Owner: "set `STUDY_HUB_ENABLED=true` after 2.8.0 is live and QA passed".
- [ ] **Step 4: Commit**

```bash
git add docs/qa/study-hub-matrix.md docs/REMAINING_WORK.md docs/superpowers/specs/2026-10-13-ai-study-hub-and-tab-bar-design.md
git commit -m "docs: study hub QA matrix and remaining work

Open: backend deploy, baseline queries, device QA, native review, flag flip, legacy deletion."
```

Merging `feat/ai-study-hub` to `main`, version bump, and release are owner gates — stop here and report.
