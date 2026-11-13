# Stories features (app side, Plan B2) - handoff

Branch `feat/stories-features-app` (merge base 4e64a207, the smart-feed app merge). Not built, not versioned, not submitted, not pushed. The server half is already deployed with all five story switches off.

## 1. What changes for users the moment this build ships (server as it is today, all five switches off)

Exactly one thing:

1. **Answers to a story's question box are no longer reported as failed.** The server answers an accepted answer with 201; the app only accepted 200, so the answer was saved but the person saw "failed". Now it reads as sent. This is live for everyone and is not behind any flag.

Nothing else is visible. With every flag off, the app does not show the new sticker choices, the progress chip on your ring, the "watched to the end" report, or the extra block in the viewers sheet, and it sends no new requests (no completion reports, no upload keys). Three things are not behind an app flag, but the server decides whether they ever appear:

- A learning sticker (correction, quiz, word) that arrives in a story is drawn and can be used. The server sends none until its switch is on.
- The viewers sheet shows its summary block when the server sends one (only to the owner, only with `STORY_INSIGHTS_ENABLED` on).
- The `story_did_well` push opens the new insights screen. The server sends none until `STORY_INSIGHTS_ENABLED` is on. (On this build the route exists whatever the flags say.)

## 2. What appears with each server switch (backend's recommended order)

The app reads its flags from app-config; they follow the server switches by themselves. All builds need to be this build or later.

| Order | Server switch | App flag | What users see |
|---|---|---|---|
| 1 | `STORY_UPLOAD_QUEUE_ENABLED` | `storyUploadQueueEnabled` | Posting a story returns to the feed at once. The story uploads in the background; your own ring shows a small progress chip, and a "Tap to retry" badge if it failed (sheet: Retry / Remove; a story whose file is gone offers Remove only; the daily-limit failure opens the limit dialog first). A story is posted once even if the app retries, restarts, or the network drops. Needs this build. |
| 2a | `STORY_STICKER_CORRECTION_ENABLED` | `storyStickerCorrectionEnabled` | Sticker sheet offers "Correction": a sentence in your learning language. Viewers type a correction (once; hidden when replies are off, for your own story, and for an expired or highlighted story). The correction reaches the author as a plain chat message. |
| 2b | `STORY_STICKER_QUIZ_ENABLED` | `storyStickerQuizEnabled` | Sticker sheet offers "Quiz": question with 2 to 4 options and a marked correct one. Viewers answer once and see the result; the author sees results at once. |
| 2c | `STORY_STICKER_WORD_ENABLED` | `storyStickerWordEnabled` | Sticker sheet offers "Word": word, meaning, optional example. Viewers can save it to their vocabulary. |
| 3 | `STORY_INSIGHTS_ENABLED` | `storyInsightsEnabled` | Viewers who watch a story to the end are counted. The viewers sheet shows views, watched to the end, replies, reactions and a sticker block (poll / quiz options with counts, correction count, question-box count) and a done-all mark per viewer. The `story_did_well` push (24 to 48 h after posting, 09:00 to 21:00 author's time, only for an expired story) opens that story's insights. |

2a, 2b, 2c are independent, any order. Do not turn on switch 3 before the server owner's native check of the 18 push translations (the backend's note), and do not before this build is in people's hands: completions only count viewers on the new app.

## 3. What is NOT in this build

- Dragging a sticker to a position (a new sticker sits in the middle of the story; the viewer ignores x / y).
- A story route beyond the insights screen (`/story-insights/:storyId`); no deep link opens a story itself.
- Reading question-box responses from the viewers sheet (it shows the count only; responses open from the story viewer).
- A card for correction messages in chat (they arrive as plain text `"sentence" -> "correction"`).
- Reels playback items (they wait on the other branch, `perf/reels-playback-r1`).
- A "story failed to load - Retry / Skip" state in the viewer.
- The owner's list of who corrected (the server sends ids only; the app shows the count).
- Poll / quiz percentages in the viewers sheet.

## 4. Known open issues (most important first)

Affects people if the switches are on:
1. The device checks in section 5 have not been run; the ring chip's look in particular is untested on a real device.
2. A completion before app-config has loaded is skipped (rare; config loads at start).
3. Own-story detection for completion reports uses only the "own story" flag of the screen; an own highlight / archive replay opened without it would send completions (the server leaves own views untracked).
4. The `story_did_well` push: if the story's views cannot be loaded, the story archive opens. If the archive itself fails it shows its own error state; there is no further fall back to the Moments tab. A missing or malformed story id opens the Moments tab; signed out opens login.
5. The viewers sheet can show "Seen by N" and "N views" differently on a stale response. The question-box line is built as "Responses: N" with an English colon and order (wrong punctuation in ja / zh / ar); "0 watched to the end" is always shown.
6. A quiz answer that succeeds with no quiz in the body shows a failure; a 200 with `{"success": false}` on a quiz answer would read as success.
7. A queued story: the 10-minute attempt timeout does not abort the request (a retry can upload in parallel; the key prevents a duplicate); a completed story keeps the last attempt's error text; a second `initialize()` while storage still says queued re-sends an in-flight story (same key, no duplicate, one wasted upload).
8. No test was seen for the "file missing" failed sheet (Remove only) in the last Task 7 round; checked by reading only. The bake-then-queue and video queue paths have no widget test either.
9. The sticker editors: a pt "Desafio" label for Quiz is flagged for native review; the "Poll:" / "Question:" chip labels are hard-coded English (they were before).

