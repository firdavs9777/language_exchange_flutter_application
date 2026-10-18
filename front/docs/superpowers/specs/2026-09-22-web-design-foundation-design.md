# Web Design Foundation — Design

**Date:** 2026-09-22
**Status:** approved, ready for implementation planning
**Goal:** give the web the app's visual vocabulary — as Tailwind tokens and a small set
of shared primitives — so that Community, Moments, Profile and Notifications each
consume tested pieces instead of re-inventing them.

**Scope:** web-only. No backend change, no API change, no new field on any model.
No user-visible surface is redesigned here; this spec produces the tokens and
components that the four surface specs will consume.

---

## 1. Where this came from

The instruction was "match web with our app". Reading both codebases, that is not one
project — it is six, and they have a dependency order:

| # | Sub-project | Kind |
|---|---|---|
| 1 | **Design foundation** (this spec) | tokens + shared primitives |
| 2 | Community | port |
| 3 | Moments | port |
| 4 | Profile | port |
| 5 | Notifications | build from scratch — the web has no bell, no history, no deep-link routing |
| 6 | AI Study / VIP redirect + app-download banner | growth |

Foundation goes first for the same reason the app's own moments spec makes the shared
pill task one: *everything else builds on a tested widget*. The web has the identical
three-way duplication the app had, and building Community first would mean writing the
pill, then rewriting it twice.

Each sub-project gets its own spec, plan and implementation pass.

---

## 2. What is actually broken

### 2.1 There are no tokens

`tailwind.config.js` is `theme: { extend: {} }`. Every brand value is a literal at the
call site: `#00BFA5` appears **145 times across 30 files**, heaviest in `HomeMain.scss`,
`Register.scss` and the chat CSS. Elsewhere the same intent is spelled `teal-500` — which
is Tailwind's `#14b8a6`, a different colour — and `MainMoments.tsx` reaches for
`from-blue-500 to-purple-600`, a palette the app does not have at all.

The elevation is off by more than the colour is. The app's `AppShadows.sm` is
`0 1px 4px rgba(0,0,0,.04)`; the web reaches for Tailwind `shadow-lg`
(`0 10px 15px rgba(0,0,0,.1)`) on the equivalent surfaces. A shadow two and a half times
the offset at two and a half times the alpha is most of why the two products do not feel
related, and no amount of colour matching fixes it.

### 2.2 The avatar is written three times

- `MemberCard.tsx` — story ring, native-language flag overlay, online dot
- `ProfileHeader.tsx:20` — ring, online dot, initials fallback
- `SingleMoment.tsx:318` — a bare `<img>` with a hover border

Three implementations, three behaviours, three sets of bugs. Only one has an initials
fallback, so a user with no photo renders as a broken image in the moments feed.

### 2.3 The language pair is drawn three ways, and none of them show proficiency

`MemberCard` shows two flag emoji and an arrow. `LanguagesCard` shows two chunky bordered
boxes plus a purple `Award` chip. The moment card header (`SingleMoment.tsx`) shows
nothing at all. On a language exchange product the exchange pair is the single most
important fact about a person, and the web currently makes three different weak claims
about it.

### 2.4 Five language-code maps, and the fallback picks the wrong language

The code/flag mapping exists in five places:

| Location | Entries | Consumers |
|---|---|---|
| `community/type.ts` — `LANGUAGE_CODES` (name→code) | 10 | `MemberCard` |
| `community/type.ts` — `LANGUAGE_FLAGS` (**code**→flag) | 10 | `MemberCard` |
| `community/utils.ts` — `getLanguageCode` + `getLanguageFlag` (**name**→flag, inline) | 10 | `CommunityDetail.tsx:23`, rendered at `:37` and `:43` |
| `tandem/LanguageFlagChip.tsx:34` — own `codes` object | 13 (the same ten plus Uzbek, Turkish, Arabic) | `TandemMemberCard`, `HighlightedProfilesCarousel` |
| (nothing in Moments or Profile) | — | they cannot reach any of the above without importing across feature folders |

Note that two of these are keyed differently — `type.ts` maps a *code* to a flag,
`utils.ts` maps a *name* to a flag — so they are not even the same kind of table, and
`CommunityDetail` is the screen that uses the odd one out.

Three carry the same fallback (`MemberCard.tsx:42`, `utils.ts:7` — spelled `.slice(0, 2)`
there — and `LanguageFlagChip.tsx:34`):

