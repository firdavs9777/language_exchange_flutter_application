# BananaTalk Codebase Audit — Strategic-Pivot Reconnaissance

**Date:** 2026-05-26
**Branch:** main @ 94e5bb4
**Scope:** Flutter app (`bananatalk_app/`) + Node/Express/MongoDB backend (`language_exchange_backend_application/`)

## 1. Feature Inventory & Code Footprint

All last-commit dates fall in the 2026-05-19 → 2026-05-26 window because the Tajik-locale wave touched almost every page. Where that was the only recent commit, "last meaningful" is the prior content commit and is noted.

| Feature                                                                 | Frontend dir | Files / ~LOC | Backend route prefix | Controller | Last meaningful commit | Analytics? |
|-------------------------------------------------------------------------|---|---|---|---|---|---|
| **Stories**                                                             | `lib/pages/stories/` | 12 | `/api/v1/stories` | `controllers/stories.js` | Pre-Tajik (no Step-19 work) | No |
| **Moments**                                                             | `lib/pages/moments/` | 30 | `/api/v1/moments` | `controllers/moments.js` | 2026-05-26 | No |
| **Community (browse/filter)**                                           | `lib/pages/community/` | 55 | `/api/v1/community/*`, `/api/v1/users/*` | `community.js`, `users.js` | 2026-05-26 | No |
| **Chat (1:1)**                                                          | `lib/pages/chat/` | 58 | `/api/v1/messages` | `messages.js`, `advancedMessages.js`, `messageSearch.js` | 2026-05-22 (1d7456f Step-19 wave) | No |
| **Voice Room**                                                          | `lib/pages/community/voice_rooms/` | 14 | `/api/v1/voice-rooms` | `voiceRooms.js` (+ LiveKit) | 2026-05 | No |
| **Waves**                                                               | `lib/pages/community/tabs/waves_tab.dart` (+ archive) | 2 | `/api/v1/community/wave(s)` AND `/api/v1/interactions/*` | `community.js` + `interactions.js` (**two impls — see §5**) | 2026-05 | No |
| **Lessons** (Duolingo)                                                  | `lib/pages/learning/lessons/` | ~9 (part of 39 in learning/) | `/api/v1/learning/lessons/*` | `learning.js` | 2026-05 | No |
| **Gamification** (XP / achievements / leaderboard / daily goals / streaks) | `lib/pages/learning/{achievements,leaderboard,streak,challenges}/` | ~14 | `/api/v1/learning/{progress,achievements,challenges}` | `learning.js` + `services/learningTrackingService.js` | 2026-05 | No |
| **AI Tutor**                                                            | `lib/pages/ai/tutor/` (+ `lib/pages/learning/main/sections/ai_tools_tab.dart`) | 12 | `/api/v1/tutor/*` | `tutor.js` (+ `tutorService.js`, `tutorImageVocabService.js`, `tutorStoryService.js`) | 2026-05 (Step-13A shipped per memory) | **Yes** — `tutor_chip_used`, `tutor_chip_completed`, `quota_*`, `paywall_*` |
| **AI Conversation**                                                     | `lib/pages/ai/conversation/` | 3 | `/api/v1/ai/conversation/*` | `aiConversation.js` | 2026-05 | No (Tutor analytics only) |
| **AI Lesson** (Assistant)                                               | (under tutor / lesson_builder) | — | `/api/v1/lesson-builder/generate`, `/:id/enhance` | `lessonBuilder.js` + `aiLessonAssistantService.js` | 2026-05 | No |
| **AI Grammar**                                                          | `lib/pages/ai/grammar/` | 1 | `/api/v1/grammar-feedback/*` | `grammarFeedback.js` | 2026-05 | No |
| **AI Pronunciation**                                                    | `lib/pages/ai/pronunciation/` | 1 | `/api/v1/tutor/pronunciation/*`, `/api/v1/speech/*` | `tutor.js`, `speech.js` | 2026-05 | Via tutor chip events |
| **AI Translation**                                                      | `lib/pages/ai/translation/` | 1 | `/api/v1/ai/translation/{enhanced,contextual,alternatives}` | `aiTranslation.js` | 2026-05-22 (Step-19 Save-phrase) | No |
| **AI Quiz**                                                             | `lib/pages/ai/quiz/` | 2 | `/api/v1/learning/quizzes/*` | `learning.js` + `aiQuizService.js` | 2026-05 | No |
| **AI Lesson Builder**                                                   | `lib/pages/ai/lesson_builder/` | 1 | `/api/v1/lesson-builder/generate/{exercises,curriculum}` | `lessonBuilder.js` | 2026-05 | No |
| **AI Chat**                                                             | == AI Conversation (no separate model) | — | (same) | (same) | (same) | No |
| **AI Story**                                                            | `lib/pages/ai/tutor/story_setup_screen.dart`, `story_reader_screen.dart` | (in tutor 12) | `/api/v1/tutor/stories/generate` | `tutor.js` + `tutorStoryService.js` | 2026-05 | Via tutor chip events |
| **AI Photo**                                                            | `lib/pages/ai/tutor/image_vocab_screen.dart` | (in tutor 12) | `/api/v1/tutor/image-vocab/{describe,grade}` | `tutor.js` + `tutorImageVocabService.js` | 2026-05 | Via tutor chip events |
| **Vocabulary / Save-to-vocab**                                          | `lib/pages/learning/vocabulary/` | 6 | `/api/v1/learning/vocabulary/*` | `learning.js` | 2026-05-22 (Step-19 Save phrase) | **No** |
| **VIP / Subscription**                                                  | `lib/pages/vip/` | 4 | `/api/v1/purchases/*` | `purchases.js`, `iosPurchase.js`, `androidPurchase.js` | 2026-05 | **Yes** — `subscription_purchased`, `subscription_purchase_failed` |
| **"See who visited" paywall**                                           | `lib/pages/profile/visitors_screen.dart`, `lib/pages/community/widgets/visitor_recall_card.dart` | 2 + card | `/api/v1/users/me/{visitors,visitor-stats,visited-profiles}`, `/api/v1/users/:id/profile-visit` | `profileVisits.js` (+ `services/profileVisitorService`) | 2026-05 | No |
| **MBTI / Blood Type / personality**                                     | `lib/pages/profile/edit_main/sections/personal_section.dart`, `lib/pages/profile/edit/blood_type_edit.dart` | 2 | None — fields on User model only, no dedicated endpoint | (`User.js` lines 212-219, surfaces via `users.js`) | Old | No |