Pre-existing, not caused by this branch (do not lose):
- The story viewer overflows by 24 px at 320 px wide, with no sticker (header / reply bar). One test drains it once, which could mask a new overflow in the same frame.
- The story viewer has no background / foreground handling (a story keeps playing / timing across app lifecycle), and `_disposeVideoController` calls `setState` after an await without a mounted check (`story_viewer_screen.dart`, around line 330).
- The moment composer's default-language label (`create_moment.dart`, around lines 347 to 349) passes the learning-language NAME to a code lookup; it may show a wrong or blank label. Unverified. (The story sticker code was fixed for this; the moment composer was not touched.)
- `test/services/session_reset_test.dart` fails on main as well; it lists `alreadyWavedProvider`, `userMomentsPagedProvider`, `userMomentsTotalProvider`.
- A save that lands before the upload queue reads prefs can overwrite the last session's tasks; one malformed task drops the whole queue on load. `upload_queue_service.dart` is about 1,180 lines.
- `flutter analyze` reports about 1,100 info-level hints project-wide (0 errors, 0 warnings).

## 5. Device checks before release

Set the server switches on a test server (or use a debug server) first, with two test accounts A and B.

- [ ] Queue on: post a photo story, a video story and a text story. Each returns to the feed at once, the ring chip shows progress, then the story appears once.
- [ ] Queue on, airplane mode: post the same three. Kill the app, relaunch, restore the network. Each story appears exactly once (no duplicate).
- [ ] Hit the daily story limit with the queue on. Confirm the failed ring offers Retry (and the limit dialog opens first), and no automatic retry loop starts.
- [ ] Sign out with a story still queued; sign in as another user. The first user's story is not posted under the second; the second user's ring shows no chip.
- [ ] Correction: A posts a story with a correction sticker; B corrects it. Check the count shows for B, A's chat has the message, and B cannot correct twice. Repeat with a blocked pair (B sees the unavailable message) and with replies turned off (no correction field).
- [ ] Quiz: A posts a quiz; B answers; B sees the correct option and percentages; A sees results; B cannot change the answer. Same blocked / replies-off checks.
- [ ] Word: A posts a word; B saves it; it appears in B's vocabulary with its example. Saving twice is harmless.
- [ ] Expired / highlighted story: open a story with a sticker from a highlight or the archive. The sticker is read-only.
- [ ] Correction field with the keyboard open on a small screen (320 to 360 wide) and in Arabic (right to left): the field stays visible and does not overflow; the story is paused while typing and resumes after.
- [ ] A story from an account on the old app version shows normally on the new one; a new-version story with a sticker shows as a plain story on the old app.
- [ ] Viewers sheet on your own story, with the insights switch on (summary block shown) and off (sheet identical to before).
- [ ] `story_did_well` push: send a test push with `{type: 'story_did_well', storyId}` for one of your expired stories while the app is KILLED. The app opens the insights screen with the summary. Repeat signed out (goes to login), with a wrong id (archive) and with no id (Moments tab).
- [ ] The ring chip's look (size, text in long languages, dark mode, the failed badge).
- [ ] Flags all off: confirm nothing on the stories bar, composer or viewer looks different from the current release.

## 6. Strings needing native review (19 locales; machine-written)

- Task 3 (`stories_features_3`): storyStickerCorrection, storyStickerQuiz, storyStickerWord, storyCorrectionSentenceHint, storyQuizQuestionHint, storyQuizOptionHint, storyQuizMarkCorrect, storyWordHint, storyWordMeaningHint, storyWordExampleHint, storyQuizDuplicateOption. (pt "Desafio" for Quiz flagged.)
- Task 4 (`stories_features_4`): storyCorrectThis, storyCorrectionFieldHint, storyCorrectionSent, storyCorrectionAlready, storyCorrectionsReceived (plural), storyQuizCorrect, storyQuizWrong, storySaveWord.
- Task 6 (`stories_features_6`): storyUploadFileMissing.
- Task 7 (`stories_features_7`): storyUploading, storyUploadRetry, storyUploadRemove, storyUploadFailed.
- Task 8 (`stories_features_8`): storyInsightViews, storyInsightCompleted, storyInsightReplies, storyInsightReactions, storyInsightQuizCorrect, storyInsightCompletedMark (several are plurals; check ru and ar).
- Task 9: no new strings.

## 7. Server dependency and order

Backend is deployed with all five switches off (nothing changes server-side until a switch is set). Order: ship this build first and wait for people to update; then switch 1, then 2a / 2b / 2c, then 3 (after the native check of the `story_did_well` push translations). Each switch is one line in `config/config.env` plus `pm2 restart language-app --update-env`; the app flags follow by themselves (the app re-reads config on resume, at most every 2 minutes). To undo a switch, set it false: stored data stays. See the backend's `docs/rollout/moments-smart-feed.md`, section "Stories features".