```ts
return LANGUAGE_CODES[language] || language.substring(0, 2).toLowerCase();
```

The backend catalog (`seeds/languages.js`) holds ~137 languages, so that fallback runs
constantly, and it does not degrade gracefully — it resolves to a **different language**:

| Language | `substring(0,2)` | Correct | Flag today | Flag after |
|---|---|---|---|---|
| Estonian | `es` | `et` | 🇪🇸 — **Spain** | 🇪🇪 |
| Frisian | `fr` | `fy` | 🇫🇷 — **France** | 🇳🇱 |
| Esperanto | `es` | `eo` | 🇪🇸 — **Spain** | 🌐 |
| Chinese (Traditional) | `ch` | `zh` | 🌐 | 🇹🇼 — see §3.2.2 |
| Persian | `pe` | `fa` | 🌐 | 🇮🇷 |
| Filipino | `fi` | `tl` — and `fi` **is Finnish** | 🌐 | 🇵🇭 |

Every row above is verified present in `seeds/languages.js` and `NAME_TO_ISO`.

The failure has two shapes, and only one of them is visible. Where the slice lands on one
of the ten flag keys, the user sees a **confidently wrong country** — an Estonian speaker
flagged as Spanish. Where it does not, the flag falls back to 🌐, which is merely
unhelpful. §3.2 fixes both, and §3.2.2 has to widen the flag table to do it. It
deliberately does **not** fix the pill's code path — see §3.2.1.

### 2.5 Two design systems are layered on top of each other

Bootstrap arrives two different ways, and they need separating because they have different
conversion costs:

- **Global CSS.** `src/index.tsx:7` loads a customised `bootstrap.custom.css`, so
  `d-flex`, `btn btn-*` and `text-muted` work anywhere. `CommunityDetail.tsx` is styled
  entirely this way and imports **no** react-bootstrap component.
- **The component library.** 20 files import from `react-bootstrap` — ten of them in
  Profile (`UserFollowing`, `UserFollowers`, `UserVisitors`, `InfoRow`, `PublicProfile`,
  `EditMyMoment`, `EditModal`, `LanguageView`, `ImageViewer/ImageModal`,
  `ImageUploader/ImageUploader`), the rest in `App.tsx`, shared chrome (`Loader`,
  `Message`, `FormContainer`, `ModalGlobal`), `navbar/TermsOfUse`, Chat and Stories.

Bootstrap is not accidental here; it is the web's original design system, and the app's
tokens live in neither it nor Tailwind.

---

## 3. Design

### 3.1 Tokens — additive, never overriding

`tailwind.config.js` gains a `theme.extend` carrying the app's values from
`lib/core/theme/app_theme.dart` under **brand-specific names**. It overrides none of
Tailwind's defaults.

```js
colors: {
  brand:  { DEFAULT: '#00BFA5', light: '#5DF2D6', dark: '#008E76' },  // AppColors.primary
  banana: { DEFAULT: '#FFD54F', light: '#FFFF81', dark: '#C9A415' },  // AppColors.secondary
  surface: { DEFAULT: '#FFFFFF', dark: '#1E1E1E' },
  canvas:  { DEFAULT: '#F8F9FA', dark: '#121212' },
  cardbg:  { DEFAULT: '#FFFFFF', dark: '#2C2C2C' },
},
borderRadius: { card: '20px', chip: '12px', sheet: '24px' },   // AppRadius.xl / md / xxl
boxShadow: {
  card:  '0 1px 4px rgba(0,0,0,0.04)',   // AppShadows.sm
  raised:'0 2px 8px rgba(0,0,0,0.06)',   // AppShadows.md
  float: '0 4px 16px rgba(0,0,0,0.08)',  // AppShadows.lg
  brand: '0 6px 16px rgba(0,191,165,0.30)',  // AppShadows.colored
},
```

**Why additive rather than overriding Tailwind's scales.** An earlier draft of this spec
overrode `teal`, `borderRadius` and `boxShadow` so that "reaching for the default produces
the app's elevation." Measured against the codebase, each of those would have detonated on
merge:

| Override | Collateral |
|---|---|
| `colors.teal` | Tailwind **replaces** the scale rather than merging, so all **327** `teal-50…teal-900` usages across 49 files stop emitting CSS — silently, with no build error |
| `borderRadius.lg/xl` | `rounded-xl` 12px → 20px at **127** call sites, `rounded-lg` 8px → 16px at **105** |
| `boxShadow.sm/md/lg` | **102** call sites re-weighted at once, including Chat and Learning, which no sub-project in this sequence touches |

