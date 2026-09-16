# Study Hub Information Architecture — Implementation Plan

**Spec:** `docs/superpowers/specs/2026-09-15-study-hub-ia-design.md`
**Date:** 2026-09-16
**Repo:** `bananatalk_app` (Flutter). Backend changes are subtractive only.

The spec is the authority. Where this plan and the spec disagree, the spec wins.

---

## Open questions, now answered

The spec left three open questions and said two of them were investigation tasks
in this plan, not settled conclusions. Both are now measured, so they are tasks
no longer.

### Q1 — which scenario library is better? **The tutor's, decisively.**

Neither library is in the database; both are code (`services/tutorScenarios.js`,
`services/aiConversationService.js` `PRACTICE_SCENARIOS`). Enumerated:

| | Tutor | AI Conversation |
|---|---|---|
| Count | **39** | 18 (3 per CEFR level) |
| Fields | `id, emoji, title, summary, goal, level, minTurns` | `id, name, description` |

Diffed by id and by title against the tutor's set:

- **4 exact duplicates** — `ask_time`, `hotel_checkin`, `job_interview`, `doctor_visit`
- **11 near-duplicates** — e.g. `meet_friend`/`self_intro`, `buy_coffee`/`coffee_shop`,
  `order_food`/`restaurant_order`, `debate`/`current_event_debate`
- **3 nominally unique** — `negotiation`, `complaint`, `improvisation`. Of these,
  `negotiation` is covered by the tutor's `salary_negotiation` and
  `contract_negotiation`, and `complaint` by `isp_complaint`.

**Exactly one scenario — `improvisation` — has no tutor counterpart.** The spec's
reversal condition ("if the AI Conversation library is substantially richer") is
not met; it is poorer on both count and structure. The tutor absorbs the shell,
not the library. Porting `improvisation` is a one-line addition, listed as Task 6
and explicitly optional.

### Q2 — which pronunciation screen survives? **`PronunciationScreen`.**

| | `PronunciationScreen` | `PronunciationStartScreen` |
|---|---|---|
| Lines | 1,025 | 151 (+171 session screen) |
| Custom sentence | yes (`TextField`, :532) | yes |
| History | yes | no |
| Stats | yes | no |
| Language selector | yes | no |

The start screen's one selling point — offering "use my own sentence" up front
rather than after the first AI sentence loads — is a presentation choice, and the
surviving screen already has the field. Nothing is lost.

### Q3 — should "Writing check" stay? **Unchanged: yes, for now.**

3 calls from 1 user in 30 days. The spec keeps it last on the list and revisits in
three months. This plan does not reopen that.

---

## Global constraints

1. **No user data is deleted.** Not `aiconversations` (141 docs), not history, not
   stats. This plan removes entry points only.
2. **Every retired screen stays reachable by deep link.** A push notification sent
   last week that opens a now-unrouted screen is a crash, not a tidy-up. This is
   the single highest-risk item in the plan and it gets its own task and its own
   test.
3. **No kill switch.** Per spec §6: this is layout, and a half-applied IA is worse
   than either state. It ships with the app release.
4. **Nothing in this plan changes what any feature does.** Entry points move and
   merge; screens are untouched except where a task says otherwise.
5. Dart imports are `package:` absolute — never relative (linter-enforced).

---

## Tasks

### Task 1 — the Practice entry list becomes one ordered value

Mirror the existing `studyHubTabOrder` pattern in
`lib/pages/learning/main/study_hub_tabs.dart`: a single ordered, testable list
rather than a literal built inline inside `_buildFeaturesGrid`
(`lib/pages/learning/main/sections/ai_tools_tab.dart:237`).

This task is first because every later task is an edit to that list, and doing it
first makes each of those a data change with a test rather than a widget-tree
edit.

**Done when:** the grid renders from the list; a pure test asserts the order; no
visual change yet.

### Task 2 — Practice: twelve entries become five

Per spec §2.2, in this order: Tutor (hero) · Lessons · Pronunciation · Quizzes ·
Writing check.

- **Remove** the `AIConversationScreen` grid entry (:243) — superseded by the tutor
- **Remove** the `TranslationScreen` grid entry (:250) — moves to chat, Task 4
- **Fold** `LessonBuilderScreen` (:254) inside Lessons, not beside it
- **Keep** `PronunciationScreen` (:249) as the single pronunciation entry (Q2)
- **Rename** the tab "AI Tools" → "Practice" (all 19 ARB locales)

The tutor hero drops to 4 chips: chat, roleplay, story, photo. The `pronounce`
chip goes, its destination being the surviving screen.

**Done when:** Practice renders exactly 5 entries; a widget test asserts that
count, asserts translation is absent, and asserts every entry has a *distinct*
destination — the test that would have caught the duplicate pronunciation and
conversation entries in the first place.

### Task 3 — retire AI Conversation creation without touching its content

- Remove the grid entry (done in Task 2); **do not delete the screen**
- `conversation_history_screen.dart` stays reachable from the tutor's session list
- Backend: retire `POST /ai-conversation/start` only. **Leave every read route
  live** — 141 saved conversations must stay readable.

**Done when:** no new AI Conversation sessions can be created from the UI; all 141
existing ones still open and read; the retirement is one route, so reversing it is
one route.

### Task 4 — translation moves to chat

Per spec §2.1. Translation is used 2.6× more than anything else (295 calls / 74
users in 30 days) and sits fifth of seven on the second tab. It belongs where its
users already are.

This is also exactly where the monetization spec puts the translation paywall, so
the two designs must land consistently — the entry point and the cap should not
disagree about where translation lives.

**Done when:** translation is reachable from chat; it is gone from the Hub; the
existing translation screen is otherwise unchanged.

### Task 5 — deep links and notifications still resolve *(highest risk)*

Audit every route name and notification payload that targets a screen this plan
un-lists. For each: the route stays registered and the screen stays in the repo.

**Done when:** a navigation test opens every retired screen by its route name and
gets the screen, not a crash. This test is the acceptance criterion for the whole
plan — Global Constraint 2 is the one that can hurt live users.

### Task 6 — *(optional)* port `improvisation` to the tutor library

One entry added to `services/tutorScenarios.js` with the tutor's field shape
(`emoji, title, summary, goal, level, minTurns`). The only scenario with no tutor
counterpart (Q1). Skippable without consequence.

---

## Testing

Per spec §5, and Task 2 and Task 5 each own the test that would have caught the
bug they fix:

- **Pure:** the Practice entry list is an ordered value; order is asserted, and a
  reorder cannot silently break `animateTo` call sites
- **Widget:** Practice renders exactly 5 entries; translation absent; all
  destinations distinct
- **Navigation:** every retired screen reachable by deep link
- **Regression:** Today and Exams unchanged

---

## What this plan does not do

Out of scope per spec §7: the Today tab's contents, the Exams tab, any change to
what a feature *does*, and deleting `aiconversations` data.

Also deliberately excluded: `isVIP()` vs `tierOf` reconciliation (backend, its own
blast radius), and the AI Conversation screen's own internals — it is being
un-listed, not rewritten.

---

## Rollout

Ships with the app release, no kill switch (spec §6). After release, watch two
numbers the spec named:

- **tutor sessions** — should rise, as it stops competing with AI Conversation
- **translation usage** — should rise, as it moves to where it is used

If tutor sessions do *not* rise, the merge was a labelling change rather than a
real consolidation, and Q1's reversal path (retiring only `POST /start`) is still
one route away.
