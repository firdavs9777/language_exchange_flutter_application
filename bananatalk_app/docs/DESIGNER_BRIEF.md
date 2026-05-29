# BananaTalk — Designer Brief

**Version:** 1.4.1 (build 10544)
**Platforms:** iOS + Android (Flutter)
**Locales:** 18 (`ar de en es fr hi id it ja ko pt ru th tl tr vi zh zh_TW`)
**Themes:** Light + Dark (both required for every screen)
**Bottom tabs:** 5 — Community, Chats, Study, Moments, Profile

---

## 1. What BananaTalk Is

BananaTalk is a **language-exchange social app** combining three product spaces:

- **Social** — find language partners, browse profiles, post moments, share stories
- **Communication** — 1-to-1 chat with translation/transcription, real-time voice rooms
- **Learning** — vocabulary, daily practice, streaks, lessons, AI tutor tools

Monetization: VIP subscription + ads (Google Mobile Ads).
Backend: Node.js + MongoDB + Socket.io + WebRTC. Production endpoint `api.banatalk.com`.

---

## 2. Brand Identity (Current)

### Color Palette

| Role | Hex | Notes |
|---|---|---|
| **Primary** | `#00BFA5` | Teal — main brand |
| Primary Light | `#5DF2D6` | |
| Primary Dark | `#008E76` | |
| **Secondary** | `#FFD54F` | Banana yellow (the namesake) |
| Secondary Light | `#FFFF81` | |
| Secondary Dark | `#C9A415` | |
| **Accent** | `#7C4DFF` | Purple |
| Accent Light | `#B47CFF` | |
| Accent Dark | `#3F1DCB` | |
| Success | `#4CAF50` | |
| Warning | `#FF9800` | |
| Error | `#E53935` | |
| Info | `#2196F3` | |

### Type & Iconography
- **Type**: `google_fonts` package (default Roboto, designer free to propose)
- **Icons**: Material Icons (Outlined for inactive, Rounded for active)
- **Design language**: Material 3, card-based, rounded corners, slide-in animations on chat bubbles

---

## 3. App Architecture — Top-Level Structure

```
Splash Screen
    │
    ├─→ (logged in) ─→ Tab Bar Menu (5 tabs)
    │
    └─→ (logged out) ─→ Login Screen
```

### Bottom Tab Bar (5 tabs)

| # | Tab | Icon | Label | Notes |
|---|---|---|---|---|
| 0 | **Community** | `explore` | Community | Discovery, voice rooms, stories, waves |
| 1 | **Chats** | `chat_bubble` | Chats | Conversation list, with unread badge |
| 2 | **Study** | `menu_book` | Study | Learning hub, vocabulary, AI tools |
| 3 | **Moments** | `auto_awesome` | Moments | Social feed (like Instagram) |
| 4 | **Profile** | `person` | Profile | Self profile, settings, with notification badge |

The tab bar is a custom rounded floating-bar style with badges on Chats (unread messages) and Profile (notifications).

---

## 4. Authentication Flow (All Screens)

### Entry
- **Splash Screen** — branded loading, checks auth state
- **Terms of Service Screen** — must accept before account creation

### Login (4 methods, all in `lib/pages/authentication/login/`)
- **Login Screen** — email + password form
- **Google Login Screen** — Google Sign-In flow
- **Apple Login Screen** — Apple Sign-In flow (required on iOS)
- **Facebook Login Screen** — Facebook OAuth flow

### Registration (multi-step)
- **Register Screen** (step 1) — email, password, basic info
- **Register Two Screen** (step 2) — profile details (name, gender, languages, photo)
- **Auth Step Progress** widget shown throughout

### Email Verification
- **Email Input Screen** — enter or confirm email
- **Email Verification Screen** — enter 6-digit code

### Password Reset (3-step)
- **Forgot Password Email Screen** — enter email
- **Forgot Password Verification Screen** — enter code from email
- **Reset Password Screen** — set new password

### Biometric (post-login)
- **Enable Biometric Prompt** — opt-in screen after first login to use Face ID / fingerprint

### Shared Auth Widgets
- `auth_screen_scaffold` — common shell
- `auth_gradient_button` — primary CTA
- `auth_text_field` — branded input
- `password_field` — password with visibility toggle
- `auth_step_progress` — step indicator

**Total auth screens:** ~12

