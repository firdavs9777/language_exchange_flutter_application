# Exam Study — App-side implementation plan

**Date:** 2026-06-27
**Companion to:** `backend/docs/superpowers/specs/2026-06-24-exam-study-design.md` + `backend/docs/superpowers/plans/2026-06-24-exam-study.md`
**Status:** draft — awaiting sign-off
**Goal:** Ship the Flutter UI for the backend's MVP exam-study feature (3 languages × 1 exam × 2 sections × ~180 questions). Free users get daily essay-eval quota; VIP unlimited.

## Locked decisions

| Q | Decision |
|---|---|
| Entry point | **Third tab in AI Study** (alongside Learn / AI Tools) |
| Monetization | **Free with daily quota** (e.g. 5 essay evals/day); **VIP = unlimited** |
| MVP slice | **Match backend Phase 1** — Reading + Writing only, no speaking/listening |

## Backend API contract (recap)

All routes under `/api/exam-study`:

| Method | Path | Purpose |
|---|---|---|
| GET | `/languages` | List active languages |
| GET | `/languages/:languageId/exams` | List exams per language |
| GET | `/exams/:examId/sections` | List sections per exam |
| GET | `/sections/:sectionId/questions?limit=&difficulty=&source=` | List practice questions |
| POST | `/questions/:questionId/submit-answer` | Submit answer. MC = 200 instant; essay/speaking = 202 + poll URL |
| GET | `/evaluations/:evaluationId` | Poll async eval status (every 2-3s) |
| GET | `/users/:userId/exams/:examId/progress` | User's progress per exam |
| POST | `/users/:userId/exams/:examId/generate-study-plan` | Create AI study plan |
| GET | `/users/:userId/study-plans/:planId` | Fetch study plan |

All require bearer auth.

## File structure (Flutter)

### Models — `lib/providers/provider_models/exam/`
- `exam_language.dart` — `ExamLanguage` (id, name, code, icon, active)
- `exam_type.dart` — `ExamType` (id, name, languageId, description, sections[], durationMinutes, scoringType, maxScore)
- `exam_section.dart` — `ExamSection` (id, examId, sectionName, sectionType, description, durationMinutes, questionCount)
- `exam_question.dart` — `ExamQuestion` (id, examId, sectionId, questionText, questionType, correctAnswer, options[], audioUrl, imageUrl, explanation, difficulty, source)
- `user_exam_progress.dart` — `UserExamProgress` (userId, examId, questionsAttempted, questionsCorrect, sectionScores{}, overallScore, lastAttemptedQuestionId, lastUpdated)
- `user_study_plan.dart` — `UserStudyPlan` + `StudyMilestone` + `DailyLesson` sub-types
- `exam_submission_result.dart` — discriminated union: `InstantResult` (score/isCorrect/explanation) | `AsyncResult` (evaluationId/pollUrl)
- `evaluation_status.dart` — `EvaluationStatus` (status: pending/completed/failed, score, feedback)

### Service — `lib/services/exam_study_service.dart`
Single class wrapping all 9 endpoints. Follows the existing pattern in `lib/providers/provider_root/message_provider.dart` (auth header via `_getToken()`, JSON decode, error rethrow). One method per endpoint.

### Providers — `lib/providers/provider_root/exam_study_provider.dart`
- `examStudyServiceProvider` → singleton `ExamStudyService`
- `examLanguagesProvider` → `FutureProvider<List<ExamLanguage>>`
- `examsForLanguageProvider.family(languageId)` → `FutureProvider<List<ExamType>>`
- `sectionsForExamProvider.family(examId)` → `FutureProvider<List<ExamSection>>`
- `questionsForSectionProvider.family((sectionId, filters))` → `FutureProvider<List<ExamQuestion>>`
- `userExamProgressProvider.family((userId, examId))` → `FutureProvider<UserExamProgress?>`
- `userStudyPlanProvider.family((userId, examId))` → `FutureProvider<UserStudyPlan?>`
- `activeEvaluationsProvider` → `StateNotifier<Map<String, EvaluationStatus>>` for tracking pending essay polls