## 2. Analytics Instrumentation State

- **SDK:** `firebase_analytics ^11.0.0` (Flutter `pubspec.yaml:58`). Init at `lib/main.dart:49`. Wrapper singleton at `lib/services/analytics_service.dart` (1–79).
- **Backend SDK:** **NONE.** `package.json` has no Firebase/Mixpanel/Amplitude/PostHog/Segment/Sentry dep, no init.
- **Total unique events fired:** **8.** All Flutter-only.

| Event | Where defined | Fired from | Params |
|---|---|---|---|
| `tutor_chip_used` | `analytics_service.dart:30-31` | tutor chip entry screens (image_vocab:60, scenario_picker:23, tutor_chat:51, story_setup:30, pronunciation_session:33) | `chip_name`, `user_tier` |
| `tutor_chip_completed` | `analytics_service.dart:39-40` | image_vocab:68, story_reader:40, pronunciation_summary_sheet:33, roleplay_chat:167, tutor_chat:145 | `chip_name`, `user_tier` |
| `quota_remaining_shown` | `analytics_service.dart:42-43` | `tutor_quota_provider.dart:84` | `chip_name`, `remaining_count` |
| `quota_hit` | `analytics_service.dart:45-46` | `main.dart:80` (global 429 hook) | `chip_name`, `tier` |
| `paywall_shown` | `analytics_service.dart:48-49` | `persona_upgrade_sheet.dart:42` | `trigger_chip`, `reason` |
| `paywall_cta_tapped` | `analytics_service.dart:51-52` | `persona_upgrade_sheet.dart:83` | `chip_name` |
| `subscription_purchased` | `analytics_service.dart:54-55` | `vip_payment_screen.dart:223, 385` | `plan`, `platform` |
| `subscription_purchase_failed` | `analytics_service.dart:57-66` | `vip_payment_screen.dart:233, 394` | `plan`, `platform`, `error_code` |
| `admin_action_taken` | `analytics_service.dart:71-78` | `admin_user_detail_screen.dart:361, 383, 409` | `action`, `target_user_id` |