---

## 5. Tab 0 — Community

The **landing tab** for most users. Has internal sub-tabs and surfaces.

### 5.1 Community Main Screen
Contains:
- **Stories row** at top (horizontal scroll of active stories + create button)
- **Voice rooms upcoming section** (scheduled rooms cards)
- **Visitor recall card** — "5 people viewed your profile" with avatars
- **Filter chips bar** — quick filters: online now, new users, prioritize nearby, etc.
- **Conversation-starter ribbon** — suggested icebreakers
- **Community tab bar** (sub-tabs below)

### 5.2 Community Sub-Tabs (`lib/pages/community/tabs/`)
- **Partner Discovery Tab** — main browse feed, language partners
- **Genders Tab** — filtered by gender
- **City Tab** — same-city users
- **Nearby Tab** — geolocation-based, distance-sorted
- **Topics Tab** — users grouped by topics/interests
- **Voice Rooms Tab** — list of active voice rooms with category filter chips, "Create Room" FAB
- **Waves Tab** — received waves inbox
- **Waves Archive Screen** — historical waves

### 5.3 Single User Profile (community detail)
- **Single Community Screen** — full profile of another user with:
  - Photos carousel
  - Name, age, location, languages (native + learning), level, MBTI, blood type
  - Bio
  - Topics/interests chips
  - Action buttons: Send Wave, Start Chat, View Moments
  - Mutual interests indicator
- **Visitors Screen** — see who visited your profile

### 5.4 Voice Rooms (sub-feature of Community)
- **Voice Room Screen** — live room with:
  - Host header
  - Participants grid (avatars with speaking indicators, hand-raise icons)
  - Mute/raise hand/leave buttons
  - In-room chat panel (with unread badge)
  - Reconnect banner
  - Host controls overlay
- **Create Room Sheet** — title, topic, language, max participants, **scheduled mode** with date picker, **category picker** (casual/language_practice/topic/qa)
- **Scheduled Room Card** — preview card with RSVP button
- **Upcoming Section** — list of scheduled rooms

### 5.5 Stories (within Community)
- **Stories Feed Widget** — horizontal scroller of active stories
- **Story Viewer Screen** — full-screen viewer with reactions, replies, view count
- **Create Story Screen** — image, video, or **text story with 13 gradient presets**
- **Highlights Row** — saved stories grouped into highlights with create button

### 5.6 Sending Waves
- **Send Wave Sheet** — bottom sheet with:
  - Target user name + avatar
  - Custom message input
  - Quick-reply chips (👋 Hi!, country-based prompts, language-based prompts)
  - Cooldown handling (24h between waves to same user)
- **Mutual Wave Dialog** — celebratory "It's a match!" moment when waves mutual

### 5.7 Community Filter Sheet (bottom sheet)
- Age range slider
- Gender selector
- Native language picker (with cached language list)
- Learning language picker
- Language level (beginner/intermediate/advanced/native)
- Country picker (with auto-detect)
- Online only toggle
- New users only toggle
- Prioritize nearby toggle
- **Topics filter section** with chips
- **Mutual interests minimum slider** (0-5)
- Sticky apply/reset bar with match-count preview

---

## 6. Tab 1 — Chats

### 6.1 Chat List Screen
- **Search bar** at top
- **Filter tabs** — All, Unread, Groups (future), Favorites
- **Chat list tiles** — avatar, name, last message preview, timestamp, unread badge, online indicator
- **Empty state** — illustration + "send a wave to start" prompt
- **Socket-driven** real-time presence and message updates

### 6.2 Chat Conversation Screen
- **Chat Header** — partner avatar/name/online status, call buttons (audio/video), options menu
- **Chat Options Menu** — search, mute, wallpaper, block, report
- **Pinned Messages Bar** — collapsible pinned message preview
- **Messages List** — Material 3 redesigned bubbles, slide-in animation, day separators
- **Typing Indicator** — animated dots
- **Conversation Empty State** — for new chats
- **Scroll-to-Bottom FAB** — appears when scrolled up

### 6.3 Message Types (every type needs design)
- Text (with **link previews** when URLs detected)
- Stickers (custom set + emoji)
- **Wave sticker** (greeting flow)
- Image (with full-screen viewer)
- Video (with player + thumbnail)
- Voice message (waveform + **on-demand transcription** button)
- File attachment
- Location (map preview)
- Replied message (with quote preview)
- Forwarded message (with "Forwarded" label)
- Deleted message placeholder