### Screens — `lib/pages/learning/exam_study/`
1. `exam_study_tab.dart` — entry widget mounted as the 3rd `TabBarView` child in LearningMain. Houses language picker.
2. `exam_picker_screen.dart` — list of exams for a chosen language.
3. `exam_dashboard_screen.dart` — sections grid + progress summary + Study Plan CTA + Continue Practice button.
4. `section_practice_screen.dart` — paged question runner (MC inline feedback / essay editor).
5. `essay_editor_screen.dart` — large textarea + word counter + submit, leads to evaluation polling.
6. `evaluation_result_screen.dart` — shown after async eval completes, displays score + feedback + strengths/improvements.
7. `progress_screen.dart` — per-section score chart + weak-area chips.
8. `study_plan_setup_screen.dart` — input target score + exam date, generates plan.
9. `study_plan_screen.dart` — weekly milestones timeline.

### Widgets — `lib/pages/learning/exam_study/widgets/`
- `language_card.dart` — flag + name card for picker
- `exam_card.dart` — exam pill with description + meta
- `section_tile.dart` — section card with progress bar + score
- `question_mc_card.dart` — multiple-choice question with options
- `question_essay_card.dart` — essay prompt + editor link
- `quota_banner.dart` — daily-essay-quota indicator (X/5 today) with VIP-upgrade CTA when exhausted
- `milestone_tile.dart` — single milestone in study plan timeline

### Router — `lib/router/app_router.dart` (modify)
Add new GoRoutes:
- `/exam-study` — language picker (mostly unused since the tab handles it, but supports deep-linking)
- `/exam-study/language/:languageId` — exam picker
- `/exam-study/exam/:examId` — dashboard
- `/exam-study/section/:sectionId/practice` — practice screen
- `/exam-study/exam/:examId/progress` — progress screen
- `/exam-study/exam/:examId/study-plan` — study plan view
- `/exam-study/exam/:examId/study-plan/new` — study plan setup

### Mount point — `lib/pages/learning/main/learning_main_screen.dart` (modify)
Add the third tab + the third `TabBarView` child:

```dart
TabBar(
  controller: _tabController,  // change length 2 → 3
  tabs: [
    Tab(child: Row(children: [Icon(Icons.psychology_rounded), Text(l10n.aiTools)])),
    Tab(child: Row(children: [Icon(Icons.school_rounded),    Text(l10n.studyHub)])),  // Learn
    Tab(child: Row(children: [Icon(Icons.assignment_rounded), Text(l10n.examStudy)])), // NEW
  ],
),
...
TabBarView(children: [const AiToolsTab(), const LearnTab(), const ExamStudyTab()]),
```

Also widen `TabController(length: 3)`.

## VIP gating — daily essay-eval quota

**Pattern:** mirror the existing translation gate (`translation_bottom_sheet.dart` line 338) — "Free users get N translations per day. Upgrade to VIP for unlimited."

**Where the gate fires:** before calling `POST /questions/:id/submit-answer` when `question.questionType == 'essay'`. The check:
- If user is VIP → proceed.
- Else read local counter (SharedPreferences key `exam_essay_evals_today_<userId>` + reset-day key), and if `< DAILY_QUOTA (5)` → increment + proceed. Else → show `vip_locked_feature.dart` style sheet with "Upgrade to VIP for unlimited evaluations".

**MC questions are always free** — they don't cost AI calls server-side.

**No coin spend** — coins (when they ship) are reserved for boosting; exam-eval has its own counter.

## Models — JSON shape (matches backend)

`ExamLanguage`:
```json
{ "_id": "...", "name": "English", "code": "en", "icon": "🇬🇧", "active": true }
```

`ExamSubmissionResult` (discriminated by status code):
```json
// MC — 200 OK
{ "score": 100, "isCorrect": true, "explanation": "...", "feedback": "Correct!" }

// Essay/speaking — 202 Accepted
{ "statusCode": 202, "pollUrl": "/api/exam-study/evaluations/<id>" }
```