Brand-named tokens cost one thing — legacy call sites keep their current look until their
sub-project converts them — and that is precisely the trade already approved for Bootstrap
in §4. It also buys a property worth having: whether a given element is app-matched
becomes answerable by reading its class name.

**`gray` is left alone, and that is a knowing divergence.** Tailwind v3's `gray` is Cool
Gray (`gray-500` = `#6b7280`) while the app uses Material grey (`#9E9E9E`) — different in
both hue and lightness. Greys carry nearly all text and border colour on the site, so
repainting them is a larger change than everything else in this spec combined, with no
primitive depending on it. Recorded as an open item, not silently assumed equivalent.

**Not tokenised:** `AppSpacing` — Tailwind's 4px scale already matches it
(`AppSpacing.md = 12` = `p-3`). `AppColors.accent` (`#7C4DFF`) — no consumer yet. Tailwind's
`shadow-xl`/`shadow-2xl` keep their defaults, since nothing in this spec uses them.

**One porting note:** Flutter's `blurRadius` is a Gaussian sigma and CSS's blur radius is
not the same quantity; these are transcribed 1:1. Applied consistently across all four
shadows, so they stay in proportion to each other. This is deliberate — do not "correct" it
without re-checking all four together.

### 3.2 `src/utils/languages.ts`

All five maps in §2.4 collapse into one module, which exposes two functions along the two
paths the app itself keeps separate:

```ts
displayCode(language: string): string   // the pill's label
languageFlag(language: string): string  // the avatar's corner flag
```

#### 3.2.1 `displayCode` mirrors the app verbatim

Ported from `LanguageCodes.displayCode` (`lib/utils/language_codes.dart:58`), algorithm
and data both:

1. `stripVariant` — drop a trailing regional parenthetical (`Chinese (Traditional)` → `Chinese`)
2. lowercase and trim; empty → `''`
3. **substring** match against the app's 19-name map, first hit wins:
   `japanese → JP`, `english → EN`, `korean → KO`, `chinese → ZH`, `spanish → ES`,
   `french → FR`, `german → DE`, `italian → IT`, `portuguese → PT`, `russian → RU`,
   `arabic → AR`, `hindi → HI`, `tajik → TG`, `vietnamese → VI`, `thai → TH`,
   `indonesian → ID`, `turkish → TR`, `filipino → TL`, `cantonese → YUE`
4. otherwise `toBaseIso6391`, uppercased — and this step is **not** a plain two-letter
   truncation. Ported from `language_codes.dart:36`, in order: return nothing for the
   untaggable set `{ase, bfi, jsl, kvk, haw}` (sign languages and Hawaiian, which have no
   639-1 code); map the three-letter bases `fil → tl` and `prs → fa`; strip a hyphen
   suffix (`pt-BR` → `pt`); then accept the result only if it is exactly two letters.
   **Skipping the `fil → tl` case here would send Filipino to step 5 and produce `FI` —
   Finnish — which is the precise bug §2.4 exists to name.**
5. otherwise the first two letters, uppercased

**This reproduces two of the app's own quirks on purpose.** `japanese → JP` is a country
code, not ISO `ja`, and `cantonese → YUE` is three letters — both contradict the comment
directly above them in the app claiming "ISO-style, not country-style". And step 5 means
any language outside the 19 falls through to a slice, so **Persian renders `PE`**.

Parity was chosen over correctness here deliberately. The pill exists so the two products
say the same thing about the same person; a web pill reading `JA` beside an app pill
reading `JP` would defeat its only purpose. When the app fixes its map, the web follows.
Both quirks are logged in §6.5 for the app team.

#### 3.2.2 `languageFlag` uses the correct map

The flag resolves through the backend's own `NAME_TO_ISO`
(`utils/languageCodes.js`) — case-insensitive, variant stripped — returning `🌐` when the
language cannot be resolved.

**The flag table is widened to match.** Correct name→code resolution alone fixes almost
nothing: `LANGUAGE_FLAGS` holds ten code keys (`en es fr de it pt ru ja ko zh`), so Persian
returns 🌐 whether it resolves to `pe` or `fa` — identical output, no observable fix. What
correct resolution *does* fix immediately is the collisions: Estonian stops rendering 🇪🇸.
To fix the rest, the flag table is expanded to cover **every code `NAME_TO_ISO` can
produce — 115 distinct codes across its 134 name keys.**