### 6.4 Message Bubble Long-Press Menu
- Reply
- Pin
- Forward
- Copy
- **Save to Vocabulary** (word-level long-press → adds to Learning vocab)
- Translate (per-conversation auto-translate toggle)
- Delete (for me / for everyone within time limit)
- React with emoji

### 6.5 Chat Input Section
- Text input with auto-grow
- **Sticker Button** → opens Sticker Panel
- **Media Option Button** → opens Media Panel (gallery, camera, file, location)
- **GIF Picker Panel** (sub-panel)
- Voice record button (hold-to-record with waveform preview)
- Send button (animated state change)

### 6.6 Chat Dialogs
- **Delete Message Dialog** — radio: delete for me / for everyone + countdown of edit-window
- **Forward Message Dialog** — pick chat(s) to forward to
- **Mute Dialog** — 1 hour, 8 hours, 1 week, forever
- **Message Actions Bottom Sheet** — alternative to long-press menu

### 6.7 Chat Sub-Screens
- **Chat Search Screen** — search within a conversation
- **Bookmarks Screen** — pinned/saved messages across chats
- **Wallpaper Picker Screen** — per-conversation chat background customization
- **Chat Media Gallery** — all images/videos shared in conversation

---

## 7. Tab 2 — Study (Learning)

### 7.1 Learning Main Screen
Layout: TabBar at top with sub-tabs.
- **Learn Tab** — core learning hub with:
  - **Progress Hero** — weekly XP bar chart, current streak, total XP (the daily-engagement focal point)
  - **Daily Practice Card** — today's quick session prompt
  - **Weekly Digest Card** — recap of last 7 days
  - Lessons section
  - Quizzes section
  - Streak section
- **AI Tools Tab** — AI feature grid (see 7.5 below)

### 7.2 Vocabulary
- **Vocabulary Screen** — saved words from chat, organized by lists/decks
- **Vocabulary Review Screen** — flashcard-style review
- **Vocabulary Add Screen** — manually add a word
- **SRS Dashboard Screen** — spaced-repetition stats and queue

### 7.3 Lessons & Quizzes
- **Lessons Screen** — list of available lessons (by language + level)
- **Lesson Player Screen** — exercise sequence with progress bar
- **Exercise types**:
  - Multiple choice
  - Fill in the blank
  - Matching (drag to pair)
  - Ordering (rearrange words)
  - Translation (type the translation)
- **Quizzes Screen** — list of quizzes
- **Quiz Player Screen** — timed quiz playback

### 7.4 Gamification
- **Streak Freeze Dialog** — use a freeze to protect streak (limited supply, regenerates)
- **Achievements Screen** — badges grid, locked vs unlocked
- **Challenges Screen** — gamified objectives with progress
- **Leaderboard Screen** with sub-tabs:
  - XP Tab — top XP earners
  - Streak Tab — longest streaks
  - Friends Tab — your friends ranked
  - My Ranks Tab — your position in each category

### 7.5 AI Tools (`lib/pages/ai/`)
A whole sub-app of AI-powered learning aids.
- **AI Main** — entry grid showing all AI tools
- **AI Conversation Screen** — chat with AI tutor
  - **Topic Selection Sheet** — pick a conversation topic
  - **Conversation History Screen** — past AI conversations
- **Grammar Feedback Screen** — paste text → get grammar critique
- **Pronunciation Screen** — record audio → AI scores pronunciation
- **Translation Screen** — translate text between language pairs
- **AI Quiz Screen** — generate custom quiz
  - **Quiz Player Screen** — play AI-generated quiz
- **Lesson Builder Screen** — AI creates custom lesson from prompt

---

## 8. Tab 3 — Moments

A social feed similar to Instagram or WeChat Moments.

### 8.1 Feed
- **Moments Feed** — vertical scroll of moment cards
- **Moment Card** — image/video, caption, likes, comments, share, tags, location
- **Filter Sheet** — by tags, location, language

### 8.2 Create
- **Create Moment Screen** — image/video upload, caption editor, **tag autocomplete from recent**, location picker, visibility settings
- **Multiple media** support per moment