Service method returns a `sealed`-style union so the caller can pattern-match:
```dart
sealed class ExamSubmissionResult {}
class InstantResult extends ExamSubmissionResult {
  final int score; final bool isCorrect; final String? explanation; final String feedback;
}
class AsyncResult extends ExamSubmissionResult {
  final String evaluationId; final String pollUrl;
}
```

## Polling strategy for async essay eval

After submitting an essay, the screen pushes to `evaluation_result_screen.dart` with the evaluation id and:
1. Starts a `Timer.periodic(Duration(seconds: 3))` that calls `GET /evaluations/:id`.
2. On `status == "completed"` → cancel timer, render score + feedback.
3. On `status == "failed"` → render error with retry option.
4. After 60s with no completion → stop polling, show "Still evaluating — check back later" with a manual refresh button.
5. Persist `evaluationId` to SharedPreferences so the user can return to the screen even after killing the app.

## Localization

~35 new keys needed across all 19 ARB files. Add via the same Python bulk-add script pattern used in the recent VIP localization pass.

Key prefixes:
- `examStudy*` (general/navigation)
- `examQuestion*` (question runner UI)
- `examProgress*` (progress dashboard)
- `examPlan*` (study plan UI)

Examples (English values shown; other locales fall back to English):
```
examStudy: "Exam Study"
examStudyChooseLanguage: "Choose your study language"
examStudyChooseExam: "Choose an exam"
examQuestionSubmit: "Submit answer"
examQuestionCorrect: "Correct!"
examQuestionIncorrect: "Incorrect"
examQuestionExplanation: "Explanation"
examEssayPrompt: "Write your essay"
examEssayWordCount: "{count} words"
examEssayMinChars: "Essay must be at least 50 characters"
examEssayMaxChars: "Essay must not exceed 5000 characters"
examEssayEvaluating: "Evaluating your essay…"
examEssayQuotaUsed: "Daily essay evaluations: {used}/{limit}"
examEssayQuotaExhausted: "You've used today's free essay evaluations. Upgrade to VIP for unlimited."
examPlanTargetScore: "Target score"
examPlanExamDate: "Exam date"
examPlanGenerate: "Generate study plan"
examPlanWeek: "Week {n}"
examProgressOverall: "Overall score"
examProgressWeakAreas: "Focus areas"
```

Two ICU placeholder keys: `examEssayWordCount({count})`, `examPlanWeek({n})`, `examEssayQuotaUsed({used}, {limit})`.

## Ship sequence — 5 chunks, separate PRs

**Each chunk gets its own PR. No mega-PR.**

### Chunk A — Foundation (Day 1)
- Models: ExamLanguage, ExamType, ExamSection, ExamQuestion (+ JSON parsers)
- Service: `getLanguages`, `getExamsForLanguage`, `getSectionsForExam`, `getQuestionsForSection`
- Providers wired for the 4 read endpoints
- L10n keys: examStudy / examStudyChooseLanguage / examStudyChooseExam + base navigation labels
- Mount: third tab in LearningMain (label only, empty body)
- ExamStudyTab renders language picker (calls `examLanguagesProvider`, grid of language cards)

**Acceptance:** opening AI Study → third tab → see "English / Spanish / Korean" cards loaded from backend.

### Chunk B — Exam picker + dashboard (Day 1-2)
- Screens: ExamPicker (uses `examsForLanguageProvider`), ExamDashboard (uses `sectionsForExamProvider`)
- Widgets: ExamCard, SectionTile (with locked progress=0 state)
- Router entries for `/exam-study/language/:id` and `/exam-study/exam/:id`
- L10n keys: examPickExam, examDashboardSection, examDashboardContinue, etc.

**Acceptance:** tap English → see IELTS → tap IELTS → see Reading + Writing tiles with section names.

