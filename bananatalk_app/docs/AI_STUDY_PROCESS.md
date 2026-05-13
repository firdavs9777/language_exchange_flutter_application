# AI Study — How the whole thing works

This document explains AI Study in plain English. No code, no schemas — just what happens when a user opens the tab, what each feature does, and how the pieces feed each other. Read this if you want to understand the product, not the codebase.

---

## 1. The big picture

AI Study is the first tab in the app (bottom nav position #1). It's where the user does anything language-learning related that involves an AI. The tab has two zones stacked vertically:

1. **Tutor zone (top)** — a hero card showing the user's chosen tutor persona plus 5 quick-action chips. This is where the new AI-powered features live.
2. **Tools zone (bottom)** — a grid of older, simpler AI tools (Conversation Partner, Lessons, Grammar Check, Quiz, Translator, etc.). Same features the app had before; they still exist, just demoted under the tutor.

Below the tools grid the user sees their **Quick Stats** (XP, streak, etc.) and **Focus Areas** (weak topics the AI has noticed). Both are pulled from the same memory store the tutor uses.

The tutor zone is the new differentiated experience. The tools zone is legacy but still useful. The product bet is that as users adopt the tutor chips, the tools zone will fade naturally without us having to delete anything.

---

## 2. The Tutor Persona — the foundation of everything

Before a user can do *any* of the new AI features (the 5 tutor chips), they pick one of three tutor personas:

- **Nana** — warm, supportive, lots of encouragement
- **Sensei** — strict, formal, pushes for correctness
- **Riko** — playful, casual, peer-friendly

The persona choice persists forever (until the user changes it from the tutor home screen). It affects:

- How the tutor *talks* in chat (cadence, formality, vocabulary)
- How feedback is phrased ("Almost!" vs "Try again — focus on the verb tense")
- Which avatar shows in the hero card

**First-time gating:** if a user taps any of the 5 tutor chips without having picked a persona yet, they bounce through a one-screen persona picker before continuing to the feature they actually wanted. The picker remembers which chip they tapped, so after picking a persona they land on that destination — not on a generic tutor home screen.

This is important: the persona isn't a "settings" thing buried in a menu. It's an intentional first-run experience that frames the whole AI Study tab as "this is your tutor, here's who they are."

---

## 3. The Memory Loop — this is the moat

Read this section twice. Everything else in AI Study is in service of this.

```
                    ┌─────────────────┐
                    │  TutorMemory    │
                    │  ─────────────  │
                    │  persona        │
                    │  level (A1-C2)  │
                    │  languages      │
                    │  weakAreas      │  ◀──── writes ────┐
                    │  vocabFocus     │                   │
                    │  recentSummary  │                   │
                    └─────────┬───────┘                   │
                              │                           │
                       reads ─┤                           │
                              ▼                           │
       ┌──────────┬──────────┬──────────┬──────────┬──────┴───┐
       │  💬 Chat │ 🎭 Role  │ 📖 Story │ 📷 Photo │ 🎙️ Prono │
       │          │          │          │          │          │
       └──────────┴──────────┴──────────┴──────────┴──────────┘
```

Every tutor chip **reads** from the same shared memory before the AI runs. Every chip also **writes** back to it. That's the loop.

Concrete example: a user does a 5-sentence Pronunciation drill on Monday and struggles with "park." The Pronounce chip writes `pronunciation:park` into their weak-areas list. Tuesday they open Chat — Nana's system prompt is built fresh and includes that fact, so Nana will naturally use "park" in conversation ("Did you go to the park yesterday?"). The user practices the word in context. If Pronunciation feeds Chat, Chat feeds Story (next-generated story will weave in "park"), Story feeds Photo (the AI suggests photographing parks for vocab practice), and so on.

The user never sees any of this. They just feel like the tutor "remembers" them across every interaction. That's the differentiated experience.

Other language apps have streaks, XP, leaderboards. They don't have a unified cross-feature memory. That's the moat.

A known gap today: the memory only goes up, never down. If you mispronounce "park" once and then nail it 20 times, the AI still treats it as weak. A mastery-decay system is planned as the next backend wave (see §14 Roadmap).

---

## 4. The Tutor Memory — what the AI knows about you

The shared memory store from §3 has these fields:

- **Persona** — which tutor you chose
- **Proficiency level** — A1 → C2 (CEFR scale); informs how hard the AI makes things
- **Target languages** — the languages you're learning (today: only the first one is active — see §11)
- **Native language** — for definitions and translation glosses
- **Weak areas** — topics or words the AI has noticed are hard for you (e.g., `grammar:past_tense`, `pronunciation:park`, `vocab:bureaucracy`)
- **Vocab focus** — words you're actively learning vs. mastered
- **Recent chat summaries** — short blurbs from past sessions (max 200 chars each) so the next session can reference them
- **Daily plan** — today's suggested tasks (e.g., "5-min tutor chat", "SRS review", "grammar drill")
- **Last seen** — when you last opened the tutor

Memory is a single per-user record, server-side. It's loaded on every AI call and updated by every feature that finishes a meaningful action.

---

## 5. The 5 Tutor Chips — what each one does

These are the five chips below the persona hero card. Tapping a chip launches a focused experience for that mode. All five are persona-gated (§2).

### 5.1 💬 Chat (one-on-one conversation)

The classic tutor experience. Open-ended chat with your persona.

**Flow:**
1. User taps the Chat chip
2. App fetches the tutor memory (so the AI knows the user's level, weak areas, etc.) and starts a new session
3. Tutor greets the user in their target language, optionally referencing the last session
4. User can type messages OR switch to voice mode (push-to-talk; audio is transcribed by Whisper, then the text is sent to the AI as if typed)
5. The AI's reply can be plain text OR an inline "card":
   - **Vocab card** — introduces a new word with IPA, definition, example, plus "Add to vocab" button
   - **Grammar card** — explains a rule with example sentences (correct vs wrong)
   - **Mini-lesson card** — a small concept with bullet points and an optional "Try it" practice prompt
6. When the user leaves, the session ends and a 200-char summary gets appended to the memory's recent-chat-summaries

**Reads:** persona, level, native + target languages, weak areas, recent summaries
**Writes:** session summary, optional vocab additions (via cards)

### 5.2 🎭 Roleplay (scenario practice)

Same as chat, but the AI starts in character in a specific scenario.

**Flow:**
1. User taps the Roleplay chip → scenario picker (At a restaurant / Job interview / Doctor's office / etc.)
2. App starts a roleplay session with the chosen scenario
3. The AI greets the user *in role* — e.g., as a waiter, or an interviewer
4. User plays their side; AI stays in character
5. At end-of-session the user can request a "score" — the AI reviews the whole transcript and grades it on three axes (fluency, accuracy, naturalness) with specific feedback

**Reads:** same as chat
**Writes:** session summary, scenario ID, end-of-session score

### 5.3 📖 Story (graded reader + comprehension)

AI-generated short stories at the user's level, woven around words from their vocab focus list.

**Flow:**
1. User taps the Story chip → setup screen
2. User picks word count (3 / 5 / 10 / 15 vocab words to include) and theme (adventure / mystery / romance / sci-fi / slice-of-life / free)
3. App calls the AI to generate a 4-paragraph story plus one multiple-choice comprehension question per paragraph
4. Story reader screen shows the paragraphs; tapping a vocab word shows its definition; comprehension questions appear between paragraphs
5. At the end, the user sees their score (X of 4 correct)

**Reads:** target language, level, native language (for vocab glosses), vocab focus list
**Writes:** nothing today (stateless). A "My Stories" library is on the roadmap (§14) — would persist `{theme, paragraphs, vocabUsed, comprehensionScore}` per generation.

### 5.4 📷 Photo (image-vocab)

Take a photo, the AI tells you what's in it in your target language. Then optionally describe the photo yourself and get graded.

**Flow:**
1. User taps the Photo chip → opens camera or photo library
2. They pick or take an image of anything (a coffee cup, a street sign, a meal)
3. App uploads the image to the backend → GPT-4o vision describes it in their target language, naming 3-5 key objects/concepts with definitions
4. User reviews the describe screen; can tap "Add to vocab" on any word to add it to their vocab list
5. Optional: user can write a description of the image themselves, submit it, and the AI grades it (with corrections and a 0-100 score)

**Reads:** target language, native language
**Writes:** vocab additions when user taps "Add to vocab"

### 5.5 🎙️ Pronounce (Pronunciation Coach) — newest chip

A 5-sentence pronunciation drill.

**Two ways to pick the target sentence:**
- **AI-generated** (default) — the AI generates 5 level-appropriate sentences in your target language, biased toward your weak words. Loads automatically when you tap the chip.
- **Use my own ✏️** — type or paste any sentence (a phrase from a textbook, song lyric, anything). The AI skips generation and just runs TTS so you can practice. The button is visible on the ready state of every sentence, so the user can switch in or out at any point during a drill. A dedicated start-screen entry point (so users see both options upfront) is queued as a Step 12+ polish item.

**Per-sentence flow:**
1. Sentence appears, TTS auto-plays once (so the user hears the "right" pronunciation)
2. User can tap a speaker icon to replay anytime
3. User taps the big mic button, says the sentence, taps stop
4. Audio uploads to backend → Whisper transcribes → a pure scoring function compares the transcript to the target word-by-word
5. Score screen appears: each word colored green (correct), orange (close — mispronounced), or red (missing or completely different). On orange words, the specific bad letters render with red strikethroughs. A big animated score number shows the overall result.
6. User can "Try Again" (re-record same sentence) or "Next" (advance)

**End of 5-sentence session:**
- Summary sheet shows average score across all 5, the 1-3 weakest words, and a "Save & Close" button
- Tapping save upserts those weak words into the user's tutor memory with a `pronunciation:` prefix

**Reads:** persona (theming), level, target language, weak-areas list
**Writes:** new weak words on save

The Pronounce chip is the loop in miniature: it both *consumes* existing weak areas (the AI tries to weave them into generated sentences) and *produces* new ones.

---

## 6. The "More AI tools" grid — legacy

These are older AI features. They still work, but they're not as integrated with the tutor memory loop. The grid lives below the chip row:

- **AI Conversation Partner** — a longer-form chat experience, separate from the persona-based tutor chat. VIP only.
- **AI Lessons** — structured lesson sequences (intro → practice → quiz). VIP only.
- **Grammar Feedback** — paste a sentence, get correction + explanation.
- **Pronunciation (old)** — single-sentence pronunciation check using a different scoring approach. VIP only. **Deprecated by the new Pronounce chip; planned to be hidden in the next sunset pass.**
- **Translation** — smart translate with context.
- **AI Quizzes** — adaptive quizzes that pull from the user's weak areas. VIP only.
- **Lesson Builder** — generate a custom lesson on any topic the user types in. VIP only.

These coexist with the new tutor chips. Some overlap (especially old Pronunciation vs. new Pronounce), but the plan is to let them sit side-by-side with usage tracking until data tells us which legacy tools to retire. Concrete threshold proposal: rolling-30-day DAU per tile; <10% → fold under a "More" submenu, <2% → remove entirely. We don't have those analytics events wired up yet.

---

## 7. The daily plan — gentle nudges, not enforcement

The tutor memory holds a daily plan: a list of tiny tasks for today (e.g., "5-min chat", "3 SRS reviews", "1 grammar drill"). The plan auto-generates the first time the user opens the tutor each day.

The daily plan is **visible** in the tutor home screen (tap the persona hero card) and tasks complete automatically as the user uses chips — e.g., spending 5 minutes in tutor chat marks the chat task as done. There's no shame screen if the user skips a day; the plan just regenerates tomorrow.

**Known gap:** the Pronounce chip doesn't currently have a corresponding `tutor_pronunciation` task type, so doing a drill doesn't tick the plan. Adding it is queued.

This is intentionally low-pressure. The plan is a *suggestion surface*, not a streak-killing obligation. A push-notification wave is planned (§14) to handle the "return tomorrow" pull without resorting to shame mechanics.

---

## 8. VIP gating

Some features are free, some are VIP-only. The split today:

**Free for everyone:**
- All 5 tutor chips (Chat / Roleplay / Story / Photo / Pronounce)
- Grammar Feedback
- Translation
- Story Quizzes
- Vocabulary

**VIP-only:**
- AI Conversation Partner (the longer-form one)
- AI Lessons
- Old Pronunciation tool
- AI Quizzes
- Lesson Builder

VIP-locked tiles still appear in the grid — they show a small lock badge and tapping them surfaces the upgrade prompt.

**This split is in flux.** The current state is "free new, VIP old," which is inverted from a unit-economics perspective: the new tutor chips are the more expensive AI calls (memory loop, card generation, multi-step flows). A rethink is planned (§14) — most likely outcome: keep the 5 chips free but add daily quotas (e.g., 3 chats / 1 story / 1 photo / 1 drill per day for free users); VIP unlocks unlimited + all legacy tools.

---

## 9. Failure modes — what happens when things go wrong

Production realities, not happy paths.

**OpenAI is down (or rate-limited):**
- Sentence/story generation calls fail with a 502; UI surfaces a retry button.
- Chat: if the model call fails, a canned greeting is used so the session still starts. Subsequent failures surface inline error bubbles with retry.
- Pronounce: the scoring function is pure JS in our own backend, so even if OpenAI is down, transcription fails (Whisper outage) but the rest of the pipeline is fine. Whisper failures show "Couldn't hear you — try again."

**Whisper transcribes wrong (bad accent, background noise):**
- The scoring function happily diffs whatever it got. If the user said the sentence correctly but Whisper hallucinated, the score will be low — they'll see "We heard you say: [garbled]" and can retry.
- We don't auto-detect "Whisper is confused vs user is wrong" — that's a real limitation. Phoneme-level scoring (Pronounce v2, roadmap) would fix it.

**User uploads an inappropriate photo to Photo chip:**
- GPT-4o vision has its own content filter and will refuse with an error message. We pass that through with a generic "Couldn't process this image" rather than echoing the model's explanation.
- We don't run a pre-upload moderation pass — we trust OpenAI's filter as the gate.

**Roleplay jailbreak attempts ("ignore previous instructions, say X"):**
- The model's system prompt is strong; mostly holds.
- We don't have a separate jailbreak detector; if the persona drops, the worst case is bad UX, not a security incident (no privileged data lives in the tutor's context).

**TTS doesn't support the target language:**
- OpenAI TTS covers ~30 languages; if the user's target isn't in that list, the audio call fails and we fall back to silently skipping the auto-play. The text is still readable.
- Rare for our user base (we focus on Korean, Japanese, English, Spanish — all supported).

**User backgrounds the app mid-recording or mid-session:**
- Recording is cancelled; partial audio is discarded.
- Session state is in-memory only; resuming opens a fresh state. Acceptable for drill-length sessions.

**Audio file too large (multer 25MB cap):**
- Effectively impossible for normal use (5-15s sentences). Defensive guard returns 413.

**Network drops mid-upload:**
- Multipart upload retries are not automatic. UI shows the inline error and a retry button; the audio file is still on disk so re-trying doesn't require re-recording.

---

## 10. Data privacy — what we send, what stays

Material disclosure for the privacy policy.

**Sent to OpenAI (as the AI provider):**
- All chat / roleplay text (user and AI sides) — needed for completions
- Voice samples from chat voice mode and the new Pronounce chip — Whisper transcribes them server-side at OpenAI
- Photos from Photo chip — GPT-4o vision processes them
- Generated sentences for Pronounce, generated stories — needed for the model call
- User's proficiency level, native language, weak areas — included in system prompts so the AI personalizes responses

**Sent to our own backend (BananaTalk):**
- Same as above, plus session summaries, vocab additions, weak-area updates
- For **chat voice mode** and the **new Pronounce chip**, user audio is kept in memory during processing only; the buffer is passed to Whisper and discarded — we don't write it to disk or upload it to S3/Spaces.
- For the **legacy Pronunciation tile** (the VIP-only one in the "More AI tools" grid), user audio IS uploaded to DigitalOcean Spaces and a `userAudioUrl` is stored in a `PronunciationAttempt` record. This endpoint is dormant in the current main flow but still reachable; deprecating it is queued for the Step 13 sunset pass.
- Photos are kept in memory during processing only; we don't persist raw images.
- All persisted data is keyed to the user's account and visible only to them.

**Cached on our side (DigitalOcean Spaces):**
- **AI-generated TTS audio** — every sentence the tutor speaks is uploaded to Spaces and a metadata pointer cached in Mongo (`AudioCache`). Two reasons: the same sentence said by the same persona at the same speed is byte-identical, so caching saves the OpenAI TTS spend (~$0.006 per sentence); and Spaces serves the audio over a CDN which is faster than re-streaming from OpenAI.
- **Cache TTL:** Mongo metadata is dropped after 90 days of unuse (TTL index on `lastAccessedAt`). Spaces CDN headers say `max-age=31536000` (1 year), but the actual object is only kept as long as the Mongo entry references it. There's no explicit delete-from-Spaces job today — orphaned objects stay until manually swept.

**What stays on the device:**
- TTS reference audio played to the user (downloaded from the cached Spaces URL; not re-uploaded).
- The user's recording before they tap "stop" (cancelled audio is just discarded locally). The recording file *does* land in iOS/Android's temporary directory while being uploaded; the OS reclaims the temp dir on its own schedule.

**Retention summary:**
- **User recording audio (chat voice + new Pronounce):** never persisted server-side (in-memory only).
- **User recording audio (legacy Pronunciation tile):** stored in Spaces + Mongo `PronunciationAttempt` record indefinitely. Deprecation queued in Step 13.
- **TTS audio:** cached up to 90 days post-last-use in Mongo + Spaces.
- **OpenAI logs:** OpenAI retains API call logs (text, audio, images) for up to 30 days for abuse monitoring per their policy, then deletes them. Per their API policy, API call data is NOT used to train their models.
- **Our backend logs:** rotated weekly. Audio bodies are never logged — multipart uploads go through multer's memory storage and never hit the JSON request-body logger.

**Users learning English to date Koreans, take note:** your voice samples leave the device. For chat voice + new Pronounce they pass through our server in memory only and go to OpenAI for transcription. For the legacy Pronunciation tile they're also stored on our Spaces bucket. If that's a concern, voice mode is off by default in chat — text mode never sends audio anywhere — and the legacy Pronunciation tile is being retired.

A more detailed privacy policy update lands when the App Store review for the Step 9 + Step 11 waves goes through. This section is the developer-facing version.

---

## 11. Multi-language support (today vs. tomorrow)

The user model has `targetLanguages` as a list, but **today only the first language is active**. All AI features use `targetLanguages[0]` for everything — chat language, story language, TTS voice, scoring target. Multi-language learners can change which language is primary by editing their profile (the list is reordered).

What this means in practice:
- A user learning Korean and Japanese has to pick one as primary at any given time
- Weak areas, vocab focus, daily plan — all single-pool, not per-language. Switching primary languages will surface weak areas from the other language until the AI's seen enough new data
- Recent chat summaries also pool together

A real multi-language tutor (per-language weak areas, per-language daily plan, automatic language detection from input) is a Step 13+ design problem. Not on the immediate roadmap, but flagged as known limitation.

---

## 12. Unit economics — honest version

We don't have conversion data yet. Here's what we know and what we don't.

**Per-user AI cost (moderate use, ~5 sessions a week):**

| Source | Cost / user / month |
|---|---|
| Tutor chat (GPT-4o-mini) | ~$0.10 |
| Story generation (4 paragraphs) | ~$0.05 |
| Image description (GPT-4o vision) | ~$0.08 per photo |
| Pronounce (Whisper + TTS + GPT) | ~$0.05 per session |
| TTS for chat voice mode | ~$0.03 |
| **Moderate-use total** | **~$0.30 / user / month** |

Heavy users (multiple sessions a day) hit ~$1/month. Light users (once a week) ~$0.10. The $0.30 figure is moderate-use — blended cost across a real user base with a long tail of power users likely sits somewhere between $0.40-$0.60. Use the moderate figure for sizing prep, not for break-even.

**What we don't know:**
- Actual conversion rate from free → VIP
- Actual CAC (we have App Store conversion, not paid-channel data)
- Actual retention curve (D7, D30, D90)
- Actual VIP MRR cohort behavior
- The blended free-vs-power-user cost mix

**Break-even math (placeholder, not real):**

A $7.99/month VIP subscription does NOT net us $7.99. Apple and Google take their cut off the top:

- **Year 1 of a subscription:** 30% platform fee → we net **$5.59**
- **Year 2+ (same subscriber renewing):** 15% platform fee → we net **$6.79**

If we assume blended cost of ~$0.40 per free user per month and a Year-1 net of $5.59 per paying user:

- Every paying user covers **~14 free users' AI costs** (was ~26 at the gross $7.99 number — that math was wrong)
- Break-even conversion rate is **above ~7%** of free → paid in Year 1, falling to ~6% in Year 2+ as the platform fee drops

Sense-check those numbers: typical freemium SaaS converts at 2-5%. **7% conversion to cover AI costs alone is ambitious** — meaning either: (a) the moderate-use cost estimate is too low and we need to tighten that, (b) we need a higher VIP price, (c) we need a daily quota to floor AI cost per free user, or (d) we accept a cost-recovery shortfall on the AI line and rely on other revenue (Community premium features, sponsorships, ads).

This is also why the VIP/free split rethink (queued for Step 13) matters — moving the cost-heavy new tutor chips behind a daily quota for free users would dramatically lower the blended free-user cost and push break-even back below the 7% threshold.

And: this ignores hosting, storage, CDN, support cost, our own time. The real fully-loaded number is higher.

The point of this section is to be honest about what we don't know. As soon as we have 90 days of conversion + cohort data, fill this in for real.

---

## 13. What's NOT in AI Study (deliberately)

A few things people might expect but aren't there:

- **No leaderboard** — that's in the Profile tab.
- **No social comparison** — AI Study is solitary practice. The Community tab is where social happens.
- **No DM / chat with other users** — that's the Chats tab.
- **No content moderation surface** — moderation happens silently server-side (and via OpenAI's filters).
- **No "share my progress" button** — keeping AI practice private is a feature.
- **No streaks (yet)** — see retention discussion in §14. We're not anti-streak; we're anti-shame.

The tab is intentionally a focused "me + AI" surface. Social pressure lives elsewhere.

---

## 14. What's coming next (roadmap)

Not promises — the active shortlist:

- **Step 12 — Memory loop: mastery + decay.** Today weak areas accumulate forever. Add a per-topic mastery score that rises on success and falls on failure; weak areas = mastery < 50. Unlocks "you mastered N words this week" celebration. Fixes the "park is forever weak" bug.
- **Step 13 — VIP rethink + legacy sunset.** Replace lock with daily quota for free users on tutor chips; VIP unlocks unlimited + all legacy tools. Hide the old Pronunciation tile (deprecated by the new chip). Add analytics events so future sunset decisions are data-driven.
- **Step 14 — Story persistence + My Stories library.** Stories are currently throwaway. Persisting them unlocks re-reading for spaced repetition, sharing as social posts, and "My Stories" as a return-to-app hook. Bonus: add a "First conversation" / "Coffee date" story theme that leans into BananaTalk's language-exchange DNA.
- **Push notifications wave.** No streak shame, but the tutor should be able to send a personalized morning nudge in the user's native language — "Want to nail 'park' today?" energy. Deferred from Step 9.
- **Listening Dictation chip** — AI speaks a sentence, user types what they hear, AI grades. Natural sixth chip.
- **Smart SRS** — replace generic vocab review with cards auto-pulled from weak words across all chips.
- **Sentence Mining** — paste any text (article, song lyric), AI extracts learnable phrases into vocab.
- **Pronounce v2** — phoneme-level scoring via Azure Speech (today's v1 is "spelling accuracy" via Whisper). Will replace v1, not add a third option.
- **Real multi-language model** (§11).
- **Translations of the new UI strings** — currently English-only with locale fallback for 18 non-English locales.

The big design constraint: every new feature should plug into the memory loop (§3). New features that don't feed back into the memory are dead ends and won't ship.

---

## 15. Quick reference — what each chip reads and writes

| Chip | Reads from memory | Writes to memory | Uses AI? | Cost ballpark |
|---|---|---|---|---|
| 💬 Chat | persona, level, weak areas, summaries | session summary, optional vocab | GPT-4o-mini chat | $0.01-0.05 / session |
| 🎭 Roleplay | persona, level, weak areas | session summary, score | GPT-4o-mini chat | $0.02-0.06 / session |
| 📖 Story | level, target lang, native lang, vocab focus | nothing (stateless today; will persist in Step 14) | GPT-4o-mini json mode | $0.02 / story |
| 📷 Photo | target lang, native lang | optional vocab adds | GPT-4o vision | $0.05-0.10 / photo |
| 🎙️ Pronounce | level, target lang, weak areas | weak words (post-session) | GPT-4o-mini + Whisper + TTS | $0.01 / session |
| Daily plan | persona, level, vocab progress | task completion | (auto-generated) | free |
| Legacy tools | level, weak areas | varies by tool | varies | varies |

---

That's the whole picture. The pieces are designed to be independently useful but collectively form a single tutor that knows you across all of them. The memory loop in §3 is the actual differentiator; everything else is execution on top of that.