### Specific coverage answers
- **Event when user saves a vocab word?** **No.** No `addVocabulary` call site fires anything; backend `learning.js:addVocabulary` is silent.
- **Event when user sends a chat message?** **No.** `messages.js:createMessage` is silent. `learningTrackingService.trackMessage` (line 44) writes XP — not an analytics log.
- **Could we answer "did user X use saved word Y in a chat within 7 days"?** **No via analytics.** Possible via raw Mongo, awkwardly:
  - `vocabularies.findOne({ user, word, createdAt })` → seed `vocab.createdAt`
  - `messages.find({ sender: userId, createdAt: { $gte: vocab.createdAt, $lte: +7d }, message: /word/i })`
  - The compound index `{ sender: 1, createdAt: -1 }` (Message.js:552) makes the time-bounded user scan cheap; the regex match on `message` is post-filter and the existing `{ message: 'text' }` text index could be used for `$text` instead of regex.
  - Missing for a clean answer: no `vocab_saved` event, no `message_sent` event, no `messageId`/`vocabId` cross-write at message-send time, no NLP lemmatization (next §), no semantic "intent to use" signal.

## 3. Vocabulary System Deep Dive

**Schema:** `models/Vocabulary.js`. Fields:
`user` · `word` · `translation` · `language` · `nativeLanguage` · `partOfSpeech` (enum) · `examples[]` · **`context.{source, conversationId, messageId, lessonId, originalSentence}`** · `pronunciation` · `audioUrl` · `imageUrl` · `notes` · `tags[]` · SRS fields (`srsLevel`, `easeFactor`, `interval`, `nextReview`, `reviewStats`, `reviewHistory[]`) · `isMastered`/`masteredAt` · `isArchived`/`archivedAt` · `isFavorite`.

| Required field | Present? |
|---|---|
| source-context: chat `messageId` | **Yes** (`context.messageId`, line 75) |
| source-context: chat `conversationId` | **Yes** (`context.conversationId`, line 71) |
| source-context: lesson | Yes (`context.lessonId`) |
| source-context: voice room | **No** |
| source-context: AI tutor session | **No** (no `tutorSessionId` field) |
| language | Yes |
| part of speech | Yes — but user-assigned (no auto-POS) |
| lemma / root form | **No** — only the inflected surface form in `word` |
| definition | Implicit — only `translation` exists |

**Save UI entry points:**
- `lib/pages/chat/message/bubble/word_long_press_handler.dart:138` — long-press on a single word in a chat bubble. Sends `exampleSentence` (full message if <200 chars). **No `messageId` is included in the payload** even though the schema accepts one.
- `lib/pages/chat/message/message_bubble.dart:736` — long-press on a full message (fallback).
- `lib/pages/learning/vocabulary/vocabulary_add_screen.dart:66` — manual add form, zero source context.

**Frontend payload** (via `LearningService.addVocabulary`, `lib/services/learning_service.dart:450-502`):
```dart
{ word, translation, language, pronunciation?, partOfSpeech?,
  exampleSentence?, exampleTranslation?, tags?, notes?, context? }
```

**Backend write endpoints:** `POST /api/v1/learning/vocabulary` (add), `PUT /api/v1/learning/vocabulary/:id`, `POST /api/v1/learning/vocabulary/:id/review`. Also written by `controllers/tutor.js:262, 759` (photo-vocab + story extraction) and `controllers/advancedMessages.js:324` ("save phrase" from chat).

**Existing vocab↔chat link:** Schema-level only. `context.messageId` can be populated back to the Message doc. **No service-layer code searches messages for vocab usage, no aggregation, no NLP.**

**NLP stack:** **None.** Backend `package.json` has no `natural`, `compromise`, `wink-nlp`, `wink-lemmatizer`, `retext`, `pos`, `nodejieba`, etc. Vocab `partOfSpeech` defaults to `'other'` unless a user fills it.

**Supported languages (Flutter `LanguageService`):** en, es, fr, de, it, pt, ja, ko, zh, ru, ar, hi, tr, vi, th, id, uz, tg. (Tajik just added in latest wave.)

## 4. Chat Message Pipeline

**Schema:** `models/Message.js`. Key fields: `sender`, `receiver`, `participants[]`, `slug`, `message` (text, ≤2000 chars), `readBy[]`, `media{}`, `mentions[]`, `corrections[]`, `selfDestruct{}`, `translations[]`, `poll`, `messageType` (enum: text|media|voice|poll|location|contact|sticker|system|call|gif), `reactions[]`, `isGroupMessage`, edit/delete flags, `replyTo`, `storyReference{}`, `forwardedFrom{}`, `pinned`.

**Storage:** **Full plaintext UTF-8** in `message` field. No app-level encryption. Translated copies stored inline in `translations[]`.

