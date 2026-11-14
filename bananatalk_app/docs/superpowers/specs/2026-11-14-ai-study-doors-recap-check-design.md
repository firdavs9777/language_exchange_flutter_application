# AI Study: three doors, after-chat recap, check before you send, say your own phrases

Date: 2026-11-14. An addition to `2026-11-14-ai-study-path-design.md` (the "path design"), chosen by the owner from a list of ideas. It reshapes that design's phase 2 and adds two lines to its phase 3 table. Where the two documents differ, this one wins for the parts it covers.

## 1. Why these three

- **Three doors.** The tab shows a daily pack and twelve equal tiles. In 30 days lessons had 4 users, exams 0, roleplay conversations 0, while the daily pack, the tutor and saved words had 28 to 42 each. Twelve equal tiles hide the three things people use.
- **Recap and check.** People come to this app to chat. In-chat translation is the most used AI feature (100 people, 623 detailed translations in 30 days) and nothing from it is kept; partners made one correction in 30 days. The two exchange competitors both charge for AI feedback on a learner's own messages (HelloTalk caps it per day, Tandem charges for the explanations). Whether people pay for it is unproven and is measured here from the first day.
- **Say your own phrases.** Pronunciation is the one study feature that is growing: all 96 attempts ever were made in the last 30 days, by 19 people. Today it practises sentences the app supplies, not the ones the learner needs.

## 2. Goals, non-goals, anti-goals

Goals, 30 days after each part is switched on:

- Of weekly actives who open the study tab, the share who go through one of the three doors: a number exists and is above 50%.
- Checks: at least 15% of weekly actives who send a message in their learning language use the check at least once a week.
- Recaps: at least 30% of recaps shown are opened, and at least one item is kept from half of those.
- Pronunciation attempts on the learner's own phrases outnumber attempts on supplied sentences.
- The paywall funnel shows a view-to-trial number for the check and for the recap.

Non-goals:

- No change to how messages are sent, delivered or stored. No automatic correction of anything.
- No new tutor features, no exam or lesson work, no partner-to-partner features.
- No release build or store submission.

Anti-goals:

- The check delays, blocks or changes a message the learner did not choose to change.
- A partner's words are sent to an AI provider because of the recap or the check. (Translation already does this at the learner's request; nothing here adds to it.)
- The chat screen gains anything that moves or covers the composer for people who never use the check.
- Free learners lose something they have today.

## 3. Constraints

- Each part ships behind its own server switch, default off: `STUDY_DOORS_ENABLED`, `STUDY_CHECK_ENABLED`, `STUDY_RECAP_ENABLED` (app-config keys `studyDoorsEnabled`, `studyCheckEnabled`, `studyRecapEnabled`). With all off, the tab and the chat screen are as they are after phase 1.
- Depends on the path design's learner record (6.1) and chat capture (6.2). Those are built first, in the same phase.
- Only the learner's own text is ever sent to the AI provider by the check and the recap.
- Everything is private to the learner and deleted with their account; items that came from a partner's message are also deleted when that partner's account is deleted.
- New strings in all 19 app languages, machine-drafted and listed for native review. Reels playback files untouched. Every commit updates `docs/REMAINING_WORK.md`.

## 4. Three doors

With `studyDoorsEnabled` on, the hub reads top to bottom:

1. Header chips (streak, level, language), as today.
2. **Today**: the daily session row, as today.
3. **My words and mistakes**: a card showing how many items are waiting ("6 words, 2 mistakes to look at"). Opens the new screen in 4.1.
4. **Talk**: a card that opens the tutor. One tap starts or resumes a conversation with the learner's persona (the persona picker first if none is set). Roleplay is a choice inside, not a separate tile.
5. **More**: one row that opens a screen holding the remaining features in today's groups and order: Story, Photo, Speak, Writing, Quizzes, Exam, Lessons, Leaderboard, Vocab packs.
6. Progress card and the ad, as today.

Announcements and the first-week guide keep their places above Today. With the switch off the hub is today's.

### 4.1 My words and mistakes (new screen)

Three sections, each hidden when empty:

- **From your chats**: candidates captured from the learner's translations (path design 6.2), most useful first. Each has Keep and Dismiss.
- **Mistakes**: sentences corrected by a partner or by the check, newest first: what was written, the correction, and for VIP the explanation. Each has Got it (clears it after three successes, the existing rule) and Say it.
- **Words to review**: the due count and a Review button that opens the existing review screen with the learner's own chat words first.

Every word or sentence on this screen has a **Say it** action (section 7).

A candidate is one word or phrase per learner and language, however many chats it came from; it remembers each chat it came from only so that a partner's deletion can remove that source. A candidate with no sources left is removed unless the learner kept it. A kept word is the learner's own saved word (the word and its translation) and stays. Keep is the same action wherever it is offered and counts once; the path design's limit of 5 keeps a day for free learners is not enforced until phase 3.

## 5. Check before you send