### 8.3 Single Moment View
- **Single Moment Screen** — full detail, comments thread, reactions, full-screen media
- **Image Viewer** — pinch/zoom full-screen
- **Video Player Widget** — full-screen with controls

### 8.4 Saved
- **Saved Moments Screen** — your bookmarked moments

### 8.5 Comments
- **Comments sub-feature** — threaded comments with reactions

### 8.6 Local actions
- **Hide-this-user moments** local mute toggle
- Report moment (flows to report screen)

---

## 9. Tab 4 — Profile

### 9.1 Profile Main Screen
- **Profile Header** — large avatar, name, age, location, languages, VIP badge
- **Profile Stats** — followers count, followings count, visitors count
- **Bio section**
- **Languages section** — native + learning with proficiency levels
- **Topics chips**
- **Sections**:
  - Personal Section — basic info
  - Language Section — language proficiency
- **Your Moments grid** — moments you've posted

### 9.2 Profile Drawer (slide-out)
- About BananaTalk (with `about_dialog`)
- Theme settings
- Settings (full settings screen)
- VIP status / upgrade
- Help & support
- Logout (with `logout_dialog` confirmation)

### 9.3 Edit Profile
- **Edit Main Screen** — sections list, with **completion percentage**
- **Edit Sub-Screens** (each is its own screen):
  - Name & Gender Edit
  - Bio Edit
  - Hometown Edit
  - Language Edit (native + learning, with levels)
  - Topics Edit
  - MBTI Edit
  - Blood Type Edit
  - Privacy Edit
  - Picture Edit (multi-photo grid with **upload handler**, **photo picker sheet**, **confirm dialog**)

### 9.4 Followers / Followings / Visitors
- **Followers Screen** — list of followers
- **Followings Screen** — users you follow
- **Visitors Screen** — recent profile visitors

### 9.5 Highlights
- **Highlights Screen** — your saved story highlights

### 9.6 Theme Screen
- Light / Dark / System (SegmentedButton)

---

## 10. Settings (accessed from Profile drawer)

### 10.1 Settings Hub
Main settings screen with categorized rows.

### 10.2 Sub-Screens
- **Language Settings Screen** — pick from 18 locales
- **Notification Preferences Screen** — per-category notification toggles
- **Email Preferences Screen** — newsletter/marketing email controls
- **Data & Storage Screen** — cache stats, clear cache (with **cache stats card** widget)
- **Blocked Users Screen** — manage block list
- **Legal Screen** — terms of service, privacy policy
- **Account Deletion** — destructive account removal flow

### 10.3 Notifications
- **Notification History Screen** — all past notifications, grouped by day
- **Notification Settings Screen** — granular notification controls

---

## 11. VIP / Premium

- **VIP Plans Screen** — pricing tiers, features comparison
- **VIP Payment Screen** — checkout flow (Apple/Google in-app purchase)
- **VIP Status Screen** — active subscription info, renewal, cancel
- **Visitor Upgrade Screen** — VIP-only feature: see who visited (paywall-gated)

---

## 12. Other Screens

- **Splash Screen** (`lib/pages/home/splash_screen.dart`)
- **Home** wrapper (`lib/pages/home/home.dart`)
- **Explore Main Screen** — discovery feed (mixed content)
- **Matching** flow (`lib/pages/matching/`) — partner matching logic UI
- **Reports** screens — report user / report content flows
- **Video Editor** — for moments/stories video editing

---

## 13. Key User Journeys

### Journey 1: New User Onboarding
1. **Splash** → no session detected
2. **Login Screen** → "Sign up" → **Register Screen** (step 1)
3. **Email Verification** → enter code
4. **Register Two Screen** (step 2) → profile basics
5. **Terms of Service** → accept
6. **Enable Biometric** prompt → opt in/out
7. Lands on **Community Tab** → browses partners
8. Sends first **Wave**
9. Receives mutual wave → **Mutual Wave Dialog**
10. Chat unlocks → **Conversation Screen** starts

### Journey 2: Daily Engaged Learner
1. Opens app → **Chats Tab** (badge alert)
2. Replies to chat → uses voice message
3. Long-presses unfamiliar word → **Save to Vocabulary**
4. Taps **Study Tab** → sees daily practice prompt
5. Completes daily practice → XP awarded
6. Reviews saved vocabulary in **Vocabulary Review Screen**
7. Streak ticks up → maybe burns a **Streak Freeze**

