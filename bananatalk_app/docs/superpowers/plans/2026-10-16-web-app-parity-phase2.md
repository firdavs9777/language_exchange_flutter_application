# Web ↔ App Parity — Phase 2 (app) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app opens every banatalk.com link the website and the app now produce (story, chat, profile QR, invites), draws stickers on text stories, carries the unmerged moments/stories audit branch, and no longer loses invite codes on a fresh install.

**Architecture:** All changes are client-side and ship with 2.7.0 (not built yet, so nothing here is live on push). Link handling stays in one place: `lib/services/deep_link_parser.dart` (pure) → `DeepLinkGate` → GoRouter. Flutter's own deep linking is switched off so only that path runs. The AASA (web repo, live) is **not** changed in this phase.

**Tech Stack:** Flutter 3.38 / Dart 3.10, Riverpod, go_router 14, app_links 6, mobile_scanner 6, qr_flutter 4, shared_preferences, `play_install_referrer` (new, Android only), flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-16-web-app-parity-design.md` §3 Phase 2; audits `docs/audits/2026-10-16-web-parity/links.md` (#1, #6, #7, #8, #10) and `moments.md` (#1, #3, #6, #7). Master plan: `docs/superpowers/plans/2026-10-16-web-app-parity.md`.

## Global Constraints

- Repo: app integration worktree `/Users/davis/Desktop/Personal/bt-integration` (branch `main`, at `8e35537e` when this plan was written). The Flutter project is `bananatalk_app/` inside it; run every `flutter` command from `/Users/davis/Desktop/Personal/bt-integration/bananatalk_app`. The branch to merge, `fix/moments-stories-audit` (`9ac04080`), lives in the same repository (the main checkout `/Users/davis/Desktop/Personal/language_exchange_flutter_application` is another worktree of it), so it is mergeable from `bt-integration` directly.
- Imports are `package:bananatalk_app/...` in `lib/` (linter enforces). Tests may import `test/helpers` relatively (existing practice).
- Every user-visible string is an ARB key in all 19 locales (`lib/l10n/app_*.arb`), regenerated with `flutter gen-l10n`, and registered in `test/l10n/hardcoded_strings_test.dart` (`_keysByTask`; new files under `_filesByTask`). New rows also go to `docs/l10n/native-qa-strings-2026-10.csv` for native review.
- `flutter analyze` ends with 0 errors and 0 warnings (infos allowed, none new in touched files).
- Every commit updates `bananatalk_app/docs/REMAINING_WORK.md` (ticks the task's line, adds new open items) and lists still-open items in the commit body. **No `Co-Authored-By` / AI attribution** in any commit.
- The AASA (`public/.well-known/apple-app-site-association`, web repo) is NOT touched here. `/story/*` and `/chat/*` are claimed on iOS only in Phase 5, once 2.7.0 is most of the iOS base.
- Do not push until the phase gate (P2-9). An app push does not deploy anything; it only lands on `main` for the 2.7.0 build.
- Shared test id: `64b7f0c2a1b2c3d4e5f60718` (24 hex chars, a valid ObjectId shape).

## Review Focus

1. **Links while signed out.** `/story/<id>` and `/chat/<id>` reach `DeepLinkGate`, which holds them until the user is signed in and on the shell (`/home`, `/tabs/..`). The backend `GET /stories/:id` requires auth, so nothing loads before that anyway. An invite picked up from the Play referrer never overwrites a code from a tapped `/i/` link. P2-2 and P2-8 pin this.
2. **Cold start vs warm start, and double handling.** Today Flutter's built-in deep linking (on by default in 3.38) and `app_links` both see a link. After P2-5 only `app_links` → `DeepLinkGate` does. On a device, check that `/i/CODE` and `/moment/<id>` open exactly one screen from a cold start (after splash) and from a warm start, with no GoRouter error page. These are QA rows WEB-APP-01/02 (P2-9).
3. **Malformed and hostile input.** `https://banatalk.com/chat/<id>?call=video` must **not** start a call: the router's `/chat/:userId` honours `?call=` and `?prefill=`, but the parser rebuilds the path from type + id, so query strings never get through. Non-ObjectId ids for `story`/`chat`/legacy `user` are dropped. An expired, private or blocked story shows "Content not available", not a blank viewer. QR payloads like `https://banatalk.com/profile/edit` are refused. P2-2, P2-3 and P2-4 pin this.
4. **2.6.1 compatibility of the new links.** 2.6.1's parser drops `story`/`chat` and its manifest does not claim them, and the AASA is unchanged. So 2.6.1 users (and iOS 2.7.0 users until Phase 5) land on the web: `/story/:id` is a Phase 3 web route and must be live before 2.7.0 reaches users. A 2.7.0 profile QR (https) scanned with **2.6.1's in-app scanner** shows "Invalid QR code". This is an accepted gap: the system camera opens the https link (web, or the app where links verify). It is recorded in REMAINING_WORK.
5. **Merge correctness.** All 39 merge conflicts are l10n (19 ARBs, 19 generated `app_localizations*.dart`, 1 QA CSV). Two things can go wrong. First, the per-key ARB merge can lose main's ~260 new keys. Second, the auto-merged `story_viewer_screen.dart` carries the branch's `_pollFor` / `hasAnswered` / reaction state, and P2-6 must keep them. The branch also leaves `momentAnsweringPrompt` out of the l10n key registry, so `hardcoded_strings_test` fails unless P2-1 registers it.

## Execution order

Sequential, one worktree (`bt-integration`, `main`):
P2-1 (merge) → P2-2 (parser + manifest) → P2-3 (story link) → P2-4 (QR) → P2-5 (Flutter deep linking off) → P2-6 (text-story chrome; needs P2-1's viewer) → P2-7 (invite code entry) → P2-8 (install referrer) → P2-9 (gate).
P2-2 to P2-5 touch disjoint files apart from the parser, and P2-7/P2-8 share only `referral_service.dart` constants. They could run in parallel worktrees after P2-1 and P2-2, but the l10n registry and REMAINING_WORK would conflict, so keep them sequential.

---

### Task P2-1: Merge `fix/moments-stories-audit` into `main` (moments#6, #7)

The branch (16 commits + a merge of main at `fa02704b`) adds: prompt/promptId/location/isReel parsing on Moments and the prompt chip on card/detail (moments#6); scheduled time sent as UTC (`0adf71db`, moments#7); editing that can clear mood/tags/location; story toggles and stickers allowed on text stories in the composer; tolerance for unpopulated story refs; viewer poll vote/answer/reaction restored; web text-story colours; question responses only from the responses endpoint; privacy settings fixes; non-personalised ads; hidden VIP badge.

**Predicted conflicts** (`git merge-tree --write-tree main fix/moments-stories-audit`, 2026-10-16): **39 files, all l10n.**
- `lib/l10n/app_{ar,de,en,es,fr,hi,id,it,ja,ko,pt,ru,tg,th,tl,tr,vi,zh,zh_TW}.arb` (19). Both sides append at the end of the file: main adds ~262–309 keys per locale (auth lock/rate-limit, password errors, wallpaper names…), the branch adds exactly one, `momentAnsweringPrompt` (+ `@momentAnsweringPrompt` in en). A per-key 3-way check found **no key changed on both sides**. Resolution: 3-way per-key (theirs wins where it changed vs base). The result is main's file plus `momentAnsweringPrompt`.
- `lib/l10n/app_localizations.dart` + 18 `app_localizations_<locale>.dart` (19): generated, resolved by `flutter gen-l10n` from the merged ARBs.
- `docs/l10n/native-qa-strings-2026-10.csv` (1): main's block (`authLocked…` rows) vs the branch's 18 `momentAnsweringPrompt` rows. None of those rows is on main. Resolution: union (keep both sides).
- **Auto-merged, needs checking:** `docs/REMAINING_WORK.md`, `lib/main.dart`, `story_viewer_screen.dart`, `story_model.dart`, `create_moment.dart`, `moment_card.dart`, `single_moment.dart`, `privacy_edit.dart`, `settings.dart`, the community tabs/widgets, `auth_providers.dart`, `message_provider.dart`, `stories_service.dart`, `privacy_utils.dart` (27 files both sides touched). `test/l10n/hardcoded_strings_test.dart` does **not** conflict (the branch did not touch it), but the branch's new key is not registered anywhere, so the "every key added to app_en.arb since f3742650 is in a _keysByTask list" test fails after the merge. Step 5 adds it.

**Files:**
- Merge commit over the files above.
- Modify: `bananatalk_app/test/l10n/hardcoded_strings_test.dart` (register `momentAnsweringPrompt`).
- Modify: `bananatalk_app/docs/REMAINING_WORK.md`.

**Interfaces:**
- Consumes: refs `main` (`8e35537e`), `fix/moments-stories-audit` (`9ac04080`), merge base `fa02704b`.
- Produces on `main`: `Moments.prompt/promptId/location/isReel`; `StoryPoll.resolvedFor(String?)`, `StoryQuestionBox.hasAnsweredBy(String?)`, `Story.reactionOf(String?)`; `_StoryViewerScreenState._pollFor(Story)`, `_answeredStoryIds`, `_reactionOverrides`; `StoryQuestionBoxWidget.hasAnswered`; l10n key `momentAnsweringPrompt(String prompt)`.

- [ ] **Step 1: Start the merge**

```bash
cd /Users/davis/Desktop/Personal/bt-integration
git status --short                                   # expected: empty
git rev-parse --short main fix/moments-stories-audit # 8e35537e / 9ac04080 (if either moved, re-run merge-tree and re-check the list above)
git merge --no-ff --no-commit fix/moments-stories-audit
git diff --name-only --diff-filter=U | wc -l         # expected: 39
git diff --name-only --diff-filter=U | grep -v '/l10n/'   # expected: only bananatalk_app/docs/l10n/native-qa-strings-2026-10.csv
```

If any non-l10n file is in conflict, stop and resolve it by hand: keep both sides' intent, and check it against the branch commit's message.

- [ ] **Step 2: ARBs, 3-way per key (theirs wins where it changed vs base)**

Write the merge helper to a temp dir (not the repo):

```bash
P2TMP=$(mktemp -d)
cat > "$P2TMP/arb3way.py" <<'EOF'
"""3-way per-key ARB merge.
Start from ours (HEAD = main). Every key whose value in theirs differs from
base wins (added or edited on the branch). Keys the branch deleted (in base,
absent in theirs) are removed unless ours also edited them. Output keeps
ours' key order, appends theirs' new keys in theirs' order, and is
byte-identical to the repo's formatting (json.dumps indent=2 + newline was
verified to reproduce the ARBs exactly).
Usage (from bananatalk_app/): python3 -I arb3way.py <base> <ours> <theirs> <arb path>"""
import json, subprocess, sys
base_rev, ours_rev, theirs_rev, path = sys.argv[1:5]
def load(rev):
    try:
        return json.loads(subprocess.check_output(['git', 'show', f'{rev}:./{path}'], stderr=subprocess.DEVNULL))
    except subprocess.CalledProcessError:
        return {}
base, ours, theirs = load(base_rev), load(ours_rev), load(theirs_rev)
result = dict(ours)
for k, v in theirs.items():
    if base.get(k) != v:
        result[k] = v
for k in base:
    if k not in theirs and k in result and ours.get(k) == base[k]:
        del result[k]
with open(path, 'w', encoding='utf-8') as f:
    f.write(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
both = [k for k in theirs if base.get(k) != theirs[k] and ours.get(k) not in (base.get(k), theirs[k])]
print(path, 'theirs-wins:', sorted(k for k in theirs if base.get(k) != theirs[k]), 'CHANGED-ON-BOTH:' if both else '', both or '')
EOF
cd /Users/davis/Desktop/Personal/bt-integration/bananatalk_app
BASE=$(git merge-base HEAD MERGE_HEAD)               # fa02704b...
for f in lib/l10n/app_*.arb; do python3 -I "$P2TMP/arb3way.py" "$BASE" HEAD MERGE_HEAD "$f"; done
```

Expected: 19 lines, each `theirs-wins: ['momentAnsweringPrompt']` (en: `['@momentAnsweringPrompt', 'momentAnsweringPrompt']`), and no `CHANGED-ON-BOTH`. If a key is printed as changed on both sides, theirs has already won. Note the key in the commit body.

Verify:

```bash
grep -l '^<<<<<<<\|^>>>>>>>' lib/l10n/*.arb                  # expected: no output
python3 -I -c "import json,glob;[json.load(open(f,encoding='utf-8')) for f in glob.glob('lib/l10n/*.arb')];print('arb ok')"
for f in lib/l10n/app_*.arb; do echo "$(grep -c '"momentAnsweringPrompt"' $f) $f"; done | grep -v '^1 '   # expected: no output
for f in lib/l10n/app_*.arb; do git show HEAD:./$f | python3 -I -c "import json,sys;print(len(json.load(sys.stdin)))" | tr '\n' ' '; python3 -I -c "import json;print(len(json.load(open('$f',encoding='utf-8'))))"; done
# expected per line: "<n> <n+1>" (en: "<n> <n+2>") — main's keys all kept, one key (+meta) added
```

- [ ] **Step 3: QA CSV, union**

```bash
python3 -I - <<'EOF'
p = 'docs/l10n/native-qa-strings-2026-10.csv'
lines = open(p, encoding='utf-8').read().split('\n')
out = [l for l in lines if not (l.startswith('<<<<<<< ') or l == '=======' or l.startswith('>>>>>>> '))]
open(p, 'w', encoding='utf-8').write('\n'.join(out))
EOF
grep -c '^<<<<<<<\|^=======$\|^>>>>>>>' docs/l10n/native-qa-strings-2026-10.csv   # expected: 0
sort docs/l10n/native-qa-strings-2026-10.csv | uniq -d | head                     # expected: no output
grep -c ',momentAnsweringPrompt,' docs/l10n/native-qa-strings-2026-10.csv          # expected: 18
```

- [ ] **Step 4: Regenerate the generated localizations**

```bash
git checkout --ours -- lib/l10n/app_localizations.dart lib/l10n/app_localizations_*.dart
flutter gen-l10n
grep -c 'momentAnsweringPrompt' lib/l10n/app_localizations.dart        # expected: >= 2 (doc + getter)
grep -l '^<<<<<<<' lib/l10n/*.dart                                     # expected: no output
git add lib/l10n docs/l10n/native-qa-strings-2026-10.csv
git diff --name-only --diff-filter=U                                   # expected: no output
```

- [ ] **Step 5: Register the branch's key in the l10n registry**

In `test/l10n/hardcoded_strings_test.dart`, at the end of `_keysByTask` (the first map, which closes after `'communityFilterNew',`), replace:

```dart
    'communityWorldwide',
    'communitySearchTitle',
    'communityFilterNew',
  ],
};
```

with:

```dart
    'communityWorldwide',
    'communitySearchTitle',
    'communityFilterNew',
  ],
  // fix/moments-stories-audit (merged in web-parity Phase 2): prompt chip on
  // moment cards / detail / composer.
  'moments-stories-audit': [
    'momentAnsweringPrompt',
  ],
};
```

- [ ] **Step 6: Semantic checks on auto-merged files**

```bash
git show :./lib/pages/moments/create/create_moment.dart | grep -n "toUtc().toIso8601String()\|momentAnsweringPrompt"
#   expected: two scheduledFor lines with toUtc(), and momentAnsweringPromptOfDay + momentAnsweringPrompt(text)
grep -n "_pollFor\|_answeredStoryIds\|_reactionOverrides\|class _QuestionResponsesSheet" lib/pages/stories/viewer/story_viewer_screen.dart | head
grep -c "^## 4. Code work" docs/REMAINING_WORK.md                     # expected: 1
flutter analyze 2>&1 | tail -3
flutter analyze 2>&1 | grep -E "^\s*(error|warning) •" | wc -l       # expected: 0
```

If analyze reports errors, they are merge-integration bugs (for example main renamed something the branch uses). Fix them on top of the merge and stage the fix.

- [ ] **Step 7: Run the branch's tests, l10n tests, then the full suite**

```bash
flutter test test/ads/personalized_ads_test.dart test/moments/moment_prompt_label_test.dart \
  test/moments/moment_prompt_parsing_test.dart test/moments/moment_update_body_test.dart \
  test/settings/privacy_edit_initial_settings_test.dart test/settings/privacy_settings_update_test.dart \
  test/stories/question_responses_list_test.dart test/stories/story_background_parsing_test.dart \
  test/stories/story_unpopulated_refs_test.dart test/stories/story_viewer_state_test.dart \
  test/utils/privacy_vip_badge_test.dart
flutter test test/l10n/
flutter test 2>&1 | tail -5
```

Expected: all pass; the full suite ends with `All tests passed!`. Record the pass count. P2-9 compares against it.

- [ ] **Step 8: REMAINING_WORK**

In `docs/REMAINING_WORK.md` §4, under the `Web ↔ app parity` heading, replace the line
`- [ ] Phase 2: app — story/QR links, Flutter deep linking off, /chat links, text-story stickers, moments branch merge, invite code entry. M`
with:

```markdown
- [ ] Phase 2: app (plan `docs/superpowers/plans/2026-10-16-web-app-parity-phase2.md`). M
  - [x] P2-1 merge `fix/moments-stories-audit` (moments#6 prompt/location/isReel, moments#7 UTC scheduling) — 39 l10n conflicts, per-key ARB merge.
  - [ ] P2-2 parser + Android manifest learn `/story/`, `/chat/`, legacy `bananatalk://user/` (links#1, #6, #8).
  - [ ] P2-3 story share link `shareUrl('story', id)` + `/story/:id` screen (links#1, moments#1).
  - [ ] P2-4 profile QR encodes `https://banatalk.com/profile/<id>`; scanner accepts both (links#8).
  - [ ] P2-5 `FlutterDeepLinkingEnabled=false` / `flutter_deeplinking_enabled=false` (links#7).
  - [ ] P2-6 text stories draw poll/question/link/location, header and reply bar (moments#3).
  - [ ] P2-7 invite code manual entry for new accounts (links#10).
  - [ ] P2-8 Play Install Referrer pickup (links#10).
  - [ ] P2-9 phase gate: full suite, analyze, debug build, QA rows, push.
```

Also in §1 Status, add the bullet:
`- fix/moments-stories-audit merged into main (2026-10-16, web-parity P2-1); its device rows are in docs/audits/2026-10-16-web-parity/moments.md.`

- [ ] **Step 9: Commit the merge**

```bash
cd /Users/davis/Desktop/Personal/bt-integration
git add bananatalk_app/test/l10n/hardcoded_strings_test.dart bananatalk_app/docs/REMAINING_WORK.md
git commit -F - <<'EOF'
Merge fix/moments-stories-audit

Moments: prompt/promptId/location/isReel parsed and the prompt chip on
card and detail (moments#6); scheduled time sent as UTC (moments#7);
edits can clear mood, tags and location. Stories: toggles and stickers on
text stories in the composer, unpopulated refs tolerated, the viewer's
poll vote / answer / reaction restored, web text-story colours, question
responses from the responses endpoint only. Privacy settings always saved
whole, non-personalised ads on opt-out, hidden VIP badge.

Conflicts were all l10n: 19 ARBs merged per key (main's keys kept, the
branch's momentAnsweringPrompt added), generated localizations rebuilt
with flutter gen-l10n, QA CSV rows unioned. momentAnsweringPrompt is
registered in the l10n key registry.

Still open (docs/REMAINING_WORK.md, Web <-> app parity Phase 2):
- P2-2..P2-8: story/chat link parsing, story share link + screen, https
  profile QR, Flutter deep linking off, text-story stickers, invite code
  entry, Play Install Referrer
- P2-9: phase gate and push; 2.7.0 still not built
EOF
git log --oneline -1
```

---

### Task P2-2: The parser and Android manifest learn `story`, `chat` and the legacy `user` QR (links#1, #6, #8)

**Files:**
- Modify: `bananatalk_app/lib/services/deep_link_parser.dart` (whole file below).
- Modify: `bananatalk_app/android/app/src/main/AndroidManifest.xml` (App Links filter).
- Modify: `bananatalk_app/test/android/android_release_config_test.dart` (App Links group).
- Test (new): `bananatalk_app/test/services/deep_link_parser_links_test.dart`.

**Interfaces:**
- Produces:
  - `String? routePathFromUri(Uri uri)` (unchanged signature) now also returns `/story/<oid>`, `/chat/<oid>`, and `/profile/<oid>` for `bananatalk://user/<oid>`.
  - `bool isObjectId(String id)`.
  - `String? normalizeInviteCode(String? raw)`: trimmed and upper-cased, or null unless it matches `^[A-Z2-7]{4,16}$`.
  - `String? userIdFromQrPayload(String raw)`: the profile user id from any accepted QR payload.
- Consumes: GoRouter routes `/chat/:userId` (exists, `lib/router/app_router.dart:212`), `/story/:storyId` (added in P2-3).

- [ ] **Step 1: Write the failing test** `test/services/deep_link_parser_links_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';

const kId = '64b7f0c2a1b2c3d4e5f60718';
String? p(String s) => routePathFromUri(Uri.parse(s));

void main() {
  group('story links (links#1)', () {
    test('https and custom scheme', () {
      expect(p('https://banatalk.com/story/$kId'), '/story/$kId');
      expect(p('bananatalk://story/$kId'), '/story/$kId');
    });
    test('malformed ids are dropped', () {
      for (final bad in [
        'abc',
        '64b7f0c2a1b2c3d4e5f6071',
        '64b7f0c2a1b2c3d4e5f60718x',
        'zzzzzzzzzzzzzzzzzzzzzzzz',
      ]) {
        expect(p('https://banatalk.com/story/$bad'), isNull, reason: bad);
      }
      expect(p('https://banatalk.com/story/'), isNull);
    });
    test('the parked domain and www are not ours', () {
      expect(p('https://bananatalk.com/story/$kId'), isNull);
      expect(p('https://www.banatalk.com/story/$kId'), isNull);
    });
  });

  group('chat links (links#6)', () {
    test('open the chat with that user', () {
      expect(p('https://banatalk.com/chat/$kId'), '/chat/$kId');
      expect(p('bananatalk://chat/$kId'), '/chat/$kId');
    });
    test('query parameters never reach the route (no auto-call, no prefill)', () {
      expect(p('https://banatalk.com/chat/$kId?call=video&prefill=hi'), '/chat/$kId');
      expect(p('bananatalk://chat/$kId?call=audio'), '/chat/$kId');
    });
    test('malformed ids and the bare /chat page are dropped', () {
      expect(p('https://banatalk.com/chat/settings'), isNull);
      expect(p('https://banatalk.com/chat'), isNull);
    });
  });

  group('legacy profile QR bananatalk://user/<id> (links#8)', () {
    test('opens the profile', () {
      expect(p('bananatalk://user/$kId'), '/profile/$kId');
    });
    test('only as the custom scheme, only with a real id', () {
      expect(p('https://banatalk.com/user/$kId'), isNull);
      expect(p('bananatalk://user/abc'), isNull);
    });
  });

  group('userIdFromQrPayload', () {
    test('accepts the https profile link and both scheme forms', () {
      expect(userIdFromQrPayload('https://banatalk.com/profile/$kId'), kId);
      expect(userIdFromQrPayload('bananatalk://user/$kId'), kId);
      expect(userIdFromQrPayload('  bananatalk://profile/$kId  '), kId);
    });
    test('rejects everything else', () {
      for (final raw in [
        'https://banatalk.com/moment/$kId',
        'https://banatalk.com/profile/edit',
        'https://banatalk.com/profile/stats',
        'https://evil.com/profile/$kId',
        'bananatalk://user/',
        'hello',
        '',
      ]) {
        expect(userIdFromQrPayload(raw), isNull, reason: raw);
      }
    });
  });

  group('normalizeInviteCode', () {
    test('upper-cases and trims', () {
      expect(normalizeInviteCode('abcd2345'), 'ABCD2345');
      expect(normalizeInviteCode(' ABCD2345 '), 'ABCD2345');
    });
    test('rejects non-codes', () {
      for (final bad in [null, '', 'ABC', 'ABCD1890', 'ABCD-2345', 'A' * 17]) {
        expect(normalizeInviteCode(bad), isNull, reason: '$bad');
      }
    });
  });

  test('existing link shapes are unchanged (2.6.1 links keep working)', () {
    expect(p('https://banatalk.com/moment/123'), '/moment/123');
    expect(p('bananatalk://profile/u9'), '/profile/u9');
    expect(p('https://banatalk.com/community/c1'), '/community/c1');
    expect(p('https://banatalk.com/community/waves'), '/community/waves');
    expect(p('https://banatalk.com/i/abcd2345'), '/invite/ABCD2345');
    expect(p('https://banatalk.com/settings'), isNull);
  });
}
```

- [ ] **Step 2: Run it; it fails**

Run: `flutter test test/services/deep_link_parser_links_test.dart`
Expected: compile error (`userIdFromQrPayload`, `normalizeInviteCode` undefined).

- [ ] **Step 3: Replace `lib/services/deep_link_parser.dart`**

```dart
/// Pure parsing logic for incoming deep links. Deliberately has no
/// dependency on `app_links` or any Flutter binding so it can be unit
/// tested without plugins.
///
/// Supports:
///   - Universal links: https://banatalk.com/<type>/<id>
///   - Custom scheme:   bananatalk://<type>/<id>
///   - Old profile QR codes: bananatalk://user/<id>
///
/// Returns the app route path (e.g. `/moment/123`) or `null` if the URI
/// doesn't match a supported deep link shape. The path is rebuilt from the
/// type and id only: query strings never reach the router (so a link can't
/// add `/chat/<id>?call=video`).
const _allowed = {'moment', 'profile', 'community', 'story', 'chat'};

/// Types added in 2.7.0 whose id must be a Mongo ObjectId: a malformed id
/// would otherwise open a screen that fetches it and fails.
const _objectIdTypes = {'story', 'chat'};

final _objectId = RegExp(r'^[0-9a-fA-F]{24}$');

final _inviteCode = RegExp(r'^[A-Z2-7]{4,16}$');

bool isObjectId(String id) => _objectId.hasMatch(id);

/// An invite code as the backend issues it (8 chars of A-Z2-7, see the
/// backend's lib/referralCode.js), or null.
String? normalizeInviteCode(String? raw) {
  if (raw == null) return null;
  final code = raw.trim().toUpperCase();
  return _inviteCode.hasMatch(code) ? code : null;
}

String? routePathFromUri(Uri uri) {
  final isHttps = uri.scheme == 'https' && uri.host == 'banatalk.com';
  final isScheme = uri.scheme == 'bananatalk';
  if (!isHttps && !isScheme) return null;

  // https://banatalk.com/<type>/<id>  → segments [type, id]
  // bananatalk://<type>/<id>          → host=type, segments=[id]
  String? type;
  String? id;
  if (isScheme) {
    type = uri.host;
    id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  } else {
    if (uri.pathSegments.length >= 2) {
      type = uri.pathSegments[0];
      id = uri.pathSegments[1];
    }
  }
  if (type == 'community' && (id == 'matches' || id == 'waves')) {
    return '/community/$id';
  }
  if (type == null || id == null || id.isEmpty) return null;
  if (type == 'i') {
    final code = normalizeInviteCode(id);
    return code == null ? null : '/invite/$code';
  }
  // Profile QR codes made before 2.7.0 encode bananatalk://user/<id>; the
  // system camera hands them to the app like any other link.
  if (isScheme && type == 'user') {
    return isObjectId(id) ? '/profile/$id' : null;
  }
  if (!_allowed.contains(type)) return null;
  if (_objectIdTypes.contains(type) && !isObjectId(id)) return null;
  return '/$type/$id';
}

/// The user id in a scanned profile QR code: the https profile link (2.7.0+)
/// or the old `bananatalk://user/<id>`, or null for anything else.
String? userIdFromQrPayload(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  final path = routePathFromUri(uri);
  if (path == null || !path.startsWith('/profile/')) return null;
  final id = path.substring('/profile/'.length);
  return isObjectId(id) ? id : null;
}
```

- [ ] **Step 4: Android manifest claims `/story/` and `/chat/`**

In `android/app/src/main/AndroidManifest.xml`, inside the `android:autoVerify="true"` intent-filter, replace:

```xml
                <data android:pathPrefix="/community/" />
                <data android:pathPrefix="/i/" />
```

with:

```xml
                <data android:pathPrefix="/community/" />
                <data android:pathPrefix="/story/" />
                <data android:pathPrefix="/chat/" />
                <data android:pathPrefix="/i/" />
```

- [ ] **Step 5: Keep the manifest test in sync**

In `test/android/android_release_config_test.dart`, group `App Links (https://banatalk.com)`, replace the two tests:

```dart
    test('every claimed prefix is a route the app handles', () {
      for (final p in prefixes) {
        final uri = Uri.parse('https://banatalk.com${p}ABCDEFGH');
        expect(routePathFromUri(uri), isNotNull, reason: p);
      }
    });

    test('every link shape the app handles is claimed', () {
      for (final path in ['/moment/123', '/profile/u1', '/community/matches', '/community/waves', '/i/ABCDEFGH']) {
```

with:

```dart
    test('every claimed prefix is a route the app handles', () {
      // story/chat ids must be ObjectIds; invite codes are A-Z2-7.
      for (final p in prefixes) {
        final id = p == '/i/' ? 'ABCDEFGH' : '64b7f0c2a1b2c3d4e5f60718';
        final uri = Uri.parse('https://banatalk.com$p$id');
        expect(routePathFromUri(uri), isNotNull, reason: p);
      }
    });

    test('every link shape the app handles is claimed', () {
      for (final path in [
        '/moment/123',
        '/profile/u1',
        '/community/matches',
        '/community/waves',
        '/story/64b7f0c2a1b2c3d4e5f60718',
        '/chat/64b7f0c2a1b2c3d4e5f60718',
        '/i/ABCDEFGH',
      ]) {
```

In the next test (`legal pages and the web home stay in the browser`), add `'/stories/abc'` (the web's per-user stories page) to the list:

```dart
      for (final path in ['/', '/privacy-policy', '/terms-of-use', '/moments/123', '/delete-account', '/stories/abc']) {
```

- [ ] **Step 6: Run the tests**

```bash
flutter test test/services/deep_link_parser_links_test.dart test/deep_link_parser_test.dart \
  test/share_url_test.dart test/android/android_release_config_test.dart \
  test/growth/referral_link_test.dart test/growth/lifecycle_links_test.dart test/services/deep_link_gate_test.dart
```
Expected: all pass.

- [ ] **Step 7: REMAINING_WORK + commit**

Tick `P2-2` and add under §4 `Web ↔ app parity`:
`- [ ] (app, links#15) Parser still accepts any id for /profile/ and /community/ (so /profile/edit, /profile/stats open a broken profile once App Links verify); add the ObjectId check there too after checking 2.6.1 share links only ever carry ObjectIds. S`

```bash
cd /Users/davis/Desktop/Personal/bt-integration
git add bananatalk_app/lib/services/deep_link_parser.dart bananatalk_app/android/app/src/main/AndroidManifest.xml \
  bananatalk_app/test/services/deep_link_parser_links_test.dart bananatalk_app/test/android/android_release_config_test.dart \
  bananatalk_app/docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(links): open /story/ and /chat/ links and old bananatalk://user QR codes

The parser now routes https://banatalk.com/story/<id> and /chat/<id>
(ObjectId ids only) and the Android App Links filter claims both. Old
profile QR codes (bananatalk://user/<id>) open the profile when scanned
with the system camera. Query strings still never reach the router, so a
link cannot add ?call= or ?prefill= to a chat. The AASA is unchanged
(iOS claims /story and /chat in Phase 5).

Still open (docs/REMAINING_WORK.md, Web <-> app parity Phase 2):
- P2-3..P2-9 (story link screen, QR, Flutter deep linking off, text-story
  stickers, invite code entry, install referrer, gate)
- ObjectId check for /profile/ and /community/ ids (links#15)
EOF
```

---

### Task P2-3: Story share link and the `/story/:id` screen (links#1, moments#1)

**Files:**
- Modify: `bananatalk_app/lib/pages/stories/viewer/story_viewer_screen.dart` (`_shareStory`, ~line 732 after P2-1).
- Create: `bananatalk_app/lib/pages/stories/viewer/story_link_screen.dart`.
- Modify: `bananatalk_app/lib/router/app_router.dart` (new route after `/moment/:momentId`).
- Modify: `bananatalk_app/test/l10n/hardcoded_strings_test.dart` (`_filesByTask`).
- Test (new): `bananatalk_app/test/stories/story_share_link_test.dart`.

**Interfaces:**
- Consumes: `shareUrl(String type, String id)` (`lib/services/link_constants.dart`); `StoriesService.getStory({required String storyId}) → Future<SingleStoryResponse>` (`success`, `data: Story?`, `blocked`). The backend `GET /stories/:id` 404s expired or inactive stories and runs the block + privacy-tier check (`storyAccessError`); it needs auth.
- Produces: `typedef StoryLoader = Future<SingleStoryResponse> Function({required String storyId});`, `class StoryLinkScreen({required String storyId, StoryLoader load = StoriesService.getStory})`; GoRoute `/story/:storyId`.

- [ ] **Step 1: Failing test** `test/stories/story_share_link_test.dart`

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_link_screen.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';
import 'package:bananatalk_app/services/link_constants.dart';

import '../helpers/community_fixture.dart';

const kId = '64b7f0c2a1b2c3d4e5f60718';

Widget _host(Widget child) => ProviderScope(
      overrides: [userProvider.overrideWith((ref) async => communityFixture())],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

Story _textStory({String userId = 'me'}) => Story.fromJson({
      '_id': kId,
      'user': {'_id': userId, 'name': 'Ana'},
      'mediaType': 'text',
      'text': 'Hello',
      'backgroundColor': '#336699',
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(hours: 20)).toIso8601String(),
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the viewer shares https://banatalk.com/story/<id>, which the app opens', () {
    final src = File('lib/pages/stories/viewer/story_viewer_screen.dart').readAsStringSync();
    expect(src, contains("shareUrl('story', story.id)"));
    expect(src, isNot(contains('bananatalk.com/story')));
    expect(shareUrl('story', kId), 'https://banatalk.com/story/$kId');
    expect(routePathFromUri(Uri.parse(shareUrl('story', kId))), '/story/$kId');
    expect(File('lib/router/app_router.dart').readAsStringSync(), contains("path: '/story/:storyId'"));
  });

  test('no link to the parked bananatalk.com domain anywhere in lib/', () {
    final hits = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('https://bananatalk.com'))
        .map((f) => f.path)
        .toList();
    expect(hits, isEmpty);
  });

  testWidgets('a story that cannot be loaded shows Content not available', (tester) async {
    String? asked;
    await tester.pumpWidget(_host(StoryLinkScreen(
      storyId: kId,
      load: ({required storyId}) async {
        asked = storyId;
        return SingleStoryResponse(success: false, error: 'Story is no longer available');
      },
    )));
    await tester.pump();
    await tester.pump();
    expect(asked, kId);
    expect(find.text('Content not available'), findsOneWidget);
    expect(find.byType(StoryViewerScreen), findsNothing);
  });

  testWidgets('a blocked story shows Content not available', (tester) async {
    await tester.pumpWidget(_host(StoryLinkScreen(
      storyId: kId,
      load: ({required storyId}) async => SingleStoryResponse(success: false, blocked: true),
    )));
    await tester.pump();
    await tester.pump();
    expect(find.text('Content not available'), findsOneWidget);
  });

  testWidgets('a loaded story plays in the story viewer', (tester) async {
    await tester.pumpWidget(_host(StoryLinkScreen(
      storyId: kId,
      load: ({required storyId}) async => SingleStoryResponse(success: true, data: _textStory()),
    )));
    await tester.pump();
    await tester.pump();
    expect(find.byType(StoryViewerScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // dispose the viewer (timers, system UI)
  });
}
```

- [ ] **Step 2: Run it; it fails**

Run: `flutter test test/stories/story_share_link_test.dart`
Expected: compile error (`story_link_screen.dart` missing).

- [ ] **Step 3: Share via `shareUrl`**

In `story_viewer_screen.dart` add the import (with the other `package:bananatalk_app/services/` imports):

```dart
import 'package:bananatalk_app/services/link_constants.dart';
```

and in `_shareStory()` replace:

```dart
    final shareText =
        'Check out $userName\'s story on Bananatalk!$storyText\n\nhttps://bananatalk.com/story/${story.id}';
```

with:

```dart
    final shareText =
        'Check out $userName\'s story on Bananatalk!$storyText\n\n${shareUrl('story', story.id)}';
```

- [ ] **Step 4: Create `lib/pages/stories/viewer/story_link_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart'
    show userProvider;
import 'package:bananatalk_app/services/stories_service.dart';

typedef StoryLoader = Future<SingleStoryResponse> Function({
  required String storyId,
});

/// `/story/:storyId`, opened from a shared story link
/// (`https://banatalk.com/story/<id>`, links#1).
///
/// Loads that one story and plays it in the normal viewer. The server
/// refuses expired, deleted, blocked and privacy-restricted stories, and
/// all of those show "Content not available" rather than an empty viewer.
class StoryLinkScreen extends ConsumerStatefulWidget {
  const StoryLinkScreen({
    super.key,
    required this.storyId,
    this.load = StoriesService.getStory,
  });

  final String storyId;
  final StoryLoader load;

  @override
  ConsumerState<StoryLinkScreen> createState() => _StoryLinkScreenState();
}

class _StoryLinkScreenState extends ConsumerState<StoryLinkScreen> {
  late final Future<SingleStoryResponse> _future =
      widget.load(storyId: widget.storyId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SingleStoryResponse>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final story = snap.data?.data;
        if (snap.hasError ||
            snap.data?.success != true ||
            story == null ||
            story.user.id.isEmpty) {
          return const _StoryUnavailable();
        }
        final me = ref.read(userProvider).valueOrNull?.id;
        return StoryViewerScreen(
          stories: [story],
          storiesUser: story.user,
          isOwnStory: me != null && me == story.user.id,
        );
      },
    );
  }
}

class _StoryUnavailable extends StatelessWidget {
  const _StoryUnavailable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hide_source_rounded, size: 56),
            const SizedBox(height: 12),
            Text(
              l10n.contentNotAvailable,
              key: const Key('story-link-unavailable'),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.goBack),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Route** — in `lib/router/app_router.dart` add the import:

```dart
import 'package:bananatalk_app/pages/stories/viewer/story_link_screen.dart';
```

and right after the `/moment/:momentId` GoRoute (ends `),` before the `/profile/:userId` comment) insert:

```dart
    // Shared story link: https://banatalk.com/story/<id> (links#1). Reached
    // only through DeepLinkGate, so the user is signed in.
    GoRoute(
      path: '/story/:storyId',
      pageBuilder: (context, state) => _buildFadeTransition(
        state: state,
        child: StoryLinkScreen(storyId: state.pathParameters['storyId']!),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ),
    ),
```

- [ ] **Step 6: Register the new file as free of English literals**

At the end of `_filesByTask` in `test/l10n/hardcoded_strings_test.dart`, replace:

```dart
  'l10n-leftovers': [
    'pages/chat/wallpaper/wallpaper_picker_screen.dart',
  ],
};
```

with:

```dart
  'l10n-leftovers': [
    'pages/chat/wallpaper/wallpaper_picker_screen.dart',
  ],
  'web-parity-p2': [
    'pages/stories/viewer/story_link_screen.dart',
  ],
};
```

- [ ] **Step 7: Run**

```bash
flutter test test/stories/story_share_link_test.dart test/l10n/hardcoded_strings_test.dart test/stories/
flutter analyze lib/pages/stories lib/router 2>&1 | tail -2
```
Expected: pass; `No issues found!` (or infos only).

- [ ] **Step 8: REMAINING_WORK + commit**

Tick `P2-3`. Add to §4 `Web ↔ app parity`:
`- [ ] (web, Phase 3) /story/:id page must be live before 2.7.0 ships: 2.6.1 and iOS 2.7.0 (AASA does not claim /story/* until Phase 5) open shared story links in the browser.`

```bash
cd /Users/davis/Desktop/Personal/bt-integration
git add bananatalk_app/lib/pages/stories/viewer/story_viewer_screen.dart bananatalk_app/lib/pages/stories/viewer/story_link_screen.dart \
  bananatalk_app/lib/router/app_router.dart bananatalk_app/test/stories/story_share_link_test.dart \
  bananatalk_app/test/l10n/hardcoded_strings_test.dart bananatalk_app/docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(stories): share stories as banatalk.com/story/<id> and open them in the app

The share sheet sent https://bananatalk.com/story/<id>, a parked
third-party domain. It now uses shareUrl('story', id). The new
/story/:storyId route loads the story and plays it in the viewer;
expired, private or blocked stories show "Content not available".

Still open (docs/REMAINING_WORK.md, Web <-> app parity Phase 2):
- P2-4..P2-9 (QR, Flutter deep linking off, text-story stickers, invite
  code entry, install referrer, gate)
- web /story/:id page (Phase 3) before 2.7.0 ships; AASA /story/* (Phase 5)
EOF
```

---

### Task P2-4: Profile QR encodes `https://banatalk.com/profile/<id>`; the scanner accepts both (links#8)

**Files:**
- Modify: `bananatalk_app/lib/widgets/qr_code_sheet.dart`.
- Test (new): `bananatalk_app/test/widgets/qr_code_sheet_payload_test.dart`.

**Interfaces:**
- Consumes: `shareUrl`, `userIdFromQrPayload` (P2-2).
- Produces: `QrCodeSheet` encodes and shares `https://banatalk.com/profile/<userId>`; `onUserScanned(String)` fires for the https link, `bananatalk://user/<id>` and `bananatalk://profile/<id>`. The caller (`chat_list_screen.dart:851`) is unchanged.

- [ ] **Step 1: Failing test** `test/widgets/qr_code_sheet_payload_test.dart`

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/qr_code_sheet.dart';

const kId = '64b7f0c2a1b2c3d4e5f60718';

void main() {
  testWidgets('My Code encodes the https profile link', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: QrCodeSheet(userId: kId, userName: 'Ana', onUserScanned: (_) {}),
        ),
      ),
    ));
    await tester.pump();
    // The sheet still builds with the https payload (QrImageView keeps its
    // data private, so the payload is pinned through the source below).
    expect(find.byType(QrImageView), findsOneWidget);
    final src = File('lib/widgets/qr_code_sheet.dart').readAsStringSync();
    expect(src, contains("shareUrl('profile', widget.userId)"));
    expect(src, isNot(contains("'bananatalk://user/\${widget.userId}'")));
    expect(src, contains('userIdFromQrPayload(raw)'));
  });
}
```

The widget pump checks that the sheet still builds (mobile_scanner is only created on the Scan tab, which is not shown). The payload itself is pinned by the source assertions plus the `userIdFromQrPayload` tests in P2-2.

- [ ] **Step 2: Run it; it fails** — `flutter test test/widgets/qr_code_sheet_payload_test.dart` → the `shareUrl('profile'…)` expectation fails.

- [ ] **Step 3: Implement** in `lib/widgets/qr_code_sheet.dart`.

Add imports:

```dart
import 'package:bananatalk_app/services/deep_link_parser.dart';
import 'package:bananatalk_app/services/link_constants.dart';
```

Replace the doc comment and `_qrData`:

```dart
  /// Called when a valid `bananatalk://user/<id>` is scanned.
```
→
```dart
  /// Called when a scanned code is a BananaTalk profile: the
  /// `https://banatalk.com/profile/<id>` link (2.7.0+) or the older
  /// `bananatalk://user/<id>`.
```

```dart
  String get _qrData => 'bananatalk://user/${widget.userId}';
```
→
```dart
  /// An https link: tappable in other chat apps and opens the web profile
  /// when the app isn't installed (links#8). The app's link handler and the
  /// scanner below both accept it.
  String get _qrData => shareUrl('profile', widget.userId);
```

Replace the scan loop body:

```dart
      if (raw.startsWith('bananatalk://user/')) {
        final scannedId = raw.substring('bananatalk://user/'.length).trim();
        if (scannedId.isEmpty) continue;

        _navigating = true;
```
→
```dart
      final scannedId = userIdFromQrPayload(raw);
      if (scannedId != null) {
        _navigating = true;
```

(the rest of the block is unchanged: `Navigator.of(context).pop(); widget.onUserScanned(scannedId); return; }`).

- [ ] **Step 4: Run** — `flutter test test/widgets/qr_code_sheet_payload_test.dart test/services/deep_link_parser_links_test.dart` → pass. `flutter analyze lib/widgets/qr_code_sheet.dart` → no issues.

- [ ] **Step 5: REMAINING_WORK + commit**

Tick `P2-4`. Add to §3 Device QA (or the parity list):
`- [ ] Accepted gap: a 2.7.0 profile QR (https) scanned with 2.6.1's in-app scanner shows "Invalid QR code"; the system camera opens it fine.`

```bash
cd /Users/davis/Desktop/Personal/bt-integration
git add bananatalk_app/lib/widgets/qr_code_sheet.dart bananatalk_app/test/widgets/qr_code_sheet_payload_test.dart bananatalk_app/docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(qr): profile QR is https://banatalk.com/profile/<id>; scanner takes both

The QR code and its share/copy link were bananatalk://user/<id>, which
other apps don't make tappable and the system camera could not open. The
QR now encodes the https profile link; the in-app scanner accepts it and
the old scheme (and old codes open from the system camera via the parser).

Still open (docs/REMAINING_WORK.md, Web <-> app parity Phase 2):
- P2-5..P2-9 (Flutter deep linking off, text-story stickers, invite code
  entry, install referrer, gate)
- accepted gap: 2.6.1's in-app scanner rejects the new https QR
EOF
```

---

### Task P2-5: Turn off Flutter's built-in deep linking (links#7)

**Files:**
- Modify: `bananatalk_app/ios/Runner/Info.plist`.
- Modify: `bananatalk_app/android/app/src/main/AndroidManifest.xml` (inside `.MainActivity`).
- Test (new): `bananatalk_app/test/services/deep_linking_config_test.dart`.

**Interfaces:** none in Dart. After this change, links reach the app only through `app_links` → `DeepLinkService` → `DeepLinkGate` (`lib/services/deep_link_service.dart`).

- [ ] **Step 1: Failing test** `test/services/deep_linking_config_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// links#7: with Flutter 3.38 defaults the engine hands /i/CODE or
/// /moment/x straight to GoRouter (no route / no errorBuilder, skips splash
/// and DeepLinkGate) while app_links pushes the same link. Only app_links +
/// DeepLinkGate may handle links.
void main() {
  test('iOS: FlutterDeepLinkingEnabled is false', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<false/>').hasMatch(plist), isTrue);
  });

  test('Android: flutter_deeplinking_enabled=false on MainActivity', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final activity = RegExp(r'<activity\s+android:name="\.MainActivity".*?</activity>', dotAll: true)
        .firstMatch(manifest)!
        .group(0)!;
    expect(
      RegExp(r'<meta-data\s+android:name="flutter_deeplinking_enabled"\s+android:value="false"\s*/>')
          .hasMatch(activity),
      isTrue,
    );
  });
}
```

- [ ] **Step 2: Run it; both tests fail** — `flutter test test/services/deep_linking_config_test.dart`.

- [ ] **Step 3: Info.plist** — replace:

```xml
	<key>FacebookDisplayName</key>
	<string>Bananatalk</string>
	<key>GIDClientID</key>
