# How BananaTalk explains itself to a new user — audit, 2026-10-10

Baseline this exists to move: **85% of signups leave on day one. D1 15%, D7 7%.**

Scope: every surface that teaches a first-time user what the app does. Written after
shipping the five page guides, to answer "what else is there?" rather than to re-describe
what just landed.

---

## 1. What exists today

| Surface | Where | Trigger | Dismissible |
|---|---|---|---|
| **Page guides** (new) | all 5 tabs | ≤3 days old, not yet acted | no — retires on act |
| **Say hi ring** (new) | top match card | while the Matches panel shows | n/a, 3 pulses |
| Feature spotlight sheet | app launch | rotating coins/rooms/voice, 1×/day, snoozeable | yes |
| AI Study promo modal | app launch | every 7 days | yes |
| Ads notice modal | app launch | once per device | yes |
| Announcement modal | app launch | server-driven | yes |
| AI tools scroll hint | AI Tools tab | first visit | self-clearing |
| Prompt of the day | Moments | daily | yes |
| Empty states | ~15 screens | no content | n/a |
| Permission priming | notifications | after first non-empty match batch | n/a |

**Read that table as a shape, not a list.** Four of the ten are *modals at app launch*,
competing for the same moment, each with its own throttle. None of them is attached to
the thing it describes. The guides are the first surface that appears **where the feature
is**, which is why they are the pattern to extend rather than add an eleventh modal to.

## 2. Gaps found

### 2a. 113 hardcoded English strings across 67 files

`flutter gen-l10n` cannot see these — they never reach an `.arb`. They are invisible to
every translation check, including the one added today.

The worst was `conversation_empty_state.dart`: **"No messages yet" / "Send a message to
start the conversation with {name}" / "Tap to say hi!"** — the screen a user lands on
immediately after tapping Say hi. A Korean user followed a Korean guide, tapped a Korean
button, and arrived at an English screen, on the one step the whole first-session funnel
is measured by. Fixed today; 110 remain.

Next by exposure:
- `create_moment.dart` — 9, on the Moments guide's own destination
- `waves_tab.dart` — 3, including the entire empty state
- `vip_upsell_banner.dart`, `chat_screen_wrapper.dart` — paywall copy, English-only
- `lesson_player_screen.dart`, `quiz_player_screen.dart`, `vocabulary_review_screen.dart`
  — 3 each, on the AI Study guide's destination

### 2b. In-chat features are invisible

Translation, correction, bookmarks and voice notes are all behind **long-press on a
message bubble** (`message_bubble.dart:1178`). Nothing anywhere says so. These are the
features that make this a language-exchange app rather than a chat app, and a user who
never long-presses never learns the app does any of them.

### 2c. The guides stop at the tab

Each guide gets someone *to* a screen. None of them survives the trip: having tapped
"Post a moment", the composer explains nothing. The hand-off is where the drop is.

## 3. Methods worth adding, in order

Ranked by (value to day-one activation) ÷ (cost), with what each one is actually worth.

### P1 — Finish localizing the guide destinations
110 strings, mechanical, no design. A guide that lands a user on an English screen is
worse than no guide: it breaks the promise the guide just made. Start with
`create_moment.dart` (Moments destination), then the learning players (AI Study
destination), then `waves_tab.dart`.

### P2 — First-use tooltip on the message bubble
One contextual tooltip on the first received message: *"Long-press to translate or
correct."* This is the single highest-value undiscovered feature in the app and the one
that differentiates it. Reuses `GuideStore` exactly as-is — add a `GuideSurface.chat`,
one new pref pair, no new infrastructure. **This is the cheapest large win on the list.**

### P3 — Activation milestones instead of a view window
Current rule: show for 3 days, retire on act. A milestone rule — *"show until the user
has done 3 of: message, post, lesson, profile"* — targets the number that actually
predicts retention. [Users who complete 3+ core actions in their first session retain
~4× better](https://www.mikecrunch.com/education-app-retention-playbook-onboarding-activation/).
The store already records per-surface `acted`, so the data is there; what is missing is
a progress surface that reads all five at once.

### P4 — Collapse the four launch modals into the spotlight
Four separate modals fire at launch, each self-throttling, none aware of the others. A
new user can meet three of them before seeing a single feature. Fold them into the one
rotating sheet that already has a snooze and a global dismiss count.

### P5 — Permission priming for notifications
Already deferred to after the first match batch, which is right. The ask itself is still
the bare OS prompt — [priming with one screen of context first](https://www.bolderapps.com/blog-posts/app-onboarding-flow-architecture-2026)
is the standard fix, and notifications are what brings a day-one user back on day two.

### Deliberately NOT recommended
- **A coach-mark tour.** Front-loaded tours are the pattern the industry moved away from;
  [contextual, just-in-time help outperforms upfront tutorials](https://www.appcues.com/blog/essential-guide-mobile-user-onboarding-ui-ux).
  It also contradicts the growth spec's own argument against friction at the moment
  someone is deciding whether to stay.
- **A welcome carousel.** Nothing is retained, and it delays the first action.
- **Gamified progress bars on the profile.** Measures profile completion, not activation.

---

## Sources

- [Appcues — essential guide to mobile user onboarding](https://www.appcues.com/blog/essential-guide-mobile-user-onboarding-ui-ux)
- [Digia — onboarding patterns: progressive disclosure vs front-loaded setup](https://www.digia.tech/post/onboarding-patterns-progressive-disclosure-vs-front-loaded-setup/)
- [Digia — mobile app onboarding: activation, patterns, retention](https://www.digia.tech/post/mobile-app-onboarding-activation-retention/)
- [Bolder Apps — onboarding flow architecture 2026](https://www.bolderapps.com/blog-posts/app-onboarding-flow-architecture-2026)
- [MikeCrunch — education app retention playbook](https://www.mikecrunch.com/education-app-retention-playbook-onboarding-activation/)
- [nvecta — in-app nudges: 12 examples & 6 design patterns](https://www.nvecta.com/blog/in-app-nudges/)
- [UXCam — apps with great user onboarding](https://uxcam.com/blog/10-apps-with-great-user-onboarding/)