**Indexes** (`Message.js`):
- Text index: `{ message: 'text', 'media.fileName': 'text' }` (line 559)
- `{ sender: 1, receiver: 1, createdAt: -1 }` (552)
- `{ receiver: 1, sender: 1, createdAt: -1 }`
- `{ participants: 1, createdAt: -1 }`
- `{ receiver: 1, read: 1, createdAt: -1 }`
- `{ sender: 1, createdAt: -1 }`, `{ receiver: 1, createdAt: -1 }`
- `{ isDeleted: 1, createdAt: -1 }` and two `{ sender, receiver, isDeleted, createdAt }` variants
- Sparse: `selfDestruct.expiresAt`, `selfDestruct.destructAt`, `mentions.user`

**Are messages searchable?** **Yes** — both via the `text` index (`$text` search) and via `GET /api/v1/messages/search` (`controllers/messageSearch.js`).

**Cost shape for "scan a user's outgoing messages for occurrences of their saved vocab":**
- Per-user, time-bounded scan: `{ sender: userId, createdAt: {$gte: …} }` is fully covered by `{ sender: 1, createdAt: -1 }`. Cheap — single index range scan per user.
- Per-word match: either `$regex` (slow, no index help) or `$text: { $search: word }` (uses text index, returns whole-doc).
- Per-user message volume: no exact count available in code, but the schema is sized for active chat (corrections, reactions, voice/video, translations) and Step-13A quota system caps `messagesSentToday` per tier (`config/limitations.js`) — suggesting messaging is a primary surface.
- A nightly job per active user would be O(messages-by-user-since-last-run) × O(saved-vocab-words-for-user) text comparisons. Cheapest path: for each new vocab word, search messages within the user's last N days using `$text`; for each new message, check against the user's vocab list in memory.

## 5. Dependency & Complexity Map

### Shared infrastructure

| Pair | Shared? | Evidence |
|---|---|---|
| Stories ↔ Moments | **No** — separate models/controllers. Embedded UI only: `pages/moments/feed/moments_main.dart` imports the stories widget. |
| Chat ↔ Voice Room | **No** — different transport (Socket.IO vs LiveKit), different models. |
| Waves ↔ Chat | **Yes** — `controllers/community.js:252` does `Message.create({ messageType: 'sticker' })` so every wave shows up in the chat thread. Flutter `mutual_wave_dialog.dart:48` deep-links to `/chat/$userId`. ⚠ **Two wave implementations** also exist: `models/Wave.js` + `controllers/interactions.js` (UserInteraction-based, swipe-deck) is a separate path that does NOT touch Message. |
| AI Tutor ↔ AI Conversation ↔ AI Lesson | Separate models, **shared `services/aiProviderService.js`** (OpenAI client) and shared `models/TutorMemory.js`. |
| Gamification ↔ Lessons | **Yes — tight.** `controllers/learning.js:637, 796` call `learningTrackingService.trackLessonCompletion / trackQuizCompletion`, which write `User.learningStats.*` + `LearningProgress`. The same service is invoked from `socket/socketHandler.js:865, 1977, 1988, 2045` — **every chat message awards XP**. |
| Vocabulary ↔ Lessons ↔ AI Tutor | **Yes** — all three write `Vocabulary`: `learning.js:205/325/350`, `tutor.js:262/759`, `advancedMessages.js:324`. Read by `aiQuizService`, `recommendationService`, `tutorStoryService`. |
| VIP gating | One method (`User.js:1107 isVIP()`) read by `middleware/checkLimitations.js`, `middleware/rateLimiter.js:173`, all 5 tutor chips, moments/stories creation, translation, profile views, profile visitors, IAP reconciliation. Flutter single source: `providers/provider_models/users_model.dart:47 isVip` + `utils/feature_gate.dart`. |

### Removal-difficulty estimate

