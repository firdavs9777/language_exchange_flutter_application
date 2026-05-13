# Study menu redesign — exploration

**Date:** 2026-05-13
**Status:** exploration only — not a spec yet, waiting on direction
**Why now:** Step 9 added 4 tutor entry points + a hero card to the AI tab, which already had 6 tool tiles + a generic hero. The tab is busy and the hierarchy is unclear.

---

## What's on the AI tab right now

When the user opens the AI tab, scrolling top to bottom they currently see:

1. **Tutor hero card** (gradient teal, "Your AI Tutor — tap to chat / Pick a persona")  ← new from Step 9
2. **Old hero card** ("AI Tutor — Practice with AI...") — generic, predates Step 9, mostly redundant now
3. **AI Features section header**
4. **2×3 grid of tool tiles:**
   - 📚 AI Lessons (purple)
   - 🔤 Grammar Check (green)
   - 🎙️ Pronunciation (orange, VIP)
   - 🌐 Translation (blue)
   - 🧠 AI Quizzes (red, VIP)
   - ✨ Lesson Builder (pink, VIP)
5. **Your Progress stats** (quiz stats, only if any)
6. **Weak Areas section** (only if any)

And when the user taps the tutor hero → `TutorHomeScreen`, they see:

1. Persona greeting
2. Today's plan checklist
3. "Start chat" button
4. 🎭 Practice scenarios card
5. 📖 Read a story card
6. 📷 Describe a photo card
7. Recent sessions list

**Total surface area:** ~15 distinct entry points, spread across 2 screens with overlap.

---

## What's hurting

1. **Two heroes stacked.** The new tutor hero and the old generic AI hero compete for the same job. New users see two "AI Tutor" cards and don't know which is *the* one.
2. **Tutor's entry points hidden one tap deep.** Scenarios / Story / Image-vocab — the showcase Step-9 features — live inside `TutorHomeScreen`. A user who doesn't tap the hero never sees them.
3. **Tools and tutor compete.** The 2×3 grid of legacy tools is visually heavier than the tutor hero. Visitors are pulled toward "Translation" or "Grammar Check" instead of trying the tutor.
4. **No taxonomy.** Lessons, Grammar Check, Pronunciation, Quiz, Lesson Builder all sound like "study things" but they're a flat list. New users guess.
5. **Existing AI Conversation feature** (cross-session memory just added in C2!) is *not even in the grid* — it's only reachable from the main chat tab. Step 9 made it smarter, no one knows.

---

## Three redesign approaches

### 🅰 Tutor-first, Tools-second (minimal, my recommendation)

**Restructure the AI tab into two sections separated by a heading:**

```
┌────────────────────────────────────────────┐
│ Tutor hero (big, gradient, 80dp tall)      │
│ "Your AI Tutor — Nana 🐻 ready when you are"│
│                                            │
│ [Quick row — 4 chips]                      │
│ 💬 Chat   🎭 Roleplay   📖 Story   📷 Photo │
└────────────────────────────────────────────┘

┌────────────────────────────────────────────┐
│ ✦ More AI tools                            │
│                                            │
│ [2-col grid, smaller cards than today]     │
│ 🌐 Translation     🔤 Grammar              │
│ 🎙️ Pronunciation  🧠 Quiz                  │
│ ✨ Lesson Builder  📚 Lessons              │
└────────────────────────────────────────────┘

[Optional below: progress + weak areas]
```

**Key moves:**
- **Delete** the old `_buildHeroCard` from `ai_main.dart`
- **Pull the tutor's 4 mode entries up** as compact chips below the tutor hero so they're visible without tapping
- **Demote the tool grid** to a `More AI tools` section with smaller card size (`childAspectRatio: 1.6` instead of `1.1`)
- **Add AI Conversation** as a 7th tile in the tools grid (currently invisible on this tab)

**Why this works:** the tutor is now obviously the recommended path, and the 4 tutor modes are 1 tap not 2. Tools stay accessible for power users who know what they want.

**Effort:** ~3-4 commits, all Flutter, no backend changes. Maybe 4 hours.

---

### 🅱 Two tabs: "Tutor" and "Tools"

Split the AI tab into a 2-tab TabBar:

```
┌──────────────────────┬──────────────────────┐
│        Tutor         │        Tools         │
├──────────────────────┴──────────────────────┤
│                                             │
│  [Current TutorHomeScreen content]          │
│                                             │
└─────────────────────────────────────────────┘
```

**Pros:** Cleanest hierarchy. Tutor and tools never compete visually.
**Cons:** Tabs add navigation depth; users might miss the tools tab entirely. Bottom-nav AI tab → top-tab Tools is two clicks just to translate a word.

**Effort:** ~5-6 commits. Some plumbing because the existing AI tab is now its own thing.

---

### 🅲 Full merge: Tutor as the *only* AI entry

Most aggressive. Delete the legacy tool tiles entirely; the tutor "owns" the AI tab. Tools become things the tutor invokes (via cards or chat suggestions).

```
┌────────────────────────────────────────────┐
│   [Entire tab = TutorHomeScreen]            │
│                                             │
│   Greeting                                  │
│   Daily plan                                │
│   Start chat                                │
│   Scenarios / Story / Photo                 │
│   "Quick tools" row at bottom               │
│     Translate · Grammar · Pronounce ·       │
│     Quiz · Build lesson                     │
└────────────────────────────────────────────┘
```

**Pros:** Cleanest mental model. The tutor is the AI.
**Cons:** Most disruptive — existing power users lose direct access to tile-based tools. AI Conversation feature gets stranded if not re-homed. Risky if any tools have heavy direct-traffic users.

**Effort:** ~7-9 commits including provider rewiring + a migration path for users who deep-linked into a specific tool.

---

## My recommendation

**🅰 Tutor-first, Tools-second.** Lowest risk, highest "looks like one cohesive product" payoff. Buys most of the hierarchy benefit of 🅱 without the tab-navigation tax.

**Key wins:**
- The tutor + its 4 modes get top-of-fold real estate, finally
- Tool tiles still exist for direct-access power users
- Existing AI Conversation gets a tile and stops being invisible
- One-screen experience preserved (no new tab depth)

**Approximate commits:**
1. Delete old `_buildHeroCard`, expand tutor hero
2. Add 4-chip row (Chat / Roleplay / Story / Photo) under tutor hero
3. Restyle tool grid: smaller cards, "More AI tools" header, add AI Conversation tile
4. (Optional) Sprinkle: telemetry events for which row gets tapped

---

## Open questions for direction

1. **Lessons / Lesson Builder** — these technically belong in the Learning tab, not AI. Worth moving? (Out of scope for this redesign; flagging as a parallel question.)
2. **VIP tiles** — Pronunciation / Quiz / Lesson Builder currently show a lock icon. Stays the same in 🅰? Probably yes.
3. **First-run experience** — should we route brand-new users straight to PersonaPicker on tab open (not just on hero tap)? Bigger UX call.
4. **Stats / Weak Areas blocks** — keep them at the bottom of the AI tab, or move to the tutor home? They're tutor-feeling already.

---

## What I'd do next if you pick 🅰

Cut a branch `feat/step10-study-menu-redesign`, knock out 3-4 commits, merge in a single half-day session. No backend changes, no risk. Want me to drive it?