- A small Check control sits beside the send button in a conversation. It appears only when the learner has typed at least three words and the text is not in their native language (judged on the device by a cheap script and stop-word test; when unsure, it appears). It never appears in rooms or group chats in this version.
- Tapping it sends the learner's text to the server and opens a sheet within about three seconds: what was written, a corrected version, and a more natural version when one differs. Buttons: Use corrected, Use natural, Keep mine. Choosing one replaces the composer text; nothing is sent until the learner presses send. Closing the sheet changes nothing.
- A check that finds nothing says so in one line and offers nothing to replace.
- Each mistake found is added to the learner's mistakes and weak areas. Nothing is added when the text was fine.
- Free: 3 checks a day, corrections without explanations. VIP and trial: unlimited within fair use (a daily ceiling set in the plan), with a short explanation per mistake in the learner's native language.
- When the free allowance is used, the control stays and opens the existing upgrade sheet with the trial line; reported to the paywall funnel as a new placement `study_check`.
- The check has its own endpoint and its own daily counter. Underneath it calls the existing writing-feedback service with a prompt of its own that returns the corrected text, a more natural version when one differs, and a list of mistakes (what was written, the fix, a one-line explanation). The Writing tile and its endpoint are not changed.
- The server never sends explanations to a free learner; they are left out of the response, not hidden by the app.
- The three free checks a day are a new free grant from the day the check is switched on: nobody has an in-chat check today, and the Writing tile's own limits stay as they are.
- Failure or slowness: after 6 seconds the sheet says the check is unavailable; the message can always be sent.

## 6. After-chat recap

- A chat session qualifies when the learner sent at least 3 messages in their learning language to one partner in a one-to-one conversation and the conversation then went quiet for 20 minutes, or the learner left the chat. At most 2 recaps a day, at most one per partner per day.
- Recaps are worked out when the app asks, not by a background job: when the learner leaves a chat, and when the hub or My words and mistakes opens. A recap therefore does not exist until the app is opened again, which is fine since there is no push.
- "In their learning language" is judged on the server by the same cheap rule the app uses for showing the Check control (not the native script or stop words; when unsure it counts). Reading the learner's own stored messages for this is intended; a partner's messages are read only to find their corrections.
- A partner's correction is the correction stored on the learner's message (the existing corrections feature), matched to the session by the message's time. These are rare today (one in 30 days), so at first most mistakes will come from the check.
- The recap holds up to three things:
  1. up to two words or phrases the learner looked up in that session (from capture; no AI);
  2. one mistake: a partner's correction from that session if there is one; otherwise, for VIP and trial only, the most useful mistake found by checking the learner's own messages from that session (one AI call).
- Free learners without a partner correction see the words plus one locked line, "See what to fix in your messages", which opens the upgrade sheet (placement `study_recap`).
- A session with nothing to show produces no recap.
- Where it appears: as a card at the top of My words and mistakes and on the hub ("From your chat with {name}"), and as one quiet line when the learner next leaves that chat ("3 things saved from this chat" with a Review action). No push notification in this version. (My call: a push about a private chat is easy to get wrong.)
- Each item has Keep, Dismiss and Say it. A recap disappears after 7 days or when every item has been kept or dismissed.

## 7. Say your own phrases

- Say it, wherever it appears (My words and mistakes, the recap, the check sheet's chosen version), opens the existing pronunciation screen with that sentence already loaded and marked as the learner's own. The screen gains optional inputs for the sentence and its language and is otherwise unchanged; the scoring request records that the sentence was the learner's own, so the goal in section 2 can be measured.
- When the daily session's third step is a speaking step and the learner has a recent kept phrase or corrected sentence, that sentence is used.
- A low score adds the weak words to the learner's record, as pronunciation already does elsewhere.
- Allowance as in the path design: 5 scored attempts a day free, unlimited within fair use for VIP and trial.

## 8. Phases, replacing the path design's phase 2

| Phase | Contents | Switches |
|---|---|---|
| 2a | Learner record with real writers for weak areas; chat capture; My words and mistakes; three doors; Say it | `STUDY_FROM_CHATS_ENABLED`, `STUDY_DOORS_ENABLED` |
| 2b | Check before you send; after-chat recap | `STUDY_CHECK_ENABLED`, `STUDY_RECAP_ENABLED` |
| 2c | Today's three-step session; the tutor's context | `STUDY_TODAY_V2_ENABLED` |
| 3 | Free, trial, paid (path design section 7), with two added lines: check before you send (3 a day free; unlimited with explanations paid) and recap (words free; the mistake from your own messages paid) | `STUDY_TRIAL_ENABLED` |

Until phase 3 is on there is no subscription to point at for the check and the recap: the free allowance applies to everyone except existing VIPs, and the locked line and the upgrade prompt appear only once `STUDY_TRIAL_ENABLED` is on. Before that, a used-up allowance simply says "3 checks a day; more tomorrow".

Each phase has a backend plan and an app plan. Events from every new surface go to the study event log; paywall views go to the paywall funnel.

## 9. Left to the builder

- The on-device test for "not in the native language"; the ranking of candidates and of the "most useful" mistake; fair-use ceilings; storage shapes; which existing endpoints grow.
- The exact wording of the new strings, within the meanings given here.

## 10. Calls I made (not the owner's decisions)

- Speak moves under More as a feature, because Say it brings pronunciation to where the learner's own sentences are.
- The check never runs by itself and never appears in rooms or group chats in this version.
- Recaps come at most twice a day and never by push.
- The recap's AI-found mistake is paid; the free recap uses only lookups and partner corrections.
- Before the trial exists, a used-up allowance says "more tomorrow" instead of selling something that cannot be bought well yet.

## 11. Owner's decisions needed

1. The free allowance for the check (3 a day) and whether the AI-found mistake in the recap should be paid.
2. Whether a Check control beside the send button is acceptable in the chat screen at all.
3. Whether the privacy policy and the stores' data forms need a line saying that text a person chooses to check is sent to an AI provider (translation already is).