**Transcribe the table; do not author it.** `seeds/languages.js` already carries a `flag:`
on all 137 entries, keyed by code — `{ code: 'fa', name: 'Persian', …, flag: '🇮🇷' }`,
`{ code: 'et', …, flag: '🇪🇪' }`, `{ code: 'fy', …, flag: '🇳🇱' }`. It has already settled
every judgment a hand-written table would stall on: Frisian is 🇳🇱, Hawaiian is 🇺🇸,
Esperanto and the sign languages have no country and carry 🌐 or 🤟. Writing 115 entries
by hand would mean re-deciding all of that, differently, in a second place.

One transform is required: **16 of the seed codes are variant-level** (`zh-CN`, `pt-BR`,
`ar-EG`), while `NAME_TO_ISO` emits base codes.

**Do not collapse blindly to first-occurrence.** The catalog holds
`zh-CN` → 🇨🇳, `zh-TW` → 🇹🇼 and `zh-HK` → 🇭🇰 as three separate entries. A naive
base-code collapse takes the first and renders **🇨🇳 for every Traditional Chinese and
Cantonese speaker** — flattening Taiwan and Hong Kong into the PRC flag on a product whose
Chinese-speaking user base is a large share of the whole. That is not a rounding error; it
is the kind of change users open support tickets about.

So `languageFlag` resolves in two steps:

1. Match the **full, unstripped** name against the seed catalog's `name` field first —
   `'Chinese (Traditional)'` → `zh-TW` → 🇹🇼, `'Cantonese'` → `zh-HK` → 🇭🇰,
   `'Portuguese (Brazil)'` → `pt-BR` → 🇧🇷.
2. Only then strip the variant and resolve the base code through `NAME_TO_ISO`.

This makes `displayCode` and `languageFlag` deliberately asymmetric, and correctly so: the
pill's *label* names the language (`ZH` either way, per §3.2.1), while the flag names the
specific variant the user actually chose. Every other base takes its sole catalog entry. Measured against the real data, **114 of
the 115 codes resolve directly from the catalog and exactly one does not**: `zh` has no
base row at all, only `zh-CN` 🇨🇳, `zh-TW` 🇹🇼 and `zh-HK` 🇭🇰. So the designation list is a
single line — `zh → 🇨🇳`, which is also what plain "Chinese" renders today, so no current
behaviour changes. The generator must **fail loudly** if a future catalog adds a second
such gap, rather than quietly emitting 🌐.

Anything still unresolved returns 🌐.

This is the §2.4 fix. A wrong flag is a wrong *picture*, and unlike the pill's label it has
no parity argument attached: the app resolves its flags by base ISO code
(`services/language_service.dart:204`) rather than through `displayCode`. The app also
carries a second, name-keyed flag map at `single_moment.dart:57`, so "the app does it this
way" is support for the choice, not proof — the choice stands on the collisions being
wrong regardless.

**Migration.** `components/community/type.ts`, `components/community/utils.ts` and
`tandem/LanguageFlagChip.tsx` all re-export from the new module rather than keeping their
own maps, so `MemberCard`, `CommunityDetail`, `TandemMemberCard` and
`HighlightedProfilesCarousel` are corrected by this spec without being rewritten by it.

`utils.ts` needs the most care of the three: its `getLanguageFlag` is keyed by language
*name* while `type.ts`'s is keyed by *code*, so the replacement must accept a name — which
the new `languageFlag(language)` does. `utils.ts` keeps `generateRandomStats` and
`useDebounce`, which have nothing to do with languages. No other behaviour in any of the
three changes.

### 3.3 `LanguageExchangePill`

The centrepiece. `KO ⇄ EN` in a brand-teal pill, with proficiency dots on the learning side.

```
╭──────────────────────╮
│  KO  ⇄  EN  ● ● ○    │   bg-brand/[0.09], rounded-full, brand-dark text
╰──────────────────────╯
```

```ts
interface LanguageExchangePillProps {
  nativeLanguage: string;
  learningLanguage: string;
  languageLevel?: string | null;
  dense?: boolean;   // smaller type + tighter padding, for the moment card header
}
```

