# Study Hub Information Architecture — Design

**Date:** 2026-09-15
**Status:** approved, ready for implementation planning
**Goal:** the Study Hub is packed and nothing is visible. Cut it from 22 entry points to a
shape that answers "what should I do now?"

---

## 1. The problem, measured

The Study Hub has three tabs and roughly **22 entry points**. The AI Tools tab alone
holds **12**: a tutor hero with 5 chips (chat, roleplay, story, photo, pronounce) plus a
7-card grid (AI Conversation, Lessons, Grammar, Pronunciation, Translation, Quizzes,
Lesson Builder).

### 1.1 The layout is close to inverted against demand

30-day usage:

| Feature | Calls / users |
|---|---|
| **Translation** | **295 / 74** |
| AI conversation | 113 / 23 |
| Tutor sessions | 39 |
| Lessons | 28 |
| Lesson builder | 28 / 14 |
| Pronunciation | 21 / 7 |
| Quizzes | 4 / 4 |
| Grammar feedback | **3 / 1** |

**Translation is used 2.6x more than anything else and sits as the fifth card of seven on
the second tab.** Grammar feedback — three calls from one person in a month — holds an
equally prominent slot.

### 1.2 Two features exist twice

- Tutor *chat* chip -> `TutorChatScreen`; grid *AI Conversation* -> `AIConversationScreen`
- Tutor *pronounce* chip -> `PronunciationStartScreen`; grid *Pronunciation* ->
  `PronunciationScreen`

And underneath, **two independent roleplay systems**:

```
GET /api/v1/tutor/scenarios           -> listScenarios   (tutor)
GET /api/v1/ai-conversation/scenarios -> getScenarios    (AI conversation)
```

Two backends, two pickers, two chat screens, the same product. This is not a labelling
problem; it is two workstreams having built the same thing. **It is also the direct cause
of "packed": the tab competes with itself.**

---

## 2. The new shape

Three tabs stay; their jobs get sharper.

| Tab | Job |
|---|---|
| **Today** | the path — one thing to do, the daily pack. Unchanged in purpose |
| **Practice** (was "AI Tools") | the toolbox, 12 entries -> 5 |
| **Exams** | unchanged |

### 2.1 Translation leaves the Hub

Translation moves into chat, where its 74 users already are. **It is not a study tool** —
nobody opens a study tab to translate; they translate mid-conversation with a person.

This also places it exactly where the monetization spec puts the translation paywall
(10/day free), so the two designs reinforce rather than fight each other.

### 2.2 Practice, ordered by use, duplicates merged

1. **Tutor** — the hero, 4 chips: chat, roleplay, story, photo *(39 sessions/30d)*
2. **Lessons** — lesson builder folded inside, not beside *(28 + 28)*
3. **Pronunciation** — one entry, not two *(21)*
4. **Quizzes** *(4)*
5. **Writing check** — grammar feedback, kept but last *(3, one user)*

**Twelve become five. Nothing is deleted** — the builder moves inside Lessons, the
duplicate pronunciation and conversation entries collapse — but the surface stops
competing with itself.

---

## 3. Resolving the conversation duplication

**The two are not identical, and the difference decides it.**

**Tutor** (`/tutor`): memory (`getMyMemory`), persona, a daily plan with completable
tasks, SRS integration, inline vocab/grammar/quiz cards, voice, quotas. It **compounds** —
it remembers the learner between sessions. 324 lifetime sessions, 39 in 30 days.

**AI Conversation** (`/ai-conversation`): topics, scenarios, saved history, stats. Each
session is standalone. 141 lifetime, 29 in 30 days.

**Decision: the Tutor survives.** Not on usage — the margin is thin — but because memory
and SRS are the difference between practice that accumulates and practice that
evaporates. A learner who uses the tutor for a month has something to show; one with 20
standalone transcripts does not.

### 3.1 Retirement must not destroy user content

141 saved conversations exist. Deleting user content to tidy a menu is the wrong trade.

- **Stop creating** new AI Conversation sessions; remove the grid entry
- **Keep history readable.** `conversation_history_screen.dart` stays reachable from the
  tutor's session list
- **Fold the scenario library.** Compare both scenario sets and merge anything the tutor
  lacks into `/tutor/scenarios` rather than discarding authored content
- Leave `/ai-conversation` read routes live; retire only `POST /start`

### 3.2 This decision is reversible, and rests on an unverified assumption

The recommendation is based on **capability, not user preference**. The 23 people who used
AI Conversation last month have never been asked, and the two scenario libraries have not
been compared for quality or coverage.

**Comparing the libraries is a task in the plan, not a settled conclusion.** If the AI
Conversation library is substantially richer, the answer may flip to keeping its scenarios
under the tutor's shell. Retiring only `POST /start` keeps that reversal cheap.

---

## 4. Migration and data safety

- **No user data is deleted.** Not conversations, not history, not stats.
- `aiconversations` (141 docs) stays queryable; only the creation entry point goes.
- The pronunciation merge picks one screen; the other is removed from navigation, not from
  the repo, until the chosen path is confirmed working in production.
- **Deep links and existing notifications** that point at removed screens must still
  resolve. A push from last week that opens a now-unreachable screen is a crash, not a
  tidy-up.

---

## 5. Testing

- **Pure:** the Practice tab's entry list is a single ordered value (mirroring the
  `studyHubTabOrder` pattern already in `study_hub_tabs.dart`), so order is testable and a
  reorder cannot silently break `animateTo` call sites.
- **Widget:** Practice renders exactly 5 entries; translation does NOT appear in the Hub;
  every entry has a distinct destination — a test that would have caught the duplicate
  pronunciation and conversation entries.
- **Navigation:** every retired screen remains reachable by deep link.
- **Regression:** `Today` and `Exams` are unchanged.

---

## 6. Rollout

The Hub reorganization ships with the app release. No kill switch — this is layout, not a
feature, and a half-applied IA is worse than either state.

Watch after release: tutor sessions (should rise as it stops competing with AI
Conversation), and translation usage (should rise as it moves to where it is used).

---

## 7. Out of scope

- Redesigning the Today tab's contents (the daily pack is working as specified)
- The Exams tab
- Any change to what the features do — this spec moves and merges entry points only
- Deleting `aiconversations` data

---

## 8. Open questions

1. **Which scenario library is better?** §3.2. Decides whether the tutor absorbs AI
   Conversation's scenarios or only its shell.
2. **Which pronunciation screen survives?** `PronunciationStartScreen` vs
   `PronunciationScreen` — same investigation, smaller stakes.
3. **Should "Writing check" stay at all?** 3 calls from 1 user in 30 days. Kept for now
   because removing a working feature on one month of data is premature, but if it is still
   at 1 user in three months it should go.