```

with:

```xml
	<key>FacebookDisplayName</key>
	<string>Bananatalk</string>
	<key>FlutterDeepLinkingEnabled</key>
	<false/>
	<key>GIDClientID</key>
```

- [ ] **Step 4: AndroidManifest** — inside `.MainActivity`, replace:

```xml
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
```

with:

```xml
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />

            <!-- Links are handled only by app_links + DeepLinkGate
                 (lib/services/deep_link_service.dart); Flutter's own deep
                 linking would also push the raw path into GoRouter (links#7). -->
            <meta-data
                android:name="flutter_deeplinking_enabled"
                android:value="false" />
```

- [ ] **Step 5: Run** — `flutter test test/services/deep_linking_config_test.dart test/android/android_release_config_test.dart` → pass. `plutil -lint ios/Runner/Info.plist` → `OK`.

- [ ] **Step 6: REMAINING_WORK + commit**

Tick `P2-5`. Device QA rows are added in P2-9 (WEB-APP-01/02).

```bash
cd /Users/davis/Desktop/Personal/bt-integration
git add bananatalk_app/ios/Runner/Info.plist bananatalk_app/android/app/src/main/AndroidManifest.xml \
  bananatalk_app/test/services/deep_linking_config_test.dart bananatalk_app/docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(links): turn off Flutter's built-in deep linking

FlutterDeepLinkingEnabled=false (iOS) and flutter_deeplinking_enabled=
false (Android). On Flutter 3.38 both default to on, so the engine pushed
/i/CODE and /moment/<id> straight into GoRouter (skipping the splash and
DeepLinkGate, error page for /i/) while app_links handled the same link.

Still open (docs/REMAINING_WORK.md, Web <-> app parity Phase 2):
- P2-6..P2-9 (text-story stickers, invite code entry, install referrer, gate)
- device QA: /i/ and /moment/ links from cold and warm start (P2-9 rows)
EOF
```

---

### Task P2-6: Text stories draw stickers, header and reply bar (moments#3)

`_buildStoryView()` returns early for `mediaType == 'text'` with only the background, overlays, mentions, gradient and progress bar. Web text stories carry poll/question/link stickers (and app text stories with a link sticker had the same problem). Fix: one stack for all story types; only the bottom layer differs. Line numbers are for the post-P2-1 file (`_buildStoryView` ~988, early return ~1000–1062).

**Files:**
- Modify: `bananatalk_app/lib/pages/stories/viewer/story_viewer_screen.dart` (`_buildStoryView`).
- Test (new): `bananatalk_app/test/stories/text_story_chrome_test.dart`.

**Interfaces:**
- Consumes (from P2-1, must be kept): `_pollFor(story)`, `hasAnswered:` on `StoryQuestionBoxWidget`, `_buildLinkPill`, `_buildReactionBar`/`_buildReplyField`, keys `story-author-name`, `story-author-avatar`, `story-location-label`, `story-hashtags`.
- Produces: text stories render the header (avatar, name, time, location, close, menu), caption hashtags, poll, question box, link pill and the reply/reaction bar. The text itself is drawn once, by `ViewerTextStoryLayer`, and is not repeated as a caption.

- [ ] **Step 1: Failing test** `test/stories/text_story_chrome_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_screen.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/story/story_poll_widget.dart';
import 'package:bananatalk_app/widgets/story/story_question_box_widget.dart';

import '../helpers/community_fixture.dart';

Story _story(Map<String, dynamic> extra) => Story.fromJson({
      '_id': '64b7f0c2a1b2c3d4e5f60718',
      'user': {'_id': 'author1', 'name': 'Ana'},
      'mediaType': 'text',
      'text': 'Hello',
      'backgroundColor': '#336699',
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(hours: 20)).toIso8601String(),
      ...extra,
    });