Dot mapping, identical to `dotsForLevel` in the app:
`A1/A2 → ●○○`, `B1/B2 → ●●○`, `C1/C2 → ●●●`, **anything else, including `null` →
no dots rendered at all.**

That last rule is the whole point, and §6.2 explains why it is the common case and not an
edge case. Absent is not zero: three empty dots read as "beginner", a claim the data has
not made.

**Codes, not country flags.** Flags remain on the avatar corner, where they describe the
person rather than the language.

No dots on the native side. They would be three-of-three for everybody, varying for
nobody, and in the app they cost ~20px that overflowed the moment header at 320pt.

A language whose code resolves to `''` renders the pill with that side's code omitted —
never a blank or collapsed component.

### 3.4 `Avatar`

One implementation replacing the three in §2.2.

```ts
interface AvatarProps {
  src?: string;
  name: string;           // drives the initials fallback
  size?: 40 | 54 | 72 | 80;
  hasStory?: boolean;     // conic brand→banana ring
  isOnline?: boolean;     // green dot, bottom-right
  flag?: string;          // native-language flag, bottom-left
}
```

`hasStory` is an **explicit prop** rather than something the primitive derives from a user
object, because the three current call sites get the value from three different places:
Community and Profile from `user.hasActiveStory` stamped by `controllers/users.js`
(§6.3), Moments from the same field stamped by `controllers/moments.js`. A primitive that
reached into a user shape itself would have to know which of those it was looking at.

**Every current caller passes a real value** — `hasActiveStory` is live on all three
payloads. Nothing here turns an existing ring off.

Initials fallback is on the primitive, not the caller — it is the behaviour two of the
three current implementations forgot.

### 3.5 `SurfaceCard`

`rounded-card bg-surface shadow-card dark:bg-cardbg-dark dark:shadow-none`, with a
`padding` prop and an optional `interactive` flag adding hover elevation and an active
press scale. Deliberately the same treatment the app gives both the community partner row
and the moment card, so the two main browse surfaces stop looking like different products.

Dark mode drops the shadow rather than darkening it, matching
`boxShadow: context.isDarkMode ? [] : AppShadows.sm` in `community_card.dart:90`.

### 3.6 `Badge`

`<Badge tone="banana">VIP</Badge>` / `<Badge tone="brand">New</Badge>` — a round chip,
tonal fill at the app's alphas (banana 28%, brand 12%), dark-tone text.

Alphas are written as arbitrary opacity modifiers (`bg-banana/[0.28]`, `bg-brand/[0.12]`),
not `/28` and `/12`. Tailwind v3's shorthand modifier only accepts steps present in
`theme.opacity`, and an absent step emits **no background rule at all** rather than a build
error — the same silent-failure shape §3.1 was restructured to avoid. Replaces the
gradient-filled badges currently inlined in `MemberCard`.

### 3.7 `FollowButton`

An outlined brand pill that becomes an outlined neutral `Following` once followed, owning
the `useFollowUserMutation` / `useUnFollowUserMutation` pair, its pending state, and its
cache invalidation.

Today `CommunityDetail.tsx` is the only consumer; Community adds it to the partner row and
Moments adds it to the card header, so it will have three. Follow state is read **from the
RTK Query cache, never from local `setState`** — the app's spec calls out that two cards by
the same author will otherwise disagree after a tap, and a web feed has exactly the same
shape.

---

## 4. Bootstrap is frozen, not removed

Bootstrap stays loaded and all 20 react-bootstrap files keep working. The rule this spec
establishes is: **no new Bootstrap markup, global-CSS or component.**

Conversion is owned per sub-project, using the corrected inventory from §2.5:

- **Community** converts `CommunityDetail.tsx` off the global Bootstrap CSS classes. It
  imports no react-bootstrap component, so this removes zero library usages.
- **Profile** converts its ten react-bootstrap files.
- **Notifications** introduces none.

That leaves ten files owned by nobody in this sequence: `App.tsx`, the shared chrome
(`Loader`, `Message` ×2, `FormContainer`, `ModalGlobal`), `navbar/TermsOfUse`,
`chat/ChatContent`, `chat/UsersList` and `stories/MyStories`. An earlier draft said the
dependency would be "deleted by whichever sub-project removes the last usage" — with these
ten unowned, that trigger can never fire.