### Chunk C — Practice flow: MC + progress (Day 2-3)
- Models: UserExamProgress
- Service: `submitAnswer` (MC path), `getUserProgress`
- Provider: `userExamProgressProvider`
- Screen: SectionPracticeScreen (paged through questions, MC card, inline feedback overlay)
- Widget: QuestionMcCard with options + selected-state
- L10n keys: examQuestion* (Correct / Incorrect / Explanation / Submit / Next)
- After each submission, invalidate `userExamProgressProvider` so dashboard updates

**Acceptance:** tap Reading → see 10 questions → answer → instant green/red feedback → progress bar on dashboard updates.

### Chunk D — Essay flow with async polling (Day 3-4)
- Models: EvaluationStatus, ExamSubmissionResult union
- Service: `submitAnswer` (essay path, returns 202), `pollEvaluation`
- Provider: `activeEvaluationsProvider` (StateNotifier tracking in-flight evals)
- Screens: EssayEditorScreen, EvaluationResultScreen
- Widget: QuotaBanner (X/5 daily, VIP upgrade pill when exhausted)
- VIP gate: check `userProvider.isVip`, fall back to SharedPreferences counter for free users
- Daily reset: counter keyed on `YYYY-MM-DD` so it auto-resets
- L10n keys: examEssay* (Prompt / WordCount / MinChars / MaxChars / Evaluating / Quota*)

**Acceptance:** tap Writing → write essay → submit → see "Evaluating…" → poll every 3s → result page with score + feedback. Free user on 6th essay sees VIP gate.

### Chunk E — Study plan + progress dashboard (Day 4-5)
- Models: UserStudyPlan + StudyMilestone + DailyLesson
- Service: `generateStudyPlan`, `getStudyPlan`
- Provider: `userStudyPlanProvider`
- Screens: ProgressScreen (per-section scores + weak-area chips), StudyPlanSetupScreen (target + date), StudyPlanScreen (vertical timeline)
- Widget: MilestoneTile
- L10n keys: examPlan*, examProgress*

**Acceptance:** dashboard → tap "View Progress" → see scores + weak areas. Tap "Start Study Plan" → enter target + date → see weekly milestone timeline.

## Out of scope (deliberate)

- **Speaking & listening sections** — backend MVP doesn't ship these either; no audio capture UI yet.
- **Mock test mode** — single full timed exam, not in MVP.
- **Leaderboard / social** — out per backend spec.
- **Web parity** — web is Community/Chats/Moments/Profile only per [[web_scope]] memory.
- **Coin spend on essays** — separate from upcoming coin economy. Daily quota counter only.
- **Offline mode** — questions need backend. No caching.
- **Push notifications for study plan reminders** — out for MVP; layer onto existing notification system later.

## Open numeric decisions

| Knob | Default | Adjust? |
|---|---|---|
| Daily free essay evals | 5 | |
| Essay min/max chars | 50 / 5000 (backend-enforced) | |
| Poll interval | 3 seconds | |
| Poll timeout | 60 seconds → manual refresh | |
| Max questions per section page | 10 (matches backend default) | |
| Tab icon for Exam Study | `Icons.assignment_rounded` | |

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Backend not ready for Chunk A | Stub `examLanguagesProvider` with mock data behind a feature flag |
| Essay polling drains battery | 3s interval + 60s timeout + dispose on screen pop |
| User loses essay text on network drop | Persist draft to SharedPreferences while editing |
| VIP quota counter resets on app reinstall | Acceptable — anti-abuse is server-side via rate limits |
| Backend `progress` 404 on first visit | Service treats 404 as `UserExamProgress.empty()` |

## Definition of done

- 5 chunks merged sequentially
- All UI strings localized via `app_en.arb` (other locales fallback)
- `flutter analyze` clean on all touched files
- Manual smoke test: full flow English → IELTS → Reading practice → see progress; English → IELTS → Writing essay → submit → polled result; generate study plan → see timeline
- Free user quota gate triggers on 6th essay submission within 24h