Future<void> _pump(WidgetTester tester, Story story, {bool own = false}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [userProvider.overrideWith((ref) async => communityFixture())],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StoryViewerScreen(stories: [story], isOwnStory: own),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _dispose(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  testWidgets('a text story shows header, location, poll, link and reply bar', (tester) async {
    await _pump(tester, _story({
      'location': {'name': 'Seoul'},
      'poll': {
        'question': 'Best snack?',
        'options': [
          {'text': 'Tteok'},
          {'text': 'Kimbap'},
        ],
      },
      'link': {'url': 'https://example.com', 'displayText': 'Open', 'host': 'example.com'},
      'hashtags': ['korean'],
    }));
    expect(find.byKey(const Key('story-author-name')), findsOneWidget);
    expect(find.byKey(const Key('story-location-label')), findsOneWidget);
    expect(find.byType(StoryPollWidget), findsOneWidget);
    expect(find.text('Best snack?'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('#korean'), findsOneWidget);
    expect(find.text('Reply to story...'), findsOneWidget);
    // The story text is drawn by the text layer only, not again as a caption.
    expect(find.text('Hello'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('a text story with a question box shows it', (tester) async {
    await _pump(tester, _story({
      'questionBox': {'prompt': 'Ask me anything', 'responses': []},
    }));
    expect(find.byType(StoryQuestionBoxWidget), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('own text story: menu, no reply bar', (tester) async {
    await _pump(tester, _story({}), own: true);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.text('Reply to story...'), findsNothing);
    await _dispose(tester);
  });
}
```

If `viewStory`'s HTTP call (made for non-own stories in `initState`) leaves an error log, ignore it. The flutter_test binding answers every request with HTTP 400, and `StoriesService.viewStory` catches it.

- [ ] **Step 2: Run it; it fails** — `flutter test test/stories/text_story_chrome_test.dart` → `story-author-name` / `StoryPollWidget` / `Reply to story...` not found.

- [ ] **Step 3: Remove the early return.** In `_buildStoryView()`, delete the whole block from

```dart
    // Text stories render their own full-screen layer; no image/video stack needed.
    if (story.mediaType == 'text') {
      return Stack(
```

through its closing

```dart
          ),
        ],
      );
    }

```

(the block ends just before the shared `return Stack(` whose first child is `// Story image/video`). Replace it with:

```dart
    // Text stories used to return early here with only the background,
    // overlays, mentions and progress bar: no header, no poll / question /
    // link / location, no reply bar, so stickers on web text stories were
    // invisible in the app (moments#3). All story types now share one stack;
    // only the bottom layer differs.
    final isTextStory = story.mediaType == 'text';

    // A text story's text IS the story (drawn by ViewerTextStoryLayer);
    // showing it again as a caption would print it twice.
    final caption = isTextStory ? null : story.text;

```

- [ ] **Step 4: Bottom layer.** In the shared stack replace:

```dart
        // Story image/video
        story.isVideo
            ? _buildVideoPlayer(story)
            : CachedImageWidget(
                imageUrl: story.mediaUrl,
                fit: BoxFit.contain,
                errorWidget: Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
```

with:

```dart
        // Story background: text layer, video or image.
        if (isTextStory)
          // Old text stories (created before overlays existed) carry their
          // content in `story.text` and have no overlays, so render it here.
          // Newer text stories carry their content in `overlays[]` (rendered
          // below), and `story.text` on those is either a copy for old clients
          // or a placeholder space, so it is suppressed whenever overlays exist.
          ViewerTextStoryLayer(
            text: parsedOverlays.isNotEmpty ? '' : (story.text ?? ''),
            backgroundColorHint: story.backgroundColor,
            textColor: story.textColor,
            fontStyle: story.fontStyle,
          )
        else if (story.isVideo)
          _buildVideoPlayer(story)
        else
          CachedImageWidget(
            imageUrl: story.mediaUrl,
            fit: BoxFit.contain,
            errorWidget: Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
```

- [ ] **Step 5: Gradient strength stays as it was for text stories.** In the shared stack's `// Gradient overlay` replace:

```dart
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
```

with:

```dart
              colors: [
                Colors.black.withValues(alpha: isTextStory ? 0.5 : 0.7),
                Colors.transparent,
              ],
```

- [ ] **Step 6: Caption uses `caption`.** Replace:

```dart
        if ((story.text != null && story.text!.isNotEmpty) ||
            story.hashtags.isNotEmpty)
```

with:

```dart
        if ((caption != null && caption.isNotEmpty) ||
            story.hashtags.isNotEmpty)
```

and inside that block replace:

```dart
                if (story.text != null && story.text!.isNotEmpty)
                  Text(
                    story.text!,
```

with:

```dart
                if (caption != null && caption.isNotEmpty)
                  Text(
                    caption,
```

The poll (`poll: _pollFor(story)`), question box (`hasAnswered: …`), link pill and reply bar blocks are **not edited**. They now apply to text stories as well.

- [ ] **Step 7: Run**

```bash
flutter test test/stories/text_story_chrome_test.dart test/stories/ test/l10n/hardcoded_strings_test.dart
flutter analyze lib/pages/stories/viewer/story_viewer_screen.dart
grep -n "if (story.mediaType == 'text') {" lib/pages/stories/viewer/story_viewer_screen.dart   # expected: no output
```
Expected: pass, no issues.

- [ ] **Step 8: REMAINING_WORK + commit**

Tick `P2-6`. Add to §3 Device QA:
`- [ ] Text story with poll / question / link / location (posted from web and from the app): stickers tappable, poll vote and answer work, header avatar opens the profile, reply sends (row WEB-APP-05).`

```bash
cd /Users/davis/Desktop/Personal/bt-integration
git add bananatalk_app/lib/pages/stories/viewer/story_viewer_screen.dart bananatalk_app/test/stories/text_story_chrome_test.dart bananatalk_app/docs/REMAINING_WORK.md
git commit -F - <<'EOF'
fix(stories): text stories show stickers, header and the reply bar

The viewer returned early for text stories and drew only the background,
overlays, mentions and progress bar, so a poll, question or link sticker
on a text story (from the web, or an app text story with a link) was
invisible and could not be answered. All story types now share one stack;
the text is drawn once by the text layer, hashtags still show.

Still open (docs/REMAINING_WORK.md, Web <-> app parity Phase 2):
- P2-7..P2-9 (invite code entry, install referrer, gate)
- device QA for text-story stickers (WEB-APP-05)
EOF
```

---

### Task P2-7: Manual invite-code entry for new accounts (links#10)

The web invite page says "enter the code after you complete your profile", but the app has no field for it. The backend's `POST /referrals/claim` only credits accounts with `profileCompleted: true` created within 14 days (`controllers/referrals.js`, `NEW_ACCOUNT_WINDOW_MS`). It answers 404 `unknown_code`, 409 (already claimed / `INVITER_CAP`) or 400 (self / not new / profile incomplete). The entry goes on the Invite friends screen (drawer, shown only when `referralsEnabled`) and is visible only to accounts younger than 14 days.

**Files:**
- Create: `bananatalk_app/lib/pages/profile/referral_invite_code_card.dart`.
- Modify: `bananatalk_app/lib/pages/profile/referral_screen.dart`.
- Modify: `bananatalk_app/lib/l10n/app_*.arb` (19) + regenerated `app_localizations*.dart`; `docs/l10n/native-qa-strings-2026-10.csv`.
- Modify: `bananatalk_app/test/l10n/hardcoded_strings_test.dart`.
- Modify: `bananatalk_app/test/growth/referral_screen_test.dart` (override `userProvider`).
- Test (new): `bananatalk_app/test/growth/invite_code_entry_test.dart`.

**Interfaces:**
- Consumes: `ReferralService.claim(String) → ReferralClaimResult{inviter, invitee, resumed}`, `ReferralRejectedException{statusCode, code}`, `referralUnknownCode`, `pendingReferralPrefsKey` (`lib/services/referral_service.dart`); `normalizeInviteCode` (P2-2); `userProvider` → `Community.createdAt` (ISO string); l10n `referralClaimed(int coins)`, `networkError`.
- Produces: `const inviteCodeEntryWindow = Duration(days: 14)`; `bool canEnterInviteCode(String createdAt, DateTime now)`; `String inviteClaimErrorText(AppLocalizations l10n, Object error)`; `class InviteCodeEntryCard extends ConsumerStatefulWidget` (keys `invite_code_card`, `invite_code_field`, `invite_code_apply`); new l10n keys `referralHaveCode`, `referralEnterCodeHint`, `referralApply`, `referralCodeUnknown`, `referralCodeNotAccepted`.

- [ ] **Step 1: Add the 5 keys to all 19 ARBs and the QA CSV**

```bash
cd /Users/davis/Desktop/Personal/bt-integration/bananatalk_app
P2TMP=${P2TMP:-$(mktemp -d)}
cat > "$P2TMP/add_invite_keys.py" <<'EOF'
import csv, json, pathlib
K = {
 'referralHaveCode': {
  'en': 'Have an invite code?', 'ar': 'هل لديك رمز دعوة؟', 'de': 'Hast du einen Einladungscode?',
  'es': '¿Tienes un código de invitación?', 'fr': "Vous avez un code d'invitation ?", 'hi': 'क्या आपके पास आमंत्रण कोड है?',
  'id': 'Punya kode undangan?', 'it': 'Hai un codice invito?', 'ja': '招待コードをお持ちですか？', 'ko': '초대 코드가 있나요?',
  'pt': 'Tem um código de convite?', 'ru': 'Есть код приглашения?', 'tg': 'Рамзи даъват доред?', 'th': 'มีรหัสเชิญไหม?',
  'tl': 'May code ng imbitasyon ka ba?', 'tr': 'Davet kodun var mı?', 'vi': 'Bạn có mã mời không?', 'zh': '有邀请码吗？', 'zh_TW': '有邀請碼嗎？'},
 'referralEnterCodeHint': {
  'en': 'Invite code', 'ar': 'رمز الدعوة', 'de': 'Einladungscode', 'es': 'Código de invitación', 'fr': "Code d'invitation",
  'hi': 'आमंत्रण कोड', 'id': 'Kode undangan', 'it': 'Codice invito', 'ja': '招待コード', 'ko': '초대 코드', 'pt': 'Código de convite',
  'ru': 'Код приглашения', 'tg': 'Рамзи даъват', 'th': 'รหัสเชิญ', 'tl': 'Code ng imbitasyon', 'tr': 'Davet kodu', 'vi': 'Mã mời',
  'zh': '邀请码', 'zh_TW': '邀請碼'},
 'referralApply': {
  'en': 'Apply', 'ar': 'تطبيق', 'de': 'Einlösen', 'es': 'Aplicar', 'fr': 'Appliquer', 'hi': 'लागू करें', 'id': 'Terapkan',
  'it': 'Applica', 'ja': '適用', 'ko': '적용', 'pt': 'Aplicar', 'ru': 'Применить', 'tg': 'Татбиқ кардан', 'th': 'ใช้', 'tl': 'Gamitin',
  'tr': 'Uygula', 'vi': 'Áp dụng', 'zh': '使用', 'zh_TW': '使用'},
 'referralCodeUnknown': {
  'en': "That invite code doesn't exist. Check it and try again.",
  'ar': 'رمز الدعوة هذا غير موجود. تحقق منه وحاول مرة أخرى.',
  'de': 'Diesen Einladungscode gibt es nicht. Prüfe ihn und versuche es erneut.',
  'es': 'Ese código de invitación no existe. Revísalo e inténtalo de nuevo.',
  'fr': "Ce code d'invitation n'existe pas. Vérifiez-le et réessayez.",
  'hi': 'यह आमंत्रण कोड मौजूद नहीं है। जाँचें और फिर से कोशिश करें।',
  'id': 'Kode undangan itu tidak ada. Periksa lalu coba lagi.',
  'it': 'Questo codice invito non esiste. Controllalo e riprova.',
  'ja': 'その招待コードは存在しません。確認してもう一度お試しください。',
  'ko': '존재하지 않는 초대 코드예요. 확인 후 다시 시도해 주세요.',
  'pt': 'Esse código de convite não existe. Confira e tente novamente.',
  'ru': 'Такого кода приглашения нет. Проверьте его и попробуйте ещё раз.',
  'tg': 'Чунин рамзи даъват вуҷуд надорад. Санҷед ва бори дигар кӯшиш кунед.',
  'th': 'ไม่มีรหัสเชิญนี้ ตรวจสอบแล้วลองอีกครั้ง',
  'tl': 'Walang ganyang code ng imbitasyon. Suriin ito at subukang muli.',
  'tr': 'Böyle bir davet kodu yok. Kontrol edip tekrar dene.',
  'vi': 'Mã mời này không tồn tại. Hãy kiểm tra và thử lại.',
  'zh': '该邀请码不存在，请检查后重试。', 'zh_TW': '此邀請碼不存在，請檢查後再試一次。'},
 'referralCodeNotAccepted': {
  'en': "This invite code can't be used on your account.",
  'ar': 'لا يمكن استخدام رمز الدعوة هذا على حسابك.',
  'de': 'Dieser Einladungscode kann für dein Konto nicht verwendet werden.',
  'es': 'Este código de invitación no se puede usar en tu cuenta.',
  'fr': "Ce code d'invitation ne peut pas être utilisé sur votre compte.",
  'hi': 'यह आमंत्रण कोड आपके खाते पर इस्तेमाल नहीं किया जा सकता।',
  'id': 'Kode undangan ini tidak bisa dipakai di akunmu.',
  'it': 'Questo codice invito non può essere usato sul tuo account.',
  'ja': 'この招待コードはお使いのアカウントでは使用できません。',
  'ko': '이 초대 코드는 내 계정에 사용할 수 없어요.',
  'pt': 'Este código de convite não pode ser usado na sua conta.',
  'ru': 'Этот код приглашения нельзя использовать в вашем аккаунте.',
  'tg': 'Ин рамзи даъватро дар ҳисоби шумо истифода бурдан мумкин нест.',
  'th': 'ใช้รหัสเชิญนี้กับบัญชีของคุณไม่ได้',
  'tl': 'Hindi magagamit ang code ng imbitasyong ito sa account mo.',
  'tr': 'Bu davet kodu hesabında kullanılamaz.',
  'vi': 'Không thể dùng mã mời này cho tài khoản của bạn.',
  'zh': '此邀请码无法用于你的账号。', 'zh_TW': '此邀請碼無法用於你的帳號。'},
}
META = {
 'referralHaveCode': 'Title of the invite-code entry card on the Invite friends screen (accounts under 14 days old)',
 'referralEnterCodeHint': 'Hint in the invite-code text field',
 'referralApply': 'Button that claims the typed invite code',
 'referralCodeUnknown': 'Error under the invite-code field: the code matches no user (or is not a valid code)',
 'referralCodeNotAccepted': 'Error under the invite-code field: server refused (already used a code, own code, account too old, inviter at limit)',
}
for arb in sorted(pathlib.Path('lib/l10n').glob('app_*.arb')):
    loc = arb.stem[len('app_'):]
    d = json.loads(arb.read_text(encoding='utf-8'))
    for k, tr in K.items():
        d[k] = tr[loc]
        if loc == 'en':
            d['@' + k] = {'description': META[k]}
    arb.write_text(json.dumps(d, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
csv_path = pathlib.Path('docs/l10n/native-qa-strings-2026-10.csv')
text = csv_path.read_text(encoding='utf-8')
with csv_path.open('a', newline='', encoding='utf-8') as f:
    if not text.endswith('\n'):
        f.write('\n')
    w = csv.writer(f, lineterminator='\n')
    for k, tr in K.items():
        for loc in sorted(tr):
            if loc != 'en':
                w.writerow(['app', loc, k, tr['en'], tr[loc], ''])
print('ok')
EOF
python3 -I "$P2TMP/add_invite_keys.py"
flutter gen-l10n
grep -c 'referralCodeNotAccepted' lib/l10n/app_localizations.dart   # expected: >= 2
```

Register the keys. In `test/l10n/hardcoded_strings_test.dart`, `_keysByTask`, replace:

```dart
  'moments-stories-audit': [
    'momentAnsweringPrompt',
  ],
};
```

with:

```dart
  'moments-stories-audit': [
    'momentAnsweringPrompt',
  ],
  'web-parity-p2': [
    'referralHaveCode',
    'referralEnterCodeHint',
    'referralApply',
    'referralCodeUnknown',
    'referralCodeNotAccepted',
  ],
};
```

and in `_filesByTask` extend the P2-3 entry:

```dart
  'web-parity-p2': [
    'pages/stories/viewer/story_link_screen.dart',
    'pages/profile/referral_invite_code_card.dart',
  ],
```

- [ ] **Step 2: Failing test** `test/growth/invite_code_entry_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/pages/profile/referral_invite_code_card.dart';
import 'package:bananatalk_app/pages/profile/referral_screen.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/referral_service.dart';

import '../helpers/community_fixture.dart';

class _FakeService implements ReferralService {
  _FakeService({this.error, this.invitee = 50});
  final Object? error;
  final int invitee;
  final claimed = <String>[];

  @override
  Future<ReferralInfo> getMine() async =>
      const ReferralInfo(code: 'ABC234', link: 'https://banatalk.com/i/ABC234', invited: 0);

  @override
  Future<ReferralClaimResult> claim(String code) async {
    claimed.add(code);
    if (error != null) throw error!;
    return ReferralClaimResult(inviter: 100, invitee: invitee);
  }
}

Future<void> _pump(WidgetTester tester, _FakeService service, {int daysOld = 2}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      referralServiceProvider.overrideWithValue(service),
      userProvider.overrideWith((ref) async => communityFixture(daysOld: daysOld)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ReferralScreen(),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  final l10n = AppLocalizationsEn();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('canEnterInviteCode', () {
    final now = DateTime.utc(2026, 10, 16, 12);
    test('inside 14 days', () {
      expect(canEnterInviteCode('2026-10-03T12:00:01Z', now), isTrue);
    });
    test('14 days or older, or unparseable', () {
      expect(canEnterInviteCode('2026-10-02T12:00:00Z', now), isFalse);
      expect(canEnterInviteCode('', now), isFalse);
      expect(canEnterInviteCode('not a date', now), isFalse);
    });
  });

  group('inviteClaimErrorText', () {
    test('unknown code', () {
      expect(
        inviteClaimErrorText(l10n, const ReferralRejectedException('x', statusCode: 404, code: referralUnknownCode)),
        l10n.referralCodeUnknown,
      );
    });
    test('other refusals', () {
      for (final e in const [
        ReferralRejectedException('Referral already claimed', statusCode: 409),
        ReferralRejectedException('limit', statusCode: 409, code: 'INVITER_CAP'),
        ReferralRejectedException('Referrals are only available to new accounts', statusCode: 400),
      ]) {
        expect(inviteClaimErrorText(l10n, e), l10n.referralCodeNotAccepted);
      }
    });
    test('network / 5xx', () {
      expect(inviteClaimErrorText(l10n, Exception('socket')), l10n.networkError);
    });
  });

  testWidgets('a new account claims a typed code', (tester) async {
    final service = _FakeService();
    await _pump(tester, service);
    expect(find.byKey(const ValueKey('invite_code_card')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('invite_code_field')), ' abcd2345 ');
    await tester.tap(find.byKey(const ValueKey('invite_code_apply')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.claimed, ['ABCD2345']);
    expect(find.text('You earned 50 coins!'), findsOneWidget);
    expect(find.byKey(const ValueKey('invite_code_card')), findsNothing);
  });

  testWidgets('an unknown code shows the error and keeps the card', (tester) async {
    final service = _FakeService(
      error: const ReferralRejectedException('Unknown referral code', statusCode: 404, code: referralUnknownCode),
    );
    await _pump(tester, service);
    await tester.enterText(find.byKey(const ValueKey('invite_code_field')), 'ZZZZ2345');
    await tester.tap(find.byKey(const ValueKey('invite_code_apply')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(l10n.referralCodeUnknown), findsOneWidget);
    expect(find.byKey(const ValueKey('invite_code_card')), findsOneWidget);
  });

  testWidgets('an invalid code is refused locally', (tester) async {
    final service = _FakeService();
    await _pump(tester, service);
    await tester.enterText(find.byKey(const ValueKey('invite_code_field')), 'AB-1');
    await tester.tap(find.byKey(const ValueKey('invite_code_apply')));
    await tester.pump();
    expect(service.claimed, isEmpty);
    expect(find.text(l10n.referralCodeUnknown), findsOneWidget);
  });

  testWidgets('a stored pending code is prefilled', (tester) async {
    SharedPreferences.setMockInitialValues({pendingReferralPrefsKey: 'QWER2345'});
    await _pump(tester, _FakeService());
    expect(find.text('QWER2345'), findsOneWidget);
  });

  testWidgets('accounts 14+ days old do not see the card', (tester) async {
    await _pump(tester, _FakeService(), daysOld: 30);
    expect(find.text('ABC234'), findsOneWidget);
    expect(find.byKey(const ValueKey('invite_code_card')), findsNothing);
  });
}
```

Update the existing `test/growth/referral_screen_test.dart` so it doesn't hit the real `userProvider`. Add the imports

```dart
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';

import '../helpers/community_fixture.dart';
```

and change its overrides line to:

```dart
    overrides: [
      referralServiceProvider.overrideWithValue(service),
      userProvider.overrideWith((ref) async => communityFixture(daysOld: 30)),
    ],
```

- [ ] **Step 3: Run; it fails** — `flutter test test/growth/invite_code_entry_test.dart` → compile error (card file missing).

- [ ] **Step 4: Create `lib/pages/profile/referral_invite_code_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';
import 'package:bananatalk_app/services/referral_service.dart';

/// The backend credits only accounts younger than this
/// (controllers/referrals.js NEW_ACCOUNT_WINDOW_MS).
const inviteCodeEntryWindow = Duration(days: 14);

/// Whether an account created at [createdAt] (ISO 8601) may still claim.
bool canEnterInviteCode(String createdAt, DateTime now) {
  final created = DateTime.tryParse(createdAt);
  if (created == null) return false;
  return now.difference(created) < inviteCodeEntryWindow;
}

/// Localized text for a failed claim.
String inviteClaimErrorText(AppLocalizations l10n, Object error) {
  if (error is ReferralRejectedException) {
    return error.code == referralUnknownCode
        ? l10n.referralCodeUnknown
        : l10n.referralCodeNotAccepted;
  }
  return l10n.networkError;
}

/// "Have an invite code?" on the Invite friends screen (links#10).
///
/// For a fresh install that lost the `/i/CODE` link: the user types the code
/// after completing their profile, as the web invite page tells them to.
/// Prefilled with a stored pending code (from a tapped link or the Play
/// install referrer) whose automatic claim did not go through.
class InviteCodeEntryCard extends ConsumerStatefulWidget {
  const InviteCodeEntryCard({super.key});

  @override
  ConsumerState<InviteCodeEntryCard> createState() =>
      _InviteCodeEntryCardState();
}

class _InviteCodeEntryCardState extends ConsumerState<InviteCodeEntryCard> {
  final _controller = TextEditingController();
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillPending();
  }

  Future<void> _prefillPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString(pendingReferralPrefsKey);
      if (mounted && pending != null && _controller.text.isEmpty) {
        _controller.text = pending;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context)!;
    final code = normalizeInviteCode(_controller.text);
    if (code == null) {
      setState(() => _error = l10n.referralCodeUnknown);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(referralServiceProvider).claim(code);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(pendingReferralPrefsKey);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
      if (result.invitee > 0) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.referralClaimed(result.invitee))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = inviteClaimErrorText(l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Card(
      key: const ValueKey('invite_code_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.referralHaveCode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('invite_code_field'),
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      hintText: l10n.referralEnterCodeHint,
                      errorText: _error,
                      errorMaxLines: 3,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      if (!_busy) _apply();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    key: const ValueKey('invite_code_apply'),
                    onPressed: _busy ? null : _apply,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.referralApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Show it on the Invite friends screen.** In `lib/pages/profile/referral_screen.dart` add imports:

```dart
import 'package:bananatalk_app/pages/profile/referral_invite_code_card.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart'
    show userProvider;
```

In `build`, after `final l10n = AppLocalizations.of(context)!;` add:

```dart
    final me = ref.watch(userProvider).valueOrNull;
    final showInviteEntry =
        me != null && canEnterInviteCode(me.createdAt, DateTime.now());
```

and make the ListView's first children:

```dart
            children: [
              if (showInviteEntry) ...[
                const InviteCodeEntryCard(),
                const SizedBox(height: 24),
              ],
              Text(l10n.referralHowItWorks, textAlign: TextAlign.center),
```

(replacing `children: [\n              Text(l10n.referralHowItWorks, textAlign: TextAlign.center),`).

- [ ] **Step 6: Run**

```bash
flutter test test/growth/invite_code_entry_test.dart test/growth/referral_screen_test.dart test/growth/referral_link_test.dart test/l10n/
flutter analyze lib/pages/profile lib/l10n/app_localizations.dart 2>&1 | tail -2
```
Expected: pass; no issues.

- [ ] **Step 7: REMAINING_WORK + commit**

Tick `P2-7`. Add under §2 Owner / §3 QA:
`- [ ] REFERRALS_ENABLED stays off until Android App Links verify (assetlinks fingerprints) — then device-check the invite card (row WEB-APP-07).`

```bash
cd /Users/davis/Desktop/Personal/bt-integration
git add bananatalk_app/lib/pages/profile/referral_invite_code_card.dart bananatalk_app/lib/pages/profile/referral_screen.dart \
  bananatalk_app/lib/l10n bananatalk_app/docs/l10n/native-qa-strings-2026-10.csv \
  bananatalk_app/test/l10n/hardcoded_strings_test.dart bananatalk_app/test/growth/invite_code_entry_test.dart \
  bananatalk_app/test/growth/referral_screen_test.dart bananatalk_app/docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(referrals): enter an invite code by hand on the Invite friends screen

The web invite page tells people to enter the code after completing their
profile, but the app had nowhere to type it. Accounts under 14 days old
(the server's window) now see "Have an invite code?" on Invite friends,
prefilled with any stored pending code. Unknown codes and server refusals
show localized errors. 5 new keys in all 19 locales, rows added to the
native QA sheet.

Still open (docs/REMAINING_WORK.md, Web <-> app parity Phase 2):
- P2-8 Play Install Referrer pickup, P2-9 gate
- REFERRALS_ENABLED off until App Links verify (owner, Phase 5)
EOF
```

---

### Task P2-8: Pick up the invite code from the Play Install Referrer (links#10)

No install-referrer package is in `pubspec.yaml` (checked 2026-10-16). `android_play_install_referrer` (0.4.0) is **discontinued** on pub.dev in favour of **`play_install_referrer`** (0.5.0, verified publisher chunkytofustudios.com, Android only). API per pub.dev: `ReferrerDetails referrerDetails = await PlayInstallReferrer.installReferrer;`, which throws on iOS and when Play services are unavailable. **Verify the version and the `ReferrerDetails.installReferrer` field name on add** (Step 1).

The web invite page must link to Play as `https://play.google.com/store/apps/details?id=com.bananatalk.app&referrer=code%3D<CODE>`. That is a web change (Phase 3, links), recorded as an open item here.

**Files:**
- Modify: `bananatalk_app/pubspec.yaml`, `bananatalk_app/pubspec.lock`.
- Create: `bananatalk_app/lib/services/install_referrer_pickup.dart`.
- Modify: `bananatalk_app/lib/main.dart` (after `DeepLinkService(goRouter).start();`).
- Test (new): `bananatalk_app/test/growth/install_referrer_pickup_test.dart`.

**Interfaces:**
- Consumes: `pendingReferralPrefsKey`, `claimPendingReferral` (unchanged; it runs at the end of registration in `register_two_screen.dart:384`); `normalizeInviteCode` (P2-2).
- Produces: `const installReferrerCheckedPrefsKey = 'install_referrer_checked'`; `String? inviteCodeFromInstallReferrer(String? referrer)`; `typedef InstallReferrerReader = Future<String?> Function()`; `Future<String?> readPlayInstallReferrer()`; `Future<void> pickUpInstallReferrer({required InstallReferrerReader read, required bool isAndroid})`.

- [ ] **Step 1: Add the package and verify its API**

```bash
cd /Users/davis/Desktop/Personal/bt-integration/bananatalk_app
flutter pub add play_install_referrer
grep -n "play_install_referrer" pubspec.yaml            # expected: play_install_referrer: ^0.5.0 (or newer — note it)
grep -rn "class ReferrerDetails\|installReferrer\b\|static Future<ReferrerDetails>" \
  ~/.pub-cache/hosted/pub.dev/play_install_referrer-*/lib/ | head
# expected: PlayInstallReferrer.installReferrer getter returning Future<ReferrerDetails>,
# and a String? installReferrer field. If names differ, adapt readPlayInstallReferrer() only.
```

- [ ] **Step 2: Failing test** `test/growth/install_referrer_pickup_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/services/install_referrer_pickup.dart';
import 'package:bananatalk_app/services/referral_service.dart';

void main() {
  group('inviteCodeFromInstallReferrer', () {
    test('reads code= from the referrer Play hands back', () {
      expect(inviteCodeFromInstallReferrer('code=ABCD2345'), 'ABCD2345');
      expect(inviteCodeFromInstallReferrer('utm_source=web&code=abcd2345&utm_medium=invite'), 'ABCD2345');
    });
    test('organic installs and junk give nothing', () {
      for (final r in [
        null,
        '',
        'utm_source=google-play&utm_medium=organic',
        'code=AB',
        'code=ABCD1890',
        'code=%E0%A4%A',
      ]) {
        expect(inviteCodeFromInstallReferrer(r), isNull, reason: '$r');
      }
    });
  });

  group('pickUpInstallReferrer', () {
    test('stores the code once', () async {
      SharedPreferences.setMockInitialValues({});
      var reads = 0;
      Future<String?> read() async {
        reads++;
        return 'code=ABCD2345';
      }

      await pickUpInstallReferrer(read: read, isAndroid: true);
      await pickUpInstallReferrer(read: read, isAndroid: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pendingReferralPrefsKey), 'ABCD2345');
      expect(prefs.getBool(installReferrerCheckedPrefsKey), isTrue);
      expect(reads, 1);
    });

    test('a code from a tapped /i/ link wins', () async {
      SharedPreferences.setMockInitialValues({pendingReferralPrefsKey: 'LINK2345'});
      await pickUpInstallReferrer(read: () async => 'code=PLAY2345', isAndroid: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pendingReferralPrefsKey), 'LINK2345');
    });

    test('not Android: never asks Play', () async {
      SharedPreferences.setMockInitialValues({});
      var reads = 0;
      await pickUpInstallReferrer(read: () async {
        reads++;
        return 'code=ABCD2345';
      }, isAndroid: false);
      expect(reads, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pendingReferralPrefsKey), isNull);
    });

    test('Play unavailable: nothing stored, retried next launch', () async {
      SharedPreferences.setMockInitialValues({});
      await pickUpInstallReferrer(read: () async => throw Exception('no Play services'), isAndroid: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(installReferrerCheckedPrefsKey), isNull);
      expect(prefs.getString(pendingReferralPrefsKey), isNull);
    });
  });
}
```

- [ ] **Step 3: Run; it fails** — `flutter test test/growth/install_referrer_pickup_test.dart` → compile error.

- [ ] **Step 4: Create `lib/services/install_referrer_pickup.dart`**

```dart
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';
import 'package:bananatalk_app/services/referral_service.dart';

/// Set once Play has answered (with or without a code), so the lookup runs
/// once per install.
const installReferrerCheckedPrefsKey = 'install_referrer_checked';

/// The web invite page links to Play with `&referrer=code%3D<CODE>`; Play
/// returns the decoded value, e.g. `code=ABCD2345`, possibly next to utm_*
/// pairs. Returns the invite code or null.
String? inviteCodeFromInstallReferrer(String? referrer) {
  if (referrer == null || referrer.trim().isEmpty) return null;
  try {
    return normalizeInviteCode(Uri.splitQueryString(referrer.trim())['code']);
  } catch (_) {
    return null; // malformed percent-encoding
  }
}

typedef InstallReferrerReader = Future<String?> Function();

/// Throws on iOS and when Google Play services are unavailable.
Future<String?> readPlayInstallReferrer() async {
  final details = await PlayInstallReferrer.installReferrer;
  return details.installReferrer;
}

/// Fresh Android installs from an invite link keep the code (links#10):
/// it is stored as the pending referral, which registration claims
/// (`claimPendingReferral`) once the profile is complete. A code from a
/// tapped `/i/` link is never overwritten. Never throws.
Future<void> pickUpInstallReferrer({
  required InstallReferrerReader read,
  required bool isAndroid,
}) async {
  if (!isAndroid) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(installReferrerCheckedPrefsKey) == true) return;
    String? raw;
    try {
      raw = await read();
    } catch (_) {
      return; // Play unavailable or not ready: try again next launch
    }
    await prefs.setBool(installReferrerCheckedPrefsKey, true);
    final code = inviteCodeFromInstallReferrer(raw);
    if (code == null) return;
    final existing = prefs.getString(pendingReferralPrefsKey);
    if (existing != null && existing.isNotEmpty) return;
    await prefs.setString(pendingReferralPrefsKey, code);
  } catch (_) {}
}
```

- [ ] **Step 5: Wire it at start-up.** In `lib/main.dart` add the import (with the other services):

```dart
import 'package:bananatalk_app/services/install_referrer_pickup.dart';
```

and replace:

```dart
  DeepLinkService(goRouter).start();
}
```

with:

```dart
  DeepLinkService(goRouter).start();

  // Android: keep an invite code from the Play Store install referrer
  // (fresh installs from banatalk.com/i/CODE). Once per install, never blocks.
  unawaited(pickUpInstallReferrer(
    read: readPlayInstallReferrer,
    isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
  ));
}
```

(`dart:async` and `package:flutter/foundation.dart` are already imported in `main.dart`.)

- [ ] **Step 6: Run + Android compile check**

```bash
flutter test test/growth/install_referrer_pickup_test.dart test/growth/
flutter analyze lib/services/install_referrer_pickup.dart lib/main.dart
J17=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
flutter build apk --debug --target-platform android-arm64 -Porg.gradle.java.installations.paths=$J17 2>&1 | tail -3
# expected: "Built build/app/outputs/flutter-apk/app-debug.apk"
```

Also confirm the merged manifest gained only the referrer service permission:
`grep -o 'BIND_GET_INSTALL_REFERRER_SERVICE' build/app/intermediates/merged_manifests/debug/*/AndroidManifest.xml 2>/dev/null || grep -rl BIND_GET_INSTALL_REFERRER_SERVICE build/app/intermediates | head -1`. Then run `flutter test test/android/android_release_config_test.dart`; it still passes because that permission is not on the unused list.

- [ ] **Step 7: REMAINING_WORK + commit**

Tick `P2-8`. Add to §4 `Web ↔ app parity`:
`- [ ] (web, Phase 3 links) Invite page "Get it on Google Play" → https://play.google.com/store/apps/details?id=com.bananatalk.app&referrer=code%3D<CODE> so P2-8 can pick the code up.`
`- [ ] Device QA: install from a Play internal-testing link with &referrer=code%3D<CODE>, register, coins credited (row WEB-APP-08; needs REFERRALS_ENABLED on a test backend).`

```bash
cd /Users/davis/Desktop/Personal/bt-integration
git add bananatalk_app/pubspec.yaml bananatalk_app/pubspec.lock bananatalk_app/lib/services/install_referrer_pickup.dart \
  bananatalk_app/lib/main.dart bananatalk_app/test/growth/install_referrer_pickup_test.dart bananatalk_app/docs/REMAINING_WORK.md
git commit -F - <<'EOF'
feat(referrals): keep the invite code from the Play install referrer

A fresh Android install from banatalk.com/i/CODE lost the code. On first
launch the app reads the Play install referrer (play_install_referrer;
android_play_install_referrer is discontinued) and stores code=<CODE> as
the pending referral, which registration already claims. A code from a
tapped invite link wins; the lookup runs once per install and retries
only if Play was unavailable.

Still open (docs/REMAINING_WORK.md, Web <-> app parity Phase 2):
- P2-9 gate
- web invite page Play link with &referrer=code%3D<CODE> (Phase 3)
- device QA via a Play internal-testing install (WEB-APP-08)
EOF
```

---

### Task P2-9: Phase gate — suite, analyze, build, QA rows, push

**Files:**
- Modify: `bananatalk_app/docs/qa/regression-suite.csv` (new "Web" rows, spec §5).
- Modify: `bananatalk_app/docs/REMAINING_WORK.md`.

- [ ] **Step 1: Full verification**

```bash
cd /Users/davis/Desktop/Personal/bt-integration/bananatalk_app
flutter gen-l10n && git status --short lib/l10n        # expected: no changes (generated files current)
flutter analyze 2>&1 | grep -E "^\s*(error|warning) •" | wc -l   # expected: 0
flutter test 2>&1 | tail -3                            # expected: All tests passed! (P2-1 count + the new tests)
J17=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
flutter build apk --debug --target-platform android-arm64 -Porg.gradle.java.installations.paths=$J17 2>&1 | tail -2
plutil -lint ios/Runner/Info.plist
```

- [ ] **Step 2: QA rows** — append to `docs/qa/regression-suite.csv` (columns `Tab,ID,Feature,Title,Preconditions,Steps,Expected,Priority,Platform,Type,2.7.0 ref,Code ref`):

```csv
Web,WEB-APP-01,Deep links,Invite and moment links from a cold start open exactly one screen,"2.7.0 installed, signed in. iOS: universal links work. Android: only after assetlinks.json has real fingerprints (else use bananatalk:// links).","1. Kill the app.
2. Tap https://banatalk.com/i/<CODE> in Notes/Messages.
3. Kill again; tap https://banatalk.com/moment/<id>.","Splash runs, then the shell; the invite is stored (no error page) and the moment opens once on top of the shell; Back returns to the tabs. No GoRouter error page, no second copy of the screen.",P0,Both,Functional,P2-5,ios/Runner/Info.plist; android/app/src/main/AndroidManifest.xml; lib/services/deep_link_gate.dart
Web,WEB-APP-02,Deep links,Same links while the app is running (warm),"As WEB-APP-01, app in background on the Home tab.","1. Tap https://banatalk.com/moment/<id>.
2. Back; tap bananatalk://profile/<id>.","Each opens once over the current tab; Back returns to it.",P0,Both,Functional,P2-5,lib/services/deep_link_service.dart
Web,WEB-APP-03,Deep links,Shared story link opens the story,"Two accounts; A has an active story; B signed in on 2.7.0 (Android with verified App Links, or bananatalk://story/<id> on iOS until the AASA claims /story/*).","1. A: story viewer > menu > Share; send the link to B.
2. B taps it. 3. Repeat after A deletes the story.","Link is https://banatalk.com/story/<id> (one n). B sees the story in the viewer. After deletion: 'Content not available' with Go Back. Signed out: the link waits for login, then opens.",P1,Both,Functional,P2-3,lib/pages/stories/viewer/story_link_screen.dart
Web,WEB-APP-04,Deep links,Chat link opens the chat and never auto-calls,"B signed in on 2.7.0, Android with verified App Links.","1. Tap https://banatalk.com/chat/<A's id>?call=video.","Chat with A opens; no call starts, no prefilled text.",P0,Android,Negative,P2-2,lib/services/deep_link_parser.dart
Web,WEB-APP-05,Stories,Text story stickers from web and app,"Web account posts a text story with a poll, another with a question, another with a link and a location; app account posts a text story with a link.","1. On 2.7.0 open each story as another user.","Header (avatar, name, time, location), poll vote, question answer, link pill (host shown) and the reply bar all work; the text is not shown twice.",P1,Both,Functional,P2-6,lib/pages/stories/viewer/story_viewer_screen.dart
Web,WEB-APP-06,QR,Profile QR is an https link and both formats scan,"2.7.0 on two phones; an old QR screenshot from 2.6.1 (bananatalk://user/<id>).","1. Chats > QR > My Code; scan it with the system camera.
2. Scan it with the other phone's in-app scanner.
3. Scan the old 2.6.1 QR in-app and with the camera.","System camera offers https://banatalk.com/profile/<id> and opens the profile (app or web). In-app scanner opens the chat for both new and old codes.",P1,Both,Functional,P2-4,lib/widgets/qr_code_sheet.dart
Web,WEB-APP-07,Referrals,Manual invite code on Invite friends,"Test backend with REFERRALS_ENABLED=true; account created < 14 days ago with completed profile; another account's code.","1. Drawer > Invite friends; enter the code lower-case; Apply.
2. Try again with a random code on another new account.
3. Open the screen on a 30-day-old account.","1: 'You earned 50 coins!', card disappears, inviter gets 100. 2: 'That invite code doesn't exist…'. 3: no card.",P1,Both,Functional,P2-7,lib/pages/profile/referral_invite_code_card.dart
Web,WEB-APP-08,Referrals,Play install referrer keeps the invite code,"Android, Play internal-testing track, test backend with REFERRALS_ENABLED=true; app not installed.","1. Open https://play.google.com/store/apps/details?id=com.bananatalk.app&referrer=code%3D<CODE> and install.
2. Open the app, sign up, complete the profile.","Coins snackbar after registration; inviter credited. Organic install: nothing happens.",P1,Android,Functional,P2-8,lib/services/install_referrer_pickup.dart
```

- [ ] **Step 3: REMAINING_WORK** — tick `P2-9` and the parent `Phase 2` line (`- [x] Phase 2: app …, merged 2026-10-xx, ships with 2.7.0`). Leave the open items added by P2-2…P2-8. Add to §3 Device QA: `- [ ] Web/app parity rows WEB-APP-01…08 (docs/qa/regression-suite.csv, Tab "Web").`

- [ ] **Step 4: Commit and push (app push does not deploy)**

```bash
cd /Users/davis/Desktop/Personal/bt-integration
git add bananatalk_app/docs/qa/regression-suite.csv bananatalk_app/docs/REMAINING_WORK.md
git commit -F - <<'EOF'
docs: web/app parity phase 2 done, device QA rows

Phase 2 (app) is on main: moments/stories audit branch merged, story and
chat links, https profile QR, Flutter deep linking off, text-story
stickers, invite code entry and Play install referrer. Full suite green,
analyze clean, debug APK builds. Device rows WEB-APP-01..08 added.

Still open (docs/REMAINING_WORK.md):
- 2.7.0 release build (owner) and device QA WEB-APP-01..08
- web Phase 3: /story/:id page, invite page Play referrer link, AASA drops /chat/*
- Phase 5: assetlinks fingerprints, AASA claims /story/* and /chat/*, REFERRALS_ENABLED
- ObjectId check for /profile/ and /community/ links (links#15)
EOF
git push origin main
git log --oneline origin/main -1
```

---

## Not in this plan (belongs elsewhere)

- AASA changes (drop `/chat/*` now: web Phase 3; claim `/story/*`, `/chat/*`: Phase 5 owner step).
- Web `/story/:id` page, smart banner per page, invite page Play referrer link: Phase 3 (web).
- `assetlinks.json` fingerprints, `REFERRALS_ENABLED`, 2.7.0 release build: owner steps (Phase 5 / `docs/releases/2.7.0-handoff.md`).
- Clipboard pickup of invite codes (iOS has no install referrer): not in the spec; the manual entry covers iOS.