**So the exit condition gets an explicit owner: a seventh sub-project, "retire Bootstrap",
scheduled after Notifications.** Its scope is exactly those ten files plus the `index.tsx`
imports, the `App.tsx` `Container`, and the four package removals. Naming it now keeps
"frozen" from quietly meaning "permanent".

Two of those four need not wait: `react-router-bootstrap` and
`@types/react-router-bootstrap` have **zero** usages anywhere in `src/`. They can be
dropped in this sub-project, and are called out here so nobody re-adds them in the
interim.

Removing Bootstrap inside *this* spec would mean rewriting ~2,600 lines of markup before a
single pixel matched the app, with the tokens it was meant to validate still unproven.

---

## 5. Dark mode

`darkMode` stays at Tailwind's default `'media'`. The tokens define dark counterparts and
**every primitive in §3 ships its dark variants from birth**, so no primitive needs
retrofitting later.

The 25 existing files carrying `dark:` classes are **not** audited here. Dark mode is
currently half-on by accident — `LanguagesCard` has `dark:bg-gray-800/80` while
`MemberCard` has none, so on an OS-dark device one card flips and the one beside it stays
white. Each surface sub-project fixes its own files as it converts them. Auditing 25 files
now would be the widest part of the foundation and would delay Community for surfaces we
are about to rewrite anyway.

---

## 6. Backend facts this rests on

Verified in `language_exchange_backend_application`, not inferred from the web's types.

### 6.1 The data exists

`controllers/users.js:20` — `USER_LIST_FIELDS` ships `languageLevel`, `topics`,
`birth_year`, `createdAt`, `isOnline`, `lastActive` and `vipSubscription.isActive`. The
pill has real backing on the list payload, and so do the match tags Community will add.

### 6.2 `languageLevel` defaults to `null`

`models/User.js:744` — `enum: ['A1','A2','B1','B2','C1','C2', null], default: null`. Any
user who never set a level carries `null`, which makes §3.3's "render no dots" rule the
**common** path. Rendering three empty dots instead would mislabel most of the user base
as beginners.

### 6.3 `hasActiveStory` is live on every payload the primitives touch

Stamped in three places, all via the privacy-aware batched helper
`lib/activeStoryFlags.js` → `usersWithVisibleActiveStory`:

- `controllers/users.js:390` — `getUsers`, the community list
- `controllers/users.js:443` — `getUser`, the profile detail
- `controllers/moments.js:33` / `:45` — moment authors, one lookup per feed page

So `communitySlice.ts:53` reads a real boolean and `MemberCard`'s story ring is a
**working feature**. The comment at `users.js:435` records why `getUser` stamps it too:
the ring "appeared on a community card and then vanished when you opened that person's
profile."

This corrects an earlier draft of this spec, which claimed the field was absent from the
community payload and instructed Community to pass `false` — that would have deleted a
shipping feature.

### 6.4 `responseRate` does not exist

It appears nowhere in the backend — no controller, model, lib, service or route. The
app's `community_model.dart:256` parses `json['responseRate']`, which is therefore always
`null`, so the app's own **`Replies fast` match tag can never fire in production.**

Consequence for us: Community must not port that tag.

### 6.5 Findings to hand back to the app team

Neither blocks this spec; both are recorded because they were found here and are invisible
from inside the app.

1. §6.4's dead `Replies fast` tag.
2. `LanguageCodes.displayCode` returns `JP` for Japanese and `YUE` for Cantonese, both
   contradicting the ISO-style rule stated in its own doc comment, and falls through to a
   two-letter slice for any of the ~118 catalog languages outside its 19-name map
   (Persian → `PE`, not `FA`). The web now mirrors this by §3.2.1.

---

## 7. Explicitly not in this spec

`MatchTags` (only Community renders it — building it now would be designing an API with no
consumer), the notification bell and unread badge (Notifications sub-project), shared empty
states and loading skeletons, the app-download banner, VIP and AI Study redirect gating,
the `gray` ramp divergence (§3.1), the Bootstrap retirement itself (§4), and any change to
routing, data fetching or the RTK Query slices beyond §3.7's use of the existing follow
mutations.

No existing surface is converted in this spec. `MemberCard`, `ProfileHeader`,
`SingleMoment` and `LanguagesCard` keep their current markup until their own sub-project
reaches them — the one exception being the §3.2 import swap, which changes their language
*data source* without touching their layout.

---

## 8. Testing

