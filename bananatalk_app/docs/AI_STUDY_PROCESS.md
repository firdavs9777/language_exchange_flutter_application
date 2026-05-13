# AI Study — How the whole thing works

This document explains AI Study in plain English. No code, no schemas — just what happens when a user opens the tab, what each feature does, and how the pieces feed each other. Read this if you want to understand the product, not the codebase.

---

## 1. The big picture

AI Study is the first tab in the app (bottom nav position #1). It's where the user does anything language-learning related that involves an AI. The tab has two zones stacked vertically:

1. **Tutor zone (top)** — a hero card showing the user's chosen tutor persona plus 5 quick-action chips. This is where the new AI-powered features live.
2. **Tools zone (bottom)** — a grid of older, simpler AI tools (Conversation Partner, Lessons, Grammar Check, Quiz, Translator, etc.). Same features the app had before; they still exist, just demoted under the tutor.

Below the tools grid the user sees their **Quick Stats** (XP, streak, etc.) and **Focus Areas** (weak topics the AI has noticed). Both are pulled from the same memory store the tutor uses.

The tutor zone is the new differentiated experience. The tools zone is legacy but still useful. The product bet is that as users adopt the tutor features, the tools zone will fade naturally without us having to delete anything.

---

## 2. The Tutor Persona — the foundation of everything

Before a user can do *any* of the new AI features (Chat / Roleplay / Story / Photo / Pronounce), they pick one of three tutor personas:

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

## 3. The Tutor Memory — what the AI knows about you

Every user has a single "TutorMemory" record that the AI features all read from and write back to. It's not a chat history — it's a *profile* the AI uses to personalize every interaction. Key fields:

- **Persona** — which tutor you chose
- **Proficiency level** — A1 → C2 (CEFR scale); informs how hard the AI makes things
- **Target languages** — the languages you're learning
- **Native language** — for definitions and translation glosses
- **Weak areas** — topics or words the AI has noticed are hard for you (e.g., `grammar:past_tense`, `pronunciation:park`, `vocab:bureaucracy`)
- **Vocab focus** — words you're actively learning vs. mastered
- **Recent chat summaries** — short blurbs from past sessions (max 200 chars each) so the next session can reference them
- **Daily plan** — today's suggested tasks (e.g., "5-min tutor chat", "SRS review", "grammar drill")
- **Last seen** — when you last opened the tutor

**Why this matters:** every feature below feeds this memory and reads from it. That's the loop. If you mispronounce "park" three times today in the Pronunciation Coach, "park" becomes a weak area. Tomorrow when you open the AI Conversation Partner, the AI's system prompt includes that fact, so the conversation naturally circles back to it. The user doesn't see any of this — they just feel like the tutor "remembers" them.

---

## 4. The 5 Tutor Chips — what each one does

These are the five quick-action chips below the persona hero card. Tapping a chip launches a focused experience for that mode.

### 4.1 💬 Chat (one-on-one conversation)

The classic tutor experience. Open-ended chat with your persona.

**Flow:**
1. User taps Chat
2. App fetches the tutor memory (so the AI knows the user's level, weak areas, etc.) and starts a new session
3. Tutor greets the user in their target language, optionally referencing the last session
4. User can type messages OR switch to voice mode (push-to-talk; audio is transcribed by Whisper, then the text is sent to the AI as if typed)
5. The AI's reply can be plain text OR an inline "card":
   - **Vocab card** — introduces a new word with IPA, definition, example, plus "Add to vocab" button
   - **Grammar card** — explains a rule with example sentences (correct vs wrong)
   - **Mini-lesson card** — a small concept with bullet points and an optional "Try it" practice prompt
6. When the user leaves, the session ends and a 200-char summary gets appended to the memory's recent-chat-summaries

**What it touches:** persona, level, native+target languages, weak areas (read), recent summaries (write), vocab focus (read+write via cards)

### 4.2 🎭 Roleplay (scenario practice)

Same as chat, but the AI starts in character in a specific scenario.

**Flow:**
1. User taps Roleplay → scenario picker (At a restaurant / Job interview / Doctor's office / etc.)
2. App starts a roleplay session with the chosen scenario
3. The AI greets the user *in role* — e.g., as a waiter, or an interviewer
4. User plays their side; AI stays in character
5. At end-of-session the user can request a "score" — the AI reviews the whole transcript and grades it on three axes (fluency, accuracy, naturalness) with specific feedback

**What it touches:** Same as chat, plus the scenario ID is recorded so the user can see which scenarios they've practiced.

### 4.3 📖 Story (graded reader + comprehension)

AI-generated short stories at the user's level, woven around words from their vocab focus list.

**Flow:**
1. User taps Story → setup screen
2. User picks word count (3 / 5 / 10 / 15 vocab words to include) and theme (adventure / mystery / romance / sci-fi / slice-of-life / free)
3. App calls the AI to generate a 4-paragraph story plus one multiple-choice comprehension question per paragraph
4. Story reader screen shows the paragraphs; tapping a vocab word shows its definition; comprehension questions appear between paragraphs
5. At the end, the user sees their score (X of 4 correct)

**What it touches:** target language, level, native language (for vocab glosses), vocab focus list (the words to weave in). Stories are *not* persisted — they're stateless per-session.

### 4.4 📷 Photo (image-vocab)

Take a photo, the AI tells you what's in it in your target language. Then optionally describe the photo yourself and get graded.

**Flow:**
1. User taps Photo → opens camera or photo library
2. They pick or take an image of anything (a coffee cup, a street sign, a meal)
3. App uploads the image to the backend → GPT-4o vision describes it in their target language, naming 3-5 key objects/concepts with definitions
4. User reviews the describe screen; can tap "Add to vocab" on any word to add it to their vocab list
5. Optional: user can write a description of the image themselves, submit it, and the AI grades it (with corrections and a 0-100 score)

**What it touches:** target language, native language. Words added go into the standard vocabulary store.

### 4.5 🎙️ Pronounce (new — Pronunciation Coach)

A 5-sentence pronunciation drill. The newest feature.

**Flow:**
1. User taps Pronounce → 5-sentence session begins
2. For each sentence:
   - App asks the backend for a sentence: the AI generates a short, level-appropriate sentence in the user's target language, optionally weaving in a word from their weak-areas list
   - The backend also generates TTS audio for that sentence (cached so identical sentences are free on repeat)
   - The sentence appears on screen, TTS auto-plays once (so the user hears the "right" pronunciation), and they can tap a speaker icon to replay
   - The user taps the big mic button, says the sentence, taps stop
   - Audio uploads to backend → Whisper transcribes → a pure scoring function compares the transcript to the target word-by-word
   - Score screen appears: each word colored green (correct), orange (close — mispronounced), or red (missing or completely different). On orange words, the specific bad letters render with red strikethroughs. A big animated score number shows the overall result.
   - User can "Try Again" (re-record same sentence) or "Next" (advance)
3. After 5 sentences, a summary sheet shows:
   - Average score across all 5
   - The 1-3 weakest words from this session
   - A "Save & Close" button
4. Tapping Save & Close upserts those weak words into the user's tutor memory with a `pronunciation:` prefix, increments their frequency, then pops back to AI Study

**What it touches:** persona (just for theming), level, target language, weak-areas list (read + write). The feature both *consumes* existing weak areas (the AI tries to weave them into generated sentences) and *produces* new ones (mistakes get logged), closing the loop.

**Bonus:** there's a "Use my own ✏️" escape hatch on the recording screen. The user can type or paste any sentence (e.g., a phrase from their textbook); the AI skips generation and just runs TTS on it before they record. Useful for "I have a specific thing I want to nail."

---

## 5. The "More AI tools" grid — legacy tools

These are older AI features. They still work, but they're not as integrated with the tutor memory loop. The grid lives below the chip row:

- **AI Conversation Partner** — a longer-form chat experience, separate from the persona-based tutor chat. VIP only.
- **AI Lessons** — structured lesson sequences (intro → practice → quiz). VIP only.
- **Grammar Feedback** — paste a sentence, get correction + explanation.
- **Pronunciation (old)** — single-sentence pronunciation check using a different scoring approach. VIP only. *Will likely be deprecated in favor of the new Pronunciation Coach.*
- **Translation** — smart translate with context.
- **AI Quizzes** — adaptive quizzes that pull from the user's weak areas. VIP only.
- **Lesson Builder** — generate a custom lesson on any topic the user types in. VIP only.

These coexist with the new tutor chips. Some overlap (especially the old Pronunciation tile vs. the new Pronounce chip), but the plan is to let them sit side-by-side until usage data shows what to keep.

---

## 6. The daily plan — gentle nudges, not enforcement

The tutor memory holds a daily plan: a list of tiny tasks for today (e.g., "5-min chat", "3 SRS reviews", "1 grammar drill"). The plan auto-generates the first time the user opens the tutor each day.

The daily plan is **visible** in the tutor home screen (tap the persona hero card) and tasks complete automatically as the user uses features — e.g., spending 5 minutes in tutor chat marks the chat task as done. There's no shame screen if the user skips a day; the plan just regenerates tomorrow.

This is intentionally low-pressure. The plan is a *suggestion surface*, not a streak-killing obligation.

---

## 7. How memory feeds back into everything

The memory loop is the most important thing to understand. It's invisible to users but it's why "the tutor feels smart."

Every feature **reads** the memory:
- Chat / Roleplay: tutor's system prompt includes proficiency level, weak areas, recent summaries, and persona personality
- Story: vocab focus list dictates which words appear; level dictates difficulty; native language gets used for glosses
- Photo: target language for descriptions, native for glosses
- Pronounce: level + target language for sentence generation, weak areas for word selection
- Old AI tools (Conversation Partner, Adaptive Quiz): also read weak areas and proficiency

Every feature **writes** to the memory:
- Chat / Roleplay: appends a session summary; may add vocab via cards
- Story: doesn't write (stateless by design)
- Photo: adds words to vocab when user taps "Add to vocab"
- Pronounce: upserts weak words after each 5-sentence session
- Daily plan: marks task progress as features get used

So if a user does a pronunciation drill and struggles with "park", then opens chat the next day, the chat AI has "pronunciation:park" in its context and will naturally use the word in conversation. That's the loop. No feature is a dead end — everything feeds the next thing.

---

## 8. VIP gating

Some features are free, some are VIP-only. The split today:

**Free for everyone:**
- Tutor Chat (all 5 chips: Chat / Roleplay / Story / Photo / Pronounce)
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

VIP-locked tiles still appear in the grid — they show a small lock badge and tapping them surfaces the upgrade prompt. The 5 new tutor chips are intentionally free because they're the new differentiated experience; we want every user to try them.

---

## 9. Costs (per-user, ballpark)

Rough OpenAI cost per active user per month, assuming moderate use (a couple chats, one story, a few pronunciations a week):

- Tutor chat (GPT-4o-mini): ~$0.10
- Story generation (4 paragraphs each): ~$0.05
- Image description (GPT-4o vision): ~$0.08 per photo
- Pronunciation (Whisper + TTS + GPT for sentence gen): ~$0.05 per session
- TTS for chat playback: ~$0.03

**Total: ~$0.30/user/month** for moderate-use free users. Heavy users (multiple sessions a day) can hit ~$1/month. VIP users pay way more than this in subscription, so the unit economics work.

---

## 10. What's NOT in AI Study (deliberately)

A few things people might expect but aren't there:

- **No leaderboard** — that's in the Profile tab.
- **No social comparison** — AI Study is solitary practice. The Community tab is where social happens.
- **No DM / chat with other users** — that's the Chats tab.
- **No content moderation surface** — moderation happens silently server-side.
- **No "share my progress" button** — keeping AI practice private is a feature.

The tab is intentionally a focused "me + AI" surface. Social pressure lives elsewhere.

---

## 11. What's coming next (roadmap)

Not promises — just the shortlist:

- **Listening Dictation** — AI speaks a sentence, user types what they hear, AI grades
- **Smart SRS** — replace generic vocab review with cards auto-pulled from weak words across all features
- **Sentence Mining** — paste any text (article, song lyric), AI extracts learnable phrases into vocab
- **Pronunciation v2** — phoneme-level scoring via Azure Speech (today's version is "spelling accuracy" via Whisper, which is good but not phonetic)
- **Daily-plan deep integration** — Pronounce becomes a real `tutor_pronunciation` task type with streak credit
- **Cross-device session resume** — start a chat on phone, finish on tablet
- **Translations of the new UI strings** — currently English-only with locale fallback for the 18 non-English locales

The big design constraint: every new feature should plug into the same tutor memory loop. New features that don't feed back into the memory are dead ends and won't ship.

---

## 12. Quick reference: what does each feature actually use?

| Feature | Reads from memory | Writes to memory | Uses AI? | Cost ballpark |
|---|---|---|---|---|
| 💬 Chat | persona, level, weak areas, summaries | session summary, optional vocab | GPT-4o-mini chat | $0.01-0.05 / session |
| 🎭 Roleplay | persona, level, weak areas | session summary, score | GPT-4o-mini chat | $0.02-0.06 / session |
| 📖 Story | level, target lang, native lang, vocab focus | nothing (stateless) | GPT-4o-mini json mode | $0.02 / story |
| 📷 Photo | target lang, native lang | optional vocab adds | GPT-4o vision | $0.05-0.10 / photo |
| 🎙️ Pronounce | level, target lang, weak areas | weak words (post-session) | GPT-4o-mini + Whisper + TTS | $0.01 / session |
| Daily plan | persona, level, vocab progress | task completion | (auto-generated) | free |
| Old AI tools | level, weak areas | varies by tool | varies | varies |

---

That's the whole picture. The pieces are designed to be independently useful but collectively form a single tutor that knows you across all of them.
