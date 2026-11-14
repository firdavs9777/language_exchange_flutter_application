# AI Study "My words" and study doors (app side, Plan S4) - handoff

Branch `feat/ai-study-my-words-app` (base app main a0de5745). Not built, not versioned, not submitted. The server half is on backend branch `feat/ai-study-my-words`, behind `STUDY_FROM_CHATS_ENABLED` and `STUDY_DOORS_ENABLED` (both off).

**Nothing in this build was checked on a device.** Everything below comes from reading the code and from automated tests. All paths are under `bananatalk_app/`.

## 1. With both switches off (today)

Nothing a person sees changes. No new screen is reachable, no new request is sent, and no new text is shown. The study hub has the same parts in the same order as now. An automated test compares the hub's full list of parts against today's list. The pronunciation screen opened from the hub behaves as before: it starts on the first sample sentence and is scored as practice.

Things that change behind the scenes with the switches off (none of them visible):
- On sign-out, the learner's words and mistakes are cleared with the rest of their data (`lib/services/session_reset.dart`).
- The pronunciation screen can be opened with a sentence and a language. Only "Say it" (below) does this.

## 2. What a person sees with each switch on

The two app-config keys come from the server's switches: `studyFromChatsEnabled` = `STUDY_FROM_CHATS_ENABLED`, `studyDoorsEnabled` = `STUDY_DOORS_ENABLED`.

### `studyFromChatsEnabled` on, doors off: nothing in the app