Existing setup: `react-scripts test` (Jest) with `@testing-library/react`. Primitives live
beside their tests, matching `MemberCard.test.tsx` and `parts/*.test.tsx`.

- Unit: `displayCode` parity with the app — `'Korean' → 'KO'`, `'Chinese (Traditional)' →
  'ZH'`, **`'Japanese' → 'JP'`** and **`'Cantonese' → 'YUE'`** (the deliberate quirks of
  §3.2.1, asserted so nobody "fixes" them into ISO), `'Persian' → 'PE'`,
  case-insensitivity, and `'' → ''`.
- Unit: `languageFlag` — the §2.4 guard, asserted on cases whose **output actually
  changes**: `'Estonian'` returns 🇪🇪 and **not** 🇪🇸, `'Frisian'` returns 🇳🇱 and not 🇫🇷
  (the collisions), and `'Persian'` returns 🇮🇷 rather than 🌐 (the widened table from
  §3.2.2). `'Esperanto'` returns 🌐 — correct, and distinct from the 🇪🇸 it shows today.
  A genuinely unknown language still returns `🌐`.
- Unit: variant fidelity, the §3.2.2 guard — `languageFlag('Chinese (Traditional)')`
  returns 🇹🇼 and **not** 🇨🇳, `'Cantonese'` returns 🇭🇰, `'Portuguese (Brazil)'` returns
  🇧🇷. A naive base-code collapse passes none of these, which is the point of asserting
  them.
  Asserting `'Persian'` "resolves via `fa` not `pe`" would prove nothing through the
  public API — both codes were absent from the old ten-key table and both rendered 🌐.
- Unit: `displayCode('Filipino') === 'TL'`, exercising the `fil → tl` branch of
  §3.2.1 step 4 specifically. Without it the port silently regresses to `FI` — Finnish.
- Unit: the level→dots mapping, each CEFR band, plus `null`, `undefined`, `''` and an
  unrecognised string all yielding no dots.
- Component: `LanguageExchangePill` renders both codes and the right dot count; **asserts
  zero dot elements when the level is null** — the §6.2 guard; renders without crashing
  when one code resolves to `''`.
- Component: `Avatar` renders initials when `src` is absent; renders the story ring only
  when `hasStory` is true; renders the online dot only when `isOnline` is true.
- Component: `FollowButton` shows `Following` from cached state, and two instances bound
  to the same user agree after one is clicked — the stale-state regression named in §3.7.
- Component: `Badge` and `SurfaceCard` render their tone/elevation classes.
- Config: a test asserting the `teal-*` scale still resolves (`teal-500` → `#14b8a6`) and
  that `rounded-xl` is still 12px — the guard against a future edit reintroducing the
  override this spec rejected in §3.1.

No snapshot tests. They would lock in markup that four sub-projects are about to consume
and reshape.

---

## 9. Risks

- **Brand tokens create a visibly mixed period.** Until each surface converts, a
  `shadow-card` row can sit beside a `shadow-lg` one on the same screen. This is the
  accepted cost of not detonating 327 + 235 + 102 call sites at once, and it resolves
  surface by surface. It does mean "the web looks inconsistent" is an expected
  intermediate state, not a bug report.
- **The pill deliberately ships two wrong codes.** `JP` and `YUE` are enshrined by §3.2.1
  and pinned by a test. If the app corrects its map, the web's test fails by design and
  must be updated in step — the failure is the notification mechanism.
- **Two primitives land with a single consumer each.** `SurfaceCard` and `Badge` are used
  by Community first and only proven when Moments and Profile arrive. If either API is
  wrong, it is wrong in one place and cheap to change; both are deliberately thin.
- **The §3.2 import swap touches live components.** `MemberCard`, `CommunityDetail`,
  `TandemMemberCard` and `HighlightedProfilesCarousel` change language source without
  changing layout. This is the only user-visible change in an otherwise invisible spec, and
  it moves in two ways: flags that were **wrong** get corrected (Estonian 🇪🇸 → 🇪🇪), and
  flags that were 🌐 become real across the widened table. Both are the fix; both should be
  eyeballed on a profile in an uncommon language before merge.
  `CommunityDetail` deserves its own look, since it is the one screen whose flag helper was
  keyed by name rather than by code.
- **`gray` stays Cool Gray.** Every text and border colour on the web remains slightly
  bluer than the app's. Accepted and documented rather than assumed away; revisit once the
  surfaces are converted and the difference can be judged side by side.