| Kill-list feature | Difficulty | Why (file paths) |
|---|---|---|
| **Stories** | **Risky** | `Message.js:228-238 storyReference.storyId`; `controllers/stories.js:506-815` writes Messages for story replies; `models/StoryHighlight.js` depends on Story; Flutter `chat/message/message_bubble/text_message_view.dart` + `image_message_view.dart` import `story_viewer_screen.dart`. Migration needed to null/drop story-reply messages. |
| **Lessons** | **Risky** | XP/streak side-effects in `learning.js:637/796`; `aiLessonAssistantService.js:7-8`, `aiLessonBuilderService.js:8-9`, `recommendationService.js:7-8` all import `Lesson` + `LessonProgress`; `User.learningStats.lessonsCompleted` written by `learningTrackingService.js:369`. Cascades into AI Lesson Assistant + AI Lesson Builder. |
| **Gamification (XP/achievements/leaderboard/daily goals/streaks)** | **Risky** | `socket/socketHandler.js:865, 1977, 1988, 2045` awards XP for chat messages + corrections — chat silently depends on the service. `aiConversation.js:24`, `grammarFeedback.js:27, 185`, `learning.js:536` read `learningStats.proficiencyLevel` to set CEFR for AI. `users.js:14 USER_PUBLIC_FIELDS` exposes `level languageLevel streakDays totalXp`. Migration: point AI services at `User.languageLevel` (already CEFR enum at User.js:580) before drop. |
| **AI Tutor** | **Risky** | Owns ~150 lines of User.js quota machinery (`consumeQuota`, `getQuotasSnapshot`, 10 counter fields lines 399-408 / 461-470). Hero of the Learning tab (`ai_tools_tab.dart:14-20`) — removing leaves an empty tab. ~127 `aiTutor*` ARB keys × 14 locales. |
| **AI Conversation** | **Moderate** | Self-contained `AIConversation.js` + `aiConversation.js` controller. Only outside coupling: reads `learningStats.proficiencyLevel` (24) and `TutorMemory` (`aiConversationService.js:87`). |
| **AI Lesson (Assistant)** | **Moderate** | Depends on `Lesson` + `LessonProgress` + `LearningProgress` — falls cleanly if Lessons go too. |
| **AI Grammar** | **Moderate** | Own model `GrammarFeedback.js`; `AIConversation.js:21-24` has a `grammarFeedback` ref; writes `TutorMemory`. |
| **AI Pronunciation** | **Moderate** | Own model `PronunciationAttempt.js`, `services/speechService.js`, `services/pronunciationScoring.js`, plus `jobs/pronunciationAudioPurgeJob.js`. Tutor counter field `pronunciationDrillsToday`. |
| **AI Quiz** | **Moderate** | `AIGeneratedQuiz.js`; `aiQuizService.js` reads `Vocabulary` + `LearningProgress` + `TutorMemory`. Drop with Lessons. |
| **AI Lesson Builder** | **Trivial** | `controllers/lessonBuilder.js` + `services/aiLessonBuilderService.js` + `pages/ai/lesson_builder/`. Nothing imports the builder back. |
| **AI Chat** | **Trivial** | Same code as AI Conversation; no separate model. |
| **AI Story** | **Trivial** | `tutorStoryService.js` + `story_setup_screen.dart` + `story_reader_screen.dart`. Counter `storyGenerationsToday`. |
| **AI Photo** | **Trivial** | `tutorImageVocabService.js` + `image_vocab_screen.dart`. Counter `photoVocabToday`. |
| **MBTI / Blood Type / personality** | **Trivial** | Fields at `User.js:212-219`. Read sites: `auth.js:370-426`, `users.js:14, 749, 788`, `emailTemplates.js:1043, 1047`, `validators/authValidator.js:73-78`. No logic depends. |
| **"See who visited" paywall** | **Moderate** | `models/ProfileVisit.js` + `controllers/profileVisits.js` + `services/profileVisitorService` + Flutter `pages/profile/visitors_screen.dart` + `pages/community/widgets/visitor_recall_card.dart` (it's a homepage card too). `User.profileStats.{totalVisits,uniqueVisitors,lastVisitorUpdate}` (508-521) + `notificationPreferences.visitorAlert` + `privacySettings.anonymousProfileVisits`. |

### User-model field ownership (cheap drops vs. migration)

Per `models/User.js`, dropping the full kill list above yields these field-level deletions:
- **Cheap drops (no migration):** `mbti`, `bloodType` (212-219); `closeFriends[]`, `closeFriendsOf[]` (524-533, Stories privacy); `profileStats.*` (508-521, visitors); `learningPreferences.*` (918-944, gamification); 5 learning notification toggles (147-166); 10 tutor quota counter pairs across `visitorLimitations` (399-408) and `regularUserLimitations` (461-470); `storiesCreatedToday` counter (420-443). **~35 fields total.**
- **Needs migration first:** `learningStats.proficiencyLevel` (read by AI services) → repoint to `User.languageLevel`. Then `learningStats.*` (863-915) and `USER_PUBLIC_FIELDS` / `USER_LIST_FIELDS` (`users.js:14-15` exposing `level languageLevel streakDays totalXp`) become safe.
- **i18n dead weight after full cull:** Sampling `app_en.arb` (2,207 keys total): ~171 `tutor*`, 58 `story*`, 32 `xp*`, 30 `vocabulary*`, 29 `streak*`, 16 `leaderboard*`, 15 `lesson*`, 7 `achievement*`, 7 `quiz*`, 6 `blood*`, 5 `grammar*`, 4 `mbti*`, 4 `challenge*`. **Conservative ~330–390 ARB keys × 14 locales ≈ 4,600–5,300 generated lines** of localization become dead. Notably ~127 of the just-shipped Tajik strings are AI-Tutor keys.

## 6. Current Monetization Surface

### Paywall trigger points (Flutter)

| File:line | Trigger |
|---|---|
| `lib/pages/chat/chat_screen_wrapper.dart:150` | Daily message limit hit for non-VIP → "Unlimited Chats" |
| `lib/pages/chat/header/chat_app_bar.dart:391` | Voice/video call CTA → "Unlimited Calls" |
| `lib/pages/chat/input/chat_input_section.dart:192` | Per-message limit indicator → VipPlansScreen |
| `lib/pages/profile/profile_main/sections/profile_stats_row.dart:160` | Profile-visitors stat tile (VIP gate) |
| `lib/pages/learning/main/sections/ai_tools_tab.dart:219` | `VipLockedFeature` overlay on 5 AI tools |
| `lib/pages/community/tabs/genders_tab.dart:14` | Imports VipPlansScreen for filter gating |
| `lib/pages/community/filter/community_filter_sheet.dart:16` | Filter-restriction paywall |
| `lib/pages/vip/vip_plans_screen.dart` | Main upsell hub |
| `lib/pages/vip/vip_payment_screen.dart` | iOS/Android IAP transaction |
| `lib/pages/vip/visitor_upgrade_screen.dart` | Visitor-mode limit screen |
| `lib/pages/vip/vip_status_screen.dart` | Renewal flow |
| Tutor chip: `persona_upgrade_sheet.dart:42, 83` | `paywall_shown` / `paywall_cta_tapped` events fire here |

### What VIP unlocks (from code, not marketing)

- 5 AI tools flipped on (`vipOnly: true` in `ai_tools_tab.dart:528`): **AI Conversation, AI Lessons (gated), AI Pronunciation, AI Quiz, AI Lesson Builder**. Grammar + Translation are free.
- Chat: unlimited daily messages (gate at `chat_screen_wrapper.dart:150`)
- Voice/video calls: unlocked (`chat_app_bar.dart:391`)
- Profile visitors list visible (`profile_stats_row.dart:160` + `profileVisits.js`)
- Higher quotas across the board per `config/limitations.js`: AI conversation 10/hr (vs 5), Translation 40/day (vs 5), Profile views 500/day (vs 20), Voice rooms unlimited (vs 3/day), Tutor chips 10+/day (vs 3)
- Community filters: gender/age filters (genders_tab, community_filter_sheet)

### Product IDs / tiers

- **Not RevenueCat.** No `revenuecat` import found anywhere. Direct Apple IAP + Android Play Billing.
- Tier enum: `['monthly', 'quarterly', 'yearly']` (`User.js:287`)
- iOS: `controllers/iosPurchase.js:173, 249, 253` parses `product_id` from receipts; `:125` matches `transaction_id`. Product IDs themselves come from the receipt/Apple, not hardcoded in code.
- Android: parallel verification in `androidPurchase.js`.
- Activation: `User.activateVIPSubscription()` instance method; `vipSubscription.transactions[]`, `warnings`, `gracePeriodNotified` all on User.

## 7. Technical Debt Flags

### TODO/FIXME/HACK/DEPRECATED

**Flutter:**
| File:line | Comment |
|---|---|
| `lib/pages/moments/create/create_moment.dart:1630` | "Re-enable video preview section when needed (commented out to reduce app size)" |
| `lib/pages/moments/create/create_moment.dart:2034` | "Re-enable video upload when needed" |
| `lib/pages/learning/vocabulary/vocabulary_screen.dart:229` | "Open vocabulary detail/edit" |
| `lib/pages/learning/vocabulary/vocabulary_screen.dart:254` | "Delete vocabulary" |
| `lib/pages/community/single/single_community_topics.dart:156` | "TODO(C16): verify this navigation — ProfileTopicsEdit is reached" |

**Backend:**
- `controllers/callController.js` — header comment `@desc [DEPRECATED] Get ICE servers for WebRTC. Retired in Step 8 / C3` — route still registered.

### Feature flags / kill switches

| Flag | Where | Default | Gates |
|---|---|---|---|
| `AI_QUOTA_ENABLED` | `config/limitations.js:11` (backend env) | true in prod (per memory: shipped in Step-13A) | Tutor chip per-day quotas |
| `isVip` (boolean on User) | `User.js:1107` + `utils/feature_gate.dart` (Flutter) | false | All paywalled features |
| `vipOnly` per-feature | `ai_tools_tab.dart:528` | per-feature | Which AI tools show the lock overlay |

### Status of features the user flagged

- **Lessons (user said "doesn't work"):** Code is **not a stub** — `controllers/learning.js` implements `getLessons`, `startLesson`, `submitLessonAnswer`, `completeLesson`; `Lesson.js` schema has exercise types, prerequisites, progress tracking; Flutter `pages/learning/lessons/lessons_screen.dart` is a real screen. **The runtime breakage the user is reporting is not visible at the source-code level** — likely a data/content gap (no seeded curriculum) or a regression behind a flag, not a missing implementation. Worth a runtime smoke-test rather than a code audit to localize.
- **Step-13A VIP gating (per memory):** Shipped. `AI_QUOTA_ENABLED` is the documented kill switch.
- **Tajik locale (just merged):** 5,751 lines of generated localizations + 1,773-line ARB. Material/Cupertino delegates fall back to Russian (`94e5bb4`). Note for the pivot: ~127 Tajik strings serve features on the kill list.

---

### Three high-leverage callouts for the pivot decision

1. **Chat silently depends on Gamification.** `socket/socketHandler.js` lines 865, 1977, 1988, 2045 award XP per message/correction. Whoever cuts gamification must strip those calls in the same wave.
2. **AI services read `learningStats.proficiencyLevel`** (`aiConversation.js:24`, `grammarFeedback.js:27/185`, `learning.js:536`). Repoint to `User.languageLevel` (the CEFR enum already on User.js:580) before any `learningStats` drop.
3. **The vocab→chat join the user is exploring is one schema change away.** Vocabulary already stores `context.messageId` (line 75). The chat-side save handler (`word_long_press_handler.dart:138`) does **not** populate it. Wire that single field through and the "did user X use saved word Y in chat" query stops being a regex-scan and becomes a join — without needing analytics or NLP. Lemmatization is still missing for matching inflections, but the structural plumbing is mostly in place.

---

## 8. Prod Measurement (2026-05-26, MongoDB Atlas `test` DB)

Read-only Mongo queries against live prod. Cutoff for "30d" = `2026-04-26`. All numbers verified — anomalies (profile-visit field name, VIP active counter) re-run.

### Baseline

| Metric | Value |
|---|---|
| Total users | **428** |
| WAU (lastActive ≥ 7d) | 103 (24%) |
| MAU on chat (distinct senders/30d) | **241 (56%)** |
| Active VIP subscribers | **0** (1 user has `userMode:'vip'` but `vipSubscription.isActive: false`) |

### Per-feature 30d traffic

| Feature | Lifetime | 30d | Distinct users | Notes |
|---|---|---|---|---|
| Chat messages | 10,216 | **3,511** | 241/30d | **The product.** |
| Profile visits | 4,582 | **1,733** | **267/30d (62%)** | #2 feature. Paywall ≠ converting. |
| Web visits | — | 711 | — | Web tracker alive |
| Waves | 437 | 288 | — | Engaged |
| Translation (enhanced) | 61 | 61 | — | All recent; moderate use |
| AI Tutor sessions | 35 | **35** | **11 (2.6%)** | All in 30d — Step-13A launch traffic; small audience |
| Moments | 55 | 27 | — | Low |
| Voice rooms | 34 | 19 | — | Recent infra |
| Vocab saves | 25 | 21 | — | Step-19 spike: 21 of 25 ever, in 30d |
| Stories | 49 | 11 | 33 lifetime creators (7.7%) | Marginal |
| Lessons (progress) | 13 | 6 | 12 ever (2.8%) | `lessonsCompleted > 0`: **0 users.** Confirmed broken/unused. |
| Grammar feedback | 9 | 3 | — | Dead |
| Voice rooms | 34 | 19 | — | Recent |
| AI Conversation | 22 | **0** | 0 | **Dead** |
| AI Quiz (generated) | 14 | **0** | 0 | **Dead** |
| AI Pronunciation attempts | **0** | 0 | 0 | **Never used** |
| User achievements awarded | **0** | 0 | 0 | **Award system never fires** |

### Fill rates

| Field | Filled | % of users |
|---|---|---|
| `mbti` | 14 | 3.3% |
| `bloodType` | 12 | 2.8% |
| `learningStats.totalXP > 0` | 23 | 5.4% |
| `learningStats.currentStreak > 1` | **0** | 0% |
| `learningStats.lessonsCompleted > 0` | **0** | 0% |

### Vocabulary deep dive

- Saves by source: `manual: 15`, `conversation: 10`, `lesson/quiz/import: 0`
- Records with `context.messageId` populated: **1 of 25** — confirms audit prediction. Chat long-press save (`word_long_press_handler.dart:138`) drops the messageId on the floor even though the schema accepts it.
- Recent saves dated 2026-05-22 — Step-19 Save-Phrase launch is exactly when conversation-source saves started appearing.

---

## 9. Kill-List Verdict (data-backed)

| Feature | 30d signal | Verdict | Reason |
|---|---|---|---|
| **AI Pronunciation** | 0 ever | **Drop now** | Never used. Trivial code removal per §5. |
| **AI Quiz** | 0/30d (14 ever) | **Drop now** | Dead. Moderate. |
| **AI Conversation** | 0/30d (22 ever) | **Drop now** | Dead. Moderate. |
| **AI Grammar** | 3/30d | **Drop now** | Effectively dead. Moderate. |
| **AI Lesson Builder** | n/a | **Drop now** | Trivial; no consumers. |
| **Gamification (XP/achievements/leaderboard/streaks/daily goals)** | 0 achievements ever, 0 streaks >1, 5% have any XP | **Drop** | Zombie feature. Chat-side XP awards must come out same wave per §5 callout #1. |
| **Lessons** | 0 users have completed a lesson | **Drop** | The "broken" report is real — either no curriculum seeded or completion logic broken. Either way, no one is using it. **Risky** removal per §5 (cascades into AI Lesson Assistant). |
| **MBTI / Blood Type** | 3% fill | **Drop now** | Trivial. No logic depends. |
| **Stories** | 11/30d, 33 creators ever (7.7%) | **Drop** (medium-priority) | Marginal use; expensive to keep (story-reply messages, highlights, close-friends list). Risky removal per §5. |
| **AI Tutor** | 35/30d, 11 users | **Keep — but quarantine** | Only AI surface with traction; all 35 sessions are post-Step-13A. Don't expand; measure conversion to VIP (currently 0) before more investment. |
| **AI Translation** | 61/30d | **Keep** | Moderate adoption; trivial isolation. |
| **Vocabulary** | 21/30d (spike from Step-19) | **Keep — wire `messageId` next** | Recent feature; saves arriving. Single 1-line fix in `word_long_press_handler.dart:138` unlocks the vocab→chat join. |
| **"See who visited" paywall** | 1,733/30d, 267 distinct visitors (**62% MAU**) | **KEEP — and re-examine paywall** | #2 most-used feature behind chat. But 0 VIP conversions despite this traffic — paywall is leaving money on the table or pricing is wrong. |
| **Waves** | 288/30d | **Keep** | Engaged. Resolve the two-implementation question (`models/Wave.js` vs `controllers/community.js → Message`). |
| **Moments** | 27/30d | **Keep** (cautiously) | Low but non-zero; cheap to keep. |
| **Voice rooms** | 19/30d | **Keep** | Recent infra investment; let it grow. |

### Top-line strategic findings

1. **VIP has zero paying subscribers.** The entire monetization apparatus — paywalls, IAP plumbing, tier counters, 5 gated AI tools — exists for an empty audience. Either the launch hasn't happened in earnest, the price is wrong, or activation is broken. **This is the highest-leverage thing to investigate before deciding what to build next.**
2. **The app is a chat app with profile visits attached.** 56% MAU on chat, 62% on profile-visits. Everything else (lessons, gamification, most AI tools, stories) is a long tail with single-digit user counts.
3. **The vocab→chat thesis is on a knife's edge.** Save-phrase shipped 4 days ago and already accounts for 84% of all vocab records ever (21/25). One Flutter line (`word_long_press_handler.dart:138`) populates `context.messageId` and the data becomes structurally joinable to the message that produced it — the seed corpus for whatever vocab-as-practice loop comes next.
4. **Gamification is fully dead.** Zero achievements ever awarded, zero streaks > 1 day. Removing it is mostly safe — but the chat XP write-path (`socketHandler.js:865, 1977, 1988, 2045`) must come out in the same change or chat will start no-op-ing on a deleted service.
5. **Pronunciation has zero attempts ever** but `models/PronunciationAttempt.js`, `services/speechService.js`, `services/pronunciationScoring.js`, and `jobs/pronunciationAudioPurgeJob.js` are all alive in the codebase. Pure dead weight.