The server starts saving words people look up in chats and the corrections they get (the server's capture). The app shows **nothing new**: the My words screen can only be reached through the doors hub, so with the doors off nobody can open it. The app does not ask the server for the list.

### `studyDoorsEnabled` on: the doors hub

The AI Study tab changes from today's grid of features to three doors, in this order under Today's pack:

1. **My words and mistakes** (green card). It shows a count line such as "3 words, 1 mistake to look at". With no words and no mistakes it shows how many review words are due ("4 words are ready"). With nothing due either, it shows "Words you look up in chats will appear here". Both of those lines show only while chat capture (`studyFromChatsEnabled`) is on. With capture off, the card shows its title alone. Tapping it opens the My words screen.
2. **Talk** (purple card). Tapping it opens the AI tutor. If no tutor persona is chosen yet, the persona picker opens first, as it does from today's tutor tile. The card shows the same "VIP" or "N conversations left today" note as today's tutor tile. A **Roleplay** text button on the card opens roleplay the same way.
3. **More ways to study** (plain row). This opens the More screen: the recommended tile (when there is one), the vocabulary packs card, and every feature group from today's grid except the tutor and roleplay (those are on the Talk card). A group with nothing left in it is not shown.

The progress card stays under the doors, as today. In the first week, the guide card's "See all features" button opens the More screen, because the grid is no longer on the hub.

### The My words screen (doors on)

- **From your chats**: words looked up in chats, each with **Keep** (adds it to the learner's vocabulary for review), **Dismiss** (removes it from the list) and **Say it**. A row leaves as soon as it is tapped, and comes back in its place with "That didn't work. Try again." if the server refuses.
- **Mistakes**: what the learner wrote, the correction and, when there is one, why. **Got it** counts up ("1 of 3"). The row leaves after the third time. **Say it** speaks the correction. A mistake with no correction shows neither the Correction line nor Say it.
- **Words to review**: how many vocabulary words are due, with a **Review** button that opens the existing review screen.
- After every Keep, Dismiss and Got it, the list and the hub card's count are fetched again. The server sends at most 20 of each kind, so the next rows come in as rows are cleared. "Nothing waiting" shows only when the server really has nothing left and nothing is loading.
- The screen fetches again each time it opens, and on pull to refresh. A failed refresh keeps the rows on screen and shows "Something went wrong" once.

If `studyFromChatsEnabled` is off while the doors are on, the screen shows only the review section, or "Nothing waiting".

### "Say it" (doors on)

Say it opens the pronunciation screen with the word or corrected sentence already filled in, in the language of the word or mistake. An exact language match wins, so a Traditional Chinese (`zh-TW`) sentence is scored as `zh-TW`, not as the first Chinese in the list. While the sentence is unchanged, the server is told it is the learner's own sentence (`source: 'own'`). If the learner edits the text, it is scored as normal practice.

## 3. Order to turn things on

1. Deploy the backend branch (switches off).
2. Turn on `STUDY_FROM_CHATS_ENABLED` on the server. Capture starts. Nothing changes in any app.
3. Release a build that contains this branch and wait until most active learners have it.
4. Do the device checklist (section 4) on that build.
5. Turn on `STUDY_DOORS_ENABLED`.

In the app the two switches act as one feature. The screen needs the doors, and the doors' My words card has nothing to show without capture. So once the build is out, both should be on together. Capture goes first so the lists already have something in them on the day the doors open. Do not turn the doors on before this build is out. Older builds ignore the key, so nothing breaks, but nobody would see the doors.

## 4. Device checklist (before either switch goes on for real)

Use a test account with the switches turned on for it, or a staging server. Check each item on one iPhone and one Android phone.

**Hub with doors**
- [ ] Order under Today's pack: My words, Talk, More ways to study, then the progress card. The feature grid, vocabulary packs card and recommended tile are not on the hub.
- [ ] Dark mode: all three doors are readable, and the card text is clear on the green and purple cards.
- [ ] Small phone (iPhone SE size), and the largest system text size: nothing is cut off. Card titles can wrap to two lines, and the emoji box is not clipped.
- [ ] A language with long strings (German or Russian app language): the card lines and the Roleplay button fit.
- [ ] An RTL language (Arabic app language): the layout is mirrored and the counts read correctly ("كلمتان" for 2 words).
- [ ] With the doors switched on while the app is open, the hub switches layout once when app-config arrives. Note how it looks (known, see section 7).

**My words**
- [ ] Keep a word: the row goes, and the word appears in Vocabulary for review.
- [ ] Dismiss a word: the row goes and does not come back after leaving and reopening.
- [ ] Got it on one mistake three times: "1 of 3", then "2 of 3", then the row goes. Leave after the first tap, reopen, and "1 of 3" is still shown.
- [ ] Back on the hub after each of the above: the card's count has dropped.
- [ ] Pull to refresh: the list reloads.
- [ ] Airplane mode, with rows already loaded (open the study tab online first, so the card has its counts):
  - Go offline and open the screen: the rows are shown.
  - Pull to refresh: "Something went wrong" shows once, and the rows stay.
  - Tap Keep: the row goes, then comes back in its place with "That didn't work. Try again.". Dismiss and Got it show the same line.
- [ ] Airplane mode from a cold start:
  - Force-quit the app and stay offline. Open the study tab, then the My words screen: "Something went wrong" and a Retry button are shown.
  - Go online and tap Retry: a spinner shows (a second tap does nothing), then the list loads.
- [ ] Reopen after all of the above: nothing kept, dismissed or finished comes back.
- [ ] An account with more than 20 words: clear the first rows and the next ones come in. "Nothing waiting" never shows in between.

**Say it**
- [ ] From a word (candidate) in a non-English language, such as French or Korean: the screen opens with that word in that language, and scoring works.
- [ ] From a mistake in a non-English language: the corrected sentence and its language are filled in.
- [ ] If possible, a `zh-TW` word: Traditional Chinese is selected, not Simplified.

**Talk, Roleplay, More**
- [ ] Talk with no persona chosen: the persona picker opens first, then the tutor.
- [ ] Talk with a persona: the tutor opens directly.
- [ ] Roleplay button: the same as Talk, but it opens roleplay.
- [ ] A free account that has used today's tutor conversations: the Talk card shows "0 conversations left today" and tapping it opens the upgrade sheet.
- [ ] More screen: every feature except the tutor and roleplay is there, and each opens.

## 5. Native review: 18 machine-drafted languages, 24 keys

The English is written by us. The other 18 were machine-drafted and need a native speaker: Arabic (ar), German (de), Spanish (es), French (fr), Hindi (hi), Indonesian (id), Italian (it), Japanese (ja), Korean (ko), Portuguese (pt), Russian (ru), Tajik (tg), Thai (th), Tagalog (tl), Turkish (tr), Vietnamese (vi), Chinese Simplified (zh), Chinese Traditional (zh_TW).

The 24 keys (in `lib/l10n/app_<locale>.arb`):

`myWordsTitle`, `myWordsCountWords`, `myWordsCountMistakes`, `myWordsCardBoth`, `myWordsCardOne`, `myWordsCardEmpty`, `myWordsFromChats`, `myWordsMistakes`, `myWordsToReview`, `myWordsDueCount`, `myWordsKeep`, `myWordsDismiss`, `myWordsGotIt`, `myWordsGotItProgress`, `myWordsSayIt`, `myWordsReview`, `myWordsEmpty`, `myWordsActionFailed`, `myWordsYouWrote`, `myWordsCorrection`, `studyDoorTalk`, `studyDoorTalkSubtitle`, `studyDoorRoleplay`, `studyDoorMore`.

Changed in the final fix round, so please look at these closely:
- `myWordsActionFailed` now means "That didn't work. Try again." in all 19, because it also shows after Dismiss and Got it.
- `myWordsDismiss` in Japanese, Thai, Korean, Indonesian and Turkish was "Close". It now means "hide": 非表示, ซ่อน, 숨기기, Sembunyikan, Gizle.
- Thai `myWordsCardBoth` now joins the two counts with "และ" ("and").
- Arabic `myWordsCountWords`, `myWordsCountMistakes` and `myWordsDueCount` now have all six Arabic plural forms (zero, one, two, few, many, other).

## 6. Calls made in this plan (not the owner's decisions)

- Roleplay is a text button on the Talk card rather than a choice inside the tutor screen; the tutor screen is not changed.
- The Review button opens the existing review screen as it is; "chat words first" needs a server ordering and is left for phase 2c.
- Using the learner's own sentence in the daily session's speaking step belongs with Today v2 (phase 2c), not here.
- The Recommended tile and Vocab packs card move to the More screen when doors are on.
- The explanation on a partner's correction is shown to everyone; the paid explanation in the design applies to the check (phase 2b).
- The free limit of 5 keeps a day is not enforced (phase 3).

Also decided during the build:
- `studyFromChatsEnabled` alone shows nothing in the app (design §4). Capture cannot be previewed in the app without the doors.
- The My words card has its own green colours. The app theme's own colours do not give white text enough contrast, so the card uses its own.

## 7. Open items

- No badge on the Roleplay button. The Talk card's note follows the tutor's allowance. A locked or used-up roleplay is still handled when it is tapped (upgrade sheet), but the button does not show it in advance.
- The hub switches layout when app-config arrives with the doors on. The first paint is today's hub, then the doors replace it.
- Nothing was device-tested (section 4).
- No release build, version bump or store submission.
- Native review of the 18 languages (section 5).

## 8. Test evidence

- `flutter analyze`: 1119 issues, 0 errors, 3 warnings, all in test files that existed before this branch (the same as the baseline).
- Full `flutter test`: 4369 passed, 0 failed (run on commit 54e0715d).
- `flutter test test/study/ test/learning/ test/l10n/ test/services/session_reset_test.dart`: 1499 passed.
