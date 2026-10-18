# Moments: web vs app parity inventory (research note)

**Date:** 2026-09-23
**Status:** research input for the "Moments parity with the app" sub-project. Not a spec.
**Sources:** backend `routes/moments.js`, `routes/comment.js`, `routes/story.js`, `controllers/moments.js`, `controllers/comments.js`; web `src/components/moments/**`, `src/components/stories/**`, `src/store/slices/momentsSlice.ts`, `storiesSlice.ts`; app `language_exchange_flutter_application/lib/pages/moments/**`.

## 1. Backend API surface (all under `/api/v1`)

| Endpoint | Purpose | Auth | Web uses | App uses |
|---|---|---|---|---|
| `GET /moments?page&limit&feed=forYou\|following` | Main feed (reels excluded) | optionalAuth | yes, without `feed` | yes, incl. `following` |
| `GET /moments/trending`, `/explore` | Discovery feeds | optionalAuth | yes | yes |
| `GET /moments/reels` | Cursor reels feed (404 unless `REELS_ENABLED`) | protect | slice only, no UI | full reels feature |
| `GET /moments/prompt-of-day` | Daily writing prompt | optionalAuth | yes | yes |
| `GET /moments/saved`, `POST/DELETE /:id/save` | Bookmarks | protect | yes | yes |
| `GET /moments/:id`, `/user/:userId` | Detail, profile feed | optionalAuth | yes | yes |
| `POST /moments`, `PUT/DELETE /:id` | CRUD | protect | yes | yes |
| `PUT /:id/photo`, `/video`, `/audio`; `DELETE /:id/video`; `GET /video-config` | Media | protect (config public) | photo/video/audio | yes |
| `POST /:id/like`, `/dislike`, `/share`, `/report` | Interactions | protect | yes | yes |
| `POST/DELETE /:id/react` | Emoji reactions | protect | yes | yes |
| `POST /moments/views` | Batched view counting | protect | **no** | yes |
| `POST /:id/translate`, `GET /:id/translations` | Server translation cache | protect | in slice, **unused in UI** | yes |
| `GET/POST /moments/:id/comments` | Comments, image upload, `correction` payload | GET public, POST protect | text only | text, image, corrections |
| `/comments/:id/like`, `/react`, `/replies`, `/translate`, `/translations` | Comment engagement | protect | **none** | all |
| `GET /stories/feed`, `/my-stories`, `/archive`, `POST /:id/archive` | Stories (24h expiry) | protect | yes | yes |
| `POST /stories`, `/stories/video`, `GET /stories/video-config` | Create | protect | yes (no video-config) | yes |
| `POST /:id/view`, `GET /:id/views` | Views, viewer list | protect | view only | both |
| `POST/DELETE /:id/react`, `GET /:id/reactions` | Story reactions | protect | react only | yes |
| `POST /:id/reply`, `/poll/vote`, `/question/answer`, `GET /question/responses`, `POST /:id/share` | Story engagement | protect | reply, poll | all |
| `/stories/highlights` (+ `/:id`, `/:id/stories`, `/user/:userId`) | Highlights | protect | list/create/delete | full |
| `/stories/close-friends(/:userId)` | Close friends | protect | slice only | yes |

There is **no AI-Study-reply endpoint**; "study" is only a moment category. Corrections are comments carrying a `correction` object (`controllers/comments.js:177`), rendered app-side by `lib/pages/moments/corrections/correction_sheet.dart`.

## 2. Feature gaps, ranked by user value

1. **Translate on tap** for moments and comments. Endpoints and slice hooks exist (`momentsSlice.ts:117-128`); nothing in the UI calls them. No backend work.
2. **Corrections** ("suggest a fix"), the learning differentiator. `POST /comments` with `correction`. No backend work.
3. **Comment engagement**: like, emoji react, threaded replies, image comments. Endpoints exist; web slice has none.
4. **Following feed tab**: pass `?feed=following`.
5. **Reels** vertical video feed (`REELS_ENABLED`-gated); the app has a whole subsystem.
6. **Story viewers list, question stickers, story share, close friends, highlight add/remove**; `updateHighlight` and `highlights/:id/stories` missing from `storiesSlice.ts`.
7. **Moment view counts**: web never posts `/moments/views`, so web traffic under-reports and skews trending.
8. **Story creation studio** (text overlays, drawing, filters, stickers): app-only; backend accepts the media.
9. **AI Study replies**: app-marketed; needs a backend endpoint first.

## 3. Web feed state (as restored in `f10b963`)

`MainMoments.tsx` (1003 lines): For You / Trending / Explore tabs with per-tab `skip`, prompt-of-the-day card with dismiss and composer prefill, client-side filters computed from the current page only, `StoriesFeed`, AdSense slots, `Pagination`. `SingleMoment.tsx` (572): like, react, share, save, video/voice/gradient media. `MomentDetail.tsx` (995) repeats the action wiring plus comments.

Smells: three 900–1000-line components; comments fetched through a second slice (`src/store/slices/comments.ts`) duplicating `momentsSlice`; `MomentDetail` duplicates `SingleMoment`'s handlers; hardcoded English ("Active filters:", "Prompt of the day", tab labels, aria-labels); page-local search silently misses results; `momentsSlice.ts` typed with `any`.

## 4. Prerender notes for `/moments`

`GET /moments`, `/trending`, `/explore`, `/prompt-of-day`, `/:id` are `optionalAuth` with `privacy: 'public'`, so anonymous fetches return real public moments and the page can be prefetched at build time. Hazards: `StoriesFeed` calls the protected `GET /stories/feed` (401 when logged out); `AdUnit` should stay client-only. Without a prefetcher the prerendered `/moments` is a loading shell, an SEO regression against the page's sitemap entry; the fix is a `/moments` prefetcher for the For You first page and the prompt of the day, relying on the existing preloaded-state transfer.