### Journey 3: Voice Room Host
1. Opens **Community Tab → Voice Rooms sub-tab**
2. Taps **Create Room FAB**
3. Picks category, language, scheduled time
4. Room created → invites broadcast
5. Joins as host → **Voice Room Screen**
6. Manages participants (mute, kick if needed)
7. Uses **In-Room Chat Panel** for text side-channel
8. Ends room

### Journey 4: Social Discovery
1. Opens **Community Tab**
2. Watches **Stories** at top
3. Browses **Partner Discovery Tab**
4. Opens **Filter Sheet** → sets mutual interests minimum to 3
5. Taps a card → **Single Community Screen**
6. Reads bio, scrolls photos
7. Taps **Send Wave** → fills custom message
8. Wave sent → snackbar confirms

### Journey 5: AI Practice
1. **Study Tab → AI Tools Tab**
2. Picks **AI Conversation**
3. **Topic Selection Sheet** → "Travel"
4. Chats with AI tutor in target language
5. AI corrects grammar inline
6. Saves conversation to **Conversation History**
7. Later: opens **Pronunciation Screen** → records audio, gets score

### Journey 6: Profile Completion
1. **Profile Tab** → sees completion % (e.g. 65%)
2. Taps **Edit Main** → opens sections list
3. Picks **Picture Edit** → uploads 3 more photos
4. Goes back → **Topics Edit** → adds 5 topics
5. Completion now 90%
6. VIP-pitched on incomplete-profile screen

---

## 14. Design Constraints

### Hard requirements
- **18 locales** — designs must accommodate:
  - **RTL** for Arabic (full layout mirror)
  - **Long translations** — German/Russian can be 30%+ longer than English; Japanese/Chinese can be 30%+ shorter
  - **Variable text** in components — buttons, chips, headers
- **Dark mode** mandatory — every screen needs both
- **iOS + Android parity** — Material 3 base, should feel native on both
- **Accessibility**:
  - 44pt minimum touch targets
  - VoiceOver/TalkBack labels
  - Sufficient contrast (WCAG AA minimum)
  - Dynamic Type support

### Real-time states matter
- Voice room speaking indicators (live audio levels)
- Typing indicators
- Online/offline presence dots
- Unread message badges
- Notification badges on tabs

### Empty / error / loading states
Currently inconsistent across the app — this is a major opportunity area.

### Tech-imposed
- Flutter framework — designs must be implementable (avoid platform-fighting curves)
- Bottom navigation is the primary nav pattern (locked)
- Bottom sheets are heavily used for actions
- Material 3 component library is the base

### Brand
- Keep **teal + banana yellow + purple** triad
- "Banana" motif should remain (logo, the namesake wave 👋, etc.)
- Personality: warm, encouraging, multilingual, social-first

---

## 15. Recently Shipped (last 30 days)

Context on what's freshly built — designer should know what's new, what's stable:

| Area | Recently shipped |
|---|---|
| **Chat** | Material 3 bubble redesign, slide-in animation, save-to-vocab long-press, per-conversation auto-translate, voice transcription on demand |
| **Voice Rooms** | Scheduled rooms + RSVP, category filter chips, host kick/end controls, mute-all, speaking indicators, reconnect banner |
| **Stories** | Text stories with 13 gradient presets, highlights row + create-highlight sheet |
| **Moments** | Tag autocomplete from recent, hide-user mute toggle, full folder restructure |
| **Community** | Filter rebuild (sticky bars, match count, ExpansionTile sections), mutual interests slider, online dots, conversation-starter prompts, profile-visitor recall card |
| **Learning** | Daily practice + grading, vocabulary AI-define, weekly digest, streak freeze power-up |
| **Settings** | Theme toggle (SegmentedButton), language switcher, notification preferences screen |

---

## 16. Known UX Pain Points

Worth attention in the redesign:

1. **Visitor recall card** is too tall — could be a notification-style row or tighter scroller
2. **Send Wave sheet** has many quick-reply chips — IA could improve
3. **Voice rooms tab** has too many UI elements competing (FAB + filter chips + scheduled section)
4. **Learning Progress Hero** is dense (bar chart + streak + XP all in one block)
5. **Filter Sheet** is a very long bottom sheet — could be cleaner / paged
6. **Empty states** across the app are inconsistent in tone and visual treatment
7. **Onboarding (auth flow)** is functional but flat — first impression matters
8. **Profile pages** could use stronger visual personality per user
9. **Wave sticker** in chat doesn't render gracefully in the new Material 3 bubble system
10. **5 bottom tabs** with badges + custom rounded bar — could be simpler hierarchy
11. **Profile Drawer** mixes settings, theme, VIP, logout — needs reorganization
12. **VIP touchpoints** are sprinkled throughout; could be more cohesive paywall design language

---

## 17. Priority Surfaces for Redesign

Ranked by impact:

| # | Surface | Why it matters |
|---|---|---|
| 1 | **Community Discovery** (Partner Discovery Tab + Single Community Screen) | Most-trafficked surface; first impression |
| 2 | **Chat Conversation Screen** | Where most time is spent; recently redesigned, can go further |
| 3 | **Voice Rooms** (list + live screen) | Differentiator vs Duolingo/Tandem; deserves distinctive identity |
| 4 | **Learning Progress Hero & Streak** | Daily-engagement focal point |
| 5 | **Send Wave + Mutual Wave moments** | The magic moments — currently functional but flat |
| 6 | **Profile Main + Profile Drawer** | Personal expression surface, complex IA |
| 7 | **Onboarding** (auth + first profile setup) | First impression for every new user |
| 8 | **Empty / Error / Loading states** (system-wide) | Brand-defining moments, currently inconsistent |
| 9 | **Bottom Tab Bar** | Used 100% of sessions; small change = huge impact |
| 10 | **VIP / Premium screens** | Revenue impact |

---

## 18. Out of Scope (Don't Redesign)

Skip these:
- Authentication screen pixel details — refresh OK, but don't rebuild flow
- Reports / moderation flows — legal/compliance constraints
- Video editor — uses platform UI
- Settings sub-screens that are pure forms (data/storage, blocked users, legal)
- Cache management UI

---

## 19. Deliverables Wishlist

Whatever fits the designer's process, but ideally:

- **Design system** in Figma (colors, type scale, spacing tokens, component library)
- **High-fidelity mocks** of the 10 priority surfaces (Section 17), both light + dark
- **Icon set** if proposing changes (currently Material Icons)
- **Animation / motion guidance** for key interactions (wave sent, level up, streak, voice room speaking, mutual wave celebration)
- **Empty-state illustration set** — consistent style, 10-15 illustrations
- **Onboarding flow** mocks (auth → first profile setup, 5-8 screens)
- **RTL** sample screens (Arabic) for at least 3 key surfaces
- **Long-locale** sample screens (German/Russian) showing how layouts handle longer text
- **Brand voice guide** for microcopy

---

## 20. Quick Stats for Context

- **18** supported languages
- **5** bottom navigation tabs (Community, Chats, Study, Moments, Profile)
- **~150+** distinct screens across the app
- **8** core feature areas (community, chat, voice rooms, stories, moments, learning, profile, settings)
- **4** social login methods (Google, Apple, Facebook, email)
- **18** AI sub-tools and conversation features in the Study tab
- **13** gradient presets for text stories
- **4** voice room categories (casual, language_practice, topic, qa)
- **5** message exercise types in lessons (multiple choice, fill blank, matching, ordering, translation)

---

## 21. Tech Stack Quick Reference

| Layer | Stack |
|---|---|
| Frontend | Flutter 3.24+, Dart 3.10+ |
| State | Riverpod 2.6 |
| Routing | go_router 14.8 |
| Real-time | socket_io_client, flutter_webrtc |
| Auth | Firebase (Apple/Google), Facebook SDK |
| Storage | shared_preferences, flutter_secure_storage, sqflite |
| Media | image_picker, just_audio, video_player, flutter_sound |
| Maps | flutter_map (location features) |
| Backend | Node.js + Express + MongoDB + Socket.io |
| Production API | `api.banatalk.com` |
| Repo | `github.com/firdavs9777/language_exchange_flutter_application` |

---

## 22. App Version & Contact

- **Current version**: `1.4.1+10544`
- **Production environment**: `api.banatalk.com`
- **Brand name**: BananaTalk (note: banatalk in the API URL is intentional)

---

*This brief is meant to be a starting point. The designer should feel free to challenge assumptions, propose IA changes, suggest removing features, and ask clarifying questions.*
